import 'dart:convert';

import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/credit_entry.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/credit_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final Product mug = testProduct(id: 'mug', name: 'Mug', price: 10);
  final Product coat = testProduct(id: 'coat', name: 'Coat', price: 200);
  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[mug, coat],
  );

  const Address here = Address(
    id: 'a1',
    label: 'Home',
    recipient: 'Ada',
    line1: '1 Test Way',
    city: 'Springfield',
    postcode: '62704',
    country: 'United States',
  );

  Future<ProviderContainer> withCredit(String code) async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    expect(await c.read(creditLedgerProvider.notifier).redeem(code), isNull);
    return c;
  }

  group('redeeming', () {
    test('a known code puts its value on the account', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      expect(c.read(storeCreditProvider), 25);
    });

    test('is case- and whitespace-insensitive', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      expect(
        await c.read(creditLedgerProvider.notifier).redeem('  aster-gift-10 '),
        isNull,
      );
      expect(c.read(storeCreditProvider), 10);
    });

    test('refuses a code it does not know', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      expect(
        await c.read(creditLedgerProvider.notifier).redeem('NOT-A-CARD'),
        isNotNull,
      );
      expect(c.read(storeCreditProvider), 0);
    });

    test('refuses the same card twice', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      expect(
        await c.read(creditLedgerProvider.notifier).redeem('ASTER-GIFT-25'),
        contains('already'),
      );
      expect(c.read(storeCreditProvider), 25);
    });
  });

  group('spending', () {
    test('takes only what the order costs, never more', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-100');
      await c.read(cartProvider.notifier).add(mug);

      final CheckoutTotal checkout = c.read(checkoutTotalProvider);
      expect(checkout.creditApplied, checkout.summary.total);
      expect(checkout.amountDue, 0);
      expect(checkout.paidEntirelyByCredit, isTrue);
      expect(checkout.creditApplied, lessThan(100));
    });

    test('covers part of an order too big for it', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      await c.read(cartProvider.notifier).add(coat);

      final CheckoutTotal checkout = c.read(checkoutTotalProvider);
      expect(checkout.creditApplied, 25);
      expect(checkout.amountDue, closeTo(checkout.summary.total - 25, 0.001));
      expect(checkout.paidEntirelyByCredit, isFalse);
    });

    test('is left alone when the shopper says to keep it', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      await c.read(cartProvider.notifier).add(coat);

      c.read(useStoreCreditProvider.notifier).set(false);
      final CheckoutTotal checkout = c.read(checkoutTotalProvider);
      expect(checkout.creditApplied, 0);
      expect(checkout.amountDue, checkout.summary.total);
    });

    test('an empty bag spends nothing', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      expect(c.read(checkoutTotalProvider).creditApplied, 0);
      expect(c.read(checkoutTotalProvider).paidEntirelyByCredit, isFalse);
    });

    test('placing the order takes it off the balance', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      await c.read(cartProvider.notifier).add(coat);

      final double applied = c.read(checkoutTotalProvider).creditApplied;
      await c
          .read(ordersProvider.notifier)
          .placeOrder(
            address: here,
            paymentLabel: 'Visa ····4242',
            creditApplied: applied,
          );

      expect(c.read(storeCreditProvider), 0);
      expect(c.read(ordersProvider).first.creditApplied, 25);
      expect(
        c.read(ordersProvider).first.cardCharged,
        closeTo(c.read(ordersProvider).first.total - 25, 0.001),
      );
    });

    test('a promo is still judged on what the order costs', () async {
      // Credit is a way of paying, not a discount, so it must not change
      // which code the shopper is offered.
      final ProviderContainer plain = await testContainer(catalog: catalog);
      await plain.read(catalogProvider.future);
      await plain.read(cartProvider.notifier).add(coat);
      final PromoOffer? without = plain.read(bestPromoProvider);

      final ProviderContainer rich = await withCredit('ASTER-GIFT-100');
      await rich.read(cartProvider.notifier).add(coat);
      final PromoOffer? with_ = rich.read(bestPromoProvider);

      expect(with_?.promo.code, without?.promo.code);
      expect(with_?.saving, without?.saving);
    });
  });

  group('coming back', () {
    test('a cancelled order hands its credit straight back', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      await c.read(cartProvider.notifier).add(coat);
      final Order order = await c
          .read(ordersProvider.notifier)
          .placeOrder(
            address: here,
            paymentLabel: 'Visa ····4242',
            creditApplied: 25,
          );
      expect(c.read(storeCreditProvider), 0);

      expect(await c.read(ordersProvider.notifier).cancel(order.id), isTrue);
      expect(c.read(storeCreditProvider), 25);
    });

    test('a refund returns the share that was paid with credit', () async {
      final ProviderContainer c = await withCredit('ASTER-GIFT-25');
      await c.read(cartProvider.notifier).add(coat);
      final Order placed = await c
          .read(ordersProvider.notifier)
          .placeOrder(
            address: here,
            paymentLabel: 'Visa ····4242',
            creditApplied: 25,
          );

      // Delivered long enough ago that the refund has already landed, but
      // still inside the return window.
      final DateTime past = DateTime.now().subtract(const Duration(days: 10));
      final Order refunded = Order(
        id: placed.id,
        placedAt: past,
        lines: placed.lines,
        subtotal: placed.subtotal,
        shipping: placed.shipping,
        discount: placed.discount,
        total: placed.total,
        shippingAddress: placed.shippingAddress,
        paymentLabel: placed.paymentLabel,
        creditApplied: 25,
        returnRequest: ReturnRequest(
          requestedAt: past,
          reason: ReturnReason.changedMind,
          lineIds: <String>[placed.lines.first.lineId],
          // Half the order comes back.
          refundAmount: placed.total / 2,
        ),
      );
      expect(refunded.status, OrderStatus.refunded);

      final ProviderContainer d = await testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'orders.list': jsonEncode(<Map<String, dynamic>>[refunded.toJson()]),
        },
      );
      expect(
        await d.read(creditLedgerProvider.notifier).redeem('ASTER-GIFT-25'),
        isNull,
      );

      // 25 redeemed, 25 spent, and half of it back with the refund.
      expect(d.read(storeCreditProvider), closeTo(12.5, 0.001));
      expect(
        d.read(creditHistoryProvider).map((CreditEntry e) => e.kind),
        containsAll(<CreditKind>[
          CreditKind.redeemed,
          CreditKind.spent,
          CreditKind.refunded,
        ]),
      );
    });
  });
}
