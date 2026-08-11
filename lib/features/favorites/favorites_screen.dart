import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';
import '../../shared/widgets/product_grid.dart';
import '../../core/layout/breakpoints.dart';
import '../product/product_detail_screen.dart';
import '../../core/layout/two_pane.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Product> products = ref.watch(favoriteProductsProvider);
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));
    final bool twoPane = useTwoPane(context);
    final String? selected =
        twoPane && products.any((Product p) => p.id == _selectedId)
        ? _selectedId
        : null;

    final Widget master = SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('Saved', style: theme.textTheme.headlineMedium),
                ),
                if (products.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addAll(context, ref, products),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: products.isEmpty
                ? EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Nothing saved yet',
                    message:
                        'Tap the heart on anything you like and it’ll wait for you here.',
                    actionLabel: 'Browse the shop',
                    onAction: () => context.go(Routes.catalog),
                  )
                : ProductGrid(
                    products: products,
                    heroPrefix: 'saved',
                    padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
                    selectedId: selected,
                    onSelect: twoPane
                        ? (String id) => setState(() => _selectedId = id)
                        : null,
                  ),
          ),
        ],
      ),
    );

    if (!twoPane) return Scaffold(body: master);

    return Scaffold(
      body: TwoPane(
        list: master,
        detail: selected == null
            ? null
            : DetailPaneSurface(
                child: ProductDetailScreen(
                  key: ValueKey<String>(selected),
                  productId: selected,
                  embedded: true,
                ),
              ),
        placeholder: const TwoPanePlaceholder(
          icon: Icons.favorite_border_rounded,
          message: 'Pick something you saved to see it here.',
        ),
      ),
    );
  }

  /// Only products with no variant choices can be bulk-added; anything needing
  /// a size or colour is skipped so we never guess on the shopper's behalf.
  Future<void> _addAll(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) async {
    int added = 0;
    int skipped = 0;
    for (final Product product in products) {
      if (!product.inStock) continue;
      if (product.sizes.isNotEmpty || product.colors.isNotEmpty) {
        skipped++;
        continue;
      }
      await ref.read(cartProvider.notifier).add(product);
      added++;
    }

    if (!context.mounted) return;
    final String message = switch ((added, skipped)) {
      (0, 0) => 'Nothing available to add',
      (0, _) => 'These need a size or colour — open them to choose',
      (_, 0) => 'Added $added to your bag',
      _ => 'Added $added — $skipped need a size or colour',
    };
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
