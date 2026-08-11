import 'dart:convert';

import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/cart_entry.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_filter_provider.dart';
import 'package:ecommerce_app/state/for_you_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  final Catalog catalog = Catalog(
    categories: const <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        icon: Icons.checkroom_rounded,
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25),
      testProduct(id: 'coat', name: 'Wool Coat', price: 80),
      testProduct(id: 'gone', name: 'Sold Out Hat', price: 15, stock: 0),
    ],
  );

  Future<ProviderContainer> container({
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    final ProviderContainer c = await testContainer(
      catalog: catalog,
      initialPrefs: prefs,
    );
    await c.read(catalogProvider.future);
    return c;
  }

  group('nothing to say', () {
    test('a fresh install shows no block at all', () async {
      final ProviderContainer c = await container();
      // A permanent empty "For you" heading is worse than no heading.
      expect(c.read(forYouProvider), isEmpty);
    });
  });

  group('back in stock', () {
    test('a watched item that has stock again is surfaced', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['tee'],
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.backInStock);
      expect(item.product?.id, 'tee');
    });

    test('a watched item still out of stock is not', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['gone'],
        },
      );
      expect(c.read(forYouProvider), isEmpty);
    });
  });

  group('price drops', () {
    test('a saved item cheaper than when it was saved is surfaced', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'tee': 40}),
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.priceDrop);
      expect(item.subtitle, contains('Linen Tee'));
    });

    test('a saved item at the same price is not', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'tee': 25}),
        },
      );
      expect(c.read(forYouProvider), isEmpty);
    });

    test('several drops collapse into one row', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee', 'coat'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{
            'tee': 40,
            'coat': 120,
          }),
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.count, 2);
      expect(item.subtitle, contains('2 saved items'));
    });
  });

  group('the bag', () {
    test('is mentioned when something is in it', () async {
      final ProviderContainer c = await container();
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.inBag);
      expect(item.subtitle, contains('1 item'));
    });
  });

  group('ordering', () {
    test('stock and price news outrank a bag reminder', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['tee'],
          'favorites.ids': <String>['coat'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'coat': 120}),
        },
      );
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);

      expect(c.read(forYouProvider).map((ForYouItem i) => i.kind), <ForYouKind>[
        ForYouKind.backInStock,
        ForYouKind.priceDrop,
        ForYouKind.inBag,
      ]);
    });

    test('recently viewed only fills in when there is no real news', () async {
      final ProviderContainer c = await container();
      await c.read(recentlyViewedProvider.notifier).record('coat');

      expect(
        c.read(forYouProvider).single.kind,
        ForYouKind.pickUpWhereYouLeftOff,
      );

      // The moment something real happens, the filler drops out.
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      expect(c.read(forYouProvider).single.kind, ForYouKind.inBag);
    });
  });

  group('orders', () {
    const Address address = Address(
      id: 'a',
      label: 'Home',
      recipient: 'Bbo',
      line1: '1 Street',
      city: 'Portland',
      postcode: '97205',
      country: 'US',
    );

    /// Seeds a stored order placed [placedAgo] in the past, so its
    /// clock-derived status is whatever the test needs rather than always
    /// "just placed".
    Future<ProviderContainer> withOrder({
      required Duration placedAgo,
      bool requestReturn = false,
    }) async {
      final Order order = Order(
        id: 'NV-TEST',
        placedAt: DateTime.now().subtract(placedAgo),
        entries: const <CartEntry>[CartEntry(productId: 'tee', quantity: 1)],
        subtotal: 25,
        shipping: 0,
        discount: 0,
        total: 25,
        shippingAddress: '${address.recipient}, ${address.oneLine}',
        paymentLabel: 'Visa •••• 4242',
      );

      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'orders.list': jsonEncode(<Map<String, dynamic>>[order.toJson()]),
        },
      );

      if (requestReturn) {
        await c
            .read(ordersProvider.notifier)
            .requestReturn(
              orderId: order.id,
              lineIds: <String>{order.entries.first.lineId},
              reason: ReturnReason.changedMind,
              refundAmount: 25,
            );
      }
      return c;
    }

    test('a just-placed order leads, still on the first stage', () async {
      final ProviderContainer c = await withOrder(placedAgo: Duration.zero);
      final ForYouItem item = c.read(forYouProvider).first;

      expect(item.kind, ForYouKind.orderInTransit);
      expect(item.title, startsWith('Arriving '));
      expect(item.subtitle, contains('Processing'));
      expect(item.progress?.stage, 0);
    });

    test('once it ships the tracker moves on', () async {
      final ProviderContainer c = await withOrder(
        placedAgo: const Duration(days: 1),
      );
      final ForYouItem item = c.read(forYouProvider).first;

      expect(item.subtitle, contains('Shipped'));
      expect(item.progress?.stage, 1);
    });

    test('a delivered parcel says how long is left to send it back', () async {
      // Standard delivery is 5 days, so this landed yesterday.
      final ProviderContainer c = await withOrder(
        placedAgo: const Duration(days: 6),
      );
      final ForYouItem item = c.read(forYouProvider).first;

      expect(item.kind, ForYouKind.orderDelivered);
      expect(item.progress?.stage, 2);
      expect(item.subtitle, contains('left to return'));
    });

    test('and stops being news once it is old', () async {
      final ProviderContainer c = await withOrder(
        placedAgo: const Duration(days: 40),
      );
      expect(
        c
            .read(forYouProvider)
            .where((ForYouItem i) => i.kind == ForYouKind.orderDelivered),
        isEmpty,
      );
    });

    test('a filed return shows when the money is due back', () async {
      final ProviderContainer c = await withOrder(
        placedAgo: const Duration(days: 8),
        requestReturn: true,
      );
      final ForYouItem item = c.read(forYouProvider).first;

      expect(item.kind, ForYouKind.returnInProgress);
      expect(item.subtitle, startsWith('Refund expected by '));
    });

    test('a cancelled order is not mentioned at all', () async {
      final ProviderContainer c = await withOrder(placedAgo: Duration.zero);
      await c
          .read(ordersProvider.notifier)
          .cancel(c.read(ordersProvider).single.id);

      expect(c.read(forYouProvider), isEmpty);
    });

    test('parcels outrank shopping nudges', () async {
      final ProviderContainer c = await withOrder(placedAgo: Duration.zero);
      await c.read(cartProvider.notifier).add(catalog.byId('coat')!);

      final List<ForYouKind> kinds = c
          .read(forYouProvider)
          .map((ForYouItem i) => i.kind)
          .toList();
      expect(kinds.first, ForYouKind.orderInTransit);
      expect(kinds, contains(ForYouKind.inBag));
    });
  });

  group('the bag row', () {
    test('says how much more buys free delivery', () async {
      final ProviderContainer c = await container();
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);

      // $25 of a $75 threshold.
      expect(
        c.read(forYouProvider).single.subtitle,
        contains('\$50.00 from free delivery'),
      );
    });

    test('and celebrates once the threshold is cleared', () async {
      final ProviderContainer c = await container();
      await c
          .read(cartProvider.notifier)
          .add(catalog.byId('coat')!, quantity: 2);

      expect(
        c.read(forYouProvider).single.subtitle,
        contains('free delivery unlocked'),
      );
    });
  });

  group('almost gone', () {
    test('a saved item down to its last few is flagged', () async {
      final Catalog scarce = Catalog(
        categories: catalog.categories,
        products: <Product>[
          testProduct(id: 'tee', name: 'Linen Tee', stock: 2),
        ],
      );
      final ProviderContainer c = await testContainer(
        catalog: scarce,
        initialPrefs: <String, Object>{
          'favorites.ids': <String>['tee'],
        },
      );
      await c.read(catalogProvider.future);

      final ForYouItem item = c
          .read(forYouProvider)
          .firstWhere((ForYouItem i) => i.kind == ForYouKind.lowStockSaved);
      expect(item.subtitle, contains('only 2 left'));
    });

    test('a sold-out favourite is left to the back-in-stock watch', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['gone'],
        },
      );
      expect(c.read(forYouProvider), isEmpty);
    });
  });
}
