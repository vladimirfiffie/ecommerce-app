import 'package:flutter/foundation.dart';

/// A named list of saved products.
///
/// Ids are kept in the order they were saved, newest last, so a list reads the
/// way it was built rather than however a set happened to iterate.
@immutable
class WishList {
  const WishList({
    required this.id,
    required this.name,
    required this.productIds,
    required this.createdAt,
  });

  factory WishList.fromJson(Map<String, dynamic> json) => WishList(
    id: json['id'] as String,
    name: json['name'] as String,
    productIds: <String>[
      for (final Object? p
          in json['productIds'] as List<dynamic>? ?? <dynamic>[])
        p! as String,
    ],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// The list every heart tap lands in, and the one that can't be deleted.
  ///
  /// There has to be somewhere for a one-tap save to go, and asking which list
  /// on every tap would make saving something a decision.
  static const String defaultId = 'saved';

  static const int maxNameLength = 40;

  final String id;
  final String name;
  final List<String> productIds;
  final DateTime createdAt;

  bool get isDefault => id == defaultId;

  int get length => productIds.length;

  bool contains(String productId) => productIds.contains(productId);

  WishList copyWith({String? name, List<String>? productIds}) => WishList(
    id: id,
    name: name ?? this.name,
    productIds: productIds ?? this.productIds,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'productIds': productIds,
    'createdAt': createdAt.toIso8601String(),
  };
}
