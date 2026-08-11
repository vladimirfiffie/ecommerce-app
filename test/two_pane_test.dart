import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/orders/order_detail_screen.dart';
import 'package:ecommerce_app/features/product/product_detail_screen.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

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
      testProduct(id: 'coat', name: 'Wool Coat', price: 120),
    ],
  );

  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    Size logical, {
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    tester.view.physicalSize = logical * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(prefs);
    final SharedPreferences store = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(store),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const NovaApp()),
    );
    await settle(tester);
    return c;
  }

  const Size phone = Size(400, 900);
  const Size tablet = Size(1100, 850);

  group('shop', () {
    testWidgets('a phone pushes the product as its own route', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, phone);
      await tester.tap(find.text('Shop').last);
      await settle(tester);

      expect(find.byType(ProductDetailScreen), findsNothing);
      await tester.tap(find.text('Linen Tee').first);
      await settle(tester);

      // The catalog is gone: a route was pushed over it.
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Shop'), findsNothing);
    });

    testWidgets('a tablet opens it beside the grid', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, tablet);
      await tester.tap(find.text('Shop').last);
      await settle(tester);

      expect(
        find.text('Pick something on the left to see it here.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Linen Tee').first);
      await settle(tester);

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      // The list is still there — that's the point of two panes.
      expect(find.text('Wool Coat'), findsWidgets);
    });

    testWidgets('selecting a second product swaps the pane', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, tablet);
      await tester.tap(find.text('Shop').last);
      await settle(tester);

      await tester.tap(find.text('Linen Tee').first);
      await settle(tester);
      expect(find.text('Add to bag'), findsOneWidget);

      await tester.tap(find.text('Wool Coat').first);
      await settle(tester);
      // Still exactly one detail pane, now showing the other product.
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Add to bag'), findsOneWidget);
    });

    testWidgets('the embedded pane has no back button', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, tablet);
      await tester.tap(find.text('Shop').last);
      await settle(tester);
      await tester.tap(find.text('Linen Tee').first);
      await settle(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });

  group('orders', () {
    Future<ProviderContainer> withOrders(WidgetTester tester, Size size) async {
      final ProviderContainer c = await pumpAt(tester, size);
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      await c
          .read(ordersProvider.notifier)
          .placeOrder(
            address: const Address(
              id: 'a',
              label: 'Home',
              recipient: 'Bbo',
              line1: '1 Street',
              city: 'Portland',
              postcode: '97205',
              country: 'US',
            ),
            paymentLabel: 'Visa •••• 4242',
          );
      await settle(tester);
      return c;
    }

    testWidgets('a tablet shows the newest order straight away', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await withOrders(tester, tablet);
      final String id = c.read(ordersProvider).single.id;

      await tester.tap(find.text('Profile').last);
      await settle(tester);
      await tester.tap(find.text('Your orders').first);
      await settle(tester);

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.text(id), findsWidgets);
    });

    testWidgets('a phone lists them without a detail pane', (
      WidgetTester tester,
    ) async {
      await withOrders(tester, phone);

      await tester.tap(find.text('Profile').last);
      await settle(tester);
      await tester.tap(find.text('Your orders').first);
      await settle(tester);

      expect(find.byType(OrderDetailScreen), findsNothing);
    });
  });

  group('layout switching', () {
    testWidgets('resizing from tablet to phone drops the second pane', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, tablet);
      await tester.tap(find.text('Shop').last);
      await settle(tester);
      await tester.tap(find.text('Linen Tee').first);
      await settle(tester);
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      // Shrink to a phone: the pane collapses rather than leaving a stranded
      // detail view with no way back.
      tester.view.physicalSize = phone * 3;
      await settle(tester);

      expect(find.byType(ProductDetailScreen), findsNothing);
      expect(find.text('Linen Tee'), findsWidgets);
    });
  });
}
