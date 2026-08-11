import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/dummyjson_product_repository.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/shared/widgets/nova_refresh.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Catalog catalog = Catalog(
    categories: const <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        icon: Icons.checkroom_rounded,
        imageUrl: '',
      ),
    ],
    products: <Product>[testProduct(id: 'tee', name: 'Linen Tee', price: 25)],
  );

  group('the cached repository', () {
    test('clearing the cache makes the next load go back to the API', () async {
      int calls = 0;
      const String body =
          '{"products":[{"id":1,"title":"Tee","category":"tops","price":9,'
          '"discountPercentage":0,"rating":4,"stock":3,"images":[],'
          '"thumbnail":"t","reviews":[],"meta":{}}]}';

      final DummyJsonProductRepository repo = DummyJsonProductRepository(
        client: MockClient((http.Request _) async {
          calls++;
          return http.Response(body, 200);
        }),
      );

      await repo.loadCatalog();
      await repo.loadCatalog();
      expect(calls, 1, reason: 'the second read is served from cache');

      repo.clearCache();
      await repo.loadCatalog();
      expect(calls, 2, reason: 'after clearing it must refetch');
    });
  });

  group('pull to refresh', () {
    Future<(ProviderContainer, FakeProductRepository)> pumpApp(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      setMockPrefs();
      final SharedPreferences store = await SharedPreferences.getInstance();
      final FakeProductRepository repo = FakeProductRepository(catalog);
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const NovaApp()),
      );
      await settle(tester);
      return (c, repo);
    }

    testWidgets('Home refetches instead of re-reading the cache', (
      WidgetTester tester,
    ) async {
      final (ProviderContainer _, FakeProductRepository repo) = await pumpApp(
        tester,
      );
      final int before = repo.loads;

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await settle(tester);

      expect(repo.cacheClears, greaterThan(0), reason: 'must bust the cache');
      expect(repo.loads, greaterThan(before));
    });

    testWidgets('Shop and Saved can both be pulled', (
      WidgetTester tester,
    ) async {
      final (ProviderContainer c, FakeProductRepository _) = await pumpApp(
        tester,
      );
      // Saved shows its empty state with nothing in it, and an empty
      // wishlist has nothing to refresh into.
      await c.read(favoritesProvider.notifier).toggle('tee');
      await settle(tester);

      for (final String tab in <String>['Shop', 'Saved']) {
        await tester.tap(find.text(tab).last);
        await settle(tester);
        expect(
          find.byType(NovaRefresh),
          findsWidgets,
          reason: '$tab should be refreshable',
        );
      }
    });

    testWidgets('pulling Shop goes back to the source', (
      WidgetTester tester,
    ) async {
      final (ProviderContainer _, FakeProductRepository repo) = await pumpApp(
        tester,
      );
      await tester.tap(find.text('Shop').last);
      await settle(tester);

      final int before = repo.loads;
      await tester.fling(find.byType(GridView), const Offset(0, 400), 1000);
      await settle(tester);

      expect(repo.loads, greaterThan(before));
    });

    testWidgets('a failed refresh does not take the screen down', (
      WidgetTester tester,
    ) async {
      setMockPrefs();
      final SharedPreferences store = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(
            _FlakyRepository(catalog),
          ),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const NovaApp()),
      );
      await settle(tester);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await settle(tester);

      // The pull swallows the error and lets the catalog's own error state
      // explain it, rather than throwing out of the gesture handler.
      expect(tester.takeException(), isNull);
    });
  });
}

/// Loads once, then fails — the shape of a device going offline mid-session.
class _FlakyRepository implements ProductRepository {
  _FlakyRepository(this.catalog);

  final Catalog catalog;
  int loads = 0;

  @override
  Future<Catalog> loadCatalog() async {
    if (loads++ > 0) throw const CatalogException('offline');
    return catalog;
  }

  @override
  void clearCache() {}
}
