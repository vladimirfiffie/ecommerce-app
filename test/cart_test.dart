import 'package:ecommerce_app/data/models/cart_entry.dart';
import 'package:ecommerce_app/data/models/cart_item.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const ProductColor onyx = ProductColor('Onyx', 0xFF1C1B1F);
  const ProductColor sand = ProductColor('Sand', 0xFFD8C3A5);

  final Product jacket = testProduct(
    id: 'jacket',
    price: 40,
    sizes: const <String>['S', 'M'],
    colors: const <ProductColor>[onyx, sand],
  );
  final Product mug = testProduct(id: 'mug', name: 'Mug', price: 10);

  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[jacket, mug],
  );

  group('cart lines', () {
    test('merges the same product + variant into one line', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      final CartNotifier cart = c.read(cartProvider.notifier);
      await cart.add(jacket, size: 'M', color: onyx);
      await cart.add(jacket, size: 'M', color: onyx, quantity: 2);

      expect(c.read(cartProvider), hasLength(1));
      expect(c.read(cartCountProvider), 3);
    });

    test('keeps different variants as separate lines', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      final CartNotifier cart = c.read(cartProvider.notifier);
      await cart.add(jacket, size: 'M', color: onyx);
      await cart.add(jacket, size: 'S', color: onyx);
      await cart.add(jacket, size: 'M', color: sand);

      expect(c.read(cartProvider), hasLength(3));
      expect(c.read(cartCountProvider), 3);
    });

    test('decrementing to zero removes the line', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      final CartNotifier cart = c.read(cartProvider.notifier);
      await cart.add(mug);
      final String lineId = c.read(cartProvider).single.lineId;

      await cart.decrement(lineId);
      expect(c.read(cartProvider), isEmpty);
    });

    test('increment stops at available stock', () async {
      final Product scarce = testProduct(id: 'scarce', stock: 2, price: 5);
      final ProviderContainer c = await testContainer(
        catalog: Catalog(categories: <Category>[], products: <Product>[scarce]),
      );
      await c.read(catalogProvider.future);

      final CartNotifier cart = c.read(cartProvider.notifier);
      await cart.add(scarce);
      final String lineId = c.read(cartProvider).single.lineId;

      await cart.increment(lineId);
      await cart.increment(lineId);
      await cart.increment(lineId);

      expect(c.read(cartCountProvider), 2);
    });

    test('restore puts an undone removal back at its original index', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      final CartNotifier cart = c.read(cartProvider.notifier);
      await cart.add(jacket, size: 'M', color: onyx);
      await cart.add(mug);

      final CartEntry first = c.read(cartProvider).first;
      await cart.remove(first.lineId);
      expect(c.read(cartProvider), hasLength(1));

      await cart.restore(first, 0);
      expect(c.read(cartProvider).first.lineId, first.lineId);
    });

    test('lines resolve against the catalog, dropping unknown products', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: const <String, Object>{
          'cart.entries':
              '[{"productId":"mug","quantity":2,"size":null,"colorName":null},'
              '{"productId":"ghost","quantity":1,"size":null,"colorName":null}]',
        },
      );
      await c.read(catalogProvider.future);

      final List<CartItem> items = c.read(cartItemsProvider);
      expect(items, hasLength(1));
      expect(items.single.product.id, 'mug');
      expect(items.single.quantity, 2);
    });
  });

  group('pricing', () {
    test('charges flat shipping below the free threshold', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug); // $10

      final CartSummary s = c.read(cartSummaryProvider);
      expect(s.subtotal, 10);
      expect(s.shipping, Pricing.flatShipping);
      expect(s.tax, closeTo(0.8, 0.001));
      expect(s.total, closeTo(10 + Pricing.flatShipping + 0.8, 0.001));
      expect(s.amountToFreeShipping, 65);
    });

    test('ships free once the threshold is met', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug, quantity: 8); // $80

      final CartSummary s = c.read(cartSummaryProvider);
      expect(s.shipping, 0);
      expect(s.hasFreeShipping, isTrue);
      expect(s.amountToFreeShipping, 0);
    });

    test('a percentage promo discounts the subtotal', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug, quantity: 10); // $100

      final String? error = c
          .read(appliedPromoProvider.notifier)
          .apply('aster10', 100);
      expect(error, isNull);

      final CartSummary s = c.read(cartSummaryProvider);
      expect(s.discount, 10);
      expect(s.total, closeTo(90 + 90 * Pricing.taxRate, 0.001));
    });

    test('rejects a promo below its minimum spend', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug); // $10

      final String? error = c
          .read(appliedPromoProvider.notifier)
          .apply('WELCOME20', 10);
      expect(error, isNotNull);
      expect(c.read(appliedPromoProvider), isNull);
    });

    test('rejects an unknown promo', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      expect(
        c.read(appliedPromoProvider.notifier).apply('NOPE', 500),
        'That code isn’t valid',
      );
    });

    test('FREESHIP waives shipping under the threshold', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      await c.read(cartProvider.notifier).add(mug); // $10

      c.read(appliedPromoProvider.notifier).apply('FREESHIP', 10);
      expect(c.read(cartSummaryProvider).shipping, 0);
    });
  });
}
