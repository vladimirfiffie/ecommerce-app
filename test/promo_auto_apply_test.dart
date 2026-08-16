import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

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
      testProduct(id: 'cheap', name: 'Socks', price: 20, stock: 20),
      testProduct(id: 'mid', name: 'Shirt', price: 60, stock: 20),
      testProduct(id: 'dear', name: 'Coat', price: 300, stock: 20),
    ],
  );

  Future<ProviderContainer> bagOf(String id, {int quantity = 1}) async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    await c
        .read(cartProvider.notifier)
        .add(catalog.byId(id)!, quantity: quantity);
    return c;
  }

  test('an empty bag is offered nothing', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    expect(c.read(bestPromoProvider), isNull);
  });

  test('a big order is offered the 20% code over the 10%', () async {
    final ProviderContainer c = await bagOf('dear');

    final PromoOffer offer = c.read(bestPromoProvider)!;
    expect(offer.promo.code, 'WELCOME20');
    // $60 off $300, and the tax that is no longer charged on it.
    expect(offer.saving, closeTo(60 * (1 + Pricing.taxRate), 0.01));
  });

  test('a code the bag has not reached is never the answer', () async {
    final ProviderContainer c = await bagOf('mid');

    // $60 is under WELCOME20's $100 floor, so it is not on the table at all.
    // Of what is left, free shipping ($6.95) beats 10% ($6 plus its tax).
    final PromoOffer offer = c.read(bestPromoProvider)!;
    expect(offer.promo.code, isNot('WELCOME20'));
    expect(offer.promo.code, 'FREESHIP');
    expect(offer.saving, closeTo(Pricing.flatShipping, 0.01));
  });

  test(
    'free shipping wins when it is worth more than the percentage',
    () async {
      final ProviderContainer c = await bagOf('cheap');

      // $20: 10% saves $2, while standard shipping is $6.95.
      final PromoOffer offer = c.read(bestPromoProvider)!;
      expect(offer.promo.code, 'FREESHIP');
      expect(offer.saving, closeTo(Pricing.flatShipping, 0.01));
    },
  );

  test('a percentage that costs free shipping is priced honestly', () async {
    // Just over the $75 threshold: shipping is already free, and taking 10%
    // off drops it back under, so the code claws back the shipping it lost.
    final ProviderContainer c = await bagOf('mid', quantity: 2);
    final double subtotal = c.read(cartSummaryProvider).subtotal;
    expect(subtotal, 120);

    final PromoOffer offer = c.read(bestPromoProvider)!;
    final CartSummary plain = summarize(
      items: c.read(cartItemsProvider),
      promo: null,
      delivery: c.read(deliveryOptionProvider),
      gift: c.read(giftOptionsProvider),
    );
    final CartSummary applied = summarize(
      items: c.read(cartItemsProvider),
      promo: offer.promo,
      delivery: c.read(deliveryOptionProvider),
      gift: c.read(giftOptionsProvider),
    );

    expect(
      offer.saving,
      closeTo(plain.total - applied.total, 0.001),
      reason: 'the saving is the difference in what you pay, not the sticker',
    );
  });

  test('express delivery is never made free by a code', () async {
    final ProviderContainer c = await bagOf('cheap');
    await c
        .read(deliveryOptionProvider.notifier)
        .select(DeliveryOption.byId('express'));

    final PromoOffer offer = c.read(bestPromoProvider)!;
    expect(
      offer.promo.code,
      'ASTER10',
      reason: 'FREESHIP cannot waive express, so it saves nothing',
    );
  });

  test('the auto-apply courtesy is offered once per session', () async {
    final ProviderContainer c = await bagOf('dear');

    expect(c.read(promoAutoApplyProvider), isFalse);
    c.read(promoAutoApplyProvider.notifier).markDone();
    expect(
      c.read(promoAutoApplyProvider),
      isTrue,
      reason: 'a code taken off must not come back by itself',
    );
  });
}
