import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../state/catalog_filter_provider.dart';
import '../../../shared/widgets/haptic_controls.dart';

/// Opens the filter & sort bottom sheet.
Future<void> showFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const FilterSheet(),
    );

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CatalogFilter filter = ref.watch(catalogFilterProvider);
    final CatalogFilterNotifier notifier = ref.read(
      catalogFilterProvider.notifier,
    );
    final List<String> subcategories = ref.watch(subcategoryOptionsProvider);
    final double ceiling = ref.watch(priceCeilingProvider);
    final int resultCount = ref.watch(filteredProductsProvider).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Filter & sort',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: filter.activeRefinements == 0
                      ? null
                      : notifier.clearRefinements,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: <Widget>[
                _Label('Sort by'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final SortOption option in SortOption.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: filter.sort == option,
                        labelStyle: TextStyle(
                          color: filter.sort == option
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => notifier.setSort(option),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                if (subcategories.length > 1) ...<Widget>[
                  _Label('Type'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Any'),
                        selected: filter.subcategory == null,
                        onSelected: (_) => notifier.setSubcategory(null),
                      ),
                      for (final String sub in subcategories)
                        ChoiceChip(
                          label: Text(sub),
                          selected: filter.subcategory == sub,
                          labelStyle: TextStyle(
                            color: filter.subcategory == sub
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (bool on) =>
                              notifier.setSubcategory(on ? sub : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                Row(
                  children: <Widget>[
                    Expanded(child: _Label('Max price')),
                    Text(
                      filter.maxPrice == null
                          ? 'Any'
                          : formatPrice(filter.maxPrice!),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                AsterSlider(
                  value: (filter.maxPrice ?? ceiling).clamp(0, ceiling),
                  min: 0,
                  max: ceiling,
                  divisions: 40,
                  label: filter.maxPrice == null
                      ? 'Any'
                      : formatPrice(filter.maxPrice!),
                  onChanged: (double value) => notifier.setMaxPrice(
                    value >= ceiling ? null : value.roundToDouble(),
                  ),
                ),
                const SizedBox(height: 16),
                _Label('Minimum rating'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final double r in <double>[0, 3, 4, 4.5])
                      ChoiceChip(
                        label: Text(
                          r == 0
                              ? 'Any'
                              : '${r.toStringAsFixed(r == 4.5 ? 1 : 0)}+',
                        ),
                        selected: filter.minRating == r,
                        labelStyle: TextStyle(
                          color: filter.minRating == r
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => notifier.setMinRating(r),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('On sale only'),
                  value: filter.onSaleOnly,
                  onChanged: notifier.setOnSaleOnly,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In stock only'),
                  value: filter.inStockOnly,
                  onChanged: notifier.setInStockOnly,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  resultCount == 0
                      ? 'No matches'
                      : 'Show $resultCount ${resultCount == 1 ? 'result' : 'results'}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    ),
  );
}
