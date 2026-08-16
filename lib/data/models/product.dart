import 'package:flutter/foundation.dart';

import 'review.dart';

/// A single purchasable item in the catalog.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.subcategory,
    required this.price,
    required this.description,
    required this.images,
    required this.rating,
    required this.reviewCount,
    this.compareAtPrice,
    this.videos = const <String>[],
    this.colors = const <ProductColor>[],
    this.sizes = const <String>[],
    this.tags = const <String>[],
    this.reviews = const <Review>[],
    this.stock = 25,
    this.isNew = false,
    this.isFeatured = false,
    this.specs = ProductSpecs.none,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String,
    categoryId: json['categoryId'] as String,
    subcategory: json['subcategory'] as String,
    price: (json['price'] as num).toDouble(),
    compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
    description: json['description'] as String? ?? '',
    images: <String>[
      for (final Object? i in json['images'] as List<dynamic>? ?? <dynamic>[])
        i as String,
    ],
    videos: <String>[
      for (final Object? v in json['videos'] as List<dynamic>? ?? <dynamic>[])
        v as String,
    ],
    rating: (json['rating'] as num).toDouble(),
    reviewCount: json['reviewCount'] as int? ?? 0,
    stock: json['stock'] as int? ?? 0,
    sizes: <String>[
      for (final Object? s in json['sizes'] as List<dynamic>? ?? <dynamic>[])
        s as String,
    ],
    colors: <ProductColor>[
      for (final Object? c in json['colors'] as List<dynamic>? ?? <dynamic>[])
        ProductColor.fromJson(c! as Map<String, dynamic>),
    ],
    tags: <String>[
      for (final Object? t in json['tags'] as List<dynamic>? ?? <dynamic>[])
        t as String,
    ],
    reviews: <Review>[
      for (final Object? r in json['reviews'] as List<dynamic>? ?? <dynamic>[])
        Review.fromJson(r! as Map<String, dynamic>),
    ],
    isNew: json['isNew'] as bool? ?? false,
    isFeatured: json['isFeatured'] as bool? ?? false,
    specs: json['specs'] == null
        ? ProductSpecs.none
        : ProductSpecs.fromJson(json['specs']! as Map<String, dynamic>),
  );

  final String id;
  final String name;
  final String brand;

  /// Top-level group id, e.g. `fashion`. Matches [Category.id].
  final String categoryId;

  /// Human-readable sub-group, e.g. `Men's Shirts`.
  final String subcategory;

  /// Current price in USD.
  final double price;

  /// Original price, when the product is discounted.
  final double? compareAtPrice;

  final String description;
  final List<String> images;

  /// Clip URLs, shown in the gallery ahead of the photos. Usually empty: the
  /// live catalog has no video, so these are seeded for a few items.
  final List<String> videos;

  final double rating;
  final int reviewCount;
  final List<ProductColor> colors;
  final List<String> sizes;
  final List<String> tags;
  final List<Review> reviews;
  final int stock;
  final bool isNew;
  final bool isFeatured;

  /// Weight, size, warranty and the rest of the small print.
  final ProductSpecs specs;

  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  bool get inStock => stock > 0;

  bool get isLowStock => stock > 0 && stock <= 10;

  /// Whole-percent discount, e.g. `25` for 25% off. Zero when not on sale.
  int get discountPercent {
    if (!isOnSale) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  String get thumbnail => images.isEmpty ? '' : images.first;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'brand': brand,
    'categoryId': categoryId,
    'subcategory': subcategory,
    'price': price,
    if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
    'description': description,
    'images': images,
    if (videos.isNotEmpty) 'videos': videos,
    'rating': rating,
    'reviewCount': reviewCount,
    'stock': stock,
    'sizes': sizes,
    'colors': colors.map((ProductColor c) => c.toJson()).toList(),
    'tags': tags,
    'reviews': reviews.map((Review r) => r.toJson()).toList(),
    'isNew': isNew,
    'isFeatured': isFeatured,
    'specs': specs.toJson(),
  };

  /// Free-text haystack used by the search field.
  String get searchIndex =>
      '$name $brand $subcategory ${tags.join(' ')}'.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// The manufacturer-ish detail a shopper checks before committing: what it
/// weighs, how big it is, what happens if it goes wrong.
///
/// Every field is optional — the catalog source fills in what it has, and the
/// spec table simply omits the rest rather than printing "Unknown".
@immutable
class ProductSpecs {
  const ProductSpecs({
    this.sku,
    this.weightGrams,
    this.widthCm,
    this.heightCm,
    this.depthCm,
    this.warranty,
    this.shipping,
    this.returnPolicy,
    this.minimumOrderQuantity,
  });

  factory ProductSpecs.fromJson(Map<String, dynamic> json) => ProductSpecs(
    sku: json['sku'] as String?,
    weightGrams: (json['weightGrams'] as num?)?.toDouble(),
    widthCm: (json['widthCm'] as num?)?.toDouble(),
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    depthCm: (json['depthCm'] as num?)?.toDouble(),
    warranty: json['warranty'] as String?,
    shipping: json['shipping'] as String?,
    returnPolicy: json['returnPolicy'] as String?,
    minimumOrderQuantity: json['minimumOrderQuantity'] as int?,
  );

  static const ProductSpecs none = ProductSpecs();

  final String? sku;
  final double? weightGrams;
  final double? widthCm;
  final double? heightCm;
  final double? depthCm;
  final String? warranty;
  final String? shipping;
  final String? returnPolicy;

  /// Some catalog lines only sell in bulk. Only worth showing above 1.
  final int? minimumOrderQuantity;

  bool get hasDimensions =>
      widthCm != null && heightCm != null && depthCm != null;

  /// True when there's at least one row worth drawing.
  bool get isNotEmpty =>
      sku != null ||
      weightGrams != null ||
      hasDimensions ||
      warranty != null ||
      shipping != null ||
      returnPolicy != null ||
      (minimumOrderQuantity ?? 1) > 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (sku != null) 'sku': sku,
    if (weightGrams != null) 'weightGrams': weightGrams,
    if (widthCm != null) 'widthCm': widthCm,
    if (heightCm != null) 'heightCm': heightCm,
    if (depthCm != null) 'depthCm': depthCm,
    if (warranty != null) 'warranty': warranty,
    if (shipping != null) 'shipping': shipping,
    if (returnPolicy != null) 'returnPolicy': returnPolicy,
    if (minimumOrderQuantity != null)
      'minimumOrderQuantity': minimumOrderQuantity,
  };
}

/// A named colorway, stored as an ARGB value so it survives serialization.
@immutable
class ProductColor {
  const ProductColor(this.name, this.argb);

  factory ProductColor.fromJson(Map<String, dynamic> json) =>
      ProductColor(json['name'] as String, json['argb'] as int);

  final String name;
  final int argb;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'argb': argb,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductColor && other.name == name && other.argb == argb);

  @override
  int get hashCode => Object.hash(name, argb);
}
