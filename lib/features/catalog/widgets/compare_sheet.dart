import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../state/compare_provider.dart';
import '../../product/widgets/specs_section.dart';

/// Two or three products side by side, row by row.
Future<void> showCompareSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _Sheet(),
    );

class _Sheet extends ConsumerWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Product> items = ref.watch(compareItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    // Every row either product has something to say about, in the order the
    // spec table already uses. A row nobody fills is left out rather than
    // drawn as a line of dashes.
    final List<String> labels = <String>[];
    final List<Map<String, String>> values = <Map<String, String>>[
      for (final Product product in items)
        <String, String>{
          for (final Spec spec in SpecsSection.rowsFor(product))
            spec.label: spec.value,
        },
    ];
    for (final Map<String, String> row in values) {
      for (final String label in row.keys) {
        if (!labels.contains(label)) labels.add(label);
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Side by side',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(compareProvider.notifier).clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final Product product in items)
                          Expanded(child: _Header(product: product)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final String label in labels)
                      _CompareRow(
                        label: label,
                        values: <String?>[
                          for (final Map<String, String> row in values)
                            row[label],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppImage(url: product.thumbnail),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            formatPrice(product.price),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          RatingStars(rating: product.rating, size: 12),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push(Routes.product(product.id));
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

/// One attribute across every column, with the label above it.
///
/// Labelled above rather than in a first column: three products and a label
/// column leaves each one about a thumb wide.
class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.label, required this.values});

  final String label;
  final List<String?> values;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String? value in values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      // An em dash rather than a blank: the gap is the
                      // answer, and a blank cell looks like a bug.
                      value ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: value == null
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
