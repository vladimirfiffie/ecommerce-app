import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/checkout/order_confirmation_screen.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(() {
    configureTestEnvironment();
    // The clock would schedule a frame a second and nothing would settle.
    changeWindowTick = null;
  });
  setUp(stubHaptics);

  const Address home = Address(
    id: 'a',
    label: 'Home',
    recipient: 'Bbo',
    line1: '1 Street',
    city: 'Town',
    postcode: '12345',
    country: 'USA',
  );

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[testProduct(id: 'coat', name: 'Wool Coat')],
  );

  Future<ProviderContainer> placeOrder(WidgetTester tester) async {
    useMobileSurface(tester);
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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

    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(ordersProvider.notifier)
        .placeOrder(address: home, paymentLabel: 'Visa •••• 4242');
    await settle(tester);

    final Order order = c.read(ordersProvider).first;
    c.read(routerProvider).push('/confirmation/${order.id}');
    await settle(tester);
    return c;
  }

  group('the order model', () {
    Order orderPlaced(Duration ago) => Order(
      id: 'A-1',
      placedAt: DateTime.now().subtract(ago),
      lines: const <OrderLine>[],
      subtotal: 10,
      shipping: 0,
      discount: 0,
      total: 10,
      shippingAddress: 'Bbo, 1 Street',
      paymentLabel: 'Visa •••• 4242',
    );

    test('the window is open the moment an order is placed', () {
      final Order order = orderPlaced(Duration.zero);
      expect(order.inChangeWindow, isTrue);
      expect(order.changeWindowLeft.inMinutes, 4);
    });

    test('it has closed five minutes later', () {
      final Order order = orderPlaced(const Duration(minutes: 5, seconds: 1));
      expect(order.inChangeWindow, isFalse);
      expect(order.changeWindowLeft, Duration.zero);
    });

    test('a cancelled order has no window at all', () {
      final Order order = orderPlaced(
        Duration.zero,
      ).copyWith(cancelledAt: DateTime.now());
      expect(order.inChangeWindow, isFalse);
    });
  });

  testWidgets('the confirmation offers a way back out', (
    WidgetTester tester,
  ) async {
    await placeOrder(tester);

    expect(find.textContaining('Changed your mind?'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Change address'), findsOneWidget);
  });

  testWidgets('cancelling takes the order out and says so', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await placeOrder(tester);

    await tester.tap(find.text('Cancel order'));
    await settle(tester);
    // The dialog is the platform's now, so its actions are whatever the
    // platform draws — tap the label rather than a button type.
    await tester.tap(find.text('Cancel order').last);
    await settle(tester);

    expect(c.read(ordersProvider).first.status, OrderStatus.cancelled);
  });

  test('the notifier refuses a change once the window has closed', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(ordersProvider.notifier)
        .placeOrder(address: home, paymentLabel: 'Visa •••• 4242');

    final String id = c.read(ordersProvider).first.id;
    expect(
      await c.read(ordersProvider.notifier).changeAddress(id, home),
      isTrue,
      reason: 'inside the window',
    );

    // Cancelling closes the window, which is the one state change a test can
    // make without waiting five real minutes.
    await c.read(ordersProvider.notifier).cancel(id);
    expect(
      await c.read(ordersProvider.notifier).changeAddress(id, home),
      isFalse,
    );
  });
}
