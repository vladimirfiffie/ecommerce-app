import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Drives the whole purchase path the way a shopper would, since the Linux
/// desktop target can't be screenshotted from this environment.
void main() {
  setUpAll(configureTestEnvironment);

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25, isFeatured: true),
      testProduct(id: 'coat', name: 'Wool Coat', price: 120),
    ],
  );

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    useMobileSurface(tester);
    stubHaptics();
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AsterApp()),
    );
    await settle(tester);
    return container;
  }

  testWidgets('shop → product → bag → checkout → confirmation', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpApp(tester);

    // Shop tab, then open a product.
    await tester.tap(find.text('Shop'));
    await settle(tester);
    await tester.tap(find.text('Linen Tee').first);
    await settle(tester);

    expect(find.text('Add to bag'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    // This product has no variants, so one tap is enough.
    await tester.tap(find.text('Add to bag'));
    await settle(tester);
    expect(container.read(cartCountProvider), 1);

    // The confirmation snackbar floats over the bottom bar; let it expire.
    await clearSnackBars(tester);

    // Back out of the detail page and into the bag.
    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text('Bag'));
    await settle(tester);

    expect(find.text('Your bag'), findsOneWidget);
    expect(find.text('Linen Tee'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await settle(tester);

    // Shipping → Payment → Review.
    expect(find.text('Ship to'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Pay with'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Review your order'), findsOneWidget);

    // The final step is a slide gesture, not a tap: drag the handle (the
    // GestureDetector lives on the handle, not the track) past the 98% mark.
    expect(find.textContaining('Slide to pay'), findsOneWidget);
    await tester.drag(find.byIcon(Icons.arrow_forward), const Offset(500, 0));
    await tester.pump();
    // The placing state holds for ~900ms before the order lands.
    await tester.pump(const Duration(milliseconds: 1200));
    await settle(tester);

    expect(find.text('Order confirmed'), findsOneWidget);

    final List<Order> orders = container.read(ordersProvider);
    expect(orders, hasLength(1));
    expect(orders.single.itemCount, 1);
    expect(orders.single.total, greaterThan(25));
    // Placing an order empties the bag.
    expect(container.read(cartProvider), isEmpty);
  });

  testWidgets('a product needing a size refuses a bare add-to-bag', (
    WidgetTester tester,
  ) async {
    useMobileSurface(tester);
    stubHaptics();
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Catalog sized = Catalog(
      categories: <Category>[],
      products: <Product>[
        testProduct(
          id: 'shirt',
          name: 'Oxford Shirt',
          sizes: const <String>['S', 'M', 'L'],
        ),
      ],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(sized),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AsterApp()),
    );
    await settle(tester);

    await tester.tap(find.text('Shop'));
    await settle(tester);
    await tester.tap(find.text('Oxford Shirt').first);
    await settle(tester);

    await tester.tap(find.text('Add to bag'));
    await settle(tester);
    expect(find.text('Pick a size first'), findsOneWidget);
    expect(container.read(cartCountProvider), 0);
    await clearSnackBars(tester);

    // The size dropdown sits under the sticky buy bar until the page is
    // scrolled, and its options only exist once it is open.
    await revealAndTap(
      tester,
      find.byType(DropdownButtonFormField<String>),
    );
    await tester.tap(find.text('M').last);
    await settle(tester);

    await tester.tap(find.text('Add to bag'));
    await settle(tester);

    expect(container.read(cartCountProvider), 1);
    expect(container.read(cartProvider).single.size, 'M');
  });

  testWidgets('wishlist survives a tab round trip', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpApp(tester);

    await tester.tap(find.text('Shop'));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await settle(tester);
    expect(container.read(favoritesProvider), hasLength(1));

    await tester.tap(find.text('Saved'));
    await settle(tester);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsNothing);
  });
}
