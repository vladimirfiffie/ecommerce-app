import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import 'cart_entry.dart';
import 'product.dart';

/// One line of a placed order, with the product as it was at purchase.
///
/// An order records something that already happened, so it can't be a join
/// against the live catalog the way the cart is. A feed that reprices an item
/// would rewrite the total on a receipt printed months ago, and one that drops
/// an item would delete the line outright — leaving the printed lines short of
/// the order's own stored subtotal. So what was actually bought is frozen here
/// when the order is placed.
///
/// The catalog is still consulted for *reorder*, which genuinely wants today's
/// price and stock rather than last year's.
@immutable
class OrderLine {
  const OrderLine({
    required this.entry,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.unitPrice,
  });

  /// Freezes [product] as it stands right now.
  factory OrderLine.fromProduct(CartEntry entry, Product product) => OrderLine(
    entry: entry,
    name: product.name,
    brand: product.brand,
    imageUrl: product.thumbnail,
    unitPrice: product.price,
  );

  /// The snapshot fields sit alongside the entry's own, so an order stored
  /// before snapshots existed still decodes — it just arrives with
  /// [hasSnapshot] false and gets resolved against the catalog instead.
  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    entry: CartEntry.fromJson(json),
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
  );

  final CartEntry entry;

  /// Product name as it read at purchase.
  final String name;

  final String brand;

  /// Product image as it was at purchase. May be empty.
  final String imageUrl;

  /// What one unit cost at purchase — not what it costs today.
  final double unitPrice;

  String get productId => entry.productId;
  String get lineId => entry.lineId;
  int get quantity => entry.quantity;
  String? get size => entry.size;
  String? get colorName => entry.colorName;

  /// False only for orders placed before lines carried a snapshot.
  bool get hasSnapshot => name.isNotEmpty;

  /// What to print for the line. A pre-snapshot line whose product has since
  /// left the catalog has no name to print, and saying so beats a blank row.
  String displayNameIn(AppL10n l10n) =>
      hasSnapshot ? name : l10n.itemNoLongerAvailable;

  double get lineTotal => unitPrice * quantity;

  /// `M · Onyx`, or null when the line has no variant.
  String? get variantLabel {
    final List<String> parts = <String>[
      if (entry.size != null) entry.size!,
      if (entry.colorName != null) entry.colorName!,
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  /// Fills a pre-snapshot line in from the catalog. A product that has since
  /// been delisted leaves the line unresolved rather than dropping it, so the
  /// lines still reconcile with the order total.
  OrderLine resolvedAgainst(Product? product) =>
      product == null ? this : OrderLine.fromProduct(entry, product);

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...entry.toJson(),
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'unitPrice': unitPrice,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLine &&
          other.entry == entry &&
          other.name == name &&
          other.unitPrice == unitPrice);

  @override
  int get hashCode => Object.hash(entry, name, unitPrice);
}
