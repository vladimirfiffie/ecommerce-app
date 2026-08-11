import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/features/orders/orders_screen.dart';
import 'package:ecommerce_app/shared/widgets/confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(find.widgetWithText(TextButton, 'Keep'), findsOneWidget);
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
