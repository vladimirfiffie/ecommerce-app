import 'package:flutter/material.dart';

/// How the order gets to the shopper.
///
/// Shipping used to be a single hardcoded rate; this makes it a choice, which
/// is what every real storefront offers.
enum DeliveryOption {
  standard(
    id: 'standard',
    price: 6.95,
    minDays: 3,
    maxDays: 5,
    icon: Icons.local_shipping_outlined,
    freeOverThreshold: true,
  ),
  express(
    id: 'express',
    price: 14.95,
    minDays: 1,
    maxDays: 2,
    icon: Icons.bolt_rounded,
  ),
  pickup(
    id: 'pickup',
    price: 0,
    minDays: 0,
    maxDays: 1,
    icon: Icons.storefront_outlined,
  );

  const DeliveryOption({
    required this.id,
    required this.price,
    required this.minDays,
    required this.maxDays,
    required this.icon,
    this.freeOverThreshold = false,
  });

  final String id;

  /// Base charge before any free-shipping threshold or promo is applied.
  final double price;

  final int minDays;
  final int maxDays;
  final IconData icon;

  /// Whether spending over the free-shipping threshold waives the charge.
  /// Express is deliberately never free — it costs real money to expedite.
  final bool freeOverThreshold;

  DateTime estimatedArrival(DateTime from) => from.add(Duration(days: maxDays));

  static DeliveryOption byId(String? id) => values.firstWhere(
    (DeliveryOption o) => o.id == id,
    orElse: () => DeliveryOption.standard,
  );
}
