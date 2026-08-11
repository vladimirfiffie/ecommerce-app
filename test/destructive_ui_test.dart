import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/features/orders/orders_screen.dart';
import 'package:ecommerce_app/shared/widgets/confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

void main() {
  ColorScheme schemeOf(WidgetTester tester, Finder finder) =>
      Theme.of(tester.element(finder)).colorScheme;

  group('destructive confirmations', () {
    testWidgets('the confirming button is red, the cancel one is not', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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

      final ColorScheme scheme = schemeOf(tester, find.text('Remove'));
      final ButtonStyle? style = tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Remove'),
              matching: find.byType(FilledButton),
            ),
          )
          .style;

      expect(
        style?.backgroundColor?.resolve(<WidgetState>{}),
        scheme.error,
        reason: 'a delete must not look like a save',
      );
      // The way out stays neutral.
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('the dialog button is dialog-sized, not page-sized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          // The real theme is what makes this go wrong: it sets a 54px
          // minimum height on every filled button, for page CTAs.
          theme: AppTheme.light(null),
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

      final Size confirm = tester.getSize(
        find.ancestor(
          of: find.text('Remove'),
          matching: find.byType(FilledButton),
        ),
      );
      final Size cancel = tester.getSize(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(TextButton),
        ),
      );

      // 48 is the accessible tap-target floor, so that's the target — the
      // bug was the theme's 54px page-button minimum leaking into dialogs.
      expect(confirm.height, lessThanOrEqualTo(48));
      // And it sits level with the plain button beside it rather than
      // towering over it.
      expect((confirm.height - cancel.height).abs(), lessThan(12));
    });

    testWidgets('the way out is named, not a bare "Keep"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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

  group('dialog actions stay on one row', () {
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

        expect(
          (left.dy - right.dy).abs(),
          lessThan(4),
          reason: 'stacked instead of sitting side by side',
        );
        expect(left.dx, lessThan(right.dx), reason: 'confirm goes last');
      });
    }
  });

  group('order status colours', () {
    Future<ColorScheme> pumpPill(
      WidgetTester tester,
      OrderStatus status,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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
