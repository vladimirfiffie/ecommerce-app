import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/features/home/widgets/deal_countdown.dart';
import 'package:ecommerce_app/state/deals_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  List<Product> pool(int n) => <Product>[
    for (int i = 0; i < n; i++)
      testProduct(
        id: 'p$i',
        name: 'Item $i',
        price: 50,
        compareAtPrice: 100 - i.toDouble(),
      ),
  ];

  group('the deadline', () {
    test('is the next local midnight', () {
      final DateTime now = DateTime(2026, 8, 11, 19, 48);
      expect(dealsEndAfter(now), DateTime(2026, 8, 12));
    });

    test('a minute before midnight still points at midnight', () {
      expect(
        dealsEndAfter(DateTime(2026, 8, 11, 23, 59)),
        DateTime(2026, 8, 12),
      );
    });
  });

  group('the countdown label', () {
    test('shows hours and minutes', () {
      expect(
        formatDealsRemaining(DateTime(2026, 8, 11, 19, 48)),
        'Ends in 4h 12m',
      );
    });

    test('drops the hours once inside the last one', () {
      expect(
        formatDealsRemaining(DateTime(2026, 8, 11, 23, 30)),
        'Ends in 30m',
      );
    });

    test('says something sensible in the final seconds', () {
      expect(
        formatDealsRemaining(DateTime(2026, 8, 11, 23, 59, 30)),
        'Ends in under a minute',
      );
    });

    test('at midnight exactly it is a fresh full day, not a negative', () {
      // The deadline rolls to the next midnight rather than going negative.
      expect(formatDealsRemaining(DateTime(2026, 8, 12)), 'Ends in 24h 0m');
    });
  });

  group('the selection', () {
    test('is stable within a day', () {
      final List<Product> products = pool(40);
      final DateTime morning = DateTime(2026, 8, 11, 8);
      final DateTime evening = DateTime(2026, 8, 11, 22);

      // Otherwise the rail would reshuffle on every rebuild.
      expect(
        dealsFor(products, morning).map((Product p) => p.id),
        dealsFor(products, evening).map((Product p) => p.id),
      );
    });

    test('changes when the day does — which is what the timer promises', () {
      final List<Product> products = pool(40);
      expect(
        dealsFor(products, DateTime(2026, 8, 11)).map((Product p) => p.id),
        isNot(
          dealsFor(products, DateTime(2026, 8, 12)).map((Product p) => p.id),
        ),
      );
    });

    test('leads with the biggest discount', () {
      final List<Product> deals = dealsFor(pool(40), DateTime(2026, 8, 11));
      for (int i = 1; i < deals.length; i++) {
        expect(
          deals[i - 1].discountPercent,
          greaterThanOrEqualTo(deals[i].discountPercent),
        );
      }
    });

    test('never repeats a product within a day', () {
      final List<Product> deals = dealsFor(pool(40), DateTime(2026, 8, 11));
      expect(deals.map((Product p) => p.id).toSet(), hasLength(deals.length));
    });

    test('copes with a pool smaller than a day’s worth', () {
      final List<Product> deals = dealsFor(pool(3), DateTime(2026, 8, 11));
      expect(deals, hasLength(3));
      expect(deals.map((Product p) => p.id).toSet(), hasLength(3));
    });

    test('an empty pool yields nothing rather than throwing', () {
      expect(dealsFor(const <Product>[], DateTime(2026, 8, 11)), isEmpty);
    });

    test('works its way through the catalogue over a fortnight', () {
      final List<Product> products = pool(40);
      final Set<String> seen = <String>{};
      for (int d = 0; d < 14; d++) {
        seen.addAll(
          dealsFor(
            products,
            DateTime(2026, 8, 1).add(Duration(days: d)),
          ).map((Product p) => p.id),
        );
      }
      // A product shouldn't be stuck on sale forever or never surface.
      expect(seen.length, greaterThan(20));
    });
  });

  group('the ticker', () {
    test('is switched off for tests', () {
      configureTestEnvironment();
      // A repeating timer would stop pumpAndSettle ever settling.
      expect(dealCountdownTick, isNull);
    });
  });

  group('where the countdown belongs', () {
    test('a product in today\'s selection is identifiable', () {
      final List<Product> products = pool(40);
      final DateTime day = DateTime(2026, 8, 11);
      final List<Product> today = dealsFor(products, day);

      // The product page shows the countdown only for these, because only
      // their membership of the selection ends at midnight.
      expect(today, isNotEmpty);
      expect(products.where(today.contains).length, today.length);

      final Product notToday = products.firstWhere(
        (Product p) => !today.contains(p),
      );
      expect(today.contains(notToday), isFalse);
    });
  });
}
