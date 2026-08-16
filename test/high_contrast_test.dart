import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// WCAG contrast ratio between two opaque colours.
double _ratio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  group('high contrast', () {
    test('pulls the light scheme further apart', () {
      final ColorScheme plain = AppTheme.light(null).colorScheme;
      final ColorScheme loud = AppTheme.light(
        null,
        highContrast: true,
      ).colorScheme;

      expect(
        _ratio(loud.onSurface, loud.surface),
        greaterThan(_ratio(plain.onSurface, plain.surface)),
      );
      expect(
        _ratio(loud.onPrimary, loud.primary),
        greaterThanOrEqualTo(_ratio(plain.onPrimary, plain.primary)),
      );
    });

    test('does the same in the dark', () {
      final ColorScheme plain = AppTheme.dark(null).colorScheme;
      final ColorScheme loud = AppTheme.dark(
        null,
        highContrast: true,
      ).colorScheme;

      expect(
        _ratio(loud.onSurface, loud.surface),
        greaterThan(_ratio(plain.onSurface, plain.surface)),
      );
    });

    test('still collapses to black for AMOLED', () {
      final ColorScheme loud = AppTheme.dark(
        null,
        amoled: true,
        highContrast: true,
      ).colorScheme;

      expect(loud.surface, const Color(0xFF000000));
    });

    test('outranks a wallpaper palette, which has no contrast dial', () {
      const ColorScheme wallpaper = ColorScheme.light(
        primary: Color(0xFF7A7A7A),
        surface: Color(0xFFBBBBBB),
        onSurface: Color(0xFF999999),
      );

      expect(AppTheme.light(wallpaper).colorScheme.surface, wallpaper.surface);

      final ColorScheme loud = AppTheme.light(
        wallpaper,
        highContrast: true,
      ).colorScheme;
      expect(loud.surface, isNot(wallpaper.surface));
      expect(
        _ratio(loud.onSurface, loud.surface),
        greaterThan(_ratio(wallpaper.onSurface, wallpaper.surface)),
      );
    });
  });

  testWidgets('the running app takes it from the platform', (
    WidgetTester tester,
  ) async {
    useMobileSurface(tester);
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Catalog catalog = Catalog(
      categories: <Category>[
        Category(
          id: 'fashion',
          label: 'Fashion',
          iconName: 'checkroom',
          imageUrl: '',
        ),
      ],
      products: <Product>[testProduct()],
    );

    Future<ColorScheme> schemeWith(bool highContrast) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              productRepositoryProvider.overrideWithValue(
                FakeProductRepository(catalog),
              ),
            ],
            child: const AsterApp(),
          ),
        ),
      );
      await settle(tester);
      return Theme.of(tester.element(find.byType(NavigationBar))).colorScheme;
    }

    final ColorScheme plain = await schemeWith(false);
    final ColorScheme loud = await schemeWith(true);

    expect(
      _ratio(loud.onSurface, loud.surface),
      greaterThan(_ratio(plain.onSurface, plain.surface)),
    );
  });
}
