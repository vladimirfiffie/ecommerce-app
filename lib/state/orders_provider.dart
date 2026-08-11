import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/address.dart';
import '../data/models/cart_entry.dart';
import '../data/models/cart_item.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';
import 'cart_provider.dart';
import '../data/models/delivery_option.dart';

/// Order history, newest first.
class OrdersNotifier extends Notifier<List<Order>> {
  static const String _key = 'orders.list';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<Order> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <Order>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <Order>[
        for (final Object? o in decoded)
          Order.fromJson(o! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <Order>[];
    }
  }

  /// Turns the current cart into an order and clears the cart.
  /// Returns the placed order.
  Future<Order> placeOrder({
    required Address address,
    required String paymentLabel,
    DeliveryOption delivery = DeliveryOption.standard,
  }) async {
    final GiftOptions gift = ref.read(giftOptionsProvider);
    final CartSummary summary = ref.read(cartSummaryProvider);
    final List<CartEntry> entries = <CartEntry>[...ref.read(cartProvider)];
    final DateTime now = DateTime.now();

    final Order order = Order(
      id: 'NV-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      placedAt: now,
      entries: entries,
      subtotal: summary.subtotal,
      shipping: summary.shipping,
      discount: summary.discount,
      total: summary.total,
      shippingAddress: '${address.recipient}, ${address.oneLine}',
      paymentLabel: paymentLabel,
      deliveryId: delivery.id,
      giftWrapped: gift.wrapped,
      giftMessage: gift.message.trim(),
    );

    final List<Order> next = <Order>[order, ...state];
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((Order o) => o.toJson()).toList()),
    );

    await ref.read(cartProvider.notifier).clear();
    ref.read(appliedPromoProvider.notifier).clear();
    ref.read(giftOptionsProvider.notifier).reset();
    return order;
  }

  Future<void> _write(List<Order> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((Order o) => o.toJson()).toList()),
    );
  }

  Order? _byId(String id) {
    for (final Order o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Cancels an order that hasn't shipped. Returns false when it's too late,
  /// so the caller can explain rather than silently doing nothing.
  Future<bool> cancel(String orderId) async {
    final Order? order = _byId(orderId);
    if (order == null || !order.canCancel) return false;

    await _write(<Order>[
      for (final Order o in state)
        if (o.id == orderId) o.copyWith(cancelledAt: DateTime.now()) else o,
    ]);
    return true;
  }

  /// What would be refunded for the given lines.
  ///
  /// Item value is refunded pro-rata against any discount that was applied.
  /// Original outbound shipping only comes back on a full return, and return
  /// postage is only covered when the fault was the shop's.
  RefundQuote quoteRefund({
    required Order order,
    required Set<String> lineIds,
    required ReturnReason reason,
    required Map<String, double> lineTotals,
  }) {
    final double returningValue = lineIds.fold(
      0,
      (double sum, String id) => sum + (lineTotals[id] ?? 0),
    );
    final double allValue = lineTotals.values.fold(
      0,
      (double sum, double v) => sum + v,
    );

    final double share = allValue == 0 ? 0 : returningValue / allValue;
    final double discountBack = order.discount * share;
    final double itemsBack = returningValue - discountBack;

    final bool everything = lineIds.length == lineTotals.length;
    final double shippingBack = everything ? order.shipping : 0;

    // Tax follows whatever is actually refunded.
    final double taxBack = (itemsBack + shippingBack) * Pricing.taxRate;

    return RefundQuote(
      items: itemsBack,
      shipping: shippingBack,
      tax: taxBack,
      returnPostagePaidByShop: reason.sellerAtFault,
      total: itemsBack + shippingBack + taxBack,
    );
  }

  /// Files a return. Returns false when the order isn't eligible.
  Future<bool> requestReturn({
    required String orderId,
    required Set<String> lineIds,
    required ReturnReason reason,
    required double refundAmount,
    String note = '',
  }) async {
    final Order? order = _byId(orderId);
    if (order == null || !order.canReturn || lineIds.isEmpty) return false;

    final ReturnRequest request = ReturnRequest(
      requestedAt: DateTime.now(),
      reason: reason,
      lineIds: lineIds.toList(),
      refundAmount: refundAmount,
      note: note.trim(),
    );
    await _write(<Order>[
      for (final Order o in state)
        if (o.id == orderId) o.copyWith(returnRequest: request) else o,
    ]);
    return true;
  }

  /// Withdraws a return that hasn't been refunded yet.
  Future<bool> cancelReturn(String orderId) async {
    final Order? order = _byId(orderId);
    if (order == null || order.status != OrderStatus.returnRequested) {
      return false;
    }
    await _write(<Order>[
      for (final Order o in state)
        if (o.id == orderId) o.copyWith(clearReturn: true) else o,
    ]);
    return true;
  }

  Future<void> clear() async {
    state = const <Order>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<OrdersNotifier, List<Order>> ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

/// How often anything showing a live order status redraws.
///
/// Set to null by `configureTestEnvironment()`: a repeating stream schedules a
/// frame per tick, which would stop `pumpAndSettle` from ever settling.
@visibleForTesting
Duration? orderStatusTick = const Duration(minutes: 1);

/// A pulse for screens that show a time-derived order status.
///
/// [Order.status] is computed from the clock rather than stored, so a card left
/// on screen would otherwise still claim "Processing" hours after the parcel
/// shipped. Watching this makes those screens keep up on their own.
///
/// Auto-disposed so the timer only runs while something is actually showing an
/// order.
final AutoDisposeStreamProvider<int> orderClockProvider =
    StreamProvider.autoDispose<int>((Ref ref) {
      final Duration? tick = orderStatusTick;
      if (tick == null) return const Stream<int>.empty();
      return Stream<int>.periodic(tick, (int i) => i);
    });

final ProviderFamily<Order?, String> orderByIdProvider =
    Provider.family<Order?, String>((Ref ref, String id) {
      for (final Order o in ref.watch(ordersProvider)) {
        if (o.id == id) return o;
      }
      return null;
    });

/// An order's lines resolved against the catalog, for thumbnails and names.
final ProviderFamily<List<CartItem>, String> orderItemsProvider =
    Provider.family<List<CartItem>, String>((Ref ref, String orderId) {
      final Order? order = ref.watch(orderByIdProvider(orderId));
      if (order == null) return const <CartItem>[];
      final Catalog catalog = ref.watch(catalogDataProvider);
      return <CartItem>[
        for (final CartEntry e in order.entries)
          if (catalog.byId(e.productId) case final Product p)
            CartItem(entry: e, product: p),
      ];
    });

/// Breakdown of what a return would put back on the card.
@immutable
class RefundQuote {
  const RefundQuote({
    required this.items,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.returnPostagePaidByShop,
  });

  final double items;

  /// Outbound shipping, refunded only when everything goes back.
  final double shipping;

  final double tax;
  final double total;

  /// True when the shop is at fault and covers return postage.
  final bool returnPostagePaidByShop;
}
