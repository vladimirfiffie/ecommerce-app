import 'dart:convert';

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
    required PaymentMethod payment,
  }) async {
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
      paymentLabel: payment.label,
    );

    final List<Order> next = <Order>[order, ...state];
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((Order o) => o.toJson()).toList()),
    );

    await ref.read(cartProvider.notifier).clear();
    ref.read(appliedPromoProvider.notifier).clear();
    return order;
  }

  Future<void> clear() async {
    state = const <Order>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<OrdersNotifier, List<Order>> ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

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
