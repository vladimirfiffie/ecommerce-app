import 'dart:convert';

import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/catalog_filter_provider.dart';
import 'package:ecommerce_app/state/for_you_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  final Catalog catalog = Catalog(
    categories: const <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        icon: Icons.checkroom_rounded,
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(id: 'tee', name: 'Linen Tee', price: 25),
      testProduct(id: 'coat', name: 'Wool Coat', price: 80),
      testProduct(id: 'gone', name: 'Sold Out Hat', price: 15, stock: 0),
    ],
  );

  Future<ProviderContainer> container({
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    final ProviderContainer c = await testContainer(
      catalog: catalog,
      initialPrefs: prefs,
    );
    await c.read(catalogProvider.future);
    return c;
  }

  group('nothing to say', () {
    test('a fresh install shows no block at all', () async {
      final ProviderContainer c = await container();
      // A permanent empty "For you" heading is worse than no heading.
      expect(c.read(forYouProvider), isEmpty);
    });
  });

  group('back in stock', () {
    test('a watched item that has stock again is surfaced', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['tee'],
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.backInStock);
      expect(item.product?.id, 'tee');
    });

    test('a watched item still out of stock is not', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['gone'],
        },
      );
      expect(c.read(forYouProvider), isEmpty);
    });
  });

  group('price drops', () {
    test('a saved item cheaper than when it was saved is surfaced', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'tee': 40}),
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.priceDrop);
      expect(item.subtitle, contains('Linen Tee'));
    });

    test('a saved item at the same price is not', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'tee': 25}),
        },
      );
      expect(c.read(forYouProvider), isEmpty);
    });

    test('several drops collapse into one row', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'favorites.ids': <String>['tee', 'coat'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{
            'tee': 40,
            'coat': 120,
          }),
        },
      );

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.count, 2);
      expect(item.subtitle, contains('2 saved items'));
    });
  });

  group('the bag', () {
    test('is mentioned when something is in it', () async {
      final ProviderContainer c = await container();
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);

      final ForYouItem item = c.read(forYouProvider).single;
      expect(item.kind, ForYouKind.inBag);
      expect(item.subtitle, contains('1 item'));
    });
  });

  group('ordering', () {
    test('stock and price news outrank a bag reminder', () async {
      final ProviderContainer c = await container(
        prefs: <String, Object>{
          'alerts.stockWatch': <String>['tee'],
          'favorites.ids': <String>['coat'],
          'alerts.priceSnapshots': jsonEncode(<String, double>{'coat': 120}),
        },
      );
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);

      expect(c.read(forYouProvider).map((ForYouItem i) => i.kind), <ForYouKind>[
        ForYouKind.backInStock,
        ForYouKind.priceDrop,
        ForYouKind.inBag,
      ]);
    });

    test('recently viewed only fills in when there is no real news', () async {
      final ProviderContainer c = await container();
      await c.read(recentlyViewedProvider.notifier).record('coat');

      expect(
        c.read(forYouProvider).single.kind,
        ForYouKind.pickUpWhereYouLeftOff,
      );

      // The moment something real happens, the filler drops out.
      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      expect(c.read(forYouProvider).single.kind, ForYouKind.inBag);
    });
  });
}
