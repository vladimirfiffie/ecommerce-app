import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/favorites/favorites_screen.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/saved_for_later_provider.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Saved-for-later used to live only as a footer of the Bag, which is why
/// Settings could reach it only by throwing the shopper into another tab.
void main() {
  setUpAll(configureTestEnvironment);

  final Product mug = testProduct(id: 'mug', name: 'Mug', price: 10);
  final Product coat = testProduct(id: 'coat', name: 'Coat', price: 200);
  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[mug, coat],
  );

  Future<ProviderContainer> pumpSaved(WidgetTester tester) async {
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
    await container.read(catalogProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const FavoritesScreen(),
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  testWidgets('the tab holds both, and opens on the lists', (
    WidgetTester tester,
  ) async {
    await pumpSaved(tester);

    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('For later'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('for later says how many are waiting', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpSaved(tester);
    await c.read(cartProvider.notifier).add(mug);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);
    await tester.pump();
    await settle(tester);

    expect(find.text('For later (1)'), findsOneWidget);
  });

  testWidgets('switching sections shows what was set aside', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpSaved(tester);
    await c.read(cartProvider.notifier).add(coat);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('For later (1)'));
    await settle(tester);

    expect(find.text('Coat'), findsOneWidget);
    // The list strip belongs to the other section.
    expect(find.text('Nothing saved yet'), findsNothing);
  });

  testWidgets('an empty for-later section points at the bag', (
    WidgetTester tester,
  ) async {
    await pumpSaved(tester);

    await tester.tap(find.text('For later'));
    await settle(tester);

    expect(find.text('Nothing set aside'), findsOneWidget);
    expect(find.text('Open your bag'), findsOneWidget);
  });

  testWidgets('the list menu only appears over a list', (
    WidgetTester tester,
  ) async {
    await pumpSaved(tester);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    await tester.tap(find.text('For later'));
    await settle(tester);

    // Rename and Delete mean nothing for a section that isn't a list.
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });

  test('Settings no longer sends anyone to the Bag for this', () {
    // The row that did is gone; the section is a navigation destination now.
    final String settings = File(
      'lib/features/profile/settings_screen.dart',
    ).readAsStringSync();
    expect(settings.contains('Saved for later'), isFalse);
  });

  testWidgets('making a list is reachable without a menu', (
    WidgetTester tester,
  ) async {
    await pumpSaved(tester);

    // Creating one used to mean the overflow menu at the top right or a
    // small chip — both a stretch on a tall phone.
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.playlist_add_rounded));
    await settle(tester);
    expect(find.text('New list'), findsWidgets);
  });

  testWidgets('and it is absent where it would mean nothing', (
    WidgetTester tester,
  ) async {
    await pumpSaved(tester);

    await tester.tap(find.text('For later'));
    await settle(tester);

    // Nothing on this section is a list, so "new list" has nothing to do.
    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
  });
}
