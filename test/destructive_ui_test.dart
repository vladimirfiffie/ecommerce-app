import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/features/orders/orders_screen.dart';
import 'package:ecommerce_app/shared/widgets/confirm.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

void main() {
  ColorScheme schemeOf(WidgetTester tester, Finder finder) =>
      Theme.of(tester.element(finder)).colorScheme;

  group('destructive confirmations', () {
    testWidgets('the confirming action is red, the way out is not', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => confirmDestructive(
                  context,
                  title: 'Remove card?',
                  message: 'Visa 4242',
                  confirmLabel: 'Remove',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The platform draws the dialog now, so the assertion is what has to be
      // true wherever it is drawn rather than the exact swatch: the
      // destructive action reads red and the way out does not. The package
      // uses its own red rather than the theme's error colour, which is the
      // one thing given up by handing the dialog over.
      final Color? confirm = _foregroundOf(tester, 'Remove');
      final Color? cancel = _foregroundOf(tester, 'Cancel');

      expect(confirm, isNotNull);
      expect(
        confirm!.r,
        greaterThan(confirm.g + confirm.b),
        reason: 'a delete must read as red, not as a save',
      );
      expect(
        cancel,
        isNot(confirm),
        reason: 'the way out must not look like the destructive action',
      );
    });

    testWidgets('the way out is named, not a bare "Keep"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => confirmDestructive(
                  context,
                  title: 'Sign out?',
                  message: 'Your bag stays on this device.',
                  confirmLabel: 'Sign out',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // "Keep" on its own reads as an instruction with no object.
      expect(find.text('Keep'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('returns false when dismissed rather than null', (
      WidgetTester tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () async {
                  result = await confirmDestructive(
                    context,
                    title: 'Sign out?',
                    message: 'You can sign back in.',
                    confirmLabel: 'Sign out',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tapping the barrier dismisses without an answer.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isFalse, reason: 'callers should not need null handling');
    });

    testWidgets('cancelling returns false and confirming returns true', (
      WidgetTester tester,
    ) async {
      late bool answer;
      Future<void> open(WidgetTester tester, String tapLabel) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () async {
                    answer = await confirmDestructive(
                      context,
                      title: 'Cancel this order?',
                      message: 'It has not shipped.',
                      confirmLabel: 'Cancel order',
                      cancelLabel: 'Keep it',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tapLabel));
        await tester.pumpAndSettle();
      }

      await open(tester, 'Keep it');
      expect(answer, isFalse);

      await open(tester, 'Cancel order');
      expect(answer, isTrue);
    });
  });

  group('the way out comes before the destructive action', () {
    // Every real pair used in the app. AlertDialog stacks its actions when
    // they don't fit, which put the way out underneath the red button.
    const List<(String, String)> pairs = <(String, String)>[
      ('Cancel', 'Remove'),
      ('Cancel', 'Delete'),
      ('Cancel', 'Discard'),
      ('Cancel', 'Sign out'),
      ('Keep it', 'Cancel order'),
    ];

    for (final (String cancel, String confirm) in pairs) {
      testWidgets('"$cancel" beside "$confirm"', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            theme: AppTheme.light(null),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () => confirmDestructive(
                    context,
                    title: 'Are you sure?',
                    message: 'This cannot be undone.',
                    confirmLabel: confirm,
                    cancelLabel: cancel,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final Offset left = tester.getCenter(find.text(cancel));
        final Offset right = tester.getCenter(find.text(confirm));

        // Side by side or stacked is the platform's call — Material's
        // OverflowBar stacks when the labels don't fit a row. What must hold
        // either way is that the way out is reached first: to the left of the
        // destructive action, or above it. Never under it.
        final bool sameRow = (left.dy - right.dy).abs() < 4;
        if (sameRow) {
          expect(left.dx, lessThan(right.dx), reason: 'confirm goes last');
        } else {
          expect(
            left.dy,
            lessThan(right.dy),
            reason: 'stacked, the way out must still come first',
          );
        }
      });
    }
  });

  group('order status colors', () {
    Future<ColorScheme> pumpPill(
      WidgetTester tester,
      OrderStatus status,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Center(child: OrderStatusPill(status: status)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return schemeOf(tester, find.byType(OrderStatusPill));
    }

    Color backgroundOf(WidgetTester tester) {
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(OrderStatusPill),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    testWidgets('cancelled reads as red', (WidgetTester tester) async {
      final ColorScheme scheme = await pumpPill(tester, OrderStatus.cancelled);
      expect(backgroundOf(tester), scheme.errorContainer);
    });

    testWidgets('refunded reads as red', (WidgetTester tester) async {
      final ColorScheme scheme = await pumpPill(tester, OrderStatus.refunded);
      expect(backgroundOf(tester), scheme.errorContainer);
    });

    testWidgets('a healthy order does not', (WidgetTester tester) async {
      final ColorScheme scheme = await pumpPill(tester, OrderStatus.shipped);
      expect(backgroundOf(tester), isNot(scheme.errorContainer));
    });
  });
}

/// The resolved foreground colour of the dialog action carrying [label].
Color? _foregroundOf(WidgetTester tester, String label) => tester
    .widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
    )
    .style
    ?.foregroundColor
    ?.resolve(<WidgetState>{});
