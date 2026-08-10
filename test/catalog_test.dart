import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/catalog_filter_provider.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

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
    categories: const <Category>[],
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
      final FavoritesNotifier favorites = c.read(favoritesProvider.notifier);

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

  group('bundled catalog asset', () {
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    test('parses and is internally consistent', () async {
      final Catalog data = await MockProductRepository(
        latency: Duration.zero,
      ).loadCatalog();

      expect(data.products, isNotEmpty);
      expect(data.categories, isNotEmpty);

      final Set<String> categoryIds = data.categories
          .map((Category c) => c.id)
          .toSet();
      final Set<String> productIds = <String>{};

      for (final Product p in data.products) {
        expect(productIds.add(p.id), isTrue, reason: 'duplicate id ${p.id}');
        expect(p.images, isNotEmpty, reason: '${p.id} has no images');
        expect(p.price, greaterThan(0));
        expect(p.rating, inInclusiveRange(0, 5));
        expect(
          categoryIds,
          contains(p.categoryId),
          reason: '${p.id} points at unknown category ${p.categoryId}',
        );
        if (p.compareAtPrice != null) {
          expect(p.compareAtPrice, greaterThan(p.price));
        }
      }

      expect(data.featured, isNotEmpty);
      expect(data.onSale, isNotEmpty);
    });
  });
}
