import 'package:flutter/foundation.dart';

import 'cart_entry.dart';
import 'product.dart';

/// A cart line resolved against the catalog: the persisted [entry] joined with
/// the live [Product] it points at.
@immutable
class CartItem {
  const CartItem({required this.entry, required this.product});

  final CartEntry entry;
  final Product product;

  String get lineId => entry.lineId;
  int get quantity => entry.quantity;
  String? get size => entry.size;

  ProductColor? get color {
    final String? name = entry.colorName;
    if (name == null) return null;
    for (final ProductColor c in product.colors) {
      if (c.name == name) return c;
    }
    return null;
  }

  double get lineTotal => product.price * quantity;

  /// `M · Onyx`, or null when the product has no variants.
  String? get variantLabel {
    final List<String> parts = <String>[
      if (entry.size != null) entry.size!,
      if (entry.colorName != null) entry.colorName!,
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem && other.entry == entry && other.product == product);

  @override
  int get hashCode => Object.hash(entry, product);
}
