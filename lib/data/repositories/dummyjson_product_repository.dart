import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import 'product_repository.dart';

/// Raised when the catalog can't be fetched. The message is shown to the user
/// verbatim by the catalog error state, so it stays in plain language.
class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads the live catalog from [dummyjson.com](https://dummyjson.com).
///
/// A free, keyless demo API — 194 products across 24 categories, rate-limited
/// to 100 requests a minute. One request fetches everything; the result is
/// held for the life of the repository, so browsing costs nothing further.
///
/// DummyJSON's 24 slugs are folded into the six storefront groups below.
///
/// Two fields have no source in the feed. Sizes are filled in per apparel
/// category from [_sizeRuns] — a shop convention rather than per-product
/// data, which is what keeps the size guide usable. Colours are left empty:
/// the only available signal is the product title, and matching colour words
/// there tags "Ice Cream" as cream and "Red Onions" as red, so a wrong
/// swatch is worse than none.
class DummyJsonProductRepository implements ProductRepository {
  DummyJsonProductRepository({
    http.Client? client,
    this.baseUrl = 'https://dummyjson.com',
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Catalog? _cache;

  /// DummyJSON slug → storefront group. Every one of its 24 categories is
  /// mapped, so nothing silently disappears from the shop.
  static const Map<String, String> _groups = <String, String>{
    'mens-shirts': 'fashion',
    'mens-shoes': 'fashion',
    'tops': 'fashion',
    'womens-dresses': 'fashion',
    'womens-shoes': 'fashion',

    'laptops': 'tech',
    'smartphones': 'tech',
    'tablets': 'tech',
    'mobile-accessories': 'tech',

    'beauty': 'beauty',
    'fragrances': 'beauty',
    'skin-care': 'beauty',

    'mens-watches': 'accessories',
    'womens-watches': 'accessories',
    'womens-bags': 'accessories',
    'womens-jewellery': 'accessories',
    'sunglasses': 'accessories',

    'furniture': 'home',
    'home-decoration': 'home',
    'kitchen-accessories': 'home',
    'groceries': 'home',

    'sports-accessories': 'sports',
    'motorcycle': 'sports',
    'vehicle': 'sports',
  };

  /// The storefront's own groups, in display order. Icons come from
  /// [Category]'s name map; the image is filled in from the first live
  /// product in each group.
  static const List<(String, String, String)> _groupInfo =
      <(String, String, String)>[
        ('fashion', 'Fashion', 'checkroom'),
        ('tech', 'Tech', 'devices'),
        ('beauty', 'Beauty', 'spa'),
        ('accessories', 'Accessories', 'watch'),
        ('home', 'Home', 'chair'),
        ('sports', 'Sports', 'sports_tennis'),
      ];

  /// Size runs offered per apparel category. The feed carries no sizes, and
  /// a clothing shop stocks a standard run regardless — so these are the
  /// storefront's, not the product's.
  static const Map<String, List<String>> _sizeRuns = <String, List<String>>{
    'mens-shirts': <String>['S', 'M', 'L', 'XL'],
    'tops': <String>['XS', 'S', 'M', 'L', 'XL'],
    'womens-dresses': <String>['XS', 'S', 'M', 'L'],
    'mens-shoes': <String>['8', '9', '10', '11', '12'],
    'womens-shoes': <String>['5', '6', '7', '8', '9'],
  };

  /// Products flagged new: the most recently created few.
  static const int _newCount = 15;

  /// Products flagged featured: the best-rated few.
  static const int _featuredCount = 12;

  @override
  Future<Catalog> loadCatalog() async {
    final Catalog? cached = _cache;
    if (cached != null) return cached;

    // limit=0 returns the whole catalog in one request rather than paging.
    final Uri uri = Uri.parse('$baseUrl/products?limit=0');

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const CatalogException(
        'The shop took too long to respond. Check your connection and '
        'try again.',
      );
    } on Object {
      throw const CatalogException(
        'Couldn’t reach the shop. Check your connection and try again.',
      );
    }

    if (response.statusCode == 429) {
      throw const CatalogException(
        'Too many requests just now — give it a minute and try again.',
      );
    }
    if (response.statusCode != 200) {
      throw CatalogException(
        'The shop returned an error (${response.statusCode}). '
        'Try again shortly.',
      );
    }

    final List<Map<String, dynamic>> raw;
    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      raw = <Map<String, dynamic>>[
        for (final Object? p in body['products'] as List<dynamic>)
          p! as Map<String, dynamic>,
      ];
    } on Object {
      throw const CatalogException(
        'The shop sent something unreadable. Try again shortly.',
      );
    }

    if (raw.isEmpty) {
      throw const CatalogException('The shop has no products right now.');
    }

    return _cache = _buildCatalog(raw);
  }

  Catalog _buildCatalog(List<Map<String, dynamic>> raw) {
    // Keep only what maps to a storefront group, so an unexpected new slug
    // can't produce products that no category filter can reach.
    final List<Map<String, dynamic>> usable = raw
        .where((Map<String, dynamic> p) => _groups.containsKey(p['category']))
        .toList();

    final Set<int> newIds = _topBy(
      usable,
      (Map<String, dynamic> p) => _createdAt(p).millisecondsSinceEpoch,
      count: _newCount,
    );
    final Set<int> featuredIds = _topBy(
      usable,
      (Map<String, dynamic> p) => (p['rating'] as num?) ?? 0,
      count: _featuredCount,
    );

    final DateTime now = DateTime.now();
    final List<Product> products = <Product>[
      for (final Map<String, dynamic> p in usable)
        _toProduct(p, now: now, newIds: newIds, featuredIds: featuredIds),
    ];

    return Catalog(categories: _toCategories(products), products: products);
  }

  /// Ids of the highest-scoring [count] entries.
  Set<int> _topBy(
    List<Map<String, dynamic>> items,
    num Function(Map<String, dynamic>) score, {
    required int count,
  }) {
    final List<Map<String, dynamic>> sorted =
        List<Map<String, dynamic>>.of(items)..sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              score(b).compareTo(score(a)),
        );
    return <int>{
      for (final Map<String, dynamic> p in sorted.take(count))
        (p['id'] as num).toInt(),
    };
  }

  List<Category> _toCategories(List<Product> products) => <Category>[
    for (final (String id, String label, String icon) in _groupInfo)
      Category.fromJson(<String, dynamic>{
        'id': id,
        'label': label,
        'icon': icon,
        'imageUrl': _firstImageIn(products, id),
      }),
  ];

  String _firstImageIn(List<Product> products, String categoryId) {
    for (final Product p in products) {
      if (p.categoryId == categoryId && p.images.isNotEmpty) {
        return p.images.first;
      }
    }
    return '';
  }

  Product _toProduct(
    Map<String, dynamic> p, {
    required DateTime now,
    required Set<int> newIds,
    required Set<int> featuredIds,
  }) {
    final int id = (p['id'] as num).toInt();
    final String slug = p['category'] as String;
    final String subcategory = _prettifySlug(slug);
    final double price = ((p['price'] as num?) ?? 0).toDouble();
    final double discount = ((p['discountPercentage'] as num?) ?? 0).toDouble();

    final List<String> images = <String>[
      for (final Object? i in (p['images'] as List<dynamic>?) ?? <dynamic>[])
        i as String,
    ];
    final String? thumbnail = p['thumbnail'] as String?;

    return Product(
      id: '$id',
      name: (p['title'] as String?) ?? 'Untitled',
      // Many DummyJSON items carry no brand; the section name reads better
      // than an "Unbranded" placeholder.
      brand: (p['brand'] as String?)?.trim().isNotEmpty ?? false
          ? p['brand'] as String
          : subcategory,
      categoryId: _groups[slug]!,
      subcategory: subcategory,
      price: price,
      // DummyJSON gives a discount percentage off an unstated original, so
      // the "was" price is derived back out of it.
      compareAtPrice: discount > 0
          ? double.parse((price / (1 - discount / 100)).toStringAsFixed(2))
          : null,
      description: (p['description'] as String?) ?? '',
      images: images.isNotEmpty ? images : <String>[?thumbnail],
      rating: ((p['rating'] as num?) ?? 0).toDouble(),
      reviewCount: ((p['reviews'] as List<dynamic>?) ?? <dynamic>[]).length,
      reviews: <Review>[
        for (final Object? r in (p['reviews'] as List<dynamic>?) ?? <dynamic>[])
          _toReview(r! as Map<String, dynamic>, now),
      ],
      stock: ((p['stock'] as num?) ?? 0).toInt(),
      tags: <String>[
        for (final Object? t in (p['tags'] as List<dynamic>?) ?? <dynamic>[])
          t as String,
      ],
      sizes: _sizeRuns[slug] ?? const <String>[],
      isNew: newIds.contains(id),
      isFeatured: featuredIds.contains(id),
    );
  }

  Review _toReview(Map<String, dynamic> r, DateTime now) {
    final DateTime? at = DateTime.tryParse((r['date'] as String?) ?? '');
    return Review(
      author: (r['reviewerName'] as String?) ?? 'Anonymous',
      rating: ((r['rating'] as num?) ?? 0).toDouble(),
      body: (r['comment'] as String?) ?? '',
      daysAgo: at == null ? 0 : now.difference(at).inDays.clamp(0, 3650),
    );
  }

  DateTime _createdAt(Map<String, dynamic> p) {
    final Object? meta = p['meta'];
    final String? raw = meta is Map<String, dynamic>
        ? meta['createdAt'] as String?
        : null;
    return DateTime.tryParse(raw ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// `womens-dresses` → `Women's Dresses`.
  static String _prettifySlug(String slug) => slug
      .split('-')
      .map(
        (String word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ')
      .replaceAll('Mens', 'Men’s')
      .replaceAll('Womens', 'Women’s');
}
