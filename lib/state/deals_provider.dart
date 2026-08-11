import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// How many products make up a day's deals.
const int kDailyDealCount = 10;

/// When the current day's deals stop being the current day's deals.
///
/// Local midnight, so the countdown on Home is measuring something that
/// actually happens rather than decorating the section with urgency.
DateTime dealsEndAfter(DateTime now) =>
    DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

/// The deals for [now]'s date, chosen deterministically.
///
/// The same day always yields the same selection — so the list doesn't
/// reshuffle every rebuild — and a new day yields a different one, which is
/// what makes "ends in 4h" true.
///
/// Ordered by discount within the day's selection, so the best saving leads.
List<Product> dealsFor(
  List<Product> onSale,
  DateTime now, {
  int count = kDailyDealCount,
}) {
  if (onSale.isEmpty) return const <Product>[];

  final int day = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(2024)).inDays;

  // Rotate through the pool a day at a time. With a stride co-prime to the
  // pool size this walks the whole catalogue before repeating, so a product
  // isn't stuck on sale forever or never picked.
  final int size = onSale.length;
  final int stride = _coprimeStride(size);
  final List<Product> picked = <Product>[
    for (int i = 0; i < count && i < size; i++)
      onSale[((day * stride) + i * stride) % size],
  ];

  picked.sort(
    (Product a, Product b) => b.discountPercent.compareTo(a.discountPercent),
  );
  return picked;
}

/// The smallest stride > 1 that shares no factor with [size], falling back to
/// 1 for tiny pools where nothing else qualifies.
int _coprimeStride(int size) {
  for (int s = 7; s < size; s++) {
    if (_gcd(s, size) == 1) return s;
  }
  return 1;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// Today's deals, rotating at local midnight.
final Provider<List<Product>> dailyDealsProvider = Provider<List<Product>>((
  Ref ref,
) {
  final Catalog catalog = ref.watch(catalogDataProvider);
  return dealsFor(catalog.onSale, DateTime.now());
});
