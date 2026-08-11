import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// One brand and everything it sells, with the few numbers worth putting in a
/// header.
///
/// Brand is free text on [Product] — there is no brand record to hang this on —
/// so it's derived from the catalog on demand rather than stored.
@immutable
class BrandPage {
  const BrandPage({required this.name, required this.products});

  /// Name as the catalog spells it, not as it arrived in the route.
  final String name;

  /// Best-rated first.
  final List<Product> products;

  bool get isEmpty => products.isEmpty;

  int get count => products.length;

  int get onSaleCount => products.where((Product p) => p.isOnSale).length;

  /// Mean rating across the brand's products, or null when nothing is rated.
  double? get averageRating {
    final List<Product> rated = products
        .where((Product p) => p.rating > 0)
        .toList();
    if (rated.isEmpty) return null;
    final double sum = rated.fold(
      0,
      (double total, Product p) => total + p.rating,
    );
    return sum / rated.length;
  }

  /// Cheapest current price, for a "from $x" line.
  double? get lowestPrice {
    if (products.isEmpty) return null;
    return products
        .map((Product p) => p.price)
        .reduce((double a, double b) => a < b ? a : b);
  }
}

/// A brand's page, keyed by name. Empty when nothing matches — a stale share
/// link or a brand that has left the catalog.
final ProviderFamily<BrandPage, String> brandProvider =
    Provider.family<BrandPage, String>((Ref ref, String brand) {
      final Catalog catalog = ref.watch(catalogDataProvider);
      final List<Product> products = catalog.byBrand(brand);
      return BrandPage(
        // Prefer the catalog's own capitalisation over whatever the link said.
        name: products.isEmpty ? brand.trim() : products.first.brand,
        products: products,
      );
    });
