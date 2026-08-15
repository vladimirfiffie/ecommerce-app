import 'dart:convert';

import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/cached_product_repository.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A repository that fails on demand, so the fallback can be exercised without
/// a network.
class _FlakySource implements ProductRepository {
  _FlakySource(this.catalog);

  final Catalog catalog;
  bool offline = false;
  int loads = 0;
  int cacheClears = 0;

  @override
  Future<Catalog> loadCatalog() async {
    loads++;
    if (offline) throw const _Down();
    return catalog;
  }

  @override
  void clearCache() => cacheClears++;
}

class _Down implements Exception {
  const _Down();
  @override
  String toString() => 'the shop is down';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Product tee = testProduct(id: 'tee', name: 'Linen Tee', price: 25);
  final Catalog catalog = Catalog(
    categories: <Category>[
      const Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[tee],
  );

  Future<SharedPreferences> emptyPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferences.getInstance();
  }

  group('the catalog snapshot', () {
    test('is written on a successful load', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final CachedProductRepository repo = CachedProductRepository(
        source: _FlakySource(catalog),
        prefs: prefs,
      );

      await repo.loadCatalog();
      expect(prefs.getString(CachedProductRepository.snapshotKey), isNotNull);
      expect(prefs.getString(CachedProductRepository.snapshotAtKey), isNotNull);
    });

    test('serves a later load without touching the source', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final _FlakySource source = _FlakySource(catalog);
      await CachedProductRepository(source: source, prefs: prefs).loadCatalog();

      // A fresh process over the same store.
      final Catalog second = await CachedProductRepository(
        source: source,
        prefs: prefs,
      ).loadCatalog();

      expect(source.loads, 1, reason: 'served from the snapshot');
      expect(second.products.single.name, 'Linen Tee');
      expect(second.categories.single.label, 'Fashion');
    });

    test('carries the whole product, not just its name', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final _FlakySource source = _FlakySource(catalog);
      await CachedProductRepository(source: source, prefs: prefs).loadCatalog();

      final Product restored = (await CachedProductRepository(
        source: source,
        prefs: prefs,
      ).loadCatalog()).products.single;

      expect(restored.price, tee.price);
      expect(restored.rating, tee.rating);
      expect(restored.stock, tee.stock);
      expect(restored.images, tee.images);
      expect(restored.categoryId, tee.categoryId);
    });

    test('is used when the source is unreachable', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final _FlakySource source = _FlakySource(catalog);
      await CachedProductRepository(source: source, prefs: prefs).loadCatalog();

      source.offline = true;
      // Stale — so this one has to go to the source, and the source is down.
      final Catalog served = await CachedProductRepository(
        source: source,
        prefs: prefs,
        clock: () => DateTime.now().add(const Duration(days: 2)),
      ).loadCatalog();

      expect(source.loads, 2, reason: 'it did try');
      expect(served.products.single.name, 'Linen Tee');
    });

    test(
      'rethrows when the source fails and nothing was ever stored',
      () async {
        final SharedPreferences prefs = await emptyPrefs();
        final _FlakySource source = _FlakySource(catalog)..offline = true;

        await expectLater(
          CachedProductRepository(source: source, prefs: prefs).loadCatalog(),
          throwsA(isA<_Down>()),
        );
      },
    );

    test('goes back to the source once stale', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final _FlakySource source = _FlakySource(catalog);
      await CachedProductRepository(source: source, prefs: prefs).loadCatalog();

      await CachedProductRepository(
        source: source,
        prefs: prefs,
        freshFor: const Duration(hours: 6),
        clock: () => DateTime.now().add(const Duration(hours: 7)),
      ).loadCatalog();

      expect(source.loads, 2);
    });

    test('a refresh forces the source but keeps the fallback', () async {
      final SharedPreferences prefs = await emptyPrefs();
      final _FlakySource source = _FlakySource(catalog);
      final CachedProductRepository repo = CachedProductRepository(
        source: source,
        prefs: prefs,
      );
      await repo.loadCatalog();

      repo.clearCache();
      await Future<void>.delayed(Duration.zero);
      expect(source.cacheClears, 1);
      expect(
        prefs.getString(CachedProductRepository.snapshotKey),
        isNotNull,
        reason: 'the data stays as a fallback',
      );

      source.offline = true;
      expect((await repo.loadCatalog()).products, hasLength(1));
      expect(source.loads, 2, reason: 'the refresh did go to the source');
    });

    test('ignores a snapshot it cannot read', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CachedProductRepository.snapshotKey: 'not json',
        CachedProductRepository.snapshotAtKey: DateTime.now().toIso8601String(),
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FlakySource source = _FlakySource(catalog);

      expect(
        (await CachedProductRepository(
          source: source,
          prefs: prefs,
        ).loadCatalog()).products,
        hasLength(1),
      );
      expect(source.loads, 1, reason: 'fell through to the source');
    });

    test('ignores a snapshot that decodes to an empty shop', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CachedProductRepository.snapshotKey: jsonEncode(<String, dynamic>{
          'categories': <dynamic>[],
          'products': <dynamic>[],
        }),
        CachedProductRepository.snapshotAtKey: DateTime.now().toIso8601String(),
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FlakySource source = _FlakySource(catalog);

      await CachedProductRepository(source: source, prefs: prefs).loadCatalog();
      expect(source.loads, 1, reason: 'an empty snapshot is not a load');
    });
  });

  group('with the catalog unreachable', () {
    /// A container whose catalog always fails, over a store that already has
    /// a bag and a wishlist in it.
    Future<ProviderContainer> stalled() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ...pastAuthGatePrefs,
        'cart.entries': jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'productId': 'tee', 'quantity': 2},
        ]),
        'favorites.ids': <String>['tee'],
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(
            _FlakySource(catalog)..offline = true,
          ),
        ],
      );
      addTearDown(c.dispose);
      await c
          .read(catalogProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      return c;
    }

    test(
      'the stored bag is still there, even though it cannot be shown',
      () async {
        final ProviderContainer c = await stalled();

        expect(
          c.read(cartItemsProvider),
          isEmpty,
          reason: 'nothing to resolve',
        );
        expect(
          c.read(cartProvider),
          hasLength(1),
          reason: 'but it is not lost',
        );
        expect(c.read(cartCountProvider), 2);
      },
    );

    test(
      'nothing is reported as delisted, because nothing was checked',
      () async {
        final ProviderContainer c = await stalled();
        expect(
          c.read(unavailableCartEntriesProvider),
          isEmpty,
          reason: 'an unreachable catalog is not evidence of a delisting',
        );
      },
    );

    test('the wishlist keeps its ids', () async {
      final ProviderContainer c = await stalled();
      expect(c.read(favoriteProductsProvider), isEmpty);
      expect(c.read(favoritesProvider), <String>{'tee'});
    });
  });

  group('with the catalog loaded', () {
    test('a delisted line is reported rather than silently dropped', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'cart.entries': jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{'productId': 'tee', 'quantity': 1},
            <String, dynamic>{'productId': 'gone', 'quantity': 3},
          ]),
        },
      );
      await c.read(catalogProvider.future);

      expect(c.read(cartItemsProvider), hasLength(1));
      final List<String> flagged = c
          .read(unavailableCartEntriesProvider)
          .map((e) => e.productId)
          .toList();
      expect(flagged, <String>['gone']);
    });

    test('flagged lines can be cleared out', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalog,
        initialPrefs: <String, Object>{
          'cart.entries': jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{'productId': 'tee', 'quantity': 1},
            <String, dynamic>{'productId': 'gone', 'quantity': 3},
          ]),
        },
      );
      await c.read(catalogProvider.future);

      await c
          .read(cartProvider.notifier)
          .removeAll(
            c.read(unavailableCartEntriesProvider).map((e) => e.lineId),
          );

      expect(c.read(cartProvider), hasLength(1));
      expect(c.read(unavailableCartEntriesProvider), isEmpty);
    });
  });

  group('the bag screen', () {
    testWidgets('says the shop is unreachable, not that the bag is empty', (
      WidgetTester tester,
    ) async {
      useMobileSurface(tester);
      setMockPrefs(<String, Object>{
        'cart.entries': jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'productId': 'tee', 'quantity': 2},
        ]),
      });
      final SharedPreferences store = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(
            _FlakySource(catalog)..offline = true,
          ),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const NovaApp()),
      );
      await settle(tester);
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined).last);
      await settle(tester);

      expect(find.text('Your bag is empty'), findsNothing);
      expect(find.text('Couldn\u2019t load your bag'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('still says empty when the bag really is empty', (
      WidgetTester tester,
    ) async {
      useMobileSurface(tester);
      setMockPrefs();
      final SharedPreferences store = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(
            _FlakySource(catalog)..offline = true,
          ),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const NovaApp()),
      );
      await settle(tester);
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined).last);
      await settle(tester);

      expect(find.text('Your bag is empty'), findsOneWidget);
    });
  });
}
