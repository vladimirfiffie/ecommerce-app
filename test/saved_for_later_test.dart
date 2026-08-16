import 'package:ecommerce_app/data/models/cart_entry.dart';
import 'package:ecommerce_app/data/models/cart_item.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/saved_for_later_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      testProduct(id: 'coat', name: 'Wool Coat', price: 120, stock: 5),
      testProduct(
        id: 'tee',
        name: 'Linen Tee',
        price: 25,
        sizes: <String>['S', 'M'],
      ),
    ],
  );

  test('saving takes the line out of the bag and keeps it', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!, quantity: 3);

    final CartEntry line = c.read(cartProvider).single;
    await c.read(savedForLaterProvider.notifier).saveForLater(line);

    expect(c.read(cartProvider), isEmpty);
    expect(c.read(savedForLaterProvider).single.productId, 'coat');
  });

  test('a saved line remembers its variant and how many', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    await c
        .read(cartProvider.notifier)
        .add(catalog.byId('tee')!, size: 'M', quantity: 2);

    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);
    await c
        .read(savedForLaterProvider.notifier)
        .moveToBag(c.read(savedForLaterProvider).single);

    final CartEntry back = c.read(cartProvider).single;
    expect(back.productId, 'tee');
    expect(back.size, 'M');
    expect(back.quantity, 2, reason: 'the quantity comes back with it');
    expect(c.read(savedForLaterProvider), isEmpty);
  });

  test('saving the same variant twice keeps one copy', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    final Product coat = catalog.byId('coat')!;

    await c.read(cartProvider.notifier).add(coat);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);
    await c.read(cartProvider.notifier).add(coat);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);

    expect(c.read(savedForLaterProvider).length, 1);
  });

  test('it survives a restart', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);

    // A relaunch is a new container over the same store. testContainer
    // seeds its own preferences, which would wipe what was just saved.
    final SharedPreferences store = c.read(sharedPreferencesProvider);
    final ProviderContainer relaunched = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
      ],
    );
    addTearDown(relaunched.dispose);
    expect(relaunched.read(savedForLaterProvider).single.productId, 'coat');
  });

  test('a product that left the catalog is dropped, not stranded', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);

    // The same store, but a catalog that no longer carries it. Built by
    // hand: testContainer would reset the preferences it is meant to share.
    final ProviderContainer thinner = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          c.read(sharedPreferencesProvider),
        ),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(
            Catalog(
              categories: catalog.categories,
              products: <Product>[catalog.byId('tee')!],
            ),
          ),
        ),
      ],
    );
    addTearDown(thinner.dispose);
    await thinner.read(catalogProvider.future);

    expect(
      thinner.read(savedForLaterItemsProvider),
      isEmpty,
      reason: 'nothing to show for a product that is gone',
    );

    await thinner
        .read(savedForLaterProvider.notifier)
        .moveToBag(thinner.read(savedForLaterProvider).single);

    expect(thinner.read(cartProvider), isEmpty);
    expect(thinner.read(savedForLaterProvider), isEmpty);
  });

  test('a move made before the catalog loads keeps the line', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);

    // Tapped while the catalog is still on its way: there is nothing to add
    // yet, and losing it to a slow connection would be the worst outcome.
    await c
        .read(savedForLaterProvider.notifier)
        .moveToBag(c.read(savedForLaterProvider).single);

    expect(c.read(savedForLaterProvider).single.productId, 'coat');
    expect(c.read(cartProvider), isEmpty);
  });

  test('the list reads newest first', () async {
    final ProviderContainer c = await testContainer(catalog: catalog);
    await c.read(catalogProvider.future);
    await c.read(cartProvider.notifier).add(catalog.byId('coat')!);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);
    await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
    await c
        .read(savedForLaterProvider.notifier)
        .saveForLater(c.read(cartProvider).single);

    final List<CartItem> shown = c.read(savedForLaterItemsProvider);
    expect(shown.map((CartItem i) => i.product.id), <String>['tee', 'coat']);
  });
}
