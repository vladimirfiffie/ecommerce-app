import '../models/category.dart';
import '../models/product.dart';

/// Everything the storefront knows about products.
///
/// Implemented by `DummyJsonProductRepository` against the live API; swapping
/// in another backend means implementing this one interface and rebinding
/// `productRepositoryProvider` — no screen code changes.
abstract class ProductRepository {
  Future<Catalog> loadCatalog();

  /// Drops any cached copy so the next [loadCatalog] goes to the source.
  ///
  /// Without this, pull-to-refresh is a no-op: invalidating the provider
  /// just re-reads the repository's own cache and returns the same catalog.
  /// Concrete for the benefit of implementations that never cache.
  void clearCache() {}
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
