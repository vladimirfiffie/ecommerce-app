import 'package:flutter/foundation.dart';

import 'cart_entry.dart';
import 'delivery_option.dart';

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
    this.deliveryId = 'standard',
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
    deliveryId: json['deliveryId'] as String? ?? 'standard',
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

  /// Which [DeliveryOption] was chosen, so the tracker can use its timeline.
  final String deliveryId;

  DeliveryOption get delivery => DeliveryOption.byId(deliveryId);

  int get itemCount =>
      entries.fold(0, (int sum, CartEntry e) => sum + e.quantity);

  DateTime get estimatedDelivery => delivery.estimatedArrival(placedAt);

  /// Progresses on its own as time passes, so the Orders tab feels live
  /// without a backend pushing updates. The pace follows the delivery method
  /// that was chosen — express shouldn't crawl like standard.
  OrderStatus get status {
    final Duration age = DateTime.now().difference(placedAt);
    final Duration toShipped = Duration(
      hours: delivery == DeliveryOption.express ? 2 : 8,
    );
    if (age < toShipped) return OrderStatus.processing;
    if (age < Duration(days: delivery.maxDays)) return OrderStatus.shipped;
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
    'deliveryId': deliveryId,
  };
}
