import 'package:ecommerce_app/data/models/review.dart';
import 'package:ecommerce_app/shared/widgets/app_image.dart';
import 'package:ecommerce_app/state/review_photos_provider.dart';
import 'package:ecommerce_app/state/reviews_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  group('telling a file from a URL', () {
    test('an absolute path is local', () {
      expect(isLocalImagePath('/data/user/0/app/review-1.jpg'), isTrue);
      expect(isLocalImagePath('file:///tmp/a.jpg'), isTrue);
    });

    test('a fetched image is not', () {
      expect(isLocalImagePath('https://cdn.example/a.webp'), isFalse);
      expect(isLocalImagePath(''), isFalse);
    });
  });

  group('a review carrying photos', () {
    const List<String> paths = <String>[
      '/tmp/review-1.jpg',
      '/tmp/review-2.jpg',
    ];

    test('keeps them through storage', () {
      final UserReview review = UserReview(
        productId: 'mug',
        rating: 5,
        body: 'Holds coffee, as promised.',
        writtenAt: DateTime(2026, 8, 1),
        photos: paths,
      );
      final UserReview back = UserReview.fromJson(review.toJson());
      expect(back.photos, paths);
    });

    test('a review with none writes no photo key at all', () {
      final UserReview review = UserReview(
        productId: 'mug',
        rating: 5,
        body: 'Holds coffee, as promised.',
        writtenAt: DateTime(2026, 8, 1),
      );
      expect(review.toJson().containsKey('photos'), isFalse);
      expect(UserReview.fromJson(review.toJson()).photos, isEmpty);
    });

    test('hands them to the shape the product page renders', () {
      final Review rendered = UserReview(
        productId: 'mug',
        rating: 5,
        body: 'Holds coffee, as promised.',
        writtenAt: DateTime(2026, 8, 1),
        photos: paths,
      ).toReview();
      expect(rendered.photos, paths);
      // Which is what puts it behind the "With photos" filter.
      expect(rendered.photos.isNotEmpty, isTrue);
    });
  });

  testWidgets('a photo that has been deleted falls back rather than throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 80,
            child: AppImage(url: '/nowhere/gone.jpg'),
          ),
        ),
      ),
    );
    // Reading the file is real I/O, so it needs the real clock rather than
    // the fake one pump drives.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    // The point of the test: a photo whose file has gone shows the same
    // placeholder a dead URL does, and takes nothing down with it.
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  test('the picker asks for nothing when the review is already full', () async {
    final ProviderContainer c = await testContainer();
    final ReviewPhotoService photos = c.read(reviewPhotosProvider);
    expect(await photos.pick(remaining: 0), isEmpty);
  });

  test(
    'a platform with no camera roll returns nothing, and does not throw',
    () async {
      // The test binding reports Android, so this states the guard directly:
      // an unregistered plugin must come back empty rather than take the
      // review down with it.
      final ProviderContainer c = await testContainer();
      expect(await c.read(reviewPhotosProvider).pick(remaining: 4), isEmpty);
    },
  );
}
