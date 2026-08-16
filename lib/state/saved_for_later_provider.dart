import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cart_entry.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';
import 'cart_provider.dart';

/// Things put aside rather than bought or given up on.
///
/// Stored as [CartEntry] like the bag itself, so a saved line keeps the size
/// and color it was chosen in, and the quantity comes back with it.
class SavedForLaterNotifier extends Notifier<List<CartEntry>> {
  static const String _key = 'cart.savedForLater';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<CartEntry> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <CartEntry>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <CartEntry>[
        for (final Object? e in decoded)
          CartEntry.fromJson(e! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <CartEntry>[];
    }
  }

  Future<void> _persist(List<CartEntry> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((CartEntry e) => e.toJson()).toList()),
    );
  }

  /// Takes a line out of the bag and keeps it here.
  ///
  /// Saving the same variant twice replaces rather than stacks: the shopper
  /// asked to keep this line, not to keep two of it.
  Future<void> saveForLater(CartEntry entry) async {
    await _persist(<CartEntry>[
      for (final CartEntry e in state)
        if (e.lineId != entry.lineId) e,
      entry,
    ]);
    await ref.read(cartProvider.notifier).remove(entry.lineId);
  }

  /// Puts a saved line back in the bag, quantity and variant intact.
  ///
  /// Two ways there may be no product to add. A catalog that has loaded and
  /// no longer carries it means the line is gone for good, so it goes. A
  /// catalog that simply hasn't arrived yet means nothing at all — dropping
  /// the line there would lose it to a slow connection.
  Future<void> moveToBag(CartEntry entry) async {
    final AsyncValue<Catalog> catalog = ref.read(catalogProvider);
    final Product? product = catalog.value?.byId(entry.productId);
    if (product == null) {
      if (catalog.hasValue) await remove(entry.lineId);
      return;
    }
    await remove(entry.lineId);

    await ref
        .read(cartProvider.notifier)
        .add(
          product,
          size: entry.size,
          color: product.colors
              .where((ProductColor c) => c.name == entry.colorName)
              .firstOrNull,
          quantity: entry.quantity,
        );
  }

  Future<void> remove(String lineId) async {
    await _persist(<CartEntry>[
      for (final CartEntry e in state)
        if (e.lineId != lineId) e,
    ]);
  }

  Future<void> clear() => _persist(const <CartEntry>[]);
}

final NotifierProvider<SavedForLaterNotifier, List<CartEntry>>
savedForLaterProvider =
    NotifierProvider<SavedForLaterNotifier, List<CartEntry>>(
      SavedForLaterNotifier.new,
    );

/// Saved lines paired with the product they refer to, newest first.
///
/// Anything the catalog no longer carries is left out — the same rule the
/// bag itself uses for lines it can't resolve.
final Provider<List<CartItem>> savedForLaterItemsProvider =
    Provider<List<CartItem>>((Ref ref) {
      final Catalog catalog = ref.watch(catalogDataProvider);
      return <CartItem>[
        for (final CartEntry entry in ref.watch(savedForLaterProvider).reversed)
          if (catalog.byId(entry.productId) case final Product product)
            CartItem(entry: entry, product: product),
      ];
    });
