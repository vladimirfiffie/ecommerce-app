import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'alerts_provider.dart';
import 'app_providers.dart';
import 'cart_provider.dart';
import 'catalog_filter_provider.dart';
import 'favorites_provider.dart';

/// What kind of nudge a [ForYouItem] is, in the order they're worth showing.
enum ForYouKind {
  /// A watched product that has come back into stock.
  backInStock,

  /// A saved product now cheaper than when it was saved.
  priceDrop,

  /// Items left in the bag.
  inBag,

  /// The last thing looked at.
  pickUpWhereYouLeftOff,
}

/// One row in the "For you" block.
class ForYouItem {
  const ForYouItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.product,
    this.count = 1,
  });

  final ForYouKind kind;
  final String title;
  final String subtitle;

  /// The product it points at, when it points at one.
  final Product? product;
  final int count;
}

/// Things the app already knows about you, gathered for the home screen.
///
/// Every input here was already tracked and acted on elsewhere — stock and
/// price watches drive notifications, the bag drives checkout — but none of
/// it was ever shown on home, so the features were invisible unless you went
/// looking for them.
final Provider<List<ForYouItem>> forYouProvider = Provider<List<ForYouItem>>((
  Ref ref,
) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  if (catalog.products.isEmpty) return const <ForYouItem>[];

  final List<ForYouItem> items = <ForYouItem>[];

  // Back in stock: a watch only stays set while the item is unavailable, so
  // one that now has stock is news.
  for (final String id in ref.watch(stockWatchProvider)) {
    final Product? p = catalog.byId(id);
    if (p != null && p.stock > 0) {
      items.add(
        ForYouItem(
          kind: ForYouKind.backInStock,
          title: 'Back in stock',
          subtitle: p.name,
          product: p,
        ),
      );
    }
  }

  // Price drops against the snapshot taken when the item was saved.
  final Map<String, double> snapshots = ref.watch(priceWatchProvider);
  final List<Product> cheaper = <Product>[
    for (final Product p in ref.watch(favoriteProductsProvider))
      if ((snapshots[p.id] ?? p.price) > p.price) p,
  ];
  if (cheaper.isNotEmpty) {
    items.add(
      ForYouItem(
        kind: ForYouKind.priceDrop,
        title: cheaper.length == 1 ? 'Price drop' : 'Price drops',
        subtitle: cheaper.length == 1
            ? '${cheaper.first.name} is cheaper than when you saved it'
            : '${cheaper.length} saved items are cheaper than when you '
                  'saved them',
        product: cheaper.first,
        count: cheaper.length,
      ),
    );
  }

  final int bagCount = ref.watch(cartCountProvider);
  if (bagCount > 0) {
    items.add(
      ForYouItem(
        kind: ForYouKind.inBag,
        title: 'Still in your bag',
        subtitle: '$bagCount ${bagCount == 1 ? 'item' : 'items'} waiting',
        count: bagCount,
      ),
    );
  }

  // Only worth saying when there's nothing more useful to say.
  if (items.isEmpty) {
    final List<Product> seen = ref.watch(recentlyViewedProductsProvider);
    if (seen.isNotEmpty) {
      items.add(
        ForYouItem(
          kind: ForYouKind.pickUpWhereYouLeftOff,
          title: 'Pick up where you left off',
          subtitle: seen.first.name,
          product: seen.first,
        ),
      );
    }
  }

  return items;
});
