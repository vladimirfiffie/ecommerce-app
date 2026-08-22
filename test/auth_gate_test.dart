import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/home/widgets/hero_carousel.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/onboarding_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:material_ui/material_ui.dart';
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
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25, isFeatured: true),
    ],
  );

  /// Boots the whole app over [store], from wherever the router decides.
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

  /// A blank device: nobody has signed in and nobody has skipped.
  ///
  /// The intro is marked seen even so — it sits in front of the gate, and
  /// these tests are about what the gate does once it is reached.
  Future<SharedPreferences> blankStore() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      OnboardingNotifier.prefsKey: true,
    });
    return SharedPreferences.getInstance();
  }

  /// Runs work that hashes a password.
  ///
  /// PBKDF2 runs 120k rounds on a real isolate, which needs real time.
  /// `testWidgets` runs inside fake async, where that future would never
  /// complete — so it has to be handed back to the real clock.
  Future<void> hashing(
    WidgetTester tester,
    Future<void> Function() body, {
    bool Function()? until,
  }) async {
    await tester.runAsync(() async {
      await body();
      if (until == null) return;
      // A tap only starts the hash; it finishes on the real clock.
      final DateTime deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!until() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await settle(tester);
  }

  group('the welcome gate', () {
    testWidgets('a fresh install opens on sign in, not the shop', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, await blankStore());

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Browse as guest'), findsOneWidget);
      expect(find.byType(HeroCarousel), findsNothing);
    });

    testWidgets('sign up is one tap away, on the same screen', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, await blankStore());

      await tester.tap(find.text('New to Aster? Create an account'));
      await settle(tester);

      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Confirm password'), findsOneWidget);
      // Still the front door, so the way past it is still offered.
      expect(find.text('Browse as guest'), findsOneWidget);
    });

    testWidgets('browsing as a guest gets into the shop', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await pumpApp(tester, await blankStore());

      await tester.tap(find.text('Browse as guest'));
      await settle(tester);

      expect(find.byType(HeroCarousel), findsOneWidget);
      expect(c.read(guestModeProvider), isTrue);
      expect(c.read(authProvider).signedIn, isFalse);
    });

    testWidgets('and is not asked again on the next launch', (
      WidgetTester tester,
    ) async {
      final SharedPreferences store = await blankStore();
      await pumpApp(tester, store);
      await tester.tap(find.text('Browse as guest'));
      await settle(tester);

      // Same store, fresh app.
      await pumpApp(tester, store);
      expect(find.byType(HeroCarousel), findsOneWidget);
      expect(find.text('Browse as guest'), findsNothing);
    });

    testWidgets('creating an account also gets in', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await pumpApp(tester, await blankStore());

      await tester.tap(find.text('New to Aster? Create an account'));
      await settle(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Bbo');
      await tester.enterText(find.byType(TextFormField).at(1), 'bbo@e.co');
      await tester.enterText(find.byType(TextFormField).at(2), 'correct horse');
      await tester.enterText(find.byType(TextFormField).at(3), 'correct horse');

      await hashing(tester, () async {
        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
        await tester.pump();
      }, until: () => !c.read(authProvider).busy);

      expect(c.read(authProvider).signedIn, isTrue);
      expect(find.byType(HeroCarousel), findsOneWidget);
    });

    testWidgets('signing out puts the gate back', (WidgetTester tester) async {
      final SharedPreferences store = await blankStore();
      final ProviderContainer c = await pumpApp(tester, store);

      await tester.tap(find.text('Browse as guest'));
      await settle(tester);
      await hashing(
        tester,
        () => c
            .read(authProvider.notifier)
            .signUp(name: 'Bbo', email: 'bbo@e.co', password: 'correct horse'),
      );

      await c.read(authProvider.notifier).signOut();
      await settle(tester);

      expect(find.text('Browse as guest'), findsOneWidget);
      expect(find.byType(HeroCarousel), findsNothing);
      expect(
        c.read(guestModeProvider),
        isFalse,
        reason: 'an earlier skip must not survive a sign-out',
      );
    });

    testWidgets('reached from Profile later it is an ordinary page', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, await blankStore());
      await tester.tap(find.text('Browse as guest'));
      await settle(tester);

      await tester.tap(find.text('Profile').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await settle(tester);

      expect(find.byType(BackButton), findsOneWidget);
      expect(
        find.text('Browse as guest'),
        findsNothing,
        reason: 'there is nothing left to skip',
      );
    });
  });

  group('the orders tile', () {
    const Address address = Address(
      id: 'a',
      label: 'Home',
      recipient: 'Bbo',
      line1: '1 Street',
      city: 'Portland',
      postcode: '97205',
      country: 'US',
    );

    Future<ProviderContainer> onProfile(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ...pastAuthGatePrefs,
      });
      final ProviderContainer c = await pumpApp(
        tester,
        await SharedPreferences.getInstance(),
      );
      await tester.tap(find.text('Profile').last);
      await settle(tester);
      return c;
    }

    testWidgets('says so plainly when there is nothing to show', (
      WidgetTester tester,
    ) async {
      await onProfile(tester);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('shows the newest order, its status and when it lands', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await onProfile(tester);

      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      await c
          .read(ordersProvider.notifier)
          .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');
      await settle(tester);

      final String id = c.read(ordersProvider).single.id;
      expect(find.text('No orders yet'), findsNothing);
      // A just-placed order hasn't shipped, so it says so and dates itself.
      expect(
        find.textContaining('$id · Processing · arriving '),
        findsOneWidget,
      );
    });

    testWidgets('counts the rest without listing them', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await onProfile(tester);

      for (int i = 0; i < 3; i++) {
        await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
        await c
            .read(ordersProvider.notifier)
            .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');
      }
      await settle(tester);

      expect(find.textContaining('+2 more'), findsOneWidget);
    });
  });
}
