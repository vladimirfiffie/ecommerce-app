import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/orders/invoice_screen.dart';
import 'package:ecommerce_app/features/product/widgets/size_guide_sheet.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:ecommerce_app/state/questions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Address address = Address(
    id: 'a',
    label: 'Home',
    recipient: 'Bbo',
    line1: '1 Street',
    city: 'Portland',
    postcode: '97205',
    country: 'US',
  );

  final Product tee = testProduct(id: 'tee', name: 'Linen Tee', price: 25);
  final Product coat = testProduct(id: 'coat', name: 'Wool Coat', price: 100);
  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[tee, coat],
  );

  Future<ProviderContainer> withOrder({
    int teeQty = 1,
    int coatQty = 0,
    DeliveryOption delivery = DeliveryOption.standard,
  }) async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    if (teeQty > 0) {
      await c.read(cartProvider.notifier).add(tee, quantity: teeQty);
    }
    if (coatQty > 0) {
      await c.read(cartProvider.notifier).add(coat, quantity: coatQty);
    }
    await c
        .read(ordersProvider.notifier)
        .placeOrder(
          address: address,
          paymentLabel: 'Visa •••• 4242',
          delivery: delivery,
        );
    return c;
  }

  group('order status', () {
    Order orderAgedBy(Duration age, {String deliveryId = 'standard'}) => Order(
      id: 'NV-1',
      placedAt: DateTime.now().subtract(age),
      lines: const <OrderLine>[],
      subtotal: 100,
      shipping: 0,
      discount: 0,
      total: 108,
      shippingAddress: 'x',
      paymentLabel: 'y',
      deliveryId: deliveryId,
    );

    test('walks processing → shipped → delivered with age', () {
      expect(
        orderAgedBy(const Duration(hours: 1)).status,
        OrderStatus.processing,
      );
      expect(orderAgedBy(const Duration(days: 1)).status, OrderStatus.shipped);
      expect(
        orderAgedBy(const Duration(days: 9)).status,
        OrderStatus.delivered,
      );
    });

    test('express moves faster than standard', () {
      final Duration age = const Duration(hours: 4);
      expect(orderAgedBy(age).status, OrderStatus.processing);
      expect(
        orderAgedBy(age, deliveryId: 'express').status,
        OrderStatus.shipped,
      );
    });

    test('only a fresh order can be cancelled', () {
      expect(orderAgedBy(const Duration(minutes: 5)).canCancel, isTrue);
      expect(orderAgedBy(const Duration(days: 2)).canCancel, isFalse);
    });

    test('only a delivered order inside the window can be returned', () {
      expect(orderAgedBy(const Duration(days: 1)).canReturn, isFalse);
      expect(orderAgedBy(const Duration(days: 9)).canReturn, isTrue);
      expect(orderAgedBy(const Duration(days: 400)).canReturn, isFalse);
    });
  });

  group('cancellation', () {
    test('cancels a processing order', () async {
      final ProviderContainer c = await withOrder();
      final Order order = c.read(ordersProvider).single;
      expect(order.canCancel, isTrue);

      expect(await c.read(ordersProvider.notifier).cancel(order.id), isTrue);
      expect(c.read(ordersProvider).single.status, OrderStatus.cancelled);
    });

    test('refuses once it has shipped', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      // Seed a two-day-old order straight into storage.
      final ProviderContainer aged = await testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'orders.list':
              '[{"id":"NV-OLD","placedAt":'
              '"${DateTime.now().subtract(const Duration(days: 2)).toIso8601String()}",'
              '"entries":[],"subtotal":10,"shipping":0,"discount":0,'
              '"total":10,"shippingAddress":"x","paymentLabel":"y"}]',
        },
      );
      await aged.read(catalogProvider.future);
      expect(
        await aged.read(ordersProvider.notifier).cancel('NV-OLD'),
        isFalse,
      );
      expect(c.read(ordersProvider), isEmpty);
    });

    test('an unknown order is a no-op', () async {
      final ProviderContainer c = await withOrder();
      expect(await c.read(ordersProvider.notifier).cancel('nope'), isFalse);
    });
  });

  group('refund maths', () {
    test('a full return gives back items, shipping and tax', () async {
      final ProviderContainer c = await withOrder(teeQty: 2);
      final Order order = c.read(ordersProvider).single;
      final List<OrderLine> items = c.read(orderItemsProvider(order.id));
      final Map<String, double> totals = <String, double>{
        for (final OrderLine i in items) i.lineId: i.lineTotal,
      };

      final RefundQuote quote = c
          .read(ordersProvider.notifier)
          .quoteRefund(
            order: order,
            lineIds: totals.keys.toSet(),
            reason: ReturnReason.changedMind,
            lineTotals: totals,
          );

      expect(quote.items, 50);
      expect(quote.shipping, order.shipping, reason: 'full return');
      expect(
        quote.total,
        closeTo(quote.items + quote.shipping + quote.tax, 0.001),
      );
      expect(quote.returnPostagePaidByShop, isFalse);
    });

    test('a partial return withholds the original shipping', () async {
      final ProviderContainer c = await withOrder(teeQty: 1, coatQty: 1);
      final Order order = c.read(ordersProvider).single;
      final List<OrderLine> items = c.read(orderItemsProvider(order.id));
      final Map<String, double> totals = <String, double>{
        for (final OrderLine i in items) i.lineId: i.lineTotal,
      };
      final String teeLine = items
          .firstWhere((OrderLine i) => i.productId == 'tee')
          .lineId;

      final RefundQuote quote = c
          .read(ordersProvider.notifier)
          .quoteRefund(
            order: order,
            lineIds: <String>{teeLine},
            reason: ReturnReason.changedMind,
            lineTotals: totals,
          );

      expect(quote.items, 25);
      expect(quote.shipping, 0, reason: 'only part of the order went back');
    });

    test('a discount is clawed back pro-rata', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(tee); // $25
      await c.read(cartProvider.notifier).add(coat); // $100
      c.read(appliedPromoProvider.notifier).apply('ASTER10', 125);
      await c
          .read(ordersProvider.notifier)
          .placeOrder(address: address, paymentLabel: 'Visa');

      final Order order = c.read(ordersProvider).single;
      expect(order.discount, closeTo(12.5, 0.001));

      final List<OrderLine> items = c.read(orderItemsProvider(order.id));
      final Map<String, double> totals = <String, double>{
        for (final OrderLine i in items) i.lineId: i.lineTotal,
      };
      final String teeLine = items
          .firstWhere((OrderLine i) => i.productId == 'tee')
          .lineId;

      final RefundQuote quote = c
          .read(ordersProvider.notifier)
          .quoteRefund(
            order: order,
            lineIds: <String>{teeLine},
            reason: ReturnReason.changedMind,
            lineTotals: totals,
          );

      // The tee is 20% of the order, so 20% of the discount is withheld.
      expect(quote.items, closeTo(25 - 2.5, 0.001));
    });

    test('the shop pays postage only when it was at fault', () async {
      final ProviderContainer c = await withOrder();
      final Order order = c.read(ordersProvider).single;
      final List<OrderLine> items = c.read(orderItemsProvider(order.id));
      final Map<String, double> totals = <String, double>{
        for (final OrderLine i in items) i.lineId: i.lineTotal,
      };

      RefundQuote quote(ReturnReason reason) => c
          .read(ordersProvider.notifier)
          .quoteRefund(
            order: order,
            lineIds: totals.keys.toSet(),
            reason: reason,
            lineTotals: totals,
          );

      expect(quote(ReturnReason.damaged).returnPostagePaidByShop, isTrue);
      expect(quote(ReturnReason.wrongItem).returnPostagePaidByShop, isTrue);
      expect(quote(ReturnReason.changedMind).returnPostagePaidByShop, isFalse);
      expect(quote(ReturnReason.wrongSize).returnPostagePaidByShop, isFalse);
    });
  });

  group('returns', () {
    /// A delivered order, aged past the delivery window.
    Future<ProviderContainer> delivered() async {
      final DateTime placed = DateTime.now().subtract(const Duration(days: 9));
      return testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'orders.list':
              '[{"id":"NV-D","placedAt":"${placed.toIso8601String()}",'
              '"entries":[{"productId":"tee","quantity":1,"size":null,'
              '"colorName":null}],"subtotal":25,"shipping":6.95,'
              '"discount":0,"total":33.95,"shippingAddress":"x",'
              '"paymentLabel":"Visa"}]',
        },
      );
    }

    test('files a return and moves the status', () async {
      final ProviderContainer c = await delivered();
      await c.read(catalogProvider.future);
      final Order order = c.read(ordersProvider).single;
      expect(order.canReturn, isTrue);

      final bool ok = await c
          .read(ordersProvider.notifier)
          .requestReturn(
            orderId: order.id,
            lineIds: <String>{'tee|-|-'},
            reason: ReturnReason.damaged,
            refundAmount: 33.95,
            note: 'Arrived torn',
          );

      expect(ok, isTrue);
      final Order after = c.read(ordersProvider).single;
      expect(after.status, OrderStatus.returnRequested);
      expect(after.returnRequest!.reason, ReturnReason.damaged);
      expect(after.returnRequest!.note, 'Arrived torn');
    });

    test('an empty selection is rejected', () async {
      final ProviderContainer c = await delivered();
      await c.read(catalogProvider.future);
      expect(
        await c
            .read(ordersProvider.notifier)
            .requestReturn(
              orderId: 'NV-D',
              lineIds: <String>{},
              reason: ReturnReason.other,
              refundAmount: 0,
            ),
        isFalse,
      );
    });

    test('a return can be withdrawn', () async {
      final ProviderContainer c = await delivered();
      await c.read(catalogProvider.future);
      await c
          .read(ordersProvider.notifier)
          .requestReturn(
            orderId: 'NV-D',
            lineIds: <String>{'tee|-|-'},
            reason: ReturnReason.changedMind,
            refundAmount: 10,
          );
      expect(
        await c.read(ordersProvider.notifier).cancelReturn('NV-D'),
        isTrue,
      );
      expect(c.read(ordersProvider).single.status, OrderStatus.delivered);
    });

    test('a return older than the refund window reads as refunded', () {
      final Order order = Order(
        id: 'NV-R',
        placedAt: DateTime.now().subtract(const Duration(days: 40)),
        lines: const <OrderLine>[],
        subtotal: 10,
        shipping: 0,
        discount: 0,
        total: 10,
        shippingAddress: 'x',
        paymentLabel: 'y',
        returnRequest: ReturnRequest(
          requestedAt: DateTime.now().subtract(const Duration(days: 10)),
          reason: ReturnReason.other,
          lineIds: const <String>['a'],
          refundAmount: 10,
        ),
      );
      expect(order.status, OrderStatus.refunded);
    });

    test('a cancelled order survives a reload', () async {
      final ProviderContainer c = await withOrder();
      final String id = c.read(ordersProvider).single.id;
      await c.read(ordersProvider.notifier).cancel(id);

      final String stored = c.read(ordersProvider).single.toJson().toString();
      expect(stored, contains('cancelledAt'));
      expect(
        Order.fromJson(c.read(ordersProvider).single.toJson()).status,
        OrderStatus.cancelled,
      );
    });
  });

  group('invoice', () {
    test('includes the essentials and the demo disclaimer', () async {
      final ProviderContainer c = await withOrder(teeQty: 2);
      final Order order = c.read(ordersProvider).single;
      final String text = buildInvoiceText(
        order,
        c.read(orderItemsProvider(order.id)),
        testL10n,
      );

      expect(text, contains('ASTER'));
      expect(text, contains(order.id));
      expect(text, contains('Linen Tee'));
      expect(text, contains('2 x'));
      expect(text, contains('Visa'));
      expect(text, contains('No payment was taken'));
    });

    test('shows a return when there is one', () async {
      final ProviderContainer c = await withOrder();
      final Order order = c
          .read(ordersProvider)
          .single
          .copyWith(
            returnRequest: ReturnRequest(
              requestedAt: DateTime.now(),
              reason: ReturnReason.damaged,
              lineIds: const <String>['x'],
              refundAmount: 12.34,
            ),
          );
      final String text = buildInvoiceText(
        order,
        const <OrderLine>[],
        testL10n,
      );
      expect(text, contains('RETURN'));
      expect(text, contains('Arrived damaged'));
    });
  });

  group('gift options', () {
    test('wrapping adds a fee and is taxed', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(tee);

      final double before = c.read(cartSummaryProvider).total;
      c.read(giftOptionsProvider.notifier).setWrapped(true);
      final CartSummary after = c.read(cartSummaryProvider);

      expect(after.giftFee, GiftOptions.wrapFee);
      expect(
        after.total,
        closeTo(before + GiftOptions.wrapFee * (1 + Pricing.taxRate), 0.001),
      );
    });

    test('carries onto the order and then resets', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(tee);
      c.read(giftOptionsProvider.notifier)
        ..setWrapped(true)
        ..setMessage('Happy birthday');

      await c
          .read(ordersProvider.notifier)
          .placeOrder(address: address, paymentLabel: 'Visa');

      final Order order = c.read(ordersProvider).single;
      expect(order.giftWrapped, isTrue);
      expect(order.giftMessage, 'Happy birthday');
      // A gift choice belongs to one order, not the next.
      expect(c.read(giftOptionsProvider).isGift, isFalse);
    });
  });

  group('deep links', () {
    test('folds the host back into the path for the custom scheme', () {
      expect(
        normalizeDeepLink(Uri.parse('aster://product/tee')),
        '/product/tee',
      );
      expect(normalizeDeepLink(Uri.parse('aster://shop')), '/shop');
      expect(
        normalizeDeepLink(Uri.parse('aster://orders/NV-1')),
        '/orders/NV-1',
      );
    });

    test('keeps a query string', () {
      expect(
        normalizeDeepLink(Uri.parse('aster://search?q=coat')),
        '/search?q=coat',
      );
    });

    test('leaves https links alone — their path already matches', () {
      expect(
        normalizeDeepLink(Uri.parse('https://aster.example.com/product/tee')),
        isNull,
      );
      expect(normalizeDeepLink(Uri.parse('/product/tee')), isNull);
    });

    test('builds a shareable product link', () {
      expect(deepLinkForProduct('tee'), contains('/product/tee'));
      expect(deepLinkForProduct('tee'), startsWith('https://'));
    });
  });

  group('size guide', () {
    test('picks a chart from the sizes on offer', () {
      expect(
        SizeChart.forProduct(testProduct(sizes: const <String>['S', 'M'])),
        SizeChart.apparel,
      );
      expect(
        SizeChart.forProduct(testProduct(sizes: const <String>['8', '9'])),
        SizeChart.mensShoes,
      );
      expect(
        SizeChart.forProduct(testProduct(sizes: const <String>['5', '6'])),
        SizeChart.womensShoes,
      );
      expect(SizeChart.forProduct(testProduct()), isNull);
    });

    test('every chart has consistent columns and rows', () {
      for (final SizeChart chart in SizeChart.values) {
        expect(chart.rows, isNotEmpty, reason: chart.name);
        for (final List<String> row in chart.rows) {
          expect(row, hasLength(chart.columns.length), reason: chart.name);
        }
      }
    });
  });

  group('questions', () {
    test('every product gets at least one seeded Q&A', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      expect(c.read(productQuestionsProvider('tee')), isNotEmpty);
    });

    test('seeds are stable for a product', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      final List<String> first = c
          .read(productQuestionsProvider('tee'))
          .map((ProductQuestion q) => q.id)
          .toList();
      final List<String> second = c
          .read(productQuestionsProvider('tee'))
          .map((ProductQuestion q) => q.id)
          .toList();
      expect(first, second);
    });

    test('an asked question pins to the top and is unanswered', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c
          .read(questionsProvider.notifier)
          .ask(productId: 'tee', body: 'Does it shrink in the wash?');

      final List<ProductQuestion> all = c.read(productQuestionsProvider('tee'));
      expect(all.first.body, 'Does it shrink in the wash?');
      expect(all.first.mine, isTrue);
      expect(all.first.isAnswered, isFalse);
    });

    test('questions are scoped to their product', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c
          .read(questionsProvider.notifier)
          .ask(productId: 'tee', body: 'A question about the tee');
      expect(
        c
            .read(productQuestionsProvider('coat'))
            .where((ProductQuestion q) => q.mine),
        isEmpty,
      );
    });

    test('blank questions are ignored and mine can be deleted', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      final QuestionsNotifier notifier = c.read(questionsProvider.notifier);

      await notifier.ask(productId: 'tee', body: '   ');
      expect(c.read(questionsProvider), isEmpty);

      await notifier.ask(productId: 'tee', body: 'A real question');
      await notifier.remove(c.read(questionsProvider).single.id);
      expect(c.read(questionsProvider), isEmpty);
    });
  });
}
