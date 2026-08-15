import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'product_repository.dart';

/// Keeps the last good catalog on disk, so the shop opens without waiting for
/// the network and still opens without one at all.
///
/// Everything else the shopper owns — bag, wishlist, orders, recently viewed —
/// is persisted and resolves *through* the catalog. With the catalog itself
/// held only in memory, a cold start with no connection emptied all of them at
/// once: a bag that had items in it read "Your bag is empty" while the tab
/// badge still showed the count.
///
/// Reads are served from the snapshot while it's [freshFor]; after that a
/// fetch is attempted and the snapshot is only used if that fetch fails. A
/// stale catalog is worse than a current one and far better than none.
class CachedProductRepository implements ProductRepository {
  CachedProductRepository({
    required this.source,
    required this.prefs,
    this.freshFor = const Duration(hours: 6),
    this.clock = DateTime.now,
  });

  static const String snapshotKey = 'catalog.snapshot';
  static const String snapshotAtKey = 'catalog.snapshotAt';

  final ProductRepository source;
  final SharedPreferences prefs;

  /// Injectable so a test can age a snapshot without waiting six hours.
  final DateTime Function() clock;

  /// How long a snapshot is served without checking the source at all.
  final Duration freshFor;

  @override
  Future<Catalog> loadCatalog() async {
    final Catalog? cached = _readSnapshot();
    if (cached != null && _isFresh) return cached;

    try {
      final Catalog fresh = await source.loadCatalog();
      await _writeSnapshot(fresh);
      return fresh;
    } on Object {
      // Offline, rate-limited, or the feed is down. Anything we've seen before
      // beats an error page over data the shopper already has.
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Pull-to-refresh. The snapshot's *data* is deliberately kept: the next
  /// load has to go to the source, but if that fails there's still something
  /// to fall back to.
  @override
  void clearCache() {
    source.clearCache();
    unawaited(prefs.remove(snapshotAtKey));
  }

  bool get _isFresh {
    final String? at = prefs.getString(snapshotAtKey);
    if (at == null) return false;
    final DateTime? written = DateTime.tryParse(at);
    if (written == null) return false;
    return clock().difference(written) < freshFor;
  }

  Catalog? _readSnapshot() {
    final String? raw = prefs.getString(snapshotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Catalog catalog = Catalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      // A snapshot that decodes to nothing is worse than none: it would look
      // like a successful load of an empty shop.
      return catalog.isEmpty ? null : catalog;
    } on Object {
      // Corrupt or written by an incompatible version. Drop it and refetch.
      unawaited(prefs.remove(snapshotKey));
      return null;
    }
  }

  Future<void> _writeSnapshot(Catalog catalog) async {
    try {
      await prefs.setString(snapshotKey, jsonEncode(catalog.toJson()));
      await prefs.setString(snapshotAtKey, clock().toIso8601String());
    } on Object catch (_) {
      // A snapshot that won't write is not worth failing a load over — the
      // catalog in hand is still perfectly good.
    }
  }
}
