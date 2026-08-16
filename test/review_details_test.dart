import 'package:ecommerce_app/data/models/review.dart';
import 'package:ecommerce_app/data/repositories/dummyjson_product_repository.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  group('tags read off the review', () {
    test('a review about sizing is filed under Fit', () {
      expect(
        Review.tagsIn('Runs small, order a size up — very snug on me.'),
        contains('Fit'),
      );
    });

    test('one review can cover more than one subject', () {
      final List<String> tags = Review.tagsIn(
        'Lovely fabric for the price, and it arrived in two days.',
      );
      expect(tags, containsAll(<String>['Quality', 'Value', 'Delivery']));
    });

    test('a review that says nothing in particular carries no tags', () {
      expect(Review.tagsIn('Love it. Would buy again.'), isEmpty);
    });

    test('nothing outside the four subjects is invented', () {
      final List<String> tags = Review.tagsIn(
        'The color is lovely and the box was purple.',
      );
      expect(tags.every(Review.allTags.contains), isTrue);
    });
  });

  group('serialization', () {
    test('the new fields round-trip', () {
      const Review review = Review(
        author: 'Amara',
        rating: 4,
        body: 'Great fit',
        daysAgo: 3,
        verified: true,
        tags: <String>['Fit'],
        photos: <String>['https://example.invalid/a.webp'],
      );

      final Review back = Review.fromJson(review.toJson());
      expect(back.verified, isTrue);
      expect(back.tags, <String>['Fit']);
      expect(back.photos, <String>['https://example.invalid/a.webp']);
    });

    test('an older stored review reads back as unverified and untagged', () {
      final Review back = Review.fromJson(<String, dynamic>{
        'author': 'Sam',
        'rating': 5,
        'body': 'Good',
        'daysAgo': 1,
      });
      expect(back.verified, isFalse);
      expect(back.tags, isEmpty);
      expect(back.photos, isEmpty);
    });
  });

  group('reviews from the live feed', () {
    String payload(String products) =>
        '{"products":[$products],"total":1,"skip":0,"limit":1}';

    const String product = '''
{"id":2,"title":"Powder Canister","description":"","category":"beauty",
 "price":14.50,"discountPercentage":0,"rating":4.9,"stock":5,"tags":[],
 "images":["https://cdn.invalid/a.webp","https://cdn.invalid/b.webp"],
 "thumbnail":"https://cdn.invalid/t.webp",
 "reviews":[
   {"rating":5,"comment":"Great quality, and it arrived fast.",
    "date":"2026-08-01T00:00:00.000Z","reviewerName":"Amara"},
   {"rating":4,"comment":"Fits well enough.",
    "date":"2026-08-01T00:00:00.000Z","reviewerName":"Sam"}],
 "meta":{"createdAt":"2020-01-01T00:00:00.000Z"}}''';

    Future<Catalog> load() => DummyJsonProductRepository(
      client: MockClient(
        (http.Request _) async => http.Response(payload(product), 200),
      ),
    ).loadCatalog();

    test('every review from the feed is a verified buyer', () async {
      final Catalog data = await load();
      final List<Review> reviews = data.byId('2')!.reviews;

      expect(reviews, hasLength(2));
      expect(reviews.every((Review r) => r.verified), isTrue);
    });

    test('tags come from what each reviewer wrote', () async {
      final Catalog data = await load();
      final List<Review> reviews = data.byId('2')!.reviews;

      expect(reviews.first.tags, containsAll(<String>['Quality', 'Delivery']));
      expect(reviews.last.tags, <String>['Fit']);
    });

    test('photos are seeded onto one review, not all of them', () async {
      final Catalog data = await load();
      final List<Review> reviews = data.byId('2')!.reviews;

      expect(reviews.first.photos, isNotEmpty);
      expect(reviews.last.photos, isEmpty);
    });
  });
}
