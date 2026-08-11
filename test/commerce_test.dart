import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/payment_card.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/payments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Standard industry test numbers — none of these are real cards.
  const String visa = '4242424242424242';
  const String mastercard = '5555555555554444';
  const String amex = '378282246310005';
  const String discover = '6011111111111117';

  group('card validation', () {
    test('accepts the network test numbers', () {
      for (final String number in <String>[visa, mastercard, amex, discover]) {
        expect(CardValidator.validateNumber(number), isNull, reason: number);
      }
    });

    test('rejects a single mistyped digit', () {
      expect(CardValidator.validateNumber('4242424242424243'), isNotNull);
    });

    test('rejects the wrong length even when Luhn-valid', () {
      // 4242 4242 4242 4242 4242 passes Luhn but is 20 digits.
      expect(CardValidator.validateNumber('42424242424242424242'), isNotNull);
      expect(CardValidator.validateNumber(''), isNotNull);
    });

    test('identifies the brand from the leading digits', () {
      expect(CardValidator.brandOf(visa), CardBrand.visa);
      expect(CardValidator.brandOf(mastercard), CardBrand.mastercard);
      expect(CardValidator.brandOf(amex), CardBrand.amex);
      expect(CardValidator.brandOf(discover), CardBrand.discover);
      expect(CardValidator.brandOf('2223003122003222'), CardBrand.mastercard);
      expect(CardValidator.brandOf('9999'), CardBrand.unknown);
      expect(CardValidator.brandOf(''), CardBrand.unknown);
    });

    test('groups digits for legibility', () {
      expect(CardValidator.format(visa), '4242 4242 4242 4242');
      expect(CardValidator.format('378282246310005'), '3782 822463 10005');
      expect(CardValidator.format('4242'), '4242');
    });

    test('amex wants 15 digits and a 4-digit CVV', () {
      expect(CardBrand.amex.numberLength, 15);
      expect(CardBrand.amex.cvvLength, 4);
      expect(CardValidator.validateCvv('123', CardBrand.amex), isNotNull);
      expect(CardValidator.validateCvv('1234', CardBrand.amex), isNull);
      expect(CardValidator.validateCvv('123', CardBrand.visa), isNull);
      expect(CardValidator.validateCvv('12', CardBrand.visa), isNotNull);
    });

    test('expiry must be a real, future month', () {
      final DateTime now = DateTime(2026, 8, 10);
      expect(CardValidator.validateExpiry('09/28', now: now), isNull);
      expect(CardValidator.validateExpiry('0928', now: now), isNull);
      expect(
        CardValidator.validateExpiry('08/26', now: now),
        isNull,
        reason: 'valid through the end of the expiry month',
      );
      expect(CardValidator.validateExpiry('07/26', now: now), isNotNull);
      expect(CardValidator.validateExpiry('13/28', now: now), isNotNull);
      expect(CardValidator.validateExpiry('1/28', now: now), isNotNull);
      expect(CardValidator.validateExpiry('09/99', now: now), isNotNull);
    });

    test('holder name must be present', () {
      expect(CardValidator.validateHolder(' '), isNotNull);
      expect(CardValidator.validateHolder('A'), isNotNull);
      expect(CardValidator.validateHolder('Bbo'), isNull);
    });
  });

  group('card storage', () {
    test('keeps only the last four digits', () {
      final PaymentCard card = CardValidator.toCard(
        number: visa,
        expiry: '09/28',
        holder: 'Bbo Jones',
      );
      expect(card.last4, '4242');
      expect(card.brand, CardBrand.visa);
      expect(card.expiryMonth, 9);
      expect(card.expiryYear, 2028);
      expect(card.label, 'Visa •••• 4242');

      final String serialised = card.toJson().toString();
      expect(serialised, isNot(contains(visa)));
      expect(serialised, isNot(contains('424242424242')));
    });

    test('the full number never reaches storage', () async {
      final ProviderContainer c = await testContainer();
      await c
          .read(paymentCardsProvider.notifier)
          .save(
            CardValidator.toCard(
              number: mastercard,
              expiry: '01/30',
              holder: 'Bbo',
            ),
          );

      final String dump = c.read(paymentCardsProvider).toString();
      expect(dump, isNot(contains(mastercard)));
    });

    test('round-trips through JSON', () {
      final PaymentCard original = CardValidator.toCard(
        number: amex,
        expiry: '11/29',
        holder: 'Bbo',
      );
      final PaymentCard restored = PaymentCard.fromJson(original.toJson());
      expect(restored.label, original.label);
      expect(restored.brand, CardBrand.amex);
      expect(restored.expiryLabel, '11/29');
    });

    test('knows when a card has expired', () {
      const PaymentCard old = PaymentCard(
        id: 'c',
        brand: CardBrand.visa,
        last4: '4242',
        expiryMonth: 1,
        expiryYear: 2020,
        holder: 'Bbo',
      );
      expect(old.isExpired, isTrue);

      final PaymentCard future = PaymentCard(
        id: 'c2',
        brand: CardBrand.visa,
        last4: '4242',
        expiryMonth: 12,
        expiryYear: DateTime.now().year + 3,
        holder: 'Bbo',
      );
      expect(future.isExpired, isFalse);
    });
  });

  group('saved cards', () {
    PaymentCard card(String last4, {int year = 2030, String? id}) =>
        PaymentCard(
          id: id ?? 'card-$last4',
          brand: CardBrand.visa,
          last4: last4,
          expiryMonth: 6,
          expiryYear: year,
          holder: 'Bbo',
        );

    test('the first card saved becomes the selection', () async {
      final ProviderContainer c = await testContainer();
      await c.read(paymentCardsProvider.notifier).save(card('4242'));
      expect(c.read(selectedCardProvider)?.last4, '4242');
      expect(c.read(hasUsableCardProvider), isTrue);
    });

    test('adding a second card leaves the selection alone', () async {
      final ProviderContainer c = await testContainer();
      final PaymentCardsNotifier cards = c.read(paymentCardsProvider.notifier);
      await cards.save(card('4242'));
      await cards.save(card('1881'));
      expect(c.read(selectedCardProvider)?.last4, '4242');
    });

    test('removing the selected card falls back to another', () async {
      final ProviderContainer c = await testContainer();
      final PaymentCardsNotifier cards = c.read(paymentCardsProvider.notifier);
      await cards.save(card('4242'));
      await cards.save(card('1881'));

      await cards.remove('card-4242');
      expect(c.read(selectedCardProvider)?.last4, '1881');
    });

    test('an expired card is not chosen as the fallback', () async {
      final ProviderContainer c = await testContainer();
      final PaymentCardsNotifier cards = c.read(paymentCardsProvider.notifier);
      await cards.save(card('0001', year: 2020));
      await cards.save(card('4242'));

      // The expired card was saved first and became the selection; once it's
      // gone the usable one should take over.
      await cards.remove('card-0001');
      expect(c.read(selectedCardProvider)?.last4, '4242');
      expect(c.read(hasUsableCardProvider), isTrue);
    });

    test('no cards means nothing usable', () async {
      final ProviderContainer c = await testContainer();
      expect(c.read(selectedCardProvider), isNull);
      expect(c.read(hasUsableCardProvider), isFalse);
    });

    test('corrupt storage degrades to empty', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{'payments.cards': 'not json'},
      );
      expect(c.read(paymentCardsProvider), isEmpty);
    });
  });

  group('delivery options', () {
    final Product mug = testProduct(id: 'mug', price: 10);
    final Catalog catalog = Catalog(
      categories: const <Category>[],
      products: <Product>[mug],
    );

    Future<ProviderContainer> withCart(int qty) async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug, quantity: qty);
      return c;
    }

    test('standard is the default and matches the old flat rate', () async {
      final ProviderContainer c = await withCart(1);
      expect(c.read(deliveryOptionProvider), DeliveryOption.standard);
      expect(c.read(cartSummaryProvider).shipping, Pricing.flatShipping);
    });

    test('express costs more and is never waived by the threshold', () async {
      final ProviderContainer c = await withCart(20); // $200, over threshold
      await c
          .read(deliveryOptionProvider.notifier)
          .select(DeliveryOption.express);

      final CartSummary s = c.read(cartSummaryProvider);
      expect(s.shipping, DeliveryOption.express.price);
      expect(s.delivery, DeliveryOption.express);
    });

    test('a FREESHIP promo does not cover express either', () async {
      final ProviderContainer c = await withCart(1);
      await c
          .read(deliveryOptionProvider.notifier)
          .select(DeliveryOption.express);
      c.read(appliedPromoProvider.notifier).apply('FREESHIP', 10);

      expect(
        c.read(cartSummaryProvider).shipping,
        DeliveryOption.express.price,
      );
    });

    test('standard is free over the threshold', () async {
      final ProviderContainer c = await withCart(20);
      expect(c.read(cartSummaryProvider).shipping, 0);
    });

    test('pickup is always free', () async {
      final ProviderContainer c = await withCart(1);
      await c
          .read(deliveryOptionProvider.notifier)
          .select(DeliveryOption.pickup);
      expect(c.read(cartSummaryProvider).shipping, 0);
    });

    test('an empty bag is never charged shipping', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c
          .read(deliveryOptionProvider.notifier)
          .select(DeliveryOption.express);
      expect(c.read(cartSummaryProvider).shipping, 0);
    });

    test('selection persists', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: const <String, Object>{
          'checkout.deliveryOption': 'pickup',
        },
      );
      expect(c.read(deliveryOptionProvider), DeliveryOption.pickup);
    });

    test('an unknown stored id falls back to standard', () {
      expect(DeliveryOption.byId('teleport'), DeliveryOption.standard);
      expect(DeliveryOption.byId(null), DeliveryOption.standard);
    });

    test('express arrives sooner than standard', () {
      final DateTime now = DateTime(2026, 8, 10);
      expect(
        DeliveryOption.express
            .estimatedArrival(now)
            .isBefore(DeliveryOption.standard.estimatedArrival(now)),
        isTrue,
      );
    });
  });
}
