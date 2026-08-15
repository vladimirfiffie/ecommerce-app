import 'package:ecommerce_app/core/l10n/enum_labels.dart';
import 'package:ecommerce_app/core/utils/formatters.dart';
import 'package:ecommerce_app/core/utils/semantic_labels.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'helpers.dart';

/// Money and dates used to be pinned to `en_US` no matter where the app ran,
/// and the words for order statuses, return reasons and auth errors lived on
/// the enums themselves — somewhere no `BuildContext` could reach, and so
/// somewhere no translation could ever apply.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeDateFormatting);

  /// Runs [body] as though the device were in [locale], then puts the global
  /// back — `Intl.defaultLocale` outlives a single test otherwise.
  T inLocale<T>(String locale, T Function() body) {
    final String? previous = Intl.defaultLocale;
    Intl.defaultLocale = locale;
    resetFormatters();
    try {
      return body();
    } finally {
      Intl.defaultLocale = previous;
      resetFormatters();
    }
  }

  /// CLDR uses narrow and non-breaking spaces as group and currency
  /// separators in several locales. Those are correct output but invisible in
  /// a source file, so comparisons flatten them to an ordinary space.
  String plainSpaces(String value) =>
      value.replaceAll(RegExp(r'[\u00A0\u202F\u2009]'), ' ');

  group('formatting', () {
    test('follows the locale rather than always being American', () {
      expect(inLocale('en_US', () => formatPrice(1299.5)), r'$1,299.50');
      expect(
        plainSpaces(inLocale('de_DE', () => formatPrice(1299.5))),
        r'1.299,50 $',
      );
    });

    test('writes dates the way the locale writes them', () {
      final DateTime day = DateTime(2026, 8, 15);
      expect(inLocale('en_US', () => formatDate(day)), 'Aug 15, 2026');
      expect(inLocale('de_DE', () => formatDate(day)), '15. Aug. 2026');
      expect(inLocale('ja_JP', () => formatDate(day)), '2026年8月15日');
    });

    test('the amount is the same amount in every locale', () {
      // Prices are quoted in USD by the feed; only the writing changes.
      expect(kCurrencyCode, 'USD');
      for (final String locale in <String>['en_US', 'fr_FR', 'ja_JP']) {
        expect(
          inLocale(locale, () => formatPrice(10)),
          contains('10'),
          reason: locale,
        );
      }
    });

    test('groups thousands the way the locale does', () {
      expect(inLocale('en_US', () => formatCount(1234)), '1.2K');
      expect(plainSpaces(inLocale('fr_FR', () => formatCount(1234))), '1,2 k');
    });
  });

  group('copy that used to live on enums', () {
    test('order statuses resolve through the lookup', () {
      final AppL10n l10n = testL10n;
      expect(OrderStatus.processing.labelIn(l10n), 'Processing');
      expect(OrderStatus.returnRequested.labelIn(l10n), 'Return requested');
    });

    test('return reasons resolve through the lookup', () {
      expect(ReturnReason.damaged.labelIn(testL10n), 'Arrived damaged');
    });

    test('delivery options resolve through the lookup', () {
      expect(DeliveryOption.pickup.labelIn(testL10n), 'Collect in store');
      expect(DeliveryOption.standard.blurbIn(testL10n), '3–5 business days');
    });

    test('every enum value has a string — no switch falls through', () {
      final AppL10n l10n = testL10n;
      for (final OrderStatus s in OrderStatus.values) {
        expect(s.labelIn(l10n), isNotEmpty, reason: s.name);
      }
      for (final ReturnReason r in ReturnReason.values) {
        expect(r.labelIn(l10n), isNotEmpty, reason: r.name);
      }
      for (final DeliveryOption d in DeliveryOption.values) {
        expect(d.labelIn(l10n), isNotEmpty, reason: d.name);
        expect(d.blurbIn(l10n), isNotEmpty, reason: d.name);
      }
    });
  });

  group('spoken labels', () {
    test('put the sale price and the old price in the right order', () {
      expect(
        inLocale(
          'en_US',
          () => priceLabel(
            testProduct(id: 'p', price: 30, compareAtPrice: 50),
            testL10n,
          ),
        ),
        r'$30.00, reduced from $50.00, 40% off',
      );
    });

    test('count the reviews grammatically', () {
      expect(ratingLabel(4.5, testL10n, 1), endsWith('from 1 review'));
      expect(ratingLabel(4.5, testL10n, 2), endsWith('from 2 reviews'));
    });

    test('take the locale with them', () {
      final String german = inLocale(
        'de_DE',
        () => priceLabel(
          testProduct(id: 'p', price: 30, compareAtPrice: 50),
          testL10n,
        ),
      );
      expect(german, contains('30,00'), reason: 'German decimal comma');
    });
  });

  group('the app', () {
    testWidgets('declares its supported locales and their delegates', (
      WidgetTester tester,
    ) async {
      expect(AppL10n.supportedLocales, contains(const Locale('en')));
      expect(AppL10n.localizationsDelegates, isNotEmpty);
    });

    testWidgets('serves strings through the standard lookup', (
      WidgetTester tester,
    ) async {
      late AppL10n found;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              found = AppL10n.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(found.retry, 'Retry');
    });
  });
}
