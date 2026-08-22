import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/product.dart';
import 'app_providers.dart';

/// One day's price for one product.
@immutable
class PricePoint {
  const PricePoint({required this.day, required this.price});

  /// Days since the epoch, in local time — the calendar day the price was
  /// seen on. A timestamp would make "one reading a day" a comparison against
  /// a moving 24 hours instead of against the date.
  final int day;

  final double price;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(
    day * Duration.millisecondsPerDay,
    isUtc: true,
  );
}

/// What the app has actually seen a product cost.
///
/// Deliberately not fabricated. A shop with a backend can show a year of
/// prices because it kept them; this one can only honestly show what it
/// watched, which starts the first time the shopper opens the product. The
/// section on the product page says so rather than implying a longer memory
/// than it has.
class PriceHistoryNotifier extends Notifier<Map<String, List<PricePoint>>> {
  static const String _key = 'prices.history';

  /// How far back a product's readings are kept.
  static const int windowDays = 60;

  /// How many products are tracked at once. Readings are only taken for
  /// products the shopper opens, and the least recently seen are dropped
  /// first, so this is a ceiling on a store that would otherwise only grow.
  static const int maxProducts = 300;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  static int dayOf(DateTime when) =>
      DateTime(when.year, when.month, when.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  @override
  Map<String, List<PricePoint>> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <String, List<PricePoint>>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return <String, List<PricePoint>>{
        for (final MapEntry<String, dynamic> e in decoded.entries)
          e.key: <PricePoint>[
            for (final Object? p in e.value as List<dynamic>)
              PricePoint(
                day: (p! as List<dynamic>)[0] as int,
                price: ((p as List<dynamic>)[1] as num).toDouble(),
              ),
          ],
      };
    } on Object {
      // Any shape of corruption here means starting the record again, which
      // costs a shopper nothing they can point at.
      return const <String, List<PricePoint>>{};
    }
  }

  /// Notes what [product] costs today.
  ///
  /// One reading per calendar day: opening the same page six times is six
  /// looks at one price, not six prices. A day whose price has changed since
  /// the morning is overwritten, so the record holds the last price seen on
  /// each day.
  Future<void> record(Product product, {DateTime? at}) async {
    final int today = dayOf(at ?? DateTime.now());
    final List<PricePoint> existing = state[product.id] ?? const <PricePoint>[];

    if (existing.isNotEmpty &&
        existing.last.day == today &&
        existing.last.price == product.price) {
      return;
    }

    final List<PricePoint> kept = <PricePoint>[
      for (final PricePoint p in existing)
        if (p.day != today && today - p.day < windowDays) p,
      PricePoint(day: today, price: product.price),
    ];

    final Map<String, List<PricePoint>> next = <String, List<PricePoint>>{
      ...state,
      product.id: kept,
    };
    await _persist(_trimmed(next));
  }

  /// Drops the least recently seen products once the store is over its cap.
  Map<String, List<PricePoint>> _trimmed(Map<String, List<PricePoint>> all) {
    if (all.length <= maxProducts) return all;
    final List<MapEntry<String, List<PricePoint>>> entries =
        all.entries.toList()..sort(
          (
            MapEntry<String, List<PricePoint>> a,
            MapEntry<String, List<PricePoint>> b,
          ) => b.value.last.day.compareTo(a.value.last.day),
        );
    return Map<String, List<PricePoint>>.fromEntries(entries.take(maxProducts));
  }

  Future<void> _persist(Map<String, List<PricePoint>> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(<String, dynamic>{
        for (final MapEntry<String, List<PricePoint>> e in next.entries)
          e.key: <List<Object>>[
            for (final PricePoint p in e.value) <Object>[p.day, p.price],
          ],
      }),
    );
  }

  Future<void> clear() async {
    state = const <String, List<PricePoint>>{};
    await _prefs.remove(_key);
  }
}

final NotifierProvider<PriceHistoryNotifier, Map<String, List<PricePoint>>>
priceHistoryProvider =
    NotifierProvider<PriceHistoryNotifier, Map<String, List<PricePoint>>>(
      PriceHistoryNotifier.new,
    );

/// What the readings for one product add up to.
@immutable
class PriceHistory {
  const PriceHistory({required this.points, required this.currentPrice});

  final List<PricePoint> points;
  final double currentPrice;

  bool get isEmpty => points.isEmpty;

  /// How many days the record spans — one when it only started today.
  int get daysTracked =>
      points.isEmpty ? 0 : points.last.day - points.first.day + 1;

  double get lowest => points.fold(
    double.infinity,
    (double low, PricePoint p) => p.price < low ? p.price : low,
  );

  double get highest => points.fold(
    0,
    (double high, PricePoint p) => p.price > high ? p.price : high,
  );

  /// True once the price has actually been seen to move.
  ///
  /// Everything worth saying about a price history needs two different
  /// numbers in it; with one, the only honest line is how long it has been
  /// watched.
  bool get hasMoved => points.length > 1 && highest - lowest > 0.005;

  /// True when what it costs today is the best it has been.
  bool get atLowest => hasMoved && currentPrice - lowest < 0.005;

  /// The change since the first reading — negative when it has come down.
  double get changeSinceStart =>
      points.isEmpty ? 0 : currentPrice - points.first.price;
}

/// Keyed on the id rather than the product: [Product] compares by id, so a
/// family keyed on one would keep serving the price it was first built with
/// even after the feed repriced it.
final priceHistoryForProvider = Provider.family<PriceHistory, String>((
  Ref ref,
  String productId,
) {
  final Product? product = ref.watch(catalogDataProvider).byId(productId);
  return PriceHistory(
    points: ref.watch(priceHistoryProvider)[productId] ?? const <PricePoint>[],
    currentPrice: product?.price ?? 0,
  );
});
