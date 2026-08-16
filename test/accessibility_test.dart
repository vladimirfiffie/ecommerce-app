import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/core/utils/semantic_labels.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/shared/widgets/price_text.dart';
import 'package:ecommerce_app/shared/widgets/product_card.dart';
import 'package:ecommerce_app/shared/widgets/quantity_stepper.dart';
import 'package:ecommerce_app/shared/widgets/rating_stars.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Nothing on the way from browsing to buying should be a picture with no
/// words attached.
void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Product onSale = testProduct(
    id: 'tee',
    name: 'Linen Tee',
    brand: 'Aster',
    price: 30,
    compareAtPrice: 50,
    rating: 4.5,
  );

  final Catalog catalog = Catalog(
    categories: <Category>[
      const Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[onSale],
  );

  Future<void> pumpBare(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('prices', () {
    testWidgets('say which number is the old one', (WidgetTester tester) async {
      await pumpBare(tester, PriceText(product: onSale));

      expect(
        find.bySemanticsLabel(r'$30.00, reduced from $50.00, 40% off'),
        findsOneWidget,
      );
    });

    testWidgets('read plainly when there is no discount', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        PriceText(product: testProduct(id: 'p', price: 12)),
      );
      expect(find.text(r'$12.00'), findsOneWidget);
    });
  });

  group('ratings', () {
    testWidgets('are a sentence, not five icons', (WidgetTester tester) async {
      await pumpBare(
        tester,
        const SizedBox(
          width: 200,
          child: RatingStars(rating: 4.5, reviewCount: 42),
        ),
      );

      expect(
        find.bySemanticsLabel('Rated 4.5 out of 5 from 42 reviews'),
        findsOneWidget,
      );
    });

    testWidgets('do not say "1 reviews"', (WidgetTester tester) async {
      expect(ratingLabel(5, testL10n, 1), 'Rated 5.0 out of 5 from 1 review');
    });
  });

  group('the quantity stepper', () {
    testWidgets('names its buttons and its number', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        QuantityStepper(quantity: 3, onDecrement: () {}, onIncrement: () {}),
      );

      expect(find.bySemanticsLabel('Decrease quantity'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase quantity'), findsOneWidget);
      expect(find.bySemanticsLabel('Quantity'), findsOneWidget);
    });

    testWidgets('keeps its buttons activatable', (WidgetTester tester) async {
      int increments = 0;
      await pumpBare(
        tester,
        QuantityStepper(
          quantity: 1,
          onDecrement: () {},
          onIncrement: () => increments++,
        ),
      );

      // Through the semantics tree, the way a screen reader would — excluding
      // the ink response's semantics would otherwise leave nothing to activate.
      final SemanticsHandle handle = tester.ensureSemantics();
      tester.semantics.tap(find.semantics.byLabel('Increase quantity'));
      expect(increments, 1);
      handle.dispose();
    });

    testWidgets('says "Remove" where a decrement really would remove', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        QuantityStepper(
          quantity: 1,
          removeAtMin: true,
          onDecrement: () {},
          onIncrement: () {},
        ),
      );
      expect(find.bySemanticsLabel('Remove'), findsOneWidget);
    });

    testWidgets('offers no bin where there is nothing to remove', (
      WidgetTester tester,
    ) async {
      // The product page clamps at one, so a bin there would promise a
      // destructive action and then do nothing.
      await pumpBare(
        tester,
        QuantityStepper(quantity: 1, onDecrement: () {}, onIncrement: () {}),
      );

      expect(find.bySemanticsLabel('Remove'), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

      // Present but switched off, rather than live and inert.
      final SemanticsNode minus = tester.getSemantics(
        find.bySemanticsLabel('Decrease quantity'),
      );
      expect(minus.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });

    testWidgets('the minus comes back once there is something to take away', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        QuantityStepper(quantity: 2, onDecrement: () {}, onIncrement: () {}),
      );

      final SemanticsNode minus = tester.getSemantics(
        find.bySemanticsLabel('Decrease quantity'),
      );
      expect(minus.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('the plus switches off at the stock ceiling', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        QuantityStepper(
          quantity: 3,
          max: 3,
          onDecrement: () {},
          onIncrement: () {},
        ),
      );

      final SemanticsNode plus = tester.getSemantics(
        find.bySemanticsLabel('Increase quantity'),
      );
      expect(plus.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });
  });

  group('a product card', () {
    testWidgets('reads as one sentence, not six fragments', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await (() async {
                SharedPreferences.setMockInitialValues(<String, Object>{});
                return SharedPreferences.getInstance();
              })(),
            ),
          ],
          child: SizedBox(width: 180, child: ProductCard(product: onSale)),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(
          'Aster. Linen Tee. \$30.00, reduced from \$50.00, 40% off. '
          'Rated 4.5 out of 5 from 42 reviews. Only 10 left',
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaves the favourite button separately reachable', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await (() async {
                SharedPreferences.setMockInitialValues(<String, Object>{});
                return SharedPreferences.getInstance();
              })(),
            ),
          ],
          child: SizedBox(width: 180, child: ProductCard(product: onSale)),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Save to wishlist'), findsOneWidget);
    });
  });

  group('the shop', () {
    Future<void> pumpApp(
      WidgetTester tester, {
      Map<String, Object> stored = const <String, Object>{},
    }) async {
      useMobileSurface(tester);
      setMockPrefs(stored);
      final SharedPreferences store = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
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
    }

    testWidgets('meets the tap-target and label guidelines on Home', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('meets the contrast guideline on Home', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('wordless tabs still stand out from the bar behind them', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        stored: <String, Object>{'settings.navLabels': false},
      );

      // With the labels off the icon is the whole target, and the text
      // guideline has no text left to judge it by. 3:1 is what WCAG asks of
      // a graphic that carries meaning on its own.
      await expectLater(
        tester,
        meetsGuideline(
          CustomMinimumContrastGuideline(
            finder: find.descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(Icon),
            ),
            minimumRatio: 3,
            description: 'Tab icons should stand out from the bar',
          ),
        ),
      );
      handle.dispose();
    });
  });
}
