import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:ecommerce_app/shared/widgets/quantity_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  /// Pumps a stepper that counts, and hands back a way to read the count.
  Future<int Function()> pumpStepper(
    WidgetTester tester, {
    int start = 1,
    int max = 99,
  }) async {
    int quantity = start;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  QuantityStepper(
                    quantity: quantity,
                    max: max,
                    onIncrement: () => setState(() => quantity++),
                    onDecrement: () => setState(() => quantity--),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return () => quantity;
  }

  Finder plus() => find.byTooltip('Increase quantity');

  /// Holds for [total], drawing frames along the way.
  ///
  /// One long pump would elapse every timer without rebuilding in between,
  /// so the button would never notice it had been switched off — a device
  /// renders a frame every 16ms and does.
  Future<void> waitFrames(WidgetTester tester, Duration total) async {
    const Duration frame = Duration(milliseconds: 50);
    for (Duration t = Duration.zero; t < total; t += frame) {
      await tester.pump(frame);
    }
  }

  testWidgets('a tap is still one step', (WidgetTester tester) async {
    final int Function() count = await pumpStepper(tester);

    await tester.tap(plus());
    await tester.pump();

    expect(count(), 2);
  });

  testWidgets('holding it counts up on its own', (WidgetTester tester) async {
    final int Function() count = await pumpStepper(tester);

    final TestGesture hold = await tester.startGesture(
      tester.getCenter(plus()),
    );
    // Nothing yet: a press this short is a tap, not a hold.
    await waitFrames(tester, const Duration(milliseconds: 200));
    expect(count(), 1);

    await waitFrames(tester, const Duration(milliseconds: 400));
    expect(count(), greaterThan(1), reason: 'the hold has started repeating');

    await waitFrames(tester, const Duration(seconds: 1));
    final int held = count();
    expect(held, greaterThan(5), reason: 'and it speeds up as it goes');

    await hold.up();
    await waitFrames(tester, const Duration(seconds: 1));
    expect(count(), held, reason: 'letting go stops it');
  });

  testWidgets('releasing a hold does not add a step of its own', (
    WidgetTester tester,
  ) async {
    final int Function() count = await pumpStepper(tester);

    final TestGesture hold = await tester.startGesture(
      tester.getCenter(plus()),
    );
    await waitFrames(tester, const Duration(milliseconds: 600));
    final int duringHold = count();

    await hold.up();
    await tester.pump();

    expect(count(), duringHold);
  });

  testWidgets('a hold stops at the ceiling instead of running past it', (
    WidgetTester tester,
  ) async {
    final int Function() count = await pumpStepper(tester, start: 1, max: 4);

    final TestGesture hold = await tester.startGesture(
      tester.getCenter(plus()),
    );
    await waitFrames(tester, const Duration(seconds: 3));

    expect(count(), 4);

    await hold.up();
    await tester.pump();
  });
}
