import 'package:flutter/foundation.dart';

import 'cart_entry.dart';

enum OrderStatus {
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered');

  const OrderStatus(this.label);

  final String label;
}

/// A placed order, persisted locally so the Orders tab survives restarts.
///
/// Lines are stored as [CartEntry] and rehydrated against the catalog, the same
/// way the cart works.
@immutable
class Order {
  const Order({
    required this.id,
    required this.placedAt,
    required this.entries,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.shippingAddress,
    required this.paymentLabel,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    placedAt: DateTime.parse(json['placedAt'] as String),
    entries: <CartEntry>[
      for (final Object? e in json['entries'] as List<dynamic>? ?? <dynamic>[])
        CartEntry.fromJson(e! as Map<String, dynamic>),
    ],
    subtotal: (json['subtotal'] as num).toDouble(),
    shipping: (json['shipping'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    shippingAddress: json['shippingAddress'] as String,
    paymentLabel: json['paymentLabel'] as String,
  );

  final String id;
  final DateTime placedAt;
  final List<CartEntry> entries;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final String shippingAddress;
  final String paymentLabel;

  int get itemCount =>
      entries.fold(0, (int sum, CartEntry e) => sum + e.quantity);

  DateTime get estimatedDelivery => placedAt.add(const Duration(days: 4));

  /// Progresses on its own as time passes, so the Orders tab feels live
  /// without a backend pushing updates.
  OrderStatus get status {
    final Duration age = DateTime.now().difference(placedAt);
    if (age < const Duration(hours: 8)) return OrderStatus.processing;
    if (age < const Duration(days: 4)) return OrderStatus.shipped;
    return OrderStatus.delivered;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'placedAt': placedAt.toIso8601String(),
    'entries': entries.map((CartEntry e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'shipping': shipping,
    'discount': discount,
    'total': total,
    'shippingAddress': shippingAddress,
    'paymentLabel': paymentLabel,
  };
}
