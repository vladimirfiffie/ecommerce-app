import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/catalog/widgets/compare_bar.dart';
import 'package:ecommerce_app/shared/widgets/product_card.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/compare_provider.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(
        id: 'a',
        name: 'Wool Coat',
        price: 120,
        specs: const ProductSpecs(weightGrams: 1400, warranty: '2 years'),
      ),
      testProduct(
        id: 'b',
        name: 'Linen Tee',
        price: 25,
        specs: const ProductSpecs(weightGrams: 200),
      ),
      testProduct(id: 'c', name: 'Field Watch', price: 90),
      testProduct(id: 'd', name: 'Leather Bag', price: 210),
    ],
  );

  group('picking products', () {
    test('holding one adds it, holding it again takes it off', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      final CompareNotifier compare = c.read(compareProvider.notifier);

      expect(compare.toggle('a'), CompareResult.added);
      expect(c.read(compareProvider), <String>['a']);
      expect(compare.toggle('a'), CompareResult.removed);
      expect(c.read(compareProvider), isEmpty);
    });

    test('a fourth is refused rather than replacing someone else', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      final CompareNotifier compare = c.read(compareProvider.notifier);

      compare
        ..toggle('a')
        ..toggle('b')
        ..toggle('c');
      expect(compare.toggle('d'), CompareResult.full);
      expect(c.read(compareProvider), <String>[
        'a',
        'b',
        'c',
      ], reason: 'the earlier picks are left alone');
    });

    test('the order picked is the order shown', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      c.read(compareProvider.notifier)
        ..toggle('c')
        ..toggle('a');

      expect(c.read(compareItemsProvider).map((Product p) => p.id), <String>[
        'c',
        'a',
      ]);
    });

    test('a product the catalog dropped falls out of the list', () async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      c.read(compareProvider.notifier)
        ..toggle('a')
        ..toggle('ghost');

      expect(c.read(compareItemsProvider).map((Product p) => p.id), <String>[
        'a',
      ]);
    });
  });

  group('the bar', () {
    Widget wrap(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const Scaffold(bottomNavigationBar: CompareBar()),
      ),
    );

    testWidgets('stays out of the way until something is picked', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);

      await tester.pumpWidget(wrap(c));
      await tester.pump();
      expect(find.text('Compare'), findsNothing);

      c.read(compareProvider.notifier).toggle('a');
      await tester.pump();
      expect(find.text('1 picked to compare'), findsOneWidget);
    });

    testWidgets('one pick cannot be compared with anything', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      c.read(compareProvider.notifier).toggle('a');

      await tester.pumpWidget(wrap(c));
      await tester.pump();

      final FilledButton button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Compare'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Hold another product to add it'), findsOneWidget);
    });

    testWidgets('two picks open the sheet, with a row per attribute', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await testContainer(catalog: catalog);
      await c.read(catalogProvider.future);
      c.read(compareProvider.notifier)
        ..toggle('a')
        ..toggle('b');

      await tester.pumpWidget(wrap(c));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
      await settle(tester);

      expect(find.text('Side by side'), findsOneWidget);
      expect(find.text('WEIGHT'), findsOneWidget);
      expect(find.text('1.4 kg'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);
      // Only the coat has a warranty, so the tee's cell says so.
      expect(find.text('WARRANTY'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });
  });

  testWidgets('a card in the comparison is marked as picked', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(product: catalog.byId('a')!),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.longPress(find.byType(ProductCard));
    await tester.pump();

    expect(c.read(compareProvider), <String>['a']);
    expect(find.textContaining('Comparing Wool Coat'), findsOneWidget);
  });
}
