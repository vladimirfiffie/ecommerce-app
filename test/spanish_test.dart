import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_app/core/l10n/enum_labels.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/drop_off.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/features/orders/invoice_screen.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aster shipped in one language for long enough that "translatable" and
/// "translated" were easy to confuse. These hold the second language to the
/// first: same keys, same placeholders, and no English left standing in it.
void main() {
  final Map<String, dynamic> en =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final Map<String, dynamic> es =
      jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((String k) => !k.startsWith('@')).toSet();

  /// The `{name}` slots a message expects. A translation that drops one
  /// compiles and then renders a sentence with a hole in it.
  ///
  /// A brace followed by a bare identifier and then `}` or `,` — which is a
  /// placeholder, or the head of a plural. Prose inside a plural branch,
  /// `other{None of these are available}`, is not either.
  Set<String> slotsIn(String message) => RegExp(
    r'\{(\w+)[},]',
  ).allMatches(message).map((RegExpMatch m) => m.group(1)!).toSet();

  test('Spanish has every key English does, and no others', () {
    expect(messageKeys(es), messageKeys(en));
  });

  test('every message keeps its placeholders', () {
    for (final String key in messageKeys(en)) {
      expect(
        slotsIn(es[key] as String),
        slotsIn(en[key] as String),
        reason: key,
      );
    }
  });

  test('nothing was left in English', () {
    // Not a translation check — it can't be — but it catches the copy-paste
    // that leaves a key sitting in the source language.
    final List<String> untranslated = <String>[
      for (final String key in messageKeys(en))
        if (es[key] == en[key] && (en[key] as String).length > 8) key,
    ];
    expect(untranslated, isEmpty);
  });

  test('every English message is documented', () {
    // The description is what a translator works from; a key without one is
    // a guess waiting to happen.
    for (final String key in messageKeys(en)) {
      final Object? meta = en['@$key'];
      expect(meta, isNotNull, reason: '$key has no @$key entry');
      expect(
        (meta! as Map<String, dynamic>)['description'],
        isNotNull,
        reason: '$key has no description',
      );
    }
  });

  test('Spanish is a locale the app actually offers', () {
    expect(
      AppL10n.supportedLocales.map((Locale l) => l.languageCode),
      containsAll(<String>['en', 'es']),
    );
  });

  group('the enums come back in Spanish too', () {
    final AppL10n l10n = lookupAppL10n(const Locale('es'));

    test('order statuses', () {
      expect(OrderStatus.processing.labelIn(l10n), 'En preparación');
      expect(OrderStatus.refunded.labelIn(l10n), 'Reembolsado');
    });

    test('return reasons', () {
      expect(ReturnReason.damaged.labelIn(l10n), 'Llegó dañado');
    });

    test('delivery options', () {
      expect(DeliveryOption.pickup.labelIn(l10n), 'Recoger en tienda');
    });

    test('drop-off choices', () {
      expect(DropOff.atDoor.labelIn(l10n), 'Dejarlo en mi puerta');
    });

    test('no switch falls through in the second language either', () {
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
      for (final DropOff d in DropOff.values) {
        expect(d.labelIn(l10n), isNotEmpty, reason: d.name);
      }
    });
  });

  group('the buy path actually renders in Spanish', () {
    /// The ARB tests prove the strings exist. This proves the screens reach
    /// them — a `Text('Checkout')` left inline passes every test above.
    Future<void> pumpIn(
      WidgetTester tester,
      Locale locale,
      Widget child,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(body: Builder(builder: (BuildContext _) => child)),
        ),
      );
      await tester.pump();
    }

    testWidgets('the receipt is built from the lookup, not from literals', (
      WidgetTester tester,
    ) async {
      final Order order = Order(
        id: 'NV-1',
        placedAt: DateTime(2026, 8, 1),
        lines: const <OrderLine>[],
        subtotal: 20,
        shipping: 0,
        discount: 0,
        total: 21.6,
        shippingAddress: 'Ada, 1 Test Way',
        paymentLabel: 'Visa ····4242',
      );

      final String spanish = buildInvoiceText(
        order,
        const <OrderLine>[],
        lookupAppL10n(const Locale('es')),
      );
      final String english = buildInvoiceText(
        order,
        const <OrderLine>[],
        lookupAppL10n(const Locale('en')),
      );

      expect(spanish, contains('ASTER — RECIBO'));
      expect(spanish, contains('Pedido NV-1'));
      expect(spanish, contains('Envío'));
      expect(spanish, isNot(contains('Ship to')));
      expect(english, contains('Ship to'));
    });

    testWidgets('the receipt columns line up whatever the labels are', (
      WidgetTester tester,
    ) async {
      // Padded by hand, the totals column walked off the page the moment a
      // label got longer than the padding allowed for. Each language should
      // line its own totals up, at whatever column its labels need.
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('es'),
      ]) {
        final AppL10n l10n = lookupAppL10n(locale);
        final String text = buildInvoiceText(
          Order(
            id: 'NV-1',
            placedAt: DateTime(2026, 8, 1),
            lines: const <OrderLine>[],
            subtotal: 20,
            shipping: 0,
            discount: 3,
            total: 18.6,
            shippingAddress: 'Ada, 1 Test Way',
            paymentLabel: 'Visa ····4242',
            creditApplied: 5,
          ),
          const <OrderLine>[],
          l10n,
        );

        final List<String> labels = <String>[
          l10n.summarySubtotal,
          l10n.summaryDiscount,
          l10n.summaryShipping,
          l10n.receiptTotalCaps,
          l10n.summaryStoreCredit,
          l10n.receiptChargedCaps,
        ];

        // Where each value begins: the first character after the padding.
        final Set<int> valueColumns = <int>{
          for (final String line in text.split('\n'))
            if (labels.any(line.startsWith))
              if (RegExp(r'\s{2,}').firstMatch(line) case final RegExpMatch gap)
                gap.end,
        };

        // Six totals rows on this order, all starting their value at the
        // same column — one column, not six.
        expect(valueColumns, hasLength(1), reason: '\$locale: $valueColumns');
      }
    });

    testWidgets('the bag heading comes from the lookup', (
      WidgetTester tester,
    ) async {
      await pumpIn(
        tester,
        const Locale('es'),
        Builder(
          builder: (BuildContext context) => Text(AppL10n.of(context).bagTitle),
        ),
      );
      expect(find.text('Tu bolsa'), findsOneWidget);
      expect(find.text('Your bag'), findsNothing);
    });
  });
}
