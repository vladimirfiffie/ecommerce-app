import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import '../data/models/wish_list.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';
import 'wishlists_provider.dart';

/// Everything saved, in any list.
///
/// Kept as the seam it always was: a heart, a tab badge and the price-drop
/// alerts all want "is this saved" and none of them care which list it landed
/// in. What changed underneath is that there is now more than one list — see
/// [WishListsNotifier].
final Provider<Set<String>> favoritesProvider = Provider<Set<String>>(
  (Ref ref) => <String>{
    for (final WishList list in ref.watch(wishListsProvider))
      ...list.productIds,
  },
);

/// Whether a single product is saved — cheap to watch per card.
final isFavoriteProvider = Provider.family<bool, String>(
  (Ref ref, String productId) =>
      ref.watch(favoritesProvider).contains(productId),
);

/// Saved products resolved against the catalog, newest first.
///
/// Ordered by when each list saved them rather than by list, so the union
/// reads as one wishlist — which is what it is, from anywhere but the Saved
/// tab.
final Provider<List<Product>> favoriteProductsProvider =
    Provider<List<Product>>((Ref ref) {
      final Catalog catalog = ref.watch(catalogDataProvider);
      final List<String> ordered = <String>[
        for (final WishList list in ref.watch(wishListsProvider))
          ...list.productIds,
      ].reversed.toList();

      final Set<String> seen = <String>{};
      return <Product>[
        for (final String id in ordered)
          if (seen.add(id))
            if (catalog.byId(id) case final Product p) p,
      ];
    });
