import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/core/theme/theme_presets.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/profile_provider.dart';
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
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[testProduct(id: 'tee', name: 'Linen Tee')],
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    useMobileSurface(tester);
    setMockPrefs(prefs);
    final SharedPreferences store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
        ],
        child: const NovaApp(),
      ),
    );
    await settle(tester);
  }

  group('greeting', () {
    test('changes across the day', () {
      expect(greetingFor(DateTime(2026, 8, 10, 2)), 'Still up');
      expect(greetingFor(DateTime(2026, 8, 10, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 8, 10, 11, 59)), 'Good morning');
      expect(greetingFor(DateTime(2026, 8, 10, 12)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 8, 10, 17, 59)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 8, 10, 18)), 'Good evening');
      expect(greetingFor(DateTime(2026, 8, 10, 23)), 'Good evening');
    });

    test('uses only the first name', () async {
      final ProviderContainer c = await testContainer();
      await c.read(displayNameProvider.notifier).set('Vladimir Fiffie Jr');
      expect(c.read(displayNameProvider), 'Vladimir Fiffie Jr');
      expect(c.read(firstNameProvider), 'Vladimir');
    });

    test('a one-word name is used as-is', () async {
      final ProviderContainer c = await testContainer();
      await c.read(displayNameProvider.notifier).set('Nova');
      expect(c.read(firstNameProvider), 'Nova');
    });

    test('blank clears the override back to the OS name', () async {
      final ProviderContainer c = await testContainer();
      await c.read(displayNameProvider.notifier).set('Sam');
      expect(c.read(displayNameProvider), 'Sam');

      await c.read(displayNameProvider.notifier).set('   ');
      expect(c.read(displayNameProvider), systemUserName() ?? '');
    });

    test('defaults to the OS account name when nothing is stored', () async {
      final ProviderContainer c = await testContainer();
      // Linux/macOS/Windows expose one; mobile deliberately does not.
      expect(c.read(displayNameProvider), systemUserName() ?? '');
    });

    test('a lowercase username is shown verbatim', () async {
      final ProviderContainer c = await testContainer();
      await c.read(displayNameProvider.notifier).set('bbo');
      expect(c.read(firstNameProvider), 'bbo');
      expect(
        greetingLine(DateTime(2026, 8, 10, 9), c.read(firstNameProvider)),
        'Good morning, bbo',
      );
    });

    test('no name means no trailing comma', () {
      expect(greetingLine(DateTime(2026, 8, 10, 9), ''), 'Good morning');
      expect(greetingLine(DateTime(2026, 8, 10, 20), ''), 'Good evening');
    });

    test('persists', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{'profile.displayName': 'Rae'},
      );
      expect(c.read(firstNameProvider), 'Rae');
    });

    testWidgets('home shows the greeting with the name', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        prefs: const <String, Object>{'profile.displayName': 'bbo'},
      );
      expect(find.text('${greetingFor(DateTime.now())}, bbo'), findsOneWidget);
    });
  });

  group('theme presets', () {
    test('ids are unique and nova is the default', () {
      final Set<String> ids = kThemePresets
          .map((ThemePreset p) => p.id)
          .toSet();
      expect(ids, hasLength(kThemePresets.length));
      expect(kThemePresets.first.id, 'nova');
      expect(presetById(null).id, 'nova');
      expect(presetById('does-not-exist').id, 'nova');
      expect(presetById('forest').label, 'Forest');
    });

    test('each preset yields a distinct primary', () {
      final Set<int> primaries = <int>{
        for (final ThemePreset p in kThemePresets)
          p.swatch(Brightness.light).toARGB32(),
      };
      expect(primaries, hasLength(kThemePresets.length));
    });

    test('the seed drives the generated scheme', () {
      final ThemePreset forest = presetById('forest');
      final ThemeData themed = AppTheme.light(null, seedColor: forest.seed);
      final ThemeData plain = AppTheme.light(null);
      expect(themed.colorScheme.primary, isNot(plain.colorScheme.primary));
      expect(
        themed.colorScheme.primary,
        ColorScheme.fromSeed(seedColor: forest.seed).primary,
      );
    });

    test('presets still work with AMOLED', () {
      final ThemeData t = AppTheme.dark(
        null,
        amoled: true,
        seedColor: presetById('rose').seed,
      );
      expect(t.colorScheme.surface, const Color(0xFF000000));
      expect(
        t.colorScheme.primary,
        ColorScheme.fromSeed(
          seedColor: presetById('rose').seed,
          brightness: Brightness.dark,
        ).primary,
      );
    });

    test('a dynamic scheme overrides the preset', () {
      final ColorScheme dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF00FF00),
      );
      final ThemeData t = AppTheme.light(
        dynamicScheme,
        seedColor: presetById('sunset').seed,
      );
      expect(t.colorScheme.primary, dynamicScheme.primary);
    });

    test('selection persists', () async {
      final ProviderContainer c = await testContainer();
      expect(c.read(settingsProvider).presetId, 'nova');

      await c.read(settingsProvider.notifier).setPreset(presetById('ocean'));
      expect(c.read(settingsProvider).preset.label, 'Ocean');

      final ProviderContainer restored = await testContainer(
        initialPrefs: const <String, Object>{'settings.themePreset': 'plum'},
      );
      expect(restored.read(settingsProvider).preset.label, 'Plum');
    });

    test('an unknown stored id falls back instead of crashing', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'settings.themePreset': 'removed-in-a-later-version',
        },
      );
      expect(c.read(settingsProvider).presetId, 'nova');
    });

    testWidgets('picking a preset repaints the app', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        prefs: const <String, Object>{'settings.themePreset': 'forest'},
      );

      final BuildContext ctx = tester.element(find.byType(NavigationBar));
      expect(
        Theme.of(ctx).colorScheme.primary,
        ColorScheme.fromSeed(seedColor: presetById('forest').seed).primary,
      );
    });
  });
}
