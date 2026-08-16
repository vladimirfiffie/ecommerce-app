import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:ecommerce_app/state/pairings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  Product make(
    String id,
    String name, {
    required String categoryId,
    required String subcategory,
    double rating = 4,
  }) => testProduct(
    id: id,
    name: name,
    categoryId: categoryId,
    subcategory: subcategory,
    rating: rating,
  );

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
      Category(
        id: 'accessories',
        label: 'Accessories',
        iconName: 'watch',
        imageUrl: '',
      ),
    ],
    products: <Product>[
      make('coat', 'Wool Coat', categoryId: 'fashion', subcategory: 'Coats'),
      make('tee', 'Linen Tee', categoryId: 'fashion', subcategory: 'Tops'),
      make(
        'bag',
        'Leather Bag',
        categoryId: 'accessories',
        subcategory: 'Bags',
        rating: 4.9,
      ),
      make(
        'watch',
        'Field Watch',
        categoryId: 'accessories',
        subcategory: 'Watches',
        rating: 4.2,
      ),
    ],
  );

  group('complete the look', () {
    test('pairs clothing with accessories, best rated first', () {
      final List<Product> shown = catalog.completeTheLook(
        catalog.byId('coat')!,
      );

      expect(shown.map((Product p) => p.id), <String>[
        'bag',
        'watch',
      ], reason: 'accessories go with fashion, and 4.9 leads 4.2');
    });

    test('never suggests the same kind of thing back', () {
      final List<Product> shown = catalog.completeTheLook(catalog.byId('bag')!);

      expect(shown.map((Product p) => p.id), isNot(contains('watch')));
      expect(
        shown.every((Product p) => p.subcategory != 'Bags'),
        isTrue,
        reason: 'another bag is what "you might also like" is for',
      );
    });
  });

  group('bought together', () {
    const Address address = Address(
      id: 'a',
      label: 'Home',
      recipient: 'Bbo',
      line1: '1 Street',
      city: 'Town',
      postcode: '12345',
      country: 'USA',
    );

    Future<ProviderContainer> withOrderOf(List<String> ids) async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      for (final String id in ids) {
        await c.read(cartProvider.notifier).add(catalog.byId(id)!);
      }
      await c
          .read(ordersProvider.notifier)
          .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');
      return c;
    }

    test('is empty when nothing has been ordered', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      expect(c.read(pairedWithProvider('coat')), isEmpty);
    });

    test('lists what shared an order with it', () async {
      final ProviderContainer c = await withOrderOf(<String>['coat', 'bag']);

      expect(
        c.read(pairedWithProvider('coat')).map((Product p) => p.id),
        <String>['bag'],
      );
      expect(
        c.read(pairedWithProvider('bag')).map((Product p) => p.id),
        <String>['coat'],
      );
    });

    test('never lists the product itself', () async {
      final ProviderContainer c = await withOrderOf(<String>['coat', 'bag']);

      expect(
        c.read(pairedWithProvider('coat')).map((Product p) => p.id),
        isNot(contains('coat')),
      );
    });

    test('what came up twice leads what came up once', () async {
      final ProviderContainer c = await withOrderOf(<String>['coat', 'bag']);
      await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
      await c.read(cartProvider.notifier).add(catalog.byId('bag')!);
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      await c
          .read(ordersProvider.notifier)
          .placeOrder(address: address, paymentLabel: 'Visa •••• 4242');

      expect(
        c.read(pairedWithProvider('coat')).map((Product p) => p.id),
        <String>['bag', 'tee'],
      );
    });
  });
}
