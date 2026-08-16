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
  Catalog({required this.categories, required this.products});

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    categories: <Category>[
      for (final Object? c
          in json['categories'] as List<dynamic>? ?? <dynamic>[])
        Category.fromJson(c! as Map<String, dynamic>),
    ],
    products: <Product>[
      for (final Object? p in json['products'] as List<dynamic>? ?? <dynamic>[])
        Product.fromJson(p! as Map<String, dynamic>),
    ],
  );

  final List<Category> categories;
  final List<Product> products;

  static final Catalog empty = Catalog(
    categories: <Category>[],
    products: <Product>[],
  );

  /// Built once on first use rather than scanned per lookup: the cart, the
  /// wishlist and every order line resolve by id on each rebuild.
  late final Map<String, Product> _byId = <String, Product>{
    for (final Product p in products) p.id: p,
  };

  bool get isEmpty => products.isEmpty;

  Product? byId(String id) => _byId[id];

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categories': categories.map((Category c) => c.toJson()).toList(),
    'products': products.map((Product p) => p.toJson()).toList(),
  };

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

  /// Everything carrying one brand, best-rated first.
  ///
  /// Matched case-insensitively: brand is free text from the source, so the
  /// same name can arrive capitalised differently on different products.
  List<Product> byBrand(String brand) {
    final String needle = brand.trim().toLowerCase();
    if (needle.isEmpty) return const <Product>[];
    final List<Product> hits = products
        .where((Product p) => p.brand.trim().toLowerCase() == needle)
        .toList();
    hits.sort((Product a, Product b) => b.rating.compareTo(a.rating));
    return hits;
  }

  /// Same category, excluding [product] itself, best-rated first.
  /// Which storefront group is worn or used alongside another.
  ///
  /// The shop's own opinion, not a claim about anyone's behaviour: a coat
  /// goes with a bag, a phone goes with a case. Groups with no natural
  /// partner pair with themselves and rely on the subcategory rule below.
  static const Map<String, String> _goesWith = <String, String>{
    'fashion': 'accessories',
    'accessories': 'fashion',
    'tech': 'tech',
    'beauty': 'beauty',
    'home': 'home',
    'sports': 'sports',
  };

  /// Things that go with [product] rather than compete with it.
  ///
  /// Always a different subcategory: another five coats is what "you might
  /// also like" is for, and putting them under "complete the look" would be
  /// the same rail twice.
  List<Product> completeTheLook(Product product, {int limit = 8}) {
    final String group = _goesWith[product.categoryId] ?? product.categoryId;
    final List<Product> pool = products
        .where(
          (Product p) =>
              p.id != product.id &&
              p.categoryId == group &&
              p.subcategory != product.subcategory,
        )
        .toList();
    pool.sort((Product a, Product b) => b.rating.compareTo(a.rating));
    return pool.take(limit).toList(growable: false);
  }

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
