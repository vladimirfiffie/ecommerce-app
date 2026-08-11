import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/shared/widgets/app_image.dart';
import 'package:ecommerce_app/features/checkout/order_confirmation_screen.dart';
import 'package:ecommerce_app/core/router/app_router.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Catalog catalog = Catalog(
    categories: const <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        icon: Icons.checkroom_rounded,
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25),
      testProduct(id: 'coat', name: 'Wool Coat', price: 120),
    ],
  );

  const Address address = Address(
    id: 'a',
    label: 'Home',
    recipient: 'Bbo',
    line1: '1 Street',
    city: 'Portland',
    postcode: '97205',
    country: 'US',
  );

  /// Boots the app, places an order, and leaves you on its detail page.
  Future<ProviderContainer> openOrder(
    WidgetTester tester, {
    List<String> productIds = const <String>['tee'],
  }) async {
    tester.view.physicalSize = const Size(400, 900) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    setMockPrefs();
    final SharedPreferences store = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(store),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const NovaApp()),
    );
    await settle(tester);

    for (final String id in productIds) {
      await c.read(cartProvider.notifier).add(catalog.byId(id)!);
    }
    await c
        .read(ordersProvider.notifier)
        .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');
    await settle(tester);
    return c;
  }

  Future<void> gotoOrder(WidgetTester tester, String id) async {
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.text('Your orders').first);
    await settle(tester);
    await tester.tap(find.text(id).first);
    await settle(tester);
  }

  group('a cancelled order', () {
    testWidgets('states it plainly instead of a rail going nowhere', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await openOrder(tester);
      final String id = c.read(ordersProvider).single.id;

      await c.read(ordersProvider.notifier).cancel(id);
      await settle(tester);
      await gotoOrder(tester, id);

      expect(find.textContaining('won’t be delivered'), findsOneWidget);
      // The delivery estimate and its three stages are meaningless now.
      expect(find.textContaining('Arriving by'), findsNothing);
      expect(find.text('Shipped'), findsNothing);
    });

    testWidgets('the notice is drawn in the error colour', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await openOrder(tester);
      final String id = c.read(ordersProvider).single.id;
      await c.read(ordersProvider.notifier).cancel(id);
      await settle(tester);
      await gotoOrder(tester, id);

      final Finder notice = find.ancestor(
        of: find.textContaining('won’t be delivered'),
        matching: find.byType(Container),
      );
      final ColorScheme scheme = Theme.of(
        tester.element(notice.first),
      ).colorScheme;

      final Iterable<Container> boxes = tester.widgetList<Container>(notice);
      final bool anyRed = boxes.any((Container c) {
        final Decoration? d = c.decoration;
        return d is BoxDecoration &&
            d.color != null &&
            d.color!.toARGB32() ==
                scheme.errorContainer.withValues(alpha: 0.5).toARGB32();
      });
      expect(anyRed, isTrue);
    });
  });

  group('an in-transit order', () {
    testWidgets('still shows the delivery rail', (WidgetTester tester) async {
      final ProviderContainer c = await openOrder(tester);
      final String id = c.read(ordersProvider).single.id;
      await gotoOrder(tester, id);

      expect(find.textContaining('Arriving by'), findsOneWidget);
      expect(find.text('Processing'), findsWidgets);
    });
  });

  group('the confirmation screen', () {
    testWidgets('shows pictures of what you actually bought', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await openOrder(
        tester,
        productIds: <String>['tee', 'coat'],
      );
      final String id = c.read(ordersProvider).single.id;

      rootNavigatorKey.currentContext!.go(Routes.confirmation(id));
      await settle(tester);

      expect(find.text('Order confirmed'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);

      // A total with no pictures makes you open the order to check what
      // you bought — one thumbnail per line item.
      expect(
        find.descendant(
          of: find.byType(OrderConfirmationScreen),
          matching: find.byType(AppImage),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('badges a line item bought more than once', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await openOrder(
        tester,
        productIds: <String>['tee', 'tee', 'tee'],
      );
      final String id = c.read(ordersProvider).single.id;

      rootNavigatorKey.currentContext!.go(Routes.confirmation(id));
      await settle(tester);

      // One thumbnail, marked x3 — not three identical pictures.
      expect(
        find.descendant(
          of: find.byType(OrderConfirmationScreen),
          matching: find.byType(AppImage),
        ),
        findsOneWidget,
      );
      expect(find.text('3'), findsWidgets);
    });
  });

  group('profile and settings do not duplicate each other', () {
    testWidgets('orders and sign out live on Profile only', (
      WidgetTester tester,
    ) async {
      await openOrder(tester);
      await tester.tap(find.text('Profile').last);
      await settle(tester);
      expect(find.text('Your orders'), findsOneWidget);

      await tester.tap(find.text('Settings').first);
      await settle(tester);
      expect(find.text('Your orders'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('addresses and cards live in Settings only', (
      WidgetTester tester,
    ) async {
      await openOrder(tester);
      await tester.tap(find.text('Profile').last);
      await settle(tester);

      expect(find.text('Addresses'), findsNothing);
      expect(find.text('Payment methods'), findsNothing);

      await tester.tap(find.text('Settings').first);
      await settle(tester);
      expect(find.text('Addresses'), findsOneWidget);
      expect(find.text('Payment methods'), findsOneWidget);
    });
  });
}
