import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/alerts_provider.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/favorites_provider.dart';
import 'package:ecommerce_app/state/notifications_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A [NotificationService] that records instead of talking to a plugin.
///
/// Mocking the method channel isn't enough here: resolving the platform
/// implementation raises a `LateInitializationError` when the plugin isn't
/// registered, and the service deliberately swallows that — so nothing would
/// ever be observable. Overriding the service is the honest seam.
class RecordingNotifications extends NotificationService {
  RecordingNotifications(super.plugin, super.settings);

  final List<String> shown = <String>[];

  @override
  Future<void> show({
    required NotifyChannel channel,
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Keep the real gating so muted channels are genuinely tested.
    if (!isOn(channel)) return;
    shown.add('$title|$body');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Catalog catalogWith({required int teeStock, double coatPrice = 100}) =>
      Catalog(
        categories: <Category>[],
        products: <Product>[
          testProduct(id: 'tee', name: 'Linen Tee', stock: teeStock),
          testProduct(id: 'coat', name: 'Wool Coat', price: coatPrice),
        ],
      );

  /// Container with recorded notifications, ready to sweep.
  Future<(ProviderContainer, RecordingNotifications)> setUpSweep({
    required Catalog catalog,
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    setMockPrefs(prefs);
    final SharedPreferences store = await SharedPreferences.getInstance();

    late final RecordingNotifications recorder;
    final ProviderContainer container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store),
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
        notificationsProvider.overrideWith((Ref ref) {
          recorder = RecordingNotifications(
            FlutterLocalNotificationsPlugin(),
            ref.watch(notificationSettingsProvider),
          );
          return recorder;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(catalogProvider.future);
    // Force the override to build before the sweep reads it.
    container.read(notificationsProvider);
    return (container, recorder);
  }

  group('stock watch', () {
    test('toggles on and off', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogWith(teeStock: 0),
      );
      final StockWatchNotifier watch = c.read(stockWatchProvider.notifier);

      expect(await watch.toggle('tee'), isTrue);
      expect(c.read(isWatchingStockProvider('tee')), isTrue);

      expect(await watch.toggle('tee'), isFalse);
      expect(c.read(stockWatchProvider), isEmpty);
    });

    test('restores from storage', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogWith(teeStock: 0),
        initialPrefs: const <String, Object>{
          'alerts.stockWatch': <String>['tee'],
        },
      );
      expect(c.read(isWatchingStockProvider('tee')), isTrue);
    });
  });

  group('back in stock', () {
    test('stays quiet while the item is still sold out', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 0),
        prefs: const <String, Object>{
          'alerts.stockWatch': <String>['tee'],
        },
      );

      final AlertSweepResult result = await c
          .read(alertSweeperProvider)
          .sweep();
      expect(result.restocked, isEmpty);
      expect(n.shown, isEmpty);
      expect(
        c.read(isWatchingStockProvider('tee')),
        isTrue,
        reason: 'the watch must survive so it can fire later',
      );
    });

    test('notifies once when it returns, then stops watching', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 12),
        prefs: const <String, Object>{
          'alerts.stockWatch': <String>['tee'],
        },
      );

      final AlertSweepResult first = await c.read(alertSweeperProvider).sweep();
      expect(first.restocked, <String>['tee']);
      expect(n.shown, hasLength(1));
      expect(n.shown.single, contains('Back in stock'));
      expect(c.read(isWatchingStockProvider('tee')), isFalse);

      final AlertSweepResult second = await c
          .read(alertSweeperProvider)
          .sweep();
      expect(second.restocked, isEmpty, reason: 'must not re-notify');
      expect(n.shown, hasLength(1));
    });

    test('a watch for a product that no longer exists is skipped', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 5),
        prefs: const <String, Object>{
          'alerts.stockWatch': <String>['gone'],
        },
      );
      expect((await c.read(alertSweeperProvider).sweep()).restocked, isEmpty);
      expect(n.shown, isEmpty);
    });
  });

  group('price drops', () {
    test('the first sweep only records a baseline', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 0),
        prefs: const <String, Object>{
          'favorites.ids': <String>['coat'],
        },
      );

      final AlertSweepResult result = await c
          .read(alertSweeperProvider)
          .sweep();
      expect(result.priceDrops, isEmpty, reason: 'nothing to compare against');
      expect(n.shown, isEmpty);
      expect(c.read(priceWatchProvider)['coat'], 100);
    });

    test('a real drop notifies and moves the baseline down', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 0, coatPrice: 70),
        prefs: const <String, Object>{
          'favorites.ids': <String>['coat'],
          'alerts.priceSnapshots': '{"coat":100.0}',
        },
      );

      final AlertSweepResult result = await c
          .read(alertSweeperProvider)
          .sweep();
      expect(result.priceDrops, <String>['coat']);
      expect(n.shown.single, contains('Price drop'));
      expect(c.read(priceWatchProvider)['coat'], 70);

      // Same price next time: no second alert.
      expect((await c.read(alertSweeperProvider).sweep()).priceDrops, isEmpty);
      expect(n.shown, hasLength(1));
    });

    test('a price rise is not a drop', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 0, coatPrice: 130),
        prefs: const <String, Object>{
          'favorites.ids': <String>['coat'],
          'alerts.priceSnapshots': '{"coat":100.0}',
        },
      );
      expect((await c.read(alertSweeperProvider).sweep()).priceDrops, isEmpty);
      expect(n.shown, isEmpty);
    });

    test('only favourites are tracked', () async {
      final (ProviderContainer c, RecordingNotifications _) = await setUpSweep(
        catalog: catalogWith(teeStock: 0),
      );
      await c.read(alertSweeperProvider).sweep();
      expect(c.read(priceWatchProvider), isEmpty);

      await c.read(favoritesProvider.notifier).toggle('coat');
      await c.read(alertSweeperProvider).sweep();
      expect(c.read(priceWatchProvider).keys, <String>['coat']);
    });
  });

  group('gating and robustness', () {
    test('muting the deals channel silences both alert kinds', () async {
      final (ProviderContainer c, RecordingNotifications n) = await setUpSweep(
        catalog: catalogWith(teeStock: 5, coatPrice: 70),
        prefs: const <String, Object>{
          'alerts.stockWatch': <String>['tee'],
          'favorites.ids': <String>['coat'],
          'alerts.priceSnapshots': '{"coat":100.0}',
          'notifications.channels': <String>['orders'],
        },
      );

      final AlertSweepResult result = await c
          .read(alertSweeperProvider)
          .sweep();
      // The sweep still detects the events; it just can't announce them.
      expect(result.restocked, <String>['tee']);
      expect(result.priceDrops, <String>['coat']);
      expect(n.shown, isEmpty);
    });

    test('an empty catalog is a no-op', () async {
      final (ProviderContainer c, RecordingNotifications _) = await setUpSweep(
        catalog: Catalog(categories: <Category>[], products: <Product>[]),
      );
      expect((await c.read(alertSweeperProvider).sweep()).isEmpty, isTrue);
    });

    test('corrupt snapshots degrade to empty', () async {
      final ProviderContainer c = await testContainer(
        catalog: catalogWith(teeStock: 0),
        initialPrefs: const <String, Object>{
          'alerts.priceSnapshots': 'not json',
        },
      );
      expect(c.read(priceWatchProvider), isEmpty);
    });
  });
}
