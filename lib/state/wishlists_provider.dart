import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';
import '../data/models/wish_list.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// Saved products, in whatever lists the shopper has made.
///
/// There is always at least one list — see [WishList.defaultId] — so a heart
/// tap always has somewhere to go.
class WishListsNotifier extends Notifier<List<WishList>> {
  static const String _key = 'wishlists';

  /// Where the flat wishlist used to live. Read once, on the first launch
  /// after the upgrade, and left alone afterwards.
  static const String legacyKey = 'favorites.ids';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<WishList> build() {
    final String? raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final List<WishList> lists = <WishList>[
          for (final Object? l in decoded)
            WishList.fromJson(l! as Map<String, dynamic>),
        ];
        if (lists.any((WishList l) => l.isDefault)) return lists;
        // A store with no default list can't take a heart tap. Rather than
        // refusing the save, put one back.
        return <WishList>[_emptyDefault(), ...lists];
      } on FormatException {
        return <WishList>[_emptyDefault()];
      }
    }

    // Everything saved before lists existed becomes the default list, so an
    // upgrade doesn't read as "you never saved anything".
    final List<String> legacy = _prefs.getStringList(legacyKey) ?? <String>[];
    return <WishList>[
      WishList(
        id: WishList.defaultId,
        name: 'Saved',
        productIds: legacy,
        createdAt: DateTime.now(),
      ),
    ];
  }

  static WishList _emptyDefault() => WishList(
    id: WishList.defaultId,
    name: 'Saved',
    productIds: const <String>[],
    createdAt: DateTime.now(),
  );

  Future<void> _persist(List<WishList> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((WishList l) => l.toJson()).toList()),
    );
  }

  WishList? byId(String id) {
    for (final WishList l in state) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Makes a list and returns its id, or null when the name is unusable.
  Future<String?> create(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final String id = 'list-${DateTime.now().microsecondsSinceEpoch}';
    await _persist(<WishList>[
      ...state,
      WishList(
        id: id,
        name: trimmed.length > WishList.maxNameLength
            ? trimmed.substring(0, WishList.maxNameLength)
            : trimmed,
        productIds: const <String>[],
        createdAt: DateTime.now(),
      ),
    ]);
    return id;
  }

  Future<void> rename(String id, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.id == id) l.copyWith(name: trimmed) else l,
    ]);
  }

  /// Deletes a list. The default one stays: something has to catch a heart.
  Future<bool> delete(String id) async {
    if (id == WishList.defaultId) return false;
    if (byId(id) == null) return false;
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.id != id) l,
    ]);
    return true;
  }

  Future<void> add(String productId, {String? listId}) async {
    final String target = listId ?? WishList.defaultId;
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.id == target && !l.contains(productId))
          l.copyWith(productIds: <String>[...l.productIds, productId])
        else
          l,
    ]);
  }

  Future<void> removeFrom(String productId, String listId) async {
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.id == listId)
          l.copyWith(
            productIds: <String>[
              for (final String id in l.productIds)
                if (id != productId) id,
            ],
          )
        else
          l,
    ]);
  }

  /// Unsaves something outright, wherever it was put.
  ///
  /// This is what an unfilled heart has to mean: leaving a copy behind in
  /// another list would show it still saved the moment the screen rebuilt.
  Future<void> removeEverywhere(String productId) async {
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.contains(productId))
          l.copyWith(
            productIds: <String>[
              for (final String id in l.productIds)
                if (id != productId) id,
            ],
          )
        else
          l,
    ]);
  }

  Future<void> setListsFor(String productId, Set<String> listIds) async {
    await _persist(<WishList>[
      for (final WishList l in state)
        if (listIds.contains(l.id) && !l.contains(productId))
          l.copyWith(productIds: <String>[...l.productIds, productId])
        else if (!listIds.contains(l.id) && l.contains(productId))
          l.copyWith(
            productIds: <String>[
              for (final String id in l.productIds)
                if (id != productId) id,
            ],
          )
        else
          l,
    ]);
  }

  /// Heart behaviour: save to the default list, or unsave from everywhere.
  ///
  /// Returns true when the product ended up saved.
  Future<bool> toggle(String productId) async {
    final bool saved = state.any((WishList l) => l.contains(productId));
    if (saved) {
      await removeEverywhere(productId);
      return false;
    }
    await add(productId);
    return true;
  }

  Future<void> emptyList(String id) async {
    await _persist(<WishList>[
      for (final WishList l in state)
        if (l.id == id) l.copyWith(productIds: const <String>[]) else l,
    ]);
  }

  /// Back to one empty list — what "clear everything" means here.
  Future<void> clear() async {
    state = <WishList>[_emptyDefault()];
    await _prefs.remove(_key);
    await _prefs.remove(legacyKey);
  }
}

final NotifierProvider<WishListsNotifier, List<WishList>> wishListsProvider =
    NotifierProvider<WishListsNotifier, List<WishList>>(WishListsNotifier.new);

/// Which lists a product is in — what the save sheet ticks.
final listsContainingProvider = Provider.family<Set<String>, String>(
  (Ref ref, String productId) => <String>{
    for (final WishList l in ref.watch(wishListsProvider))
      if (l.contains(productId)) l.id,
  },
);

/// The products in one list, resolved against the catalog and newest first.
final wishListProductsProvider = Provider.family<List<Product>, String>((
  Ref ref,
  String listId,
) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  for (final WishList l in ref.watch(wishListsProvider)) {
    if (l.id != listId) continue;
    return <Product>[
      for (final String id in l.productIds.reversed)
        if (catalog.byId(id) case final Product p) p,
    ];
  }
  return const <Product>[];
});
