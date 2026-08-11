import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/utils/formatters.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'alerts_provider.dart';
import 'app_providers.dart';
import 'cart_provider.dart';
import 'catalog_filter_provider.dart';
import 'favorites_provider.dart';
import 'orders_provider.dart';

/// What kind of nudge a [ForYouItem] is.
///
/// Declaration order is display order: anything with a parcel attached to it
/// outranks shopping nudges, because it's the thing with a clock on it.
enum ForYouKind {
  /// An order that hasn't arrived yet.
  orderInTransit,

  /// One that just did, while the return window still means something.
  orderDelivered,

  /// A return that's been filed and is waiting on a refund.
  returnInProgress,

  /// A watched product that has come back into stock.
  backInStock,

  /// A saved product now cheaper than when it was saved.
  priceDrop,

  /// A saved product down to its last few.
  lowStockSaved,

  /// Items left in the bag.
  inBag,

  /// The last thing looked at.
  pickUpWhereYouLeftOff,
}

/// How far along a parcel is, for the mini tracker on an order row.
@immutable
class OrderProgress {
  const OrderProgress({required this.stage, this.stageCount = 3});

  /// Zero-based: 0 processing, 1 shipped, 2 delivered.
  final int stage;
  final int stageCount;

  /// Stages completed so far, as a fraction of the journey.
  double get fraction => (stage + 1) / stageCount;
}

/// One row in the "For you" block.
@immutable
class ForYouItem {
  const ForYouItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.route,
    this.product,
    this.count = 1,
    this.progress,
  });

  final ForYouKind kind;
  final String title;
  final String subtitle;

  /// Where tapping the row goes.
  final String route;

  /// The product it points at, when it points at one.
  final Product? product;
  final int count;

  /// Set only on order rows, which draw a progress bar.
  final OrderProgress? progress;
}

/// A delivery stays newsworthy for a few days, then it's just history.
const Duration _deliveredIsNews = Duration(days: 3);

/// How few is "almost gone" for something you've saved.
const int _lowStockThreshold = 3;

/// At most this many rows — home is a shop, not a dashboard.
const int _maxItems = 4;

/// Things the app already knows about you, gathered for the home screen.
///
/// Every input here was already tracked and acted on elsewhere — stock and
/// price watches drive notifications, orders drive the tracker — but none of
/// it was ever shown on home, so the features were invisible unless you went
/// looking for them.
///
/// Watches the order clock, so rows whose status is derived from the time of
/// day age on their own instead of freezing at whatever they said on load.
final Provider<List<ForYouItem>> forYouProvider = Provider<List<ForYouItem>>((
  Ref ref,
) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  if (catalog.products.isEmpty) return const <ForYouItem>[];

  final List<ForYouItem> items = <ForYouItem>[
    ..._orderItems(ref),
    ..._shoppingItems(ref, catalog),
  ];

  // Only worth saying when there's nothing more useful to say.
  if (items.isEmpty) {
    final List<Product> seen = ref.watch(recentlyViewedProductsProvider);
    if (seen.isNotEmpty) {
      items.add(
        ForYouItem(
          kind: ForYouKind.pickUpWhereYouLeftOff,
          title: 'Pick up where you left off',
          subtitle: seen.first.name,
          route: Routes.product(seen.first.id),
          product: seen.first,
        ),
      );
    }
  }

  items.sort(
    (ForYouItem a, ForYouItem b) => a.kind.index.compareTo(b.kind.index),
  );
  return items.take(_maxItems).toList(growable: false);
});

/// Rows about parcels: one in transit, one just delivered, one going back.
///
/// Only the newest of each — three rows about three orders is a status board,
/// and the Orders screen already is one.
List<ForYouItem> _orderItems(Ref ref) {
  final List<Order> orders = ref.watch(ordersProvider);
  if (orders.isEmpty) return const <ForYouItem>[];

  // Status comes off the clock rather than storage, so these rows have to be
  // recomputed as time passes or they'd freeze at whatever they said on load.
  ref.watch(orderClockProvider);

  final DateTime now = DateTime.now();
  final List<ForYouItem> items = <ForYouItem>[];
  Order? transit;
  Order? delivered;
  Order? returning;

  // Orders are newest first, so the first match of each kind is the one.
  for (final Order o in orders) {
    switch (o.status) {
      case OrderStatus.processing:
      case OrderStatus.shipped:
        transit ??= o;
      case OrderStatus.delivered:
        if (now.difference(o.deliveredAt) <= _deliveredIsNews) delivered ??= o;
      case OrderStatus.returnRequested:
        returning ??= o;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        break;
    }
  }

  if (transit != null) {
    items.add(
      ForYouItem(
        kind: ForYouKind.orderInTransit,
        title: 'Arriving ${formatDeliveryDate(transit.estimatedDelivery)}',
        subtitle: '${transit.id} · ${transit.status.label}',
        route: Routes.order(transit.id),
        progress: OrderProgress(
          stage: transit.status == OrderStatus.processing ? 0 : 1,
        ),
      ),
    );
  }

  if (delivered != null) {
    final int daysLeft = delivered.returnDaysLeft;
    items.add(
      ForYouItem(
        kind: ForYouKind.orderDelivered,
        title: 'Delivered',
        subtitle: delivered.canReturn
            ? '${delivered.id} · $daysLeft ${daysLeft == 1 ? 'day' : 'days'} '
                  'left to return'
            : '${delivered.id} · arrived '
                  '${formatDeliveryDate(delivered.deliveredAt)}',
        route: Routes.order(delivered.id),
        progress: const OrderProgress(stage: 2),
      ),
    );
  }

  if (returning != null) {
    items.add(
      ForYouItem(
        kind: ForYouKind.returnInProgress,
        title: 'Return in progress',
        subtitle:
            'Refund expected by '
            '${formatDeliveryDate(returning.returnRequest!.expectedRefundBy)}',
        route: Routes.order(returning.id),
      ),
    );
  }

  return items;
}

/// Rows about things you were looking at or nearly bought.
List<ForYouItem> _shoppingItems(Ref ref, Catalog catalog) {
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
          route: Routes.product(p.id),
          product: p,
        ),
      );
    }
  }

  final List<Product> saved = ref.watch(favoriteProductsProvider);

  // Price drops against the snapshot taken when the item was saved.
  final Map<String, double> snapshots = ref.watch(priceWatchProvider);
  final List<Product> cheaper = <Product>[
    for (final Product p in saved)
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
        route: cheaper.length == 1
            ? Routes.product(cheaper.first.id)
            : Routes.favorites,
        product: cheaper.first,
        count: cheaper.length,
      ),
    );
  }

  // Something saved that's nearly gone. Out-of-stock items aren't mentioned —
  // the back-in-stock watch is the answer to those, not a nudge to hurry.
  final List<Product> almostGone = <Product>[
    for (final Product p in saved)
      if (p.stock > 0 && p.stock <= _lowStockThreshold) p,
  ];
  if (almostGone.isNotEmpty) {
    final Product first = almostGone.first;
    items.add(
      ForYouItem(
        kind: ForYouKind.lowStockSaved,
        title: 'Almost gone',
        subtitle: almostGone.length == 1
            ? '${first.name} — only ${first.stock} left'
            : '${almostGone.length} saved items are down to their last few',
        route: almostGone.length == 1
            ? Routes.product(first.id)
            : Routes.favorites,
        product: first,
        count: almostGone.length,
      ),
    );
  }

  final int bagCount = ref.watch(cartCountProvider);
  if (bagCount > 0) {
    final CartSummary summary = ref.watch(cartSummaryProvider);
    // What free delivery is measured against — the discounted subtotal, the
    // same figure the bag's own progress bar uses.
    final double toGo =
        Pricing.freeShippingThreshold - (summary.subtotal - summary.discount);
    final String waiting = '$bagCount ${bagCount == 1 ? 'item' : 'items'}';

    items.add(
      ForYouItem(
        kind: ForYouKind.inBag,
        title: 'Still in your bag',
        subtitle: toGo > 0
            ? '$waiting · ${formatPrice(toGo)} from free delivery'
            : '$waiting · free delivery unlocked',
        route: Routes.cart,
        count: bagCount,
      ),
    );
  }

  return items;
}
