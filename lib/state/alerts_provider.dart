import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/formatters.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';
import 'favorites_provider.dart';
import 'notifications_provider.dart';

/// Products the shopper asked to be told about when they come back in stock.
class StockWatchNotifier extends Notifier<Set<String>> {
  static const String _key = 'alerts.stockWatch';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  bool isWatching(String productId) => state.contains(productId);

  /// Returns true when the product ended up watched.
  Future<bool> toggle(String productId) async {
    final Set<String> next = <String>{...state};
    final bool added = next.add(productId);
    if (!added) next.remove(productId);
    state = next;
    await _prefs.setStringList(_key, next.toList());
    return added;
  }

  Future<void> stopWatching(String productId) async {
    if (!state.contains(productId)) return;
    final Set<String> next = <String>{...state}..remove(productId);
    state = next;
    await _prefs.setStringList(_key, next.toList());
  }

  Future<void> clear() async {
    state = <String>{};
    await _prefs.remove(_key);
  }
}

final NotifierProvider<StockWatchNotifier, Set<String>> stockWatchProvider =
    NotifierProvider<StockWatchNotifier, Set<String>>(StockWatchNotifier.new);

final isWatchingStockProvider = Provider.family<bool, String>(
  (Ref ref, String productId) =>
      ref.watch(stockWatchProvider).contains(productId),
);

/// Last price seen for each favorited product, so a drop can be detected.
class PriceWatchNotifier extends Notifier<Map<String, double>> {
  static const String _key = 'alerts.priceSnapshots';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<String, double> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <String, double>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return <String, double>{
        for (final MapEntry<String, dynamic> e in decoded.entries)
          e.key: (e.value as num).toDouble(),
      };
    } on FormatException {
      return const <String, double>{};
    }
  }

  Future<void> write(Map<String, double> next) async {
    state = next;
    await _prefs.setString(_key, jsonEncode(next));
  }

  Future<void> clear() async {
    state = const <String, double>{};
    await _prefs.remove(_key);
  }
}

final NotifierProvider<PriceWatchNotifier, Map<String, double>>
priceWatchProvider = NotifierProvider<PriceWatchNotifier, Map<String, double>>(
  PriceWatchNotifier.new,
);

/// What a sweep found, so callers (and tests) can see the outcome.
@immutable
class AlertSweepResult {
  const AlertSweepResult({
    this.restocked = const <String>[],
    this.priceDrops = const <String>[],
  });

  final List<String> restocked;
  final List<String> priceDrops;

  bool get isEmpty => restocked.isEmpty && priceDrops.isEmpty;
}

/// Checks watched products against the current catalog and notifies on any
/// change since last time.
///
/// The bundled catalog is static, so in this build a restock only fires if the
/// data changes underneath — the plumbing is real, the events are rare. Price
/// snapshots are taken the first time a product is favorited, so a genuine
/// price change would be caught.
class AlertSweeper {
  const AlertSweeper(this.ref);

  final Ref ref;

  Future<AlertSweepResult> sweep() async {
    final Catalog catalog = ref.read(catalogDataProvider);
    if (catalog.products.isEmpty) return const AlertSweepResult();

    final NotificationService notifications = ref.read(notificationsProvider);
    final List<String> restocked = <String>[];
    final List<String> dropped = <String>[];

    // Back in stock.
    for (final String id in <String>{...ref.read(stockWatchProvider)}) {
      final Product? product = catalog.byId(id);
      if (product == null || !product.inStock) continue;

      restocked.add(id);
      await notifications.show(
        channel: NotifyChannel.deals,
        id: id.hashCode.abs() % 90000 + 1000,
        title: 'Back in stock',
        body: '${product.name} is available again.',
        payload: id,
      );
      // One alert per restock; re-arm by tapping the button again.
      await ref.read(stockWatchProvider.notifier).stopWatching(id);
    }

    // Price drops on favorites.
    final Set<String> favorites = ref.read(favoritesProvider);
    final Map<String, double> snapshots = <String, double>{
      ...ref.read(priceWatchProvider),
    };
    final Map<String, double> next = <String, double>{};

    for (final String id in favorites) {
      final Product? product = catalog.byId(id);
      if (product == null) continue;

      final double? was = snapshots[id];
      if (was != null && product.price < was) {
        dropped.add(id);
        await notifications.show(
          channel: NotifyChannel.deals,
          id: id.hashCode.abs() % 90000 + 50000,
          title: 'Price drop',
          body:
              '${product.name} is now ${formatPrice(product.price)}, '
              'down from ${formatPrice(was)}.',
          payload: id,
        );
      }
      next[id] = product.price;
    }
    await ref.read(priceWatchProvider.notifier).write(next);

    return AlertSweepResult(restocked: restocked, priceDrops: dropped);
  }
}

final Provider<AlertSweeper> alertSweeperProvider = Provider<AlertSweeper>(
  AlertSweeper.new,
);
