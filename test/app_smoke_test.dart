import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'package:ecommerce_app/features/home/widgets/hero_carousel.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

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
      testProduct(id: 'coat', name: 'Wool Coat', price: 120, isFeatured: true),
      testProduct(id: 'tee', name: 'Linen Tee', price: 25, isNew: true),
    ],
  );

  Future<Widget> buildApp() async {
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
      child: const AsterApp(),
    );
  }

  testWidgets('boots to the home tab and renders the catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    // The greeting is the header now — no brand mark above it.
    expect(find.textContaining('Good'), findsOneWidget);
    expect(find.text('Aster'), findsNothing);
    // Categories live on Shop and Search now, not duplicated on Home.
    expect(find.text('Browse categories'), findsNothing);
    expect(find.byType(HeroCarousel), findsOneWidget);
    expect(find.text('Wool Coat'), findsWidgets);
  });

  testWidgets('bottom navigation switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    await tester.tap(find.text('Bag'));
    await settle(tester);
    expect(find.text('Your bag'), findsOneWidget);
    expect(find.text('Your bag is empty'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await settle(tester);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await settle(tester);
    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets('adding to the bag updates the cart badge and totals', (
    WidgetTester tester,
  ) async {
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

    // The tee has no size or colour options, so it adds in one tap.
    await container
        .read(cartProvider.notifier)
        .add(catalog.byId('tee')!, quantity: 2);
    await settle(tester);

    expect(container.read(cartCountProvider), 2);

    await tester.tap(find.text('Bag'));
    await settle(tester);

    expect(find.text('Linen Tee'), findsOneWidget);
    expect(find.textContaining(r'$50.00'), findsWidgets);
  });
}
