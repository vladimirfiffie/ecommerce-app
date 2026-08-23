import 'package:ecommerce_app/shared/widgets/haptic_controls.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  Future<int Function()> pumpSlider(WidgetTester tester) async {
    stubHaptics();
    // Haptics off, so the widget builds its plain-button fallback. What is
    // under test is what happens *after* confirming, which is the same
    // either way — and driving haptic_kit's slider by hand would be testing
    // that package's drag handling rather than this widget's state.
    setMockPrefs(<String, Object>{'haptics.enabled': false});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int confirms = 0;
    await tester.pumpWidget(
      ProviderScope(
        // The slider asks the haptic settings which control to build, and
        // those come off disk.
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: AsterSlideToConfirm(
                label: 'Slide to pay \$84.20',
                fallbackLabel: 'Pay \$84.20',
                onConfirmed: () => confirms++,
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    return () => confirms;
  }

  testWidgets('confirming turns it into a tick', (WidgetTester tester) async {
    final int Function() confirms = await pumpSlider(tester);

    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.text('Pay \$84.20'));
    await settle(tester);

    expect(confirms(), 1);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('it stays confirmed rather than snapping back', (
    WidgetTester tester,
  ) async {
    // Placing an order takes a beat. A control that looks untouched while
    // that happens invites a second go at paying.
    final int Function() confirms = await pumpSlider(tester);

    await tester.tap(find.text('Pay \$84.20'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.check_rounded), warnIfMissed: false);
    await settle(tester);

    expect(confirms(), 1, reason: 'a second attempt must not charge again');
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('the tick still says what was confirmed', (
    WidgetTester tester,
  ) async {
    await pumpSlider(tester);

    await tester.tap(find.text('Pay \$84.20'));
    await settle(tester);

    // A tick on its own tells a screen reader nothing about what happened.
    expect(find.bySemanticsLabel('Slide to pay \$84.20'), findsOneWidget);
  });
}
