import 'package:flutter/foundation.dart';

/// The persisted half of a cart line.
///
/// Only the selection is stored; the [Product] itself is rehydrated from the
/// catalog by id, so a price or image change on the backend shows up
/// immediately instead of going stale in local storage.
@immutable
class CartEntry {
  const CartEntry({
    required this.productId,
    required this.quantity,
    this.size,
    this.colorName,
  });

  factory CartEntry.fromJson(Map<String, dynamic> json) => CartEntry(
    productId: json['productId'] as String,
    quantity: json['quantity'] as int? ?? 1,
    size: json['size'] as String?,
    colorName: json['colorName'] as String?,
  );

  final String productId;
  final int quantity;
  final String? size;
  final String? colorName;

  /// Identity of a cart line: same product *and* same variant.
  String get lineId => '$productId|${size ?? '-'}|${colorName ?? '-'}';

  CartEntry copyWith({int? quantity}) => CartEntry(
    productId: productId,
    quantity: quantity ?? this.quantity,
    size: size,
    colorName: colorName,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'productId': productId,
    'quantity': quantity,
    'size': size,
    'colorName': colorName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartEntry &&
          other.lineId == lineId &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(lineId, quantity);
}
