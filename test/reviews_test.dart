import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/models/review.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:ecommerce_app/state/reviews_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Product reviewed = Product(
    id: 'coat',
    name: 'Wool Coat',
    brand: 'Nova',
    categoryId: 'fashion',
    subcategory: 'Coats',
    price: 100,
    description: 'Warm.',
    images: const <String>['https://example.invalid/1.webp'],
    // 4.0 across 3 published reviews makes the averaging arithmetic checkable.
    rating: 4,
    reviewCount: 3,
    reviews: const <Review>[
      Review(author: 'Amara', rating: 4, body: 'Good', daysAgo: 3),
      Review(author: 'Jonas', rating: 4, body: 'Fine', daysAgo: 9),
      Review(author: 'Priya', rating: 4, body: 'Nice', daysAgo: 20),
    ],
  );

  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[reviewed],
  );

  Future<ProviderContainer> loaded() async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    return c;
  }

  UserReview mine({double rating = 5, String body = 'Excellent coat'}) =>
      UserReview(
        productId: 'coat',
        rating: rating,
        title: 'Great',
        body: body,
        writtenAt: DateTime(2026, 8, 1),
      );

  group('storage', () {
    test('saving then reading back round-trips', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine());

      final UserReview? saved = c.read(myReviewProvider('coat'));
      expect(saved, isNotNull);
      expect(saved!.rating, 5);
      expect(saved.title, 'Great');
      expect(saved.body, 'Excellent coat');
    });

    test('one review per product — saving again replaces', () async {
      final ProviderContainer c = await loaded();
      final UserReviewsNotifier notifier = c.read(userReviewsProvider.notifier);

      await notifier.save(mine(rating: 2, body: 'Disappointing at first'));
      await notifier.save(mine(rating: 5, body: 'Grew on me completely'));

      expect(c.read(userReviewsProvider), hasLength(1));
      expect(c.read(myReviewProvider('coat'))!.rating, 5);
    });

    test('delete removes it', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine());
      await c.read(userReviewsProvider.notifier).delete('coat');
      expect(c.read(myReviewProvider('coat')), isNull);
    });

    test('survives a restart', () async {
      final ProviderContainer first = await loaded();
      await first.read(userReviewsProvider.notifier).save(mine());

      // A fresh container over the same (mock) storage.
      final ProviderContainer second = await testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'reviews.mine':
              '[{"productId":"coat","rating":5.0,"title":"Great",'
              '"body":"Excellent coat","writtenAt":"2026-08-01T00:00:00.000"}]',
        },
      );
      expect(second.read(myReviewProvider('coat'))!.body, 'Excellent coat');
    });

    test('corrupt storage degrades to empty rather than throwing', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: const <String, Object>{'reviews.mine': 'not json'},
      );
      expect(c.read(userReviewsProvider), isEmpty);
    });
  });

  group('display', () {
    test('own review is pinned above the published ones', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine());

      final List<Review> list = c.read(productReviewsProvider(reviewed));
      expect(list, hasLength(4));
      expect(list.first.author, 'You');
      expect(list.first.body, contains('Excellent coat'));
    });

    test('headline and body are combined for display', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine());
      expect(
        c.read(productReviewsProvider(reviewed)).first.body,
        'Great\nExcellent coat',
      );
    });

    test('without a headline only the body shows', () async {
      final ProviderContainer c = await loaded();
      await c
          .read(userReviewsProvider.notifier)
          .save(
            UserReview(
              productId: 'coat',
              rating: 4,
              body: 'Just the body',
              writtenAt: DateTime(2026, 8, 1),
            ),
          );
      expect(
        c.read(productReviewsProvider(reviewed)).first.body,
        'Just the body',
      );
    });

    test('published reviews stand alone when nothing was written', () async {
      final ProviderContainer c = await loaded();
      final List<Review> list = c.read(productReviewsProvider(reviewed));
      expect(list, hasLength(3));
      expect(list.first.author, 'Amara');
    });
  });

  group('rating summary', () {
    test('is untouched without a personal review', () async {
      final ProviderContainer c = await loaded();
      final ({double rating, int count}) s = c.read(
        productRatingProvider(reviewed),
      );
      expect(s.rating, 4.0);
      expect(s.count, 3);
    });

    test('folds a 5-star review into the published average', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine());

      final ({double rating, int count}) s = c.read(
        productRatingProvider(reviewed),
      );
      // (4*3 + 5) / 4 = 4.25
      expect(s.count, 4);
      expect(s.rating, closeTo(4.25, 0.0001));
    });

    test('a harsh review pulls the average down', () async {
      final ProviderContainer c = await loaded();
      await c.read(userReviewsProvider.notifier).save(mine(rating: 1));

      final ({double rating, int count}) s = c.read(
        productRatingProvider(reviewed),
      );
      // (4*3 + 1) / 4 = 3.25
      expect(s.rating, closeTo(3.25, 0.0001));
    });
  });

  group('verified-buyer rule', () {
    test('a product never ordered cannot be reviewed', () async {
      final ProviderContainer c = await loaded();
      expect(c.read(canReviewProvider('coat')), isFalse);
    });

    test('ordering the product unlocks reviewing', () async {
      final ProviderContainer c = await loaded();
      await c.read(cartProvider.notifier).add(reviewed);
      await c
          .read(ordersProvider.notifier)
          .placeOrder(
            address: const Address(
              id: 'a',
              label: 'Home',
              recipient: 'Alex',
              line1: '1 Street',
              city: 'Portland',
              postcode: '97205',
              country: 'US',
            ),
            paymentLabel: 'Visa •••• 4242',
          );

      expect(c.read(canReviewProvider('coat')), isTrue);
      expect(c.read(canReviewProvider('something-else')), isFalse);
    });
  });
}
