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
import 'widgets/compare_bar.dart';
import 'widgets/filter_sheet.dart';
import '../../shared/widgets/product_grid.dart';
import '../../core/layout/breakpoints.dart';
import '../product/product_detail_screen.dart';
import '../../core/layout/two_pane.dart';
import '../../shared/widgets/aster_refresh.dart';

/// The full catalog: category strip, refinement bar, grid/list of results.
///
/// On a wide window this becomes master–detail: the grid stays on the left
/// and the selected product opens beside it, so browsing doesn't lose your
/// place. Phones keep pushing a route.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final CatalogFilter filter = ref.watch(catalogFilterProvider);
    final List<Product> products = ref.watch(filteredProductsProvider);
    final bool gridView = ref.watch(settingsProvider).gridView;
    final bool twoPane = useTwoPane(context);

    // Drop a selection that the current filters have excluded, so the detail
    // pane never shows something the list no longer contains.
    final String? selected =
        twoPane && products.any((Product p) => p.id == _selectedId)
        ? _selectedId
        : null;

    final Widget master = SafeArea(
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
              _ => AsterRefresh(
                child: _Results(
                  products: products,
                  gridView: gridView,
                  selectedId: selected,
                  onSelect: twoPane
                      ? (String id) => setState(() => _selectedId = id)
                      : null,
                ),
              ),
            },
          ),
        ],
      ),
    );

    if (!twoPane) {
      return Scaffold(body: master, bottomNavigationBar: const CompareBar());
    }

    return Scaffold(
      bottomNavigationBar: const CompareBar(),
      body: TwoPane(
        list: master,
        detail: selected == null
            ? null
            : DetailPaneSurface(
                // Keyed so switching products rebuilds cleanly instead of
                // inheriting the previous one's variant selection.
                child: ProductDetailScreen(
                  key: ValueKey<String>(selected),
                  productId: selected,
                  embedded: true,
                ),
              ),
        placeholder: const TwoPanePlaceholder(
          icon: Icons.touch_app_outlined,
          message: 'Pick something on the left to see it here.',
        ),
      ),
    );
  }
}

/// Results in whichever layout is chosen, tapping through or selecting
/// depending on whether a detail pane is present.
class _Results extends StatelessWidget {
  const _Results({
    required this.products,
    required this.gridView,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Product> products;
  final bool gridView;
  final String? selectedId;

  /// Null on phones, where a tap should push a route instead.
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) => gridView
      ? _ResultsGrid(
          products: products,
          selectedId: selectedId,
          onSelect: onSelect,
        )
      : _ResultsList(
          products: products,
          selectedId: selectedId,
          onSelect: onSelect,
        );
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
            return _CategoryChip(
              label: 'All',
              selected: selected == null,
              onSelected: () =>
                  ref.read(catalogFilterProvider.notifier).setCategory(null),
            );
          }
          final Category category = categories[index - 1];
          final bool isSelected = selected == category.id;
          return _CategoryChip(
            label: category.label,
            icon: category.icon,
            selected: isSelected,
            onSelected: () => ref
                .read(catalogFilterProvider.notifier)
                .setCategory(isSelected ? null : category.id),
          );
        },
      ),
    );
  }
}

/// One chip in the category strip.
///
/// "All" and the categories are the same widget so their label styling can't
/// drift apart — previously "All" alone fell back to the default chip label
/// color and weight, so it looked grayer and lighter than the rest.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return ChoiceChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 17,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      onSelected: (_) => onSelected(),
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
  const _ResultsGrid({
    required this.products,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));
    return ProductGrid(
      products: products,
      heroPrefix: 'catalog',
      padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 32),
      selectedId: selectedId,
      onSelect: onSelect,
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.products,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String>? onSelect;

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
        final bool selected = product.id == selectedId;
        return Card(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
              : null,
          child: ProductRow(
            product: product,
            heroPrefix: 'catalog',
            subtitle: Text(product.subcategory),
            onTap: onSelect == null ? null : () => onSelect!(product.id),
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
