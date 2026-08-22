import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/data/models/review.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/reviews_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  /// A product carrying more reviews than the page will show at once.
  Product reviewed(String id, String name) => Product(
    id: id,
    name: name,
    brand: 'Aster',
    categoryId: 'fashion',
    subcategory: 'Coats',
    price: 120,
    description: 'A test product.',
    images: const <String>['https://example.invalid/1.webp'],
    rating: 4.5,
    reviewCount: 4,
    reviews: <Review>[
      for (int i = 0; i < 4; i++)
        Review(
          author: 'Reviewer $i',
          rating: 4,
          body: 'Fits well, number $i.',
          daysAgo: i,
          verified: true,
          tags: const <String>['Fit'],
        ),
    ],
  );

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[reviewed('coat', 'Wool Coat')],
  );

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Map<String, Object> stored = const <String, Object>{},
  }) async {
    useMobileSurface(tester);
    setMockPrefs(stored);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const AsterApp()),
    );
    await settle(tester);
    return c;
  }

  testWidgets('with nothing written it says so and points at orders', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester);
    c.read(routerProvider).push('/reviews');
    await settle(tester);

    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.text('Your orders'), findsOneWidget);
  });

  testWidgets('a written review is listed with its product', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester);
    await c
        .read(userReviewsProvider.notifier)
        .save(
          UserReview(
            productId: 'coat',
            rating: 5,
            title: 'Warm',
            body: 'Runs a little large but very warm.',
            writtenAt: DateTime.now(),
          ),
        );

    c.read(routerProvider).push('/reviews');
    await settle(tester);

    expect(find.text('Wool Coat'), findsOneWidget);
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Open product'), findsOneWidget);
  });

  testWidgets('deleting one takes it off the list', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester);
    await c
        .read(userReviewsProvider.notifier)
        .save(
          UserReview(
            productId: 'coat',
            rating: 4,
            body: 'Good enough.',
            writtenAt: DateTime.now(),
          ),
        );

    c.read(routerProvider).push('/reviews');
    await settle(tester);

    await tester.tap(findByTooltip('Delete'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(c.read(userReviewsProvider), isEmpty);
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('the product page shows a few reviews and links to the rest', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester);
    c.read(routerProvider).push('/product/coat');
    await settle(tester);

    await tester.dragUntilVisible(
      find.textContaining('See all'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await settle(tester);

    // Four reviews, three shown, and the rest one tap away.
    expect(find.text('See all 4 reviews'), findsOneWidget);
    expect(find.textContaining('Fits well, number'), findsNWidgets(3));

    await tester.tap(find.text('See all 4 reviews'));
    await settle(tester);

    expect(find.textContaining('Fits well, number'), findsNWidgets(4));
    expect(find.text('See all 4 reviews'), findsNothing);
  });
}
