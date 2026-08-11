import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/core/layout/breakpoints.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/settings_provider.dart';
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
      for (int i = 0; i < 8; i++)
        testProduct(id: 'p$i', name: 'Product $i', price: 20.0 + i),
    ],
  );

  Future<void> pumpAt(WidgetTester tester, Size logical) async {
    tester.view.physicalSize = logical * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
        ],
        child: const NovaApp(),
      ),
    );
    await settle(tester);
  }

  group('breakpoints', () {
    test('classify by width', () {
      expect(Breakpoints.fromWidth(360), WindowSize.compact);
      expect(Breakpoints.fromWidth(599), WindowSize.compact);
      expect(Breakpoints.fromWidth(600), WindowSize.medium);
      expect(Breakpoints.fromWidth(839), WindowSize.medium);
      expect(Breakpoints.fromWidth(840), WindowSize.expanded);
      expect(Breakpoints.fromWidth(1400), WindowSize.expanded);
    });

    test('grid columns grow with the window', () {
      expect(Breakpoints.gridColumns(360), 2);
      expect(Breakpoints.gridColumns(700), 3);
      expect(Breakpoints.gridColumns(900), 4);
      expect(Breakpoints.gridColumns(1250), 5);
      expect(Breakpoints.gridColumns(1600), 6);
    });

    test('only expanded counts as wide', () {
      expect(WindowSize.compact.isWide, isFalse);
      expect(WindowSize.medium.isWide, isFalse);
      expect(WindowSize.expanded.isWide, isTrue);
      expect(WindowSize.medium.isAtLeastMedium, isTrue);
      expect(WindowSize.compact.isAtLeastMedium, isFalse);
    });
  });

  group('shell navigation adapts', () {
    testWidgets('phone width uses the bottom bar', (WidgetTester tester) async {
      await pumpAt(tester, const Size(400, 900));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('tablet width uses the rail', (WidgetTester tester) async {
      await pumpAt(tester, const Size(1000, 800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the rail still switches tabs', (WidgetTester tester) async {
      await pumpAt(tester, const Size(1000, 800));
      await tester.tap(find.text('Bag').last);
      await settle(tester);
      expect(find.text('Your bag'), findsOneWidget);
    });
  });

  group('AMOLED theme', () {
    test('flattens dark surfaces to true black', () {
      final ThemeData normal = AppTheme.dark(null);
      final ThemeData amoled = AppTheme.dark(null, amoled: true);

      expect(amoled.colorScheme.surface, const Color(0xFF000000));
      expect(amoled.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(normal.colorScheme.surface, isNot(const Color(0xFF000000)));
    });

    test('keeps elevation tiers distinguishable', () {
      final ColorScheme s = AppTheme.dark(null, amoled: true).colorScheme;
      expect(
        s.surfaceContainerLow.toARGB32(),
        greaterThan(s.surface.toARGB32()),
      );
      expect(
        s.surfaceContainerHighest.toARGB32(),
        greaterThan(s.surfaceContainer.toARGB32()),
      );
    });

    test('leaves the brand palette alone', () {
      final ColorScheme plain = AppTheme.dark(null).colorScheme;
      final ColorScheme black = AppTheme.dark(null, amoled: true).colorScheme;
      expect(black.primary, plain.primary);
      expect(black.primaryContainer, plain.primaryContainer);
      expect(black.error, plain.error);
    });

    test('does not touch the light theme', () {
      expect(
        AppTheme.light(null).colorScheme.surface,
        isNot(const Color(0xFF000000)),
      );
    });

    testWidgets('the setting drives the live theme', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      setMockPrefs(<String, Object>{
        'settings.themeMode': 'dark',
        'settings.amoled': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            productRepositoryProvider.overrideWithValue(
              FakeProductRepository(catalog),
            ),
          ],
          child: const NovaApp(),
        ),
      );
      await settle(tester);

      final BuildContext ctx = tester.element(find.byType(NavigationBar));
      expect(Theme.of(ctx).colorScheme.surface, const Color(0xFF000000));
    });
  });

  group('settings persistence', () {
    test('amoled round-trips through storage', () async {
      final ProviderContainer c = await testContainer();
      expect(c.read(settingsProvider).amoled, isFalse);

      await c.read(settingsProvider.notifier).setAmoled(true);
      expect(c.read(settingsProvider).amoled, isTrue);

      final ProviderContainer restored = await testContainer(
        initialPrefs: const <String, Object>{'settings.amoled': true},
      );
      expect(restored.read(settingsProvider).amoled, isTrue);
    });
  });
}
