import 'package:ecommerce_app/shared/widgets/fade_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool stillness = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: stillness),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  /// The transition FadeUp itself owns — page routes have their own.
  Finder fadeIn(Finder of) =>
      find.descendant(of: of, matching: find.byType(FadeTransition));

  double opacityOf(WidgetTester tester, Finder of) =>
      tester.widget<FadeTransition>(fadeIn(of).first).opacity.value;

  testWidgets('rises into place and holds there', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const FadeUp(child: Text('Bag'))));
    await tester.pump();

    expect(opacityOf(tester, find.byType(FadeUp)), 0);
    final double start = tester.getTopLeft(find.text('Bag')).dy;

    await tester.pump(const Duration(milliseconds: 400));

    expect(opacityOf(tester, find.byType(FadeUp)), 1);
    expect(tester.getTopLeft(find.text('Bag')).dy, lessThan(start));
  });

  testWidgets('a later item starts after an earlier one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FadeUp.at(0, child: const Text('Home')),
            FadeUp.at(2, child: const Text('Saved')),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    // 55ms a step, so the third item's turn has not come round yet.
    expect(opacityOf(tester, find.byType(FadeUp).first), greaterThan(0));
    expect(opacityOf(tester, find.byType(FadeUp).last), 0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityOf(tester, find.byType(FadeUp).last), 1);
  });

  testWidgets('an item that has not appeared yet is still tappable', (
    WidgetTester tester,
  ) async {
    // Disposed at the end of the body: the tester checks for stray handles
    // before tearDown callbacks get a turn.
    final SemanticsHandle handle = tester.ensureSemantics();

    int taps = 0;
    await tester.pumpWidget(
      wrap(
        FadeUp.at(
          4,
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Profile'),
          ),
        ),
      ),
    );
    await tester.pump();

    // Fully transparent, but a screen reader must still find the action —
    // NavigationBar asserts outright if a tab of its own loses one.
    expect(opacityOf(tester, find.byType(FadeUp)), 0);
    expect(
      tester
          .getSemantics(find.byType(ElevatedButton))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(taps, 1);

    handle.dispose();
  });

  testWidgets('a rebuild does not replay it', (WidgetTester tester) async {
    late StateSetter rebuild;
    int badge = 0;

    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            rebuild = setState;
            return FadeUp(child: Text('Bag $badge'));
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacityOf(tester, find.byType(FadeUp)), 1);

    // What a badge count changing under the bar looks like.
    rebuild(() => badge = 3);
    await tester.pump();

    expect(find.text('Bag 3'), findsOneWidget);
    expect(opacityOf(tester, find.byType(FadeUp)), 1);
  });

  testWidgets('reduce motion puts the child straight down', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const FadeUp(child: Text('Shop')), stillness: true),
    );
    await tester.pump();

    expect(fadeIn(find.byType(FadeUp)), findsNothing);
    expect(find.text('Shop'), findsOneWidget);
  });
}
