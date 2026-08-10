import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category.dart';
import '../models/product.dart';

/// Everything the storefront knows about products.
///
/// Swapping the mock for a real backend means implementing this one interface
/// and rebinding `catalogRepositoryProvider` — no screen code changes.
abstract class ProductRepository {
  Future<Catalog> loadCatalog();
}

/// The in-memory result of a catalog load.
class Catalog {
  const Catalog({required this.categories, required this.products});

  final List<Category> categories;
  final List<Product> products;

  static const Catalog empty = Catalog(
    categories: <Category>[],
    products: <Product>[],
  );

  Product? byId(String id) {
    for (final Product p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> get featured =>
      products.where((Product p) => p.isFeatured).toList(growable: false);

  List<Product> get newArrivals =>
      products.where((Product p) => p.isNew).toList(growable: false);

  List<Product> get onSale {
    final List<Product> sale = products
        .where((Product p) => p.isOnSale)
        .toList();
    sale.sort(
      (Product a, Product b) => b.discountPercent.compareTo(a.discountPercent),
    );
    return sale;
  }

  List<Product> inCategory(String categoryId) => products
      .where((Product p) => p.categoryId == categoryId)
      .toList(growable: false);

  /// Same category, excluding [product] itself, best-rated first.
  List<Product> related(Product product, {int limit = 8}) {
    final List<Product> pool = products
        .where(
          (Product p) =>
              p.categoryId == product.categoryId && p.id != product.id,
        )
        .toList();
    pool.sort((Product a, Product b) => b.rating.compareTo(a.rating));
    return pool.take(limit).toList(growable: false);
  }
}

/// Loads the bundled `catalog.json`. Deliberately async and slightly delayed so
/// the loading skeletons are exercised the way a network repository would.
class MockProductRepository implements ProductRepository {
  MockProductRepository({this.latency = const Duration(milliseconds: 350)});

  final Duration latency;

  static const String _assetPath = 'assets/data/catalog.json';

  Catalog? _cache;

  @override
  Future<Catalog> loadCatalog() async {
    final Catalog? cached = _cache;
    if (cached != null) return cached;

    final String raw = await rootBundle.loadString(_assetPath);
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    final Catalog catalog = Catalog(
      categories: <Category>[
        for (final Object? c in json['categories'] as List<dynamic>)
          Category.fromJson(c! as Map<String, dynamic>),
      ],
      products: <Product>[
        for (final Object? p in json['products'] as List<dynamic>)
          Product.fromJson(p! as Map<String, dynamic>),
      ],
    );
    return _cache = catalog;
  }
}
