import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/state/search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ecommerce_app/state/settings_provider.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/shared/widgets/product_grid.dart';
import 'package:ecommerce_app/shared/widgets/app_image.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/app.dart';

void main() {
  Product p(
    String id,
    String name, {
    String brand = 'Aster',
    String subcategory = 'Tops',
    List<String> tags = const <String>[],
    double rating = 4,
    int stock = 5,
  }) => testProduct(
    id: id,
    name: name,
    price: 20,
    brand: brand,
    subcategory: subcategory,
    tags: tags,
    rating: rating,
    stock: stock,
  );

  List<Product> run(List<Product> products, String query) => searchProducts(
    products,
    <String, String>{for (final Product x in products) x.id: x.searchIndex},
    query,
  );

  group('matching', () {
    test('finds a product when the words are out of order', () {
      final List<Product> products = <Product>[p('1', 'Blue Linen Tee')];

      // The old contiguous-substring match found neither of these.
      expect(run(products, 'tee linen').single.id, '1');
      expect(run(products, 'blue tee').single.id, '1');
    });

    test('every word has to match, not just one', () {
      final List<Product> products = <Product>[
        p('1', 'Blue Linen Tee'),
        p('2', 'Red Wool Coat'),
      ];
      expect(run(products, 'blue coat'), isEmpty);
      expect(run(products, 'wool coat').single.id, '2');
    });

    test('matches across brand, category and tags', () {
      final List<Product> products = <Product>[
        p('1', 'Runner', brand: 'Apex', subcategory: 'Mens Shoes'),
        p('2', 'Sandal', tags: <String>['summer']),
      ];
      expect(run(products, 'apex').single.id, '1');
      expect(run(products, 'shoes').single.id, '1');
      expect(run(products, 'summer').single.id, '2');
    });

    test('an empty or whitespace query returns nothing', () {
      final List<Product> products = <Product>[p('1', 'Tee')];
      expect(run(products, ''), isEmpty);
      expect(run(products, '   '), isEmpty);
    });

    test('is case insensitive', () {
      final List<Product> products = <Product>[p('1', 'Linen Tee')];
      expect(run(products, 'LINEN').single.id, '1');
    });
  });

  group('ranking', () {
    test('an exact name beats an incidental tag match', () {
      final List<Product> products = <Product>[
        p('tagged', 'Wool Coat', tags: <String>['linen']),
        p('named', 'Linen'),
      ];
      // Catalog order would have put the tag hit first.
      expect(run(products, 'linen').first.id, 'named');
    });

    test('a name match beats a brand match', () {
      final List<Product> products = <Product>[
        p('brand', 'Runner', brand: 'Linen Co'),
        p('name', 'Linen Shirt'),
      ];
      expect(run(products, 'linen').first.id, 'name');
    });

    test(
      'a title that starts with the query outranks one that contains it',
      () {
        final List<Product> products = <Product>[
          p('mid', 'Soft Linen Shirt'),
          p('start', 'Linen Shirt Classic'),
        ];
        expect(run(products, 'linen').first.id, 'start');
      },
    );

    test('rating breaks a tie between equally good matches', () {
      final List<Product> products = <Product>[
        p('meh', 'Linen Tee', rating: 3),
        p('good', 'Linen Tee', rating: 4.8),
      ];
      expect(run(products, 'linen tee').first.id, 'good');
    });

    test('in-stock edges out sold-out when nothing else separates them', () {
      final List<Product> products = <Product>[
        p('gone', 'Linen Tee', stock: 0, rating: 4),
        p('here', 'Linen Tee', stock: 7, rating: 4),
      ];
      expect(run(products, 'linen tee').first.id, 'here');
    });
  });

  group('limits', () {
    test('caps the result count', () {
      final List<Product> products = <Product>[
        for (int i = 0; i < 60; i++) p('$i', 'Linen Tee $i'),
      ];
      expect(run(products, 'linen'), hasLength(24));
    });
  });

  group('the search screen', () {
    testWidgets('offers a grid and a list, and remembers the choice', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await pumpSearch(tester, query: 'linen');

      // Starts in whichever mode the Shop is in; toggling swaps both.
      final bool startedInGrid = c.read(settingsProvider).gridView;
      expect(
        find.byType(ProductGrid),
        startedInGrid ? findsOneWidget : findsNothing,
      );

      await tester.tap(
        find.byIcon(
          startedInGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
        ),
      );
      await settle(tester);

      expect(c.read(settingsProvider).gridView, !startedInGrid);
      expect(
        find.byType(ProductGrid),
        startedInGrid ? findsNothing : findsOneWidget,
      );
    });

    testWidgets('the toggle is hidden until there is something to view', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester);
      expect(find.byIcon(Icons.view_list_rounded), findsNothing);
      expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
    });

    testWidgets('browse shows category pictures rather than word chips', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester);

      expect(find.text('Browse'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
      // One tappable picture per category in the live catalog.
      expect(find.byType(AppImage), findsWidgets);
    });

    testWidgets('the matched words are picked out in a result', (
      WidgetTester tester,
    ) async {
      await pumpSearch(tester, query: 'linen');
      expect(
        find.textContaining('Linen Tee', findRichText: true),
        findsWidgets,
      );
    });
  });
}

/// Opens the search screen, optionally with a query already typed.
Future<ProviderContainer> pumpSearch(
  WidgetTester tester, {
  String query = '',
}) async {
  tester.view.physicalSize = const Size(400, 900) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  setMockPrefs();
  final SharedPreferences store = await SharedPreferences.getInstance();
  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: 'https://example.test/f.webp',
      ),
    ],
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25),
      testProduct(id: 'coat', name: 'Wool Coat', price: 120),
    ],
  );
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

  await tester.tap(find.text('Shop').last);
  await settle(tester);
  await tester.tap(find.byIcon(Icons.search_rounded).first);
  await settle(tester);

  if (query.isNotEmpty) {
    await tester.enterText(find.byType(TextField).first, query);
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }
  return c;
}
