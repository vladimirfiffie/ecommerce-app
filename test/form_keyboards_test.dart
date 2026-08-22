import 'package:ecommerce_app/features/checkout/widgets/address_sheet.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A form that asks for five digits and puts up a full alphabet keyboard makes
/// the shopper work for no reason. These pin the keyboard each field declares.
void main() {
  setUpAll(configureTestEnvironment);

  Future<void> pumpAddressSheet(WidgetTester tester) async {
    useMobileSurface(tester);
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: AddressSheet()),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  /// What keyboard the field carrying [label] asks the platform for.
  ///
  /// Read off the [TextField] rather than the [TextFormField] wrapping it:
  /// TextFormField keeps its decoration and keyboard private and passes them
  /// down, so the built field is where they can be seen.
  TextInputType? keyboardFor(WidgetTester tester, String label) {
    final Finder field = find.byWidgetPredicate(
      (Widget w) => w is TextField && w.decoration?.labelText == label,
    );
    expect(field, findsOneWidget, reason: 'no field labelled "$label"');
    return tester.widget<TextField>(field).keyboardType;
  }

  testWidgets('a US ZIP asks for digits', (WidgetTester tester) async {
    // The field takes five digits and the validator rejects anything else,
    // so an alphabet keyboard offers nothing the field will accept.
    await pumpAddressSheet(tester);
    expect(keyboardFor(tester, 'ZIP'), TextInputType.number);
  });

  testWidgets('the recipient asks for a name', (WidgetTester tester) async {
    await pumpAddressSheet(tester);
    expect(keyboardFor(tester, 'Full name'), TextInputType.name);
  });

  testWidgets('the street line asks for an address', (
    WidgetTester tester,
  ) async {
    await pumpAddressSheet(tester);
    expect(keyboardFor(tester, 'Street address'), TextInputType.streetAddress);
  });

  testWidgets('the city and country are left alone', (
    WidgetTester tester,
  ) async {
    // Free text, and no keyboard the platform has fits them better than the
    // ordinary one — declaring anything here would be noise.
    await pumpAddressSheet(tester);
    expect(keyboardFor(tester, 'City'), TextInputType.text);
    expect(keyboardFor(tester, 'Country'), TextInputType.text);
  });
}
