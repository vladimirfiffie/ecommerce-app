import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/shared/widgets/animated_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('animated check', () {
    Future<void> pumpCheck(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AnimatedCheck(color: AppTheme.success)),
        ),
      ),
    );

    CustomPainter painterOf(WidgetTester tester) => tester
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.byType(AnimatedCheck),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .painter!;

    testWidgets('draws progressively rather than appearing at once', (
      WidgetTester tester,
    ) async {
      await pumpCheck(tester);
      await tester.pump();

      // shouldRepaint compares the painter's own progress values, so it is
      // true only when the ring/tick/halo actually moved between frames.
      final CustomPainter atStart = painterOf(tester);

      await tester.pump(const Duration(milliseconds: 300));
      final CustomPainter midway = painterOf(tester);
      expect(
        midway.shouldRepaint(atStart),
        isTrue,
        reason: 'ring should sweep',
      );

      await tester.pump(const Duration(milliseconds: 300));
      final CustomPainter later = painterOf(tester);
      expect(later.shouldRepaint(midway), isTrue, reason: 'tick should draw');
    });

    testWidgets('settles — it does not loop', (WidgetTester tester) async {
      await pumpCheck(tester);
      // A repeating success animation would hang every pumpAndSettle in the
      // suite, so this guards the whole test run, not just this widget.
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedCheck), findsOneWidget);
    });

    testWidgets('stops repainting once finished', (WidgetTester tester) async {
      await pumpCheck(tester);
      await tester.pumpAndSettle();

      final CustomPainter settled = painterOf(tester);
      await tester.pump(const Duration(milliseconds: 400));

      // Nothing left to animate, so the next frame asks for no repaint.
      expect(painterOf(tester).shouldRepaint(settled), isFalse);
    });

    testWidgets('is isolated behind a repaint boundary', (
      WidgetTester tester,
    ) async {
      await pumpCheck(tester);
      // Otherwise every frame of the tick repaints the whole screen.
      expect(
        find.descendant(
          of: find.byType(AnimatedCheck),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });

    testWidgets('scales with the requested size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AnimatedCheck(color: Colors.green, size: 48)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Size size = tester.getSize(
        find
            .descendant(
              of: find.byType(AnimatedCheck),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(size, const Size(48, 48));
    });

    testWidgets('disposes its controller cleanly', (WidgetTester tester) async {
      await pumpCheck(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Leaving mid-animation must not leave a ticker running.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
