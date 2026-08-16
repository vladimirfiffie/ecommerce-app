import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// What happened when a product was held down.
enum CompareResult { added, removed, full }

/// Products picked out to be put side by side.
///
/// Not persisted: a comparison is a question you are asking right now, and
/// finding yesterday's shortlist still on screen would be a puzzle rather
/// than a convenience.
class CompareNotifier extends Notifier<List<String>> {
  /// Three columns is what a phone can show without turning each one into a
  /// column of ellipses.
  static const int max = 3;

  @override
  List<String> build() => const <String>[];

  bool contains(String id) => state.contains(id);

  bool get isFull => state.length >= max;

  /// Adds or removes, and says which of the three things happened.
  ///
  /// A full list refuses rather than dropping someone else's pick to make
  /// room — and says so, because a hold that appears to do nothing reads as
  /// a broken gesture.
  CompareResult toggle(String productId) {
    if (state.contains(productId)) {
      state = <String>[
        for (final String id in state)
          if (id != productId) id,
      ];
      return CompareResult.removed;
    }
    if (isFull) return CompareResult.full;
    state = <String>[...state, productId];
    return CompareResult.added;
  }

  void clear() => state = const <String>[];
}

final NotifierProvider<CompareNotifier, List<String>> compareProvider =
    NotifierProvider<CompareNotifier, List<String>>(CompareNotifier.new);

/// The picked products, in the order they were picked.
///
/// Anything the catalog has dropped falls out rather than showing an empty
/// column.
final Provider<List<Product>> compareItemsProvider = Provider<List<Product>>((
  Ref ref,
) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  return <Product>[
    for (final String id in ref.watch(compareProvider))
      if (catalog.byId(id) case final Product product) product,
  ];
});
