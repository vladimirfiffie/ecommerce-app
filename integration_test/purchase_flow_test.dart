import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/payment_card.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:ecommerce_app/state/payments_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haptic_kit/haptic_kit.dart';
import 'package:ecommerce_app/state/notifications_provider.dart';
import 'package:ecommerce_app/state/haptics_provider.dart';
import 'package:ecommerce_app/state/biometrics_provider.dart';
import 'package:ecommerce_app/state/alerts_provider.dart';
import 'package:ecommerce_app/shared/widgets/product_card.dart';
import 'package:ecommerce_app/features/home/widgets/hero_carousel.dart';

/// End-to-end tests against the **real** app: the bundled catalog, the real
/// plugin registrations and the real renderer.
///
/// The suite under `test/` stubs plugin channels, so these are the only tests
/// that exercise haptics, notifications and biometrics as actually registered
/// on the platform.
///
///   flutter test integration_test -d linux
///   flutter test integration_test -d `<android-device-id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Advances past entrance animations. `pumpAndSettle` can't be used: the
  /// image shimmer never stops, so the frame queue never drains.
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// A product with no size or colour choices, so it adds in one tap.
  Product simpleProduct(ProviderContainer container) => container
      .read(catalogDataProvider)
      .products
      .firstWhere(
        (Product p) => p.sizes.isEmpty && p.colors.isEmpty && p.inStock,
      );

  Future<ProviderContainer> launch(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NovaApp()),
    );
    // The real repository loads the bundled asset with a deliberate delay.
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    return container;
  }

  testWidgets('the live catalog loads and Home renders', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await launch(tester);
    final Catalog catalog = c.read(catalogDataProvider);

    expect(catalog.products.length, greaterThan(100));
    expect(catalog.categories, isNotEmpty);
    expect(find.byType(HeroCarousel), findsOneWidget);
  });

  testWidgets('opening a product and adding it to the bag', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await launch(tester);
    final Product product = simpleProduct(c);

    await tester.tap(find.text('Shop').last);
    await settle(tester);

    // Search rather than scroll: the catalog order isn't fixed.
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, product.name);
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    // By type, not by text: find.text also matches the search field's own
    // contents, and highlighted result names are RichText rather than Text.
    expect(find.byType(ProductCard), findsWidgets);
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester);
    await tester.tap(find.text('Add to bag'));
    await settle(tester);

    expect(c.read(cartCountProvider), 1);
  });

  testWidgets('checkout places an order end to end', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await launch(tester);

    // A card built through the real validator, so this can't drift from the
    // production rules.
    await c
        .read(paymentCardsProvider.notifier)
        .save(
          CardValidator.toCard(
            number: '4242424242424242',
            expiry: '09/30',
            holder: 'Integration Test',
          ),
        );

    await c.read(cartProvider.notifier).add(simpleProduct(c));
    await settle(tester);

    await tester.tap(find.text('Bag').last);
    await settle(tester);

    // The wide (desktop/tablet) cart labels this button "Checkout · $x" in a
    // side panel; the phone layout just says "Checkout". Match both.
    await tester.tap(find.textContaining('Checkout').last);
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // The final action adapts to the platform: with haptics available it's a
    // slide-to-confirm handle, otherwise a plain Pay button. Drive whichever
    // this platform actually rendered.
    final Finder slideHandle = find.byIcon(Icons.arrow_forward);
    if (slideHandle.evaluate().isNotEmpty) {
      await tester.drag(slideHandle, const Offset(500, 0));
    } else {
      await tester.tap(find.textContaining('Pay ').last);
    }
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);

    expect(c.read(ordersProvider), hasLength(1));
    expect(c.read(cartProvider), isEmpty);
    expect(find.text('Order confirmed'), findsOneWidget);
  });

  testWidgets('the real plugins are safe on this platform', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await launch(tester);

    // No channel stubs here: these hit whatever is actually registered on the
    // running platform. On Android/iOS they do real work; on desktop the
    // platform guards should drop them. Either way, nothing may throw.
    final HapticService haptics = c.read(hapticsProvider);
    await expectLater(haptics.impact(), completes);
    await expectLater(haptics.selection(), completes);
    await expectLater(
      haptics.notification(HapticNotificationStyle.success),
      completes,
    );

    final NotificationService notifications = c.read(notificationsProvider);
    await expectLater(notifications.ensureInitialized(), completes);
    await expectLater(notifications.hasPermission(), completes);
    await expectLater(notifications.cancelAll(), completes);

    // Capability queries, not a prompt — an integration test must not block
    // waiting for a fingerprint.
    await expectLater(c.read(biometricStatusProvider.future), completes);

    // And the alert sweep, which fans out across several of them.
    await expectLater(c.read(alertSweeperProvider).sweep(), completes);
  });
}
