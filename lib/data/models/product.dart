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
    this.colors = const <ProductColor>[],
    this.sizes = const <String>[],
    this.tags = const <String>[],
    this.reviews = const <Review>[],
    this.stock = 25,
    this.isNew = false,
    this.isFeatured = false,
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
  final double rating;
  final int reviewCount;
  final List<ProductColor> colors;
  final List<String> sizes;
  final List<String> tags;
  final List<Review> reviews;
  final int stock;
  final bool isNew;
  final bool isFeatured;

  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  bool get inStock => stock > 0;

  bool get isLowStock => stock > 0 && stock <= 10;

  /// Whole-percent discount, e.g. `25` for 25% off. Zero when not on sale.
  int get discountPercent {
    if (!isOnSale) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  String get thumbnail => images.isEmpty ? '' : images.first;

  /// Free-text haystack used by the search field.
  String get searchIndex =>
      '$name $brand $subcategory ${tags.join(' ')}'.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// A named colourway, stored as an ARGB value so it survives serialisation.
@immutable
class ProductColor {
  const ProductColor(this.name, this.argb);

  factory ProductColor.fromJson(Map<String, dynamic> json) =>
      ProductColor(json['name'] as String, json['argb'] as int);

  final String name;
  final int argb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductColor && other.name == name && other.argb == argb);

  @override
  int get hashCode => Object.hash(name, argb);
}
