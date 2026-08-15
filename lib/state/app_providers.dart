import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/cached_product_repository.dart';
import '../data/repositories/dummyjson_product_repository.dart';
import '../data/repositories/product_repository.dart';

/// Bound in `main()` with the real instance; overriding it in a test swaps the
/// whole persistence layer.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in ProviderScope',
      ),
    );

/// The single seam between the UI and wherever products come from.
///
/// Live data, with the last good copy kept on disk — see
/// [CachedProductRepository] for why the shop can't be online-only.
final Provider<ProductRepository> productRepositoryProvider =
    Provider<ProductRepository>(
      (Ref ref) => CachedProductRepository(
        source: DummyJsonProductRepository(),
        prefs: ref.watch(sharedPreferencesProvider),
      ),
    );

/// The loaded catalog. Everything product-shaped derives from this.
///
/// Riverpod's automatic retry is switched off here on purpose. A provider
/// being retried reports itself as loading, so a shop that can't be reached
/// would sit on a spinner indefinitely instead of saying so — and every screen
/// that resolves through the catalog would go back to looking empty for
/// reasons it couldn't explain. The repository already falls back to its
/// on-disk snapshot, and where that isn't there either, the error states offer
/// a Retry the shopper controls.
final FutureProvider<Catalog> catalogProvider = FutureProvider<Catalog>(
  (Ref ref) => ref.watch(productRepositoryProvider).loadCatalog(),
  retry: (int retryCount, Object error) => null,
);

/// Catalog data once loaded, or an empty catalog while loading/failed.
/// Lets synchronous derived providers stay simple.
final Provider<Catalog> catalogDataProvider = Provider<Catalog>(
  (Ref ref) => ref.watch(catalogProvider).value ?? Catalog.empty,
);
