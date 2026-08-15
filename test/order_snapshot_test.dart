import 'dart:convert';

import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/orders/invoice_screen.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// An order is a record of something that already happened, so none of what it
/// says may change when the catalog behind it does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Address address = Address(
    id: 'a',
    label: 'Home',
    recipient: 'Bbo',
    line1: '1 Street',
    city: 'Portland',
    postcode: '97205',
    country: 'US',
  );

  final Product tee = testProduct(id: 'tee', name: 'Linen Tee', price: 25);
  final Product coat = testProduct(id: 'coat', name: 'Wool Coat', price: 100);

  Catalog catalogOf(List<Product> products) =>
      Catalog(categories: <Category>[], products: products);

  /// Places an order for two tees against [catalog], then rebuilds the world
  /// over the same stored orders with [thenCatalog] — which is what a repriced
  /// or shrunken feed looks like from the app's side.
  Future<ProviderContainer> orderThen(Catalog thenCatalog) async {
    final ProviderContainer first = await testContainer(
      catalog: catalogOf(<Product>[tee, coat]),
    );
    await first.read(catalogProvider.future);
    await first.read(cartProvider.notifier).add(tee, quantity: 2);
    await first
        .read(ordersProvider.notifier)
        .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');

    final String stored = jsonEncode(
      first.read(ordersProvider).map((Order o) => o.toJson()).toList(),
    );

    final ProviderContainer second = await testContainer(
      catalog: thenCatalog,
      initialPrefs: <String, Object>{'orders.list': stored},
    );
    await second.read(catalogProvider.future);
    return second;
  }

  group('a placed order', () {
    test(
      'keeps the price it was bought at when the catalog reprices',
      () async {
        final Product repriced = testProduct(
          id: 'tee',
          name: 'Linen Tee',
          price: 99,
        );
        final ProviderContainer c = await orderThen(
          catalogOf(<Product>[repriced, coat]),
        );

        final Order order = c.read(ordersProvider).single;
        final List<OrderLine> lines = c.read(orderItemsProvider(order.id));

        expect(lines.single.unitPrice, 25, reason: 'price at purchase');
        expect(lines.single.lineTotal, 50);
        expect(order.subtotal, 50);
      },
    );

    test(
      'keeps the name it was bought under when the catalog renames',
      () async {
        final Product renamed = testProduct(
          id: 'tee',
          name: 'Linen T-Shirt (2027)',
          price: 25,
        );
        final ProviderContainer c = await orderThen(
          catalogOf(<Product>[renamed, coat]),
        );

        final Order order = c.read(ordersProvider).single;
        expect(
          c.read(orderItemsProvider(order.id)).single.displayNameIn(testL10n),
          'Linen Tee',
        );
      },
    );

    test('still lists a product that has since been delisted', () async {
      final ProviderContainer c = await orderThen(catalogOf(<Product>[coat]));

      final Order order = c.read(ordersProvider).single;
      final List<OrderLine> lines = c.read(orderItemsProvider(order.id));

      expect(lines, hasLength(1));
      expect(lines.single.displayNameIn(testL10n), 'Linen Tee');
      // The whole point: what's printed still adds up to what was charged.
      final double printed = lines.fold(
        0,
        (double sum, OrderLine l) => sum + l.lineTotal,
      );
      expect(printed, order.subtotal);
    });

    test('renders in full with the catalog unreachable', () async {
      final ProviderContainer c = await orderThen(catalogOf(<Product>[]));

      final Order order = c.read(ordersProvider).single;
      final List<OrderLine> lines = c.read(orderItemsProvider(order.id));

      expect(lines, hasLength(1));
      expect(lines.single.displayNameIn(testL10n), 'Linen Tee');
      expect(lines.single.lineTotal, 50);
    });

    test('prints a receipt that reconciles with its own total', () async {
      final ProviderContainer c = await orderThen(catalogOf(<Product>[]));
      final Order order = c.read(ordersProvider).single;

      final String receipt = buildInvoiceText(
        order,
        c.read(orderItemsProvider(order.id)),
        testL10n,
      );

      expect(receipt, contains('Linen Tee'));
      expect(receipt, contains('2 x'));
      expect(receipt, contains(r'$50.00'));
    });
  });

  group('an order stored before lines carried a snapshot', () {
    /// Exactly what earlier versions wrote: entries with no product detail.
    String legacyOrderJson() => jsonEncode(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'NV-OLD',
        'placedAt': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'entries': <Map<String, dynamic>>[
          <String, dynamic>{'productId': 'tee', 'quantity': 2},
        ],
        'subtotal': 50.0,
        'shipping': 0.0,
        'discount': 0.0,
        'total': 54.0,
        'shippingAddress': 'Bbo, 1 Street',
        'paymentLabel': 'Visa •••• 4242',
      },
    ]);

    test('loads and fills itself in from the catalog', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogOf(<Product>[tee, coat]),
        initialPrefs: <String, Object>{'orders.list': legacyOrderJson()},
      );
      await c.read(catalogProvider.future);

      final List<OrderLine> lines = c.read(orderItemsProvider('NV-OLD'));
      expect(lines.single.displayNameIn(testL10n), 'Linen Tee');
      expect(lines.single.lineTotal, 50);
    });

    test('keeps the line, and says so, when the product has gone', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogOf(<Product>[coat]),
        initialPrefs: <String, Object>{'orders.list': legacyOrderJson()},
      );
      await c.read(catalogProvider.future);

      final List<OrderLine> lines = c.read(orderItemsProvider('NV-OLD'));
      expect(lines, hasLength(1), reason: 'never silently dropped');
      expect(lines.single.displayNameIn(testL10n), 'Item no longer available');
    });

    test('resolves into a line that round-trips with its snapshot', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogOf(<Product>[tee, coat]),
        initialPrefs: <String, Object>{'orders.list': legacyOrderJson()},
      );
      await c.read(catalogProvider.future);

      final OrderLine resolved = c.read(orderItemsProvider('NV-OLD')).single;
      expect(resolved.hasSnapshot, isTrue);
      expect(OrderLine.fromJson(resolved.toJson()).unitPrice, 25);
    });
  });
}
