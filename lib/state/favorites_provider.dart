import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// Wishlist, stored as a set of product ids.
class FavoritesNotifier extends Notifier<Set<String>> {
  static const String _key = 'favorites.ids';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  bool contains(String productId) => state.contains(productId);

  /// Returns true when the product ended up favorited.
  Future<bool> toggle(String productId) async {
    final Set<String> next = <String>{...state};
    final bool added = next.add(productId);
    if (!added) next.remove(productId);
    state = next;
    await _prefs.setStringList(_key, next.toList());
    return added;
  }

  Future<void> clear() async {
    state = <String>{};
    await _prefs.remove(_key);
  }
}

final NotifierProvider<FavoritesNotifier, Set<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

/// Whether a single product is favorited — cheap to watch per card.
final isFavoriteProvider = Provider.family<bool, String>(
  (Ref ref, String productId) =>
      ref.watch(favoritesProvider).contains(productId),
);

/// Favorited products resolved against the catalog.
final Provider<List<Product>> favoriteProductsProvider =
    Provider<List<Product>>((Ref ref) {
      final Set<String> ids = ref.watch(favoritesProvider);
      final Catalog catalog = ref.watch(catalogDataProvider);
      return <Product>[
        for (final String id in ids)
          if (catalog.byId(id) case final Product p) p,
      ];
    });
