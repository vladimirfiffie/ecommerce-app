import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/models/order_line.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';
import 'orders_provider.dart';

/// Products that have shared an order with this one, most often first.
///
/// Read off this device's own orders and nobody else's, because this device's
/// orders are the only ones that exist — there is no server keeping anyone
/// else's. That makes the rail honest but usually empty, which is why the
/// product page hides it rather than padding it out with guesses.
final pairedWithProvider = Provider.family<List<Product>, String>((
  Ref ref,
  String productId,
) {
  final List<Order> orders = ref.watch(ordersProvider);
  final Catalog catalog = ref.watch(catalogDataProvider);

  final Map<String, int> together = <String, int>{};
  for (final Order order in orders) {
    final bool includesIt = order.lines.any(
      (OrderLine line) => line.productId == productId,
    );
    if (!includesIt) continue;

    for (final OrderLine line in order.lines) {
      if (line.productId == productId) continue;
      together[line.productId] = (together[line.productId] ?? 0) + 1;
    }
  }

  final List<MapEntry<String, int>> ranked = together.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
      final int byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  return <Product>[
    for (final MapEntry<String, int> entry in ranked)
      if (catalog.byId(entry.key) case final Product product) product,
  ];
});
