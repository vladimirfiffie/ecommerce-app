import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/features/checkout/widgets/address_picker_sheet.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:ecommerce_app/state/addresses_provider.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  const Address home = Address(
    id: 'a1',
    label: 'Home',
    recipient: 'Ada',
    line1: '1 Test Way',
    city: 'Springfield',
    postcode: '62704',
    country: 'United States',
  );
  const Address work = Address(
    id: 'a2',
    label: 'Work',
    recipient: 'Ada',
    line1: '9 Office Road',
    city: 'Springfield',
    postcode: '62705',
    country: 'United States',
  );

  /// Opens the sheet over a bare host.
  ///
  /// The returned list is empty until the sheet closes, and then holds
  /// exactly what the caller was handed — including a null, which is the
  /// case that matters most.
  Future<(List<Address?>, ProviderContainer)> openSheet(
    WidgetTester tester, {
    List<Address> saved = const <Address>[home, work],
    String? currentId,
  }) async {
    useMobileSurface(tester);
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    for (final Address address in saved) {
      await container.read(addressesProvider.notifier).upsert(address);
    }

    final List<Address?> returned = <Address?>[];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () async => returned.add(
                  await showAddressPickerSheet(context, currentId: currentId),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await settle(tester);
    // Still awaiting: nothing has been handed back yet.
    expect(returned, isEmpty);
    return (returned, container);
  }

  testWidgets('lists every saved address', (WidgetTester tester) async {
    final (List<Address?> _, ProviderContainer container) = await openSheet(
      tester,
    );

    expect(find.text('Where should it go?'), findsOneWidget);
    for (final Address address in container.read(addressesProvider)) {
      expect(
        find.text('${address.label}  ·  ${address.recipient}'),
        findsOneWidget,
        reason: address.id,
      );
    }
  });

  testWidgets('badges the one it is currently going to, and only that one', (
    WidgetTester tester,
  ) async {
    await openSheet(tester, currentId: 'a2');

    expect(find.text('Current'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Work  ·  Ada'),
        matching: find.text('Current'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking one hands it back', (WidgetTester tester) async {
    final (List<Address?> returned, ProviderContainer _) = await openSheet(
      tester,
      currentId: 'a1',
    );

    await tester.tap(find.text('Work  ·  Ada'));
    await settle(tester);

    expect(find.text('Where should it go?'), findsNothing);
    expect(returned, hasLength(1));
    expect(returned.single?.id, 'a2');
  });

  testWidgets('dismissing it hands back nothing at all', (
    WidgetTester tester,
  ) async {
    // The distinction the old code couldn't make: backing out used to read
    // as choosing whatever was already selected, and redirected the order.
    final (List<Address?> returned, ProviderContainer _) = await openSheet(
      tester,
      currentId: 'a1',
    );

    await tester.tapAt(const Offset(20, 20));
    await settle(tester);

    expect(find.text('Where should it go?'), findsNothing);
    expect(returned, hasLength(1));
    expect(returned.single, isNull);
  });

  testWidgets('there is always something to pick', (WidgetTester tester) async {
    // The store seeds one address and refuses to remove the last, so the
    // picker has no empty state — and must not grow one that never shows.
    final (List<Address?> _, ProviderContainer container) = await openSheet(
      tester,
      saved: const <Address>[],
    );

    expect(container.read(addressesProvider), isNotEmpty);
    expect(find.byType(ListTile), findsWidgets);
    // And a way to add another, wherever the list stands.
    expect(find.text('Add a new address'), findsOneWidget);
  });

  testWidgets('it is a sheet, not a page you have to come back from', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
