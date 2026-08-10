import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/skeletons.dart';
import '../../state/app_providers.dart';
import '../../state/catalog_filter_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/filter_sheet.dart';
import '../../shared/widgets/product_grid.dart';
import '../../core/layout/breakpoints.dart';

/// The full catalog: category strip, refinement bar, grid/list of results.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final CatalogFilter filter = ref.watch(catalogFilterProvider);
    final List<Product> products = ref.watch(filteredProductsProvider);
    final bool gridView = ref.watch(settingsProvider).gridView;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _Header(
              onSearch: () => context.push(Routes.search),
              query: filter.query,
            ),
            if (catalog.hasValue)
              _CategoryStrip(categories: catalog.value!.categories),
            _RefinementBar(
              resultCount: products.length,
              filter: filter,
              gridView: gridView,
              onToggleView: () =>
                  ref.read(settingsProvider.notifier).setGridView(!gridView),
              onOpenFilters: () => showFilterSheet(context),
            ),
            const Divider(height: 1),
            Expanded(
              child: switch (catalog) {
                AsyncLoading<Catalog>() => const ProductGridSkeleton(),
                AsyncError<Catalog>(:final Object error) => EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn’t load products',
                  message: '$error',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(catalogProvider),
                ),
                _ when products.isEmpty => EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: filter.activeRefinements > 0
                      ? 'Try loosening your filters — there’s plenty more in the shop.'
                      : 'Nothing here yet. Try a different category.',
                  actionLabel: filter.activeRefinements > 0
                      ? 'Clear filters'
                      : null,
                  onAction: filter.activeRefinements > 0
                      ? () => ref
                            .read(catalogFilterProvider.notifier)
                            .clearRefinements()
                      : null,
                ),
                _ =>
                  gridView
                      ? _ResultsGrid(products: products)
                      : _ResultsList(products: products),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.query});

  final VoidCallback onSearch;
  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(
        children: <Widget>[
          Expanded(child: Text('Shop', style: theme.textTheme.headlineMedium)),
          IconButton.filledTonal(
            onPressed: onSearch,
            tooltip: 'Search',
            icon: Icon(
              query.isEmpty ? Icons.search_rounded : Icons.edit_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? selected = ref.watch(catalogFilterProvider).categoryId;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(catalogFilterProvider.notifier).setCategory(null),
            );
          }
          final Category category = categories[index - 1];
          final bool isSelected = selected == category.id;
          return ChoiceChip(
            avatar: Icon(
              category.icon,
              size: 17,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(category.label),
            selected: isSelected,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => ref
                .read(catalogFilterProvider.notifier)
                .setCategory(isSelected ? null : category.id),
          );
        },
      ),
    );
  }
}

class _RefinementBar extends StatelessWidget {
  const _RefinementBar({
    required this.resultCount,
    required this.filter,
    required this.gridView,
    required this.onToggleView,
    required this.onOpenFilters,
  });

  final int resultCount;
  final CatalogFilter filter;
  final bool gridView;
  final VoidCallback onToggleView;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int active = filter.activeRefinements;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$resultCount ${resultCount == 1 ? 'item' : 'items'}'
              '${filter.query.isEmpty ? '' : ' for “${filter.query}”'}',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleView,
            tooltip: gridView ? 'List view' : 'Grid view',
            icon: Icon(
              gridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
            ),
          ),
          Badge(
            isLabelVisible: active > 0,
            label: Text('$active'),
            child: IconButton.filledTonal(
              onPressed: onOpenFilters,
              tooltip: 'Filter and sort',
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));
    return ProductGrid(
      products: products,
      heroPrefix: 'catalog',
      padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 32),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      itemCount: products.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];
        return Card(
          child: ProductRow(
            product: product,
            heroPrefix: 'catalog',
            subtitle: Text(product.subcategory),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ).animate(delay: (index % 8 * 30).ms).fadeIn(duration: 220.ms);
      },
    );
  }
}
