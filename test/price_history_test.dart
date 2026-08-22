import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/price_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  Product priced(double price) => testProduct(id: 'mug', price: price);

  Future<ProviderContainer> loaded([double price = 20]) async {
    final ProviderContainer c = await testContainer(
      catalog: Catalog(
        categories: <Category>[],
        products: <Product>[priced(price)],
      ),
    );
    await c.read(catalogProvider.future);
    return c;
  }

  final DateTime day1 = DateTime(2026, 8, 1, 9);
  final DateTime day1Later = DateTime(2026, 8, 1, 20);
  final DateTime day2 = DateTime(2026, 8, 2, 9);
  final DateTime day3 = DateTime(2026, 8, 3, 9);

  test('a first look records one reading', () async {
    final ProviderContainer c = await loaded();
    await c.read(priceHistoryProvider.notifier).record(priced(20), at: day1);

    final PriceHistory h = c.read(priceHistoryForProvider('mug'));
    expect(h.points, hasLength(1));
    expect(h.daysTracked, 1);
    expect(h.hasMoved, isFalse);
    // One reading is a price, not a history: nothing can be claimed about it
    // being the lowest.
    expect(h.atLowest, isFalse);
  });

  test('looking again the same day at the same price adds nothing', () async {
    final ProviderContainer c = await loaded();
    final PriceHistoryNotifier history = c.read(priceHistoryProvider.notifier);
    await history.record(priced(20), at: day1);
    await history.record(priced(20), at: day1Later);

    expect(c.read(priceHistoryForProvider('mug')).points, hasLength(1));
  });

  test('a change within the day overwrites that day', () async {
    // The record holds the last price seen on each date, not every price.
    final ProviderContainer c = await loaded();
    final PriceHistoryNotifier history = c.read(priceHistoryProvider.notifier);
    await history.record(priced(20), at: day1);
    await history.record(priced(18), at: day1Later);

    final PriceHistory h = c.read(priceHistoryForProvider('mug'));
    expect(h.points, hasLength(1));
    expect(h.points.single.price, 18);
    expect(h.daysTracked, 1);
  });

  test('separate days are separate readings', () async {
    final ProviderContainer c = await loaded(18);
    final PriceHistoryNotifier history = c.read(priceHistoryProvider.notifier);
    await history.record(priced(20), at: day1);
    await history.record(priced(24), at: day2);
    await history.record(priced(18), at: day3);

    final PriceHistory h = c.read(priceHistoryForProvider('mug'));
    expect(h.points, hasLength(3));
    expect(h.daysTracked, 3);
    expect(h.lowest, 18);
    expect(h.highest, 24);
    expect(h.hasMoved, isTrue);
    expect(h.changeSinceStart, -2);
    expect(h.atLowest, isTrue);
  });

  test('today being dearer than before is not the lowest', () async {
    final ProviderContainer c = await loaded(24);
    final PriceHistoryNotifier history = c.read(priceHistoryProvider.notifier);
    await history.record(priced(20), at: day1);
    await history.record(priced(24), at: day2);

    final PriceHistory h = c.read(priceHistoryForProvider('mug'));
    expect(h.atLowest, isFalse);
    expect(h.changeSinceStart, 4);
  });

  test('readings older than the window fall off', () async {
    final ProviderContainer c = await loaded();
    final PriceHistoryNotifier history = c.read(priceHistoryProvider.notifier);
    final DateTime old = day1.subtract(
      const Duration(days: PriceHistoryNotifier.windowDays + 5),
    );
    await history.record(priced(50), at: old);
    await history.record(priced(20), at: day1);

    final PriceHistory h = c.read(priceHistoryForProvider('mug'));
    expect(h.points, hasLength(1));
    expect(h.highest, 20);
  });

  test('the record is written to disk, not just held in memory', () async {
    final ProviderContainer c = await loaded();
    await c.read(priceHistoryProvider.notifier).record(priced(20), at: day1);
    await c.read(priceHistoryProvider.notifier).record(priced(24), at: day2);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('prices.history');
    expect(raw, isNotNull);
    expect(raw, contains('20'));
    expect(raw, contains('24'));

    // And read back the way it was written — a store that round-trips into
    // something else is the same as no store at all.
    final ProviderContainer reopened = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(priceHistoryProvider)['mug'], hasLength(2));
  });

  test('a product never opened has no history to show', () async {
    final ProviderContainer c = await loaded();
    expect(c.read(priceHistoryForProvider('mug')).isEmpty, isTrue);
  });
}
