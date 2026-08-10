import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
final Provider<ProductRepository> productRepositoryProvider =
    Provider<ProductRepository>((Ref ref) => MockProductRepository());

/// The loaded catalog. Everything product-shaped derives from this.
final FutureProvider<Catalog> catalogProvider = FutureProvider<Catalog>(
  (Ref ref) => ref.watch(productRepositoryProvider).loadCatalog(),
);

/// Catalog data once loaded, or an empty catalog while loading/failed.
/// Lets synchronous derived providers stay simple.
final Provider<Catalog> catalogDataProvider = Provider<Catalog>(
  (Ref ref) => ref.watch(catalogProvider).valueOrNull ?? Catalog.empty,
);
