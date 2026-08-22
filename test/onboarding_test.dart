import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/onboarding/onboarding_screen.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[testProduct()],
  );

  /// Boots the app over [store] from wherever the router sends it.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    SharedPreferences store,
  ) async {
    useMobileSurface(tester);
    final ProviderContainer c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const AsterApp()),
    );
    await settle(tester);
    return c;
  }

  /// Nothing seen, nobody signed in — a phone that just installed this.
  Future<SharedPreferences> freshInstall() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    return SharedPreferences.getInstance();
  }

  testWidgets('a first launch opens on the intro, ahead of sign in', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, await freshInstall());

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Aster'), findsOneWidget);
    expect(find.text('Browse as guest'), findsNothing);
  });

  testWidgets('it says the three things worth saying', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, await freshInstall());

    expect(find.text('Welcome to Aster'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await settle(tester);
    expect(find.text('Nothing here costs anything'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await settle(tester);
    expect(find.text('It all stays on this device'), findsOneWidget);

    // Last page offers the way out rather than another Next.
    expect(find.widgetWithText(FilledButton, 'Get started'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Next'), findsNothing);
  });

  testWidgets('finishing it hands over to the sign-in gate', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester, await freshInstall());

    await tester.tap(find.text('Skip'));
    await settle(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Browse as guest'), findsOneWidget);
    expect(c.read(onboardingSeenProvider), isTrue);
    // Skipping the intro is not the same as clearing the gate.
    expect(c.read(pastAuthGateProvider), isFalse);
  });

  testWidgets('a second launch never shows it again', (
    WidgetTester tester,
  ) async {
    final SharedPreferences store = await freshInstall();
    await pumpApp(tester, store);
    await tester.tap(find.text('Skip'));
    await settle(tester);

    // Same store, fresh app.
    await pumpApp(tester, store);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Browse as guest'), findsOneWidget);
  });

  testWidgets('signing out puts back the gate, not the intro', (
    WidgetTester tester,
  ) async {
    final SharedPreferences store = await freshInstall();
    final ProviderContainer c = await pumpApp(tester, store);

    await tester.tap(find.text('Skip'));
    await settle(tester);
    await tester.tap(find.text('Browse as guest'));
    await settle(tester);

    await c.read(authProvider.notifier).signOut();
    await settle(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Browse as guest'), findsOneWidget);
  });
}
