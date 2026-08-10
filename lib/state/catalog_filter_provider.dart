import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

enum SortOption {
  relevance('Recommended'),
  priceLowHigh('Price: low to high'),
  priceHighLow('Price: high to low'),
  topRated('Top rated'),
  biggestDiscount('Biggest discount');

  const SortOption(this.label);

  final String label;
}

/// Everything the catalog screen filters on. Immutable so Riverpod can diff it.
@immutable
class CatalogFilter {
  const CatalogFilter({
    this.query = '',
    this.categoryId,
    this.subcategory,
    this.sort = SortOption.relevance,
    this.maxPrice,
    this.minRating = 0,
    this.onSaleOnly = false,
    this.inStockOnly = false,
  });

  final String query;
  final String? categoryId;
  final String? subcategory;
  final SortOption sort;

  /// Null means "no ceiling".
  final double? maxPrice;
  final double minRating;
  final bool onSaleOnly;
  final bool inStockOnly;

  /// Count of active refinements, shown on the Filters button badge.
  /// Query and category are excluded — they have their own visible UI.
  int get activeRefinements =>
      (maxPrice != null ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (onSaleOnly ? 1 : 0) +
      (inStockOnly ? 1 : 0) +
      (sort != SortOption.relevance ? 1 : 0) +
      (subcategory != null ? 1 : 0);

  CatalogFilter copyWith({
    String? query,
    String? Function()? categoryId,
    String? Function()? subcategory,
    SortOption? sort,
    double? Function()? maxPrice,
    double? minRating,
    bool? onSaleOnly,
    bool? inStockOnly,
  }) => CatalogFilter(
    query: query ?? this.query,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    subcategory: subcategory == null ? this.subcategory : subcategory(),
    sort: sort ?? this.sort,
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    minRating: minRating ?? this.minRating,
    onSaleOnly: onSaleOnly ?? this.onSaleOnly,
    inStockOnly: inStockOnly ?? this.inStockOnly,
  );
}

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setCategory(String? id) =>
      state = state.copyWith(categoryId: () => id, subcategory: () => null);

  void setSubcategory(String? value) =>
      state = state.copyWith(subcategory: () => value);

  void setSort(SortOption sort) => state = state.copyWith(sort: sort);

  void setMaxPrice(double? value) =>
      state = state.copyWith(maxPrice: () => value);

  void setMinRating(double value) => state = state.copyWith(minRating: value);

  void setOnSaleOnly(bool value) => state = state.copyWith(onSaleOnly: value);

  void setInStockOnly(bool value) => state = state.copyWith(inStockOnly: value);

  /// Clears refinements but keeps the query and category the shopper navigated
  /// into — resetting those would feel like losing your place.
  void clearRefinements() =>
      state = CatalogFilter(query: state.query, categoryId: state.categoryId);

  void reset() => state = const CatalogFilter();
}

final NotifierProvider<CatalogFilterNotifier, CatalogFilter>
catalogFilterProvider = NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
  CatalogFilterNotifier.new,
);

/// The catalog after search, filters and sort are applied.
final Provider<List<Product>>
filteredProductsProvider = Provider<List<Product>>((Ref ref) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  final CatalogFilter f = ref.watch(catalogFilterProvider);
  final String q = f.query.trim().toLowerCase();

  final List<Product> result = catalog.products.where((Product p) {
    if (f.categoryId != null && p.categoryId != f.categoryId) return false;
    if (f.subcategory != null && p.subcategory != f.subcategory) return false;
    if (f.onSaleOnly && !p.isOnSale) return false;
    if (f.inStockOnly && !p.inStock) return false;
    if (f.maxPrice != null && p.price > f.maxPrice!) return false;
    if (p.rating < f.minRating) return false;
    if (q.isNotEmpty && !p.searchIndex.contains(q)) return false;
    return true;
  }).toList();

  switch (f.sort) {
    case SortOption.relevance:
      result.sort((Product a, Product b) {
        final int featured = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
        if (featured != 0) return featured;
        return b.rating.compareTo(a.rating);
      });
    case SortOption.priceLowHigh:
      result.sort((Product a, Product b) => a.price.compareTo(b.price));
    case SortOption.priceHighLow:
      result.sort((Product a, Product b) => b.price.compareTo(a.price));
    case SortOption.topRated:
      result.sort((Product a, Product b) => b.rating.compareTo(a.rating));
    case SortOption.biggestDiscount:
      result.sort(
        (Product a, Product b) =>
            b.discountPercent.compareTo(a.discountPercent),
      );
  }
  return result;
});

/// Subcategory labels available inside the current category selection.
final Provider<List<String>> subcategoryOptionsProvider =
    Provider<List<String>>((Ref ref) {
      final Catalog catalog = ref.watch(catalogDataProvider);
      final String? categoryId = ref.watch(catalogFilterProvider).categoryId;
      final Set<String> labels = <String>{
        for (final Product p in catalog.products)
          if (categoryId == null || p.categoryId == categoryId) p.subcategory,
      };
      final List<String> sorted = labels.toList()..sort();
      return sorted;
    });

/// Highest price in the catalog, used as the price slider's ceiling.
final Provider<double> priceCeilingProvider = Provider<double>((Ref ref) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  double max = 0;
  for (final Product p in catalog.products) {
    if (p.price > max) max = p.price;
  }
  return max == 0 ? 1000 : (max / 50).ceil() * 50;
});

/// Persisted search history for the search screen's suggestions.
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const String _key = 'search.history';
  static const int _limit = 8;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<String> build() => _prefs.getStringList(_key) ?? const <String>[];

  Future<void> record(String term) async {
    final String value = term.trim();
    if (value.length < 2) return;
    final List<String> next = <String>[
      value,
      ...state.where((String s) => s.toLowerCase() != value.toLowerCase()),
    ].take(_limit).toList();
    state = next;
    await _prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    state = const <String>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<SearchHistoryNotifier, List<String>>
searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

/// Product ids the shopper opened, most recent first.
class RecentlyViewedNotifier extends Notifier<List<String>> {
  static const String _key = 'recentlyViewed.ids';
  static const int _limit = 12;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<String> build() => _prefs.getStringList(_key) ?? const <String>[];

  Future<void> record(String productId) async {
    final List<String> next = <String>[
      productId,
      ...state.where((String id) => id != productId),
    ].take(_limit).toList();
    state = next;
    await _prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    state = const <String>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<RecentlyViewedNotifier, List<String>>
recentlyViewedProvider = NotifierProvider<RecentlyViewedNotifier, List<String>>(
  RecentlyViewedNotifier.new,
);

final Provider<List<Product>> recentlyViewedProductsProvider =
    Provider<List<Product>>((Ref ref) {
      final List<String> ids = ref.watch(recentlyViewedProvider);
      final Catalog catalog = ref.watch(catalogDataProvider);
      return <Product>[
        for (final String id in ids)
          if (catalog.byId(id) case final Product p) p,
      ];
    });
