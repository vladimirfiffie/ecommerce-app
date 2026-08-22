import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/models/wish_list.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:ecommerce_app/state/wishlists_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final Product mug = testProduct(id: 'mug', name: 'Mug');
  final Product coat = testProduct(id: 'coat', name: 'Coat');
  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[mug, coat],
  );

  Future<ProviderContainer> loaded({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    final ProviderContainer c = await testContainer(
      catalog: catalog,
      initialPrefs: initialPrefs,
    );
    await c.read(catalogProvider.future);
    return c;
  }

  test('a fresh install has one list, and it is the default', () async {
    final ProviderContainer c = await loaded();
    expect(c.read(wishListsProvider), hasLength(1));
    expect(c.read(wishListsProvider).single.isDefault, isTrue);
    expect(c.read(wishListsProvider).single.productIds, isEmpty);
  });

  test('an old flat wishlist becomes the default list', () async {
    // Upgrading must not read as "you never saved anything".
    final ProviderContainer c = await loaded(
      initialPrefs: <String, Object>{
        WishListsNotifier.legacyKey: <String>['mug', 'coat'],
      },
    );
    expect(c.read(wishListsProvider), hasLength(1));
    expect(c.read(wishListsProvider).single.productIds, <String>[
      'mug',
      'coat',
    ]);
    expect(c.read(favoritesProvider), <String>{'mug', 'coat'});
  });

  group('the heart', () {
    test('saves into the default list', () async {
      final ProviderContainer c = await loaded();
      expect(await c.read(wishListsProvider.notifier).toggle('mug'), isTrue);
      expect(c.read(isFavoriteProvider('mug')), isTrue);
      expect(c.read(wishListsProvider).single.productIds, contains('mug'));
    });

    test('unsaves from every list at once', () async {
      // An unfilled heart has to mean unsaved. A copy left behind in another
      // list would show it filled again on the next rebuild.
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      final String? gifts = await lists.create('Gifts');
      await lists.add('mug');
      await lists.add('mug', listId: gifts);
      expect(c.read(listsContainingProvider('mug')), hasLength(2));

      expect(await lists.toggle('mug'), isFalse);
      expect(c.read(isFavoriteProvider('mug')), isFalse);
      expect(c.read(favoritesProvider), isEmpty);
    });

    test(
      'is filled when the product is in any list, not just the default',
      () async {
        final ProviderContainer c = await loaded();
        final WishListsNotifier lists = c.read(wishListsProvider.notifier);
        final String? gifts = await lists.create('Gifts');
        await lists.add('coat', listId: gifts);

        expect(c.read(isFavoriteProvider('coat')), isTrue);
        expect(c.read(favoriteProductsProvider).single.id, 'coat');
      },
    );
  });

  group('lists', () {
    test('are created, renamed and deleted', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);

      final String? id = await lists.create('  Gifts  ');
      expect(id, isNotNull);
      expect(lists.byId(id!)!.name, 'Gifts');

      await lists.rename(id, 'Birthday');
      expect(lists.byId(id)!.name, 'Birthday');

      expect(await lists.delete(id), isTrue);
      expect(lists.byId(id), isNull);
    });

    test('refuse an empty name', () async {
      final ProviderContainer c = await loaded();
      expect(await c.read(wishListsProvider.notifier).create('   '), isNull);
      expect(c.read(wishListsProvider), hasLength(1));
    });

    test('the default one cannot be deleted', () async {
      // Something has to be there to catch a heart tap.
      final ProviderContainer c = await loaded();
      expect(
        await c.read(wishListsProvider.notifier).delete(WishList.defaultId),
        isFalse,
      );
      expect(c.read(wishListsProvider), hasLength(1));
    });

    test(
      'a missing default list is put back rather than refusing a save',
      () async {
        final ProviderContainer c = await loaded(
          initialPrefs: <String, Object>{
            'wishlists':
                '[{"id":"gifts","name":"Gifts","productIds":[],'
                '"createdAt":"2026-01-01T00:00:00.000"}]',
          },
        );
        expect(
          c.read(wishListsProvider).any((WishList l) => l.isDefault),
          isTrue,
        );
      },
    );

    test('deleting one takes its saves with it', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      final String? gifts = await lists.create('Gifts');
      await lists.add('mug', listId: gifts);
      expect(c.read(favoritesProvider), contains('mug'));

      await lists.delete(gifts!);
      expect(c.read(favoritesProvider), isEmpty);
    });

    test('the same product can sit in two lists', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      final String? gifts = await lists.create('Gifts');
      await lists.setListsFor('mug', <String>{WishList.defaultId, gifts!});

      expect(c.read(listsContainingProvider('mug')), hasLength(2));
      // Still one product, however many lists it is in.
      expect(c.read(favoriteProductsProvider), hasLength(1));
    });

    test('adding twice does not duplicate the line', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      await lists.add('mug');
      await lists.add('mug');
      expect(c.read(wishListsProvider).single.productIds, <String>['mug']);
    });

    test('a list shows what is in it, newest first', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      await lists.add('mug');
      await lists.add('coat');
      expect(
        c
            .read(wishListProductsProvider(WishList.defaultId))
            .map((Product p) => p.id),
        <String>['coat', 'mug'],
      );
    });

    test('emptying one keeps the list itself', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      await lists.add('mug');
      await lists.emptyList(WishList.defaultId);

      expect(c.read(wishListsProvider), hasLength(1));
      expect(c.read(favoritesProvider), isEmpty);
    });

    test('clearing everything leaves one empty list behind', () async {
      final ProviderContainer c = await loaded();
      final WishListsNotifier lists = c.read(wishListsProvider.notifier);
      await lists.create('Gifts');
      await lists.add('mug');

      await lists.clear();
      expect(c.read(wishListsProvider), hasLength(1));
      expect(c.read(wishListsProvider).single.isDefault, isTrue);
      expect(c.read(favoritesProvider), isEmpty);
    });
  });
}
