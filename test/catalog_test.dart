import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/catalog_filter_provider.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:ecommerce_app/state/wishlists_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerce_app/data/repositories/dummyjson_product_repository.dart';
import 'dart:io';

void main() {
  final Product cheap = testProduct(
    id: 'cheap',
    name: 'Linen Tee',
    price: 20,
    rating: 3.2,
  );
  final Product mid = testProduct(
    id: 'mid',
    name: 'Wool Coat',
    price: 120,
    compareAtPrice: 200,
    rating: 4.8,
    isFeatured: true,
  );
  final Product pricey = testProduct(
    id: 'pricey',
    name: 'Cashmere Scarf',
    brand: 'Lune',
    categoryId: 'accessories',
    price: 300,
    rating: 4.2,
    stock: 0,
  );

  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[cheap, mid, pricey],
  );

  Future<ProviderContainer> loaded() async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    return c;
  }

  group('Product', () {
    test('computes the discount percentage', () {
      expect(mid.isOnSale, isTrue);
      expect(mid.discountPercent, 40);
      expect(cheap.isOnSale, isFalse);
      expect(cheap.discountPercent, 0);
    });

    test('parses from catalog JSON', () {
      final Product parsed = Product.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'Thing',
        'brand': 'Brand',
        'categoryId': 'home',
        'subcategory': 'Decor',
        'price': 12.5,
        'compareAtPrice': 25.0,
        'description': 'Nice',
        'images': <String>['a.webp'],
        'rating': 4.25,
        'reviewCount': 7,
        'stock': 3,
        'sizes': <String>['S'],
        'colors': <Map<String, Object>>[
          <String, Object>{'name': 'Sand', 'argb': 0xFFD8C3A5},
        ],
        'tags': <String>['decor'],
        'isNew': true,
      });

      expect(parsed.discountPercent, 50);
      expect(parsed.isLowStock, isTrue);
      expect(parsed.colors.single.name, 'Sand');
      expect(parsed.isFeatured, isFalse);
      expect(parsed.isNew, isTrue);
    });
  });

  group('filters', () {
    test('search matches name and brand, case-insensitively', () async {
      final ProviderContainer c = await loaded();
      c.read(catalogFilterProvider.notifier).setQuery('lune');
      expect(
        c.read(filteredProductsProvider).map((Product p) => p.id),
        <String>['pricey'],
      );
    });

    test('category narrows the result set', () async {
      final ProviderContainer c = await loaded();
      c.read(catalogFilterProvider.notifier).setCategory('accessories');
      expect(c.read(filteredProductsProvider).single.id, 'pricey');
    });

    test('max price and in-stock filters compose', () async {
      final ProviderContainer c = await loaded();
      final CatalogFilterNotifier n = c.read(catalogFilterProvider.notifier);
      n.setMaxPrice(150);
      n.setInStockOnly(true);
      expect(
        c.read(filteredProductsProvider).map((Product p) => p.id).toSet(),
        <String>{'cheap', 'mid'},
      );
    });

    test('on-sale filter keeps only discounted products', () async {
      final ProviderContainer c = await loaded();
      c.read(catalogFilterProvider.notifier).setOnSaleOnly(true);
      expect(c.read(filteredProductsProvider).single.id, 'mid');
    });

    test('sorts by price ascending and descending', () async {
      final ProviderContainer c = await loaded();
      final CatalogFilterNotifier n = c.read(catalogFilterProvider.notifier);

      n.setSort(SortOption.priceLowHigh);
      expect(
        c.read(filteredProductsProvider).map((Product p) => p.id),
        <String>['cheap', 'mid', 'pricey'],
      );

      n.setSort(SortOption.priceHighLow);
      expect(
        c.read(filteredProductsProvider).map((Product p) => p.id),
        <String>['pricey', 'mid', 'cheap'],
      );
    });

    test('relevance puts featured products first', () async {
      final ProviderContainer c = await loaded();
      expect(c.read(filteredProductsProvider).first.id, 'mid');
    });

    test('clearRefinements keeps query and category', () async {
      final ProviderContainer c = await loaded();
      final CatalogFilterNotifier n = c.read(catalogFilterProvider.notifier);
      n.setQuery('scarf');
      n.setCategory('accessories');
      n.setOnSaleOnly(true);
      n.setMinRating(4);

      n.clearRefinements();
      final CatalogFilter f = c.read(catalogFilterProvider);
      expect(f.query, 'scarf');
      expect(f.categoryId, 'accessories');
      expect(f.onSaleOnly, isFalse);
      expect(f.minRating, 0);
      expect(f.activeRefinements, 0);
    });

    test('changing category clears the subcategory', () async {
      final ProviderContainer c = await loaded();
      final CatalogFilterNotifier n = c.read(catalogFilterProvider.notifier);
      n.setSubcategory('Jackets');
      n.setCategory('accessories');
      expect(c.read(catalogFilterProvider).subcategory, isNull);
    });
  });

  group('catalog queries', () {
    test('related excludes the product itself and stays in category', () async {
      final ProviderContainer c = await loaded();
      final Catalog data = c.read(catalogDataProvider);
      final List<Product> related = data.related(cheap);
      expect(related.map((Product p) => p.id), <String>['mid']);
    });

    test('onSale is ordered by deepest discount', () async {
      final ProviderContainer c = await loaded();
      expect(c.read(catalogDataProvider).onSale.first.id, 'mid');
    });
  });

  group('favorites', () {
    test('toggle adds then removes, and persists', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier favorites = c.read(wishListsProvider.notifier);

      expect(await favorites.toggle('mid'), isTrue);
      expect(c.read(isFavoriteProvider('mid')), isTrue);
      expect(c.read(favoriteProductsProvider).single.id, 'mid');

      expect(await favorites.toggle('mid'), isFalse);
      expect(c.read(favoritesProvider), isEmpty);
    });

    test('restores from preferences on start', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: const <String, Object>{
          'favorites.ids': <String>['pricey'],
        },
      );
      await c.read(catalogProvider.future);
      expect(c.read(favoriteProductsProvider).single.id, 'pricey');
    });
  });

  group('live catalog mapping', () {
    // A verbatim slice of a real dummyjson.com response, so the mapping is
    // tested against the shape the API actually sends rather than an
    // idealised one. Unit tests never touch the network.
    String payload(String products) =>
        '{"products":[$products],"total":2,"skip":0,"limit":2}';

    const String mascara = '''
{"id":1,"title":"Essence Mascara Lash Princess","description":"A volumizing mascara.",
 "category":"beauty","price":9.99,"discountPercentage":10.48,"rating":2.56,"stock":99,
 "tags":["beauty","mascara"],"brand":"Essence",
 "images":["https://cdn.dummyjson.com/p/1.webp"],
 "thumbnail":"https://cdn.dummyjson.com/p/thumb.webp",
 "reviews":[{"rating":5,"comment":"Very happy!","date":"2025-04-30T09:41:02.053Z",
             "reviewerName":"Hazel Evans","reviewerEmail":"h@x.dummyjson.com"}],
 "meta":{"createdAt":"2025-04-30T09:41:02.053Z"}}''';

    // No brand, no discount, no images — all real gaps in the live data.
    const String bare = '''
{"id":2,"title":"Powder Canister","description":"","category":"groceries",
 "price":14.50,"discountPercentage":0,"rating":4.9,"stock":5,"tags":[],
 "images":[],"thumbnail":"https://cdn.dummyjson.com/p/thumb2.webp",
 "reviews":[],"meta":{"createdAt":"2020-01-01T00:00:00.000Z"}}''';

    DummyJsonProductRepository repoReturning(String body, {int status = 200}) =>
        DummyJsonProductRepository(
          client: MockClient(
            (http.Request _) async => http.Response(
              body,
              status,
              headers: <String, String>{'content-type': 'application/json'},
            ),
          ),
        );

    test('maps the live fields onto the storefront model', () async {
      final Catalog data = await repoReturning(
        payload('$mascara,$bare'),
      ).loadCatalog();

      final Product m = data.byId('1')!;
      expect(m.name, 'Essence Mascara Lash Princess');
      expect(m.brand, 'Essence');
      expect(m.categoryId, 'beauty', reason: 'beauty slug folds into beauty');
      expect(m.subcategory, 'Beauty');
      expect(m.price, 9.99);
      expect(m.rating, 2.56);
      expect(m.stock, 99);
      expect(m.tags, contains('mascara'));
      expect(m.reviewCount, 1);
      expect(m.reviews.single.author, 'Hazel Evans');
      expect(m.reviews.single.body, 'Very happy!');
    });

    test('derives the was-price from the discount percentage', () async {
      final Catalog data = await repoReturning(payload(mascara)).loadCatalog();
      final Product m = data.products.single;

      // 9.99 at 10.48% off implies an original of ~11.16.
      expect(m.compareAtPrice, closeTo(11.16, 0.01));
      expect(m.compareAtPrice, greaterThan(m.price));
      expect(m.isOnSale, isTrue);
    });

    test('leaves the was-price unset when nothing is discounted', () async {
      final Catalog data = await repoReturning(payload(bare)).loadCatalog();
      expect(data.products.single.compareAtPrice, isNull);
    });

    test(
      'falls back to the section name when a product has no brand',
      () async {
        final Catalog data = await repoReturning(payload(bare)).loadCatalog();
        // Better than an "Unbranded" placeholder on the many unbranded items.
        expect(data.products.single.brand, 'Groceries');
      },
    );

    test('falls back to the thumbnail when the image list is empty', () async {
      final Catalog data = await repoReturning(payload(bare)).loadCatalog();
      expect(data.products.single.images, <String>[
        'https://cdn.dummyjson.com/p/thumb2.webp',
      ]);
    });

    test('every product lands in a real category', () async {
      final Catalog data = await repoReturning(
        payload('$mascara,$bare'),
      ).loadCatalog();
      final Set<String> ids = data.categories.map((Category c) => c.id).toSet();

      expect(data.categories, hasLength(6));
      for (final Product p in data.products) {
        expect(ids, contains(p.categoryId));
      }
    });

    test('drops products whose category has no storefront group', () async {
      const String alien =
          '{"id":9,"title":"Mystery","category":"quantum-widgets","price":1,'
          '"discountPercentage":0,"rating":5,"stock":1,"images":[],'
          '"thumbnail":"t","reviews":[],"meta":{}}';
      final Catalog data = await repoReturning(
        payload('$mascara,$alien'),
      ).loadCatalog();

      // Otherwise it would exist but no filter could ever reach it.
      expect(data.products.map((Product p) => p.id), <String>['1']);
    });

    test('apparel gets a size run so the size guide stays usable', () async {
      const String shirt =
          '{"id":3,"title":"Blue Shirt","category":"mens-shirts","price":40,'
          '"discountPercentage":0,"rating":4,"stock":9,"images":[],'
          '"thumbnail":"t","reviews":[],"meta":{}}';
      final Catalog data = await repoReturning(payload(shirt)).loadCatalog();

      expect(data.products.single.sizes, <String>['S', 'M', 'L', 'XL']);
    });

    test('non-apparel gets no sizes', () async {
      final Catalog data = await repoReturning(payload(mascara)).loadCatalog();
      expect(data.products.single.sizes, isEmpty);
    });

    test('no product claims a color it cannot support', () async {
      // The feed has no color field; guessing from the title tags
      // "Ice Cream" as cream, so the selector stays hidden instead.
      const String iceCream =
          '{"id":4,"title":"Ice Cream","category":"groceries","price":5,'
          '"discountPercentage":0,"rating":4,"stock":9,"images":[],'
          '"thumbnail":"t","reviews":[],"meta":{}}';
      final Catalog data = await repoReturning(payload(iceCream)).loadCatalog();

      expect(data.products.single.colors, isEmpty);
    });

    test('flags the best-rated as featured', () async {
      final Catalog data = await repoReturning(
        payload('$mascara,$bare'),
      ).loadCatalog();
      expect(data.byId('2')!.isFeatured, isTrue, reason: 'rated 4.9');
    });

    test('caches, so browsing costs one request', () async {
      int calls = 0;
      final DummyJsonProductRepository repo = DummyJsonProductRepository(
        client: MockClient((http.Request _) async {
          calls++;
          return http.Response(payload(mascara), 200);
        }),
      );

      await repo.loadCatalog();
      await repo.loadCatalog();
      await repo.loadCatalog();
      expect(calls, 1);
    });
  });

  group('live catalog failures', () {
    Future<Object?> errorFrom(http.Client client) async {
      try {
        await DummyJsonProductRepository(client: client).loadCatalog();
        return null;
      } on Object catch (error) {
        return error;
      }
    }

    test('rate limiting says to wait rather than showing a raw 429', () async {
      final Object? e = await errorFrom(
        MockClient((http.Request _) async => http.Response('slow down', 429)),
      );
      expect(e, isA<CatalogException>());
      expect('$e', contains('give it a minute'));
    });

    test('a server error is reported in plain language', () async {
      final Object? e = await errorFrom(
        MockClient((http.Request _) async => http.Response('boom', 503)),
      );
      expect('$e', contains('503'));
      expect('$e', isNot(contains('Exception:')));
    });

    test('an unreachable host is reported as a connection problem', () async {
      final Object? e = await errorFrom(
        MockClient(
          (http.Request _) async => throw const SocketException('no route'),
        ),
      );
      expect('$e', contains('Check your connection'));
    });

    test('malformed json does not leak a parser error', () async {
      final Object? e = await errorFrom(
        MockClient((http.Request _) async => http.Response('<html>', 200)),
      );
      expect('$e', contains('unreadable'));
    });

    test('an empty catalog is an error, not a blank shop', () async {
      final Object? e = await errorFrom(
        MockClient(
          (http.Request _) async =>
              http.Response('{"products":[],"total":0}', 200),
        ),
      );
      expect('$e', contains('no products'));
    });
  });
}
