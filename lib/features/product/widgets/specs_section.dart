import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product.dart';

/// One line of the spec table.
@immutable
class Spec {
  const Spec(this.label, this.value);

  final String label;
  final String value;
}

/// "Specifications" — the measurable facts about a product.
///
/// Draws nothing at all when the catalog gave us nothing, rather than an empty
/// heading. Rows are built from whatever is present, so a product with only a
/// SKU still gets a sensible one-row table.
class SpecsSection extends StatelessWidget {
  const SpecsSection({required this.product, super.key});

  final Product product;

  /// The rows worth drawing, in the order a shopper scans them.
  static List<Spec> rowsFor(Product product) {
    final ProductSpecs s = product.specs;
    return <Spec>[
      Spec('Category', product.subcategory),
      if (s.hasDimensions)
        Spec(
          'Dimensions',
          '${_number(s.widthCm!)} × ${_number(s.heightCm!)} × '
              '${_number(s.depthCm!)} cm',
        ),
      if (s.weightGrams != null) Spec('Weight', _weight(s.weightGrams!)),
      if (s.warranty != null) Spec('Warranty', s.warranty!),
      if (s.shipping != null) Spec('Shipping', s.shipping!),
      if (s.returnPolicy != null) Spec('Returns', s.returnPolicy!),
      if ((s.minimumOrderQuantity ?? 1) > 1)
        Spec('Minimum order', '${s.minimumOrderQuantity} units'),
      if (s.sku != null) Spec('SKU', s.sku!),
    ];
  }

  /// Grams below a kilo, kilograms above — nobody reads "1400 g".
  static String _weight(double grams) =>
      grams >= 1000 ? '${_number(grams / 1000)} kg' : '${_number(grams)} g';

  /// Drops a pointless trailing `.0`.
  static String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Spec> rows = rowsFor(product);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Specifications', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                _SpecRow(spec: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.spec});

  final Spec spec;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Fixed label column so values line up down the table; long values
          // wrap in the remaining space rather than pushing it out of shape.
          SizedBox(
            width: 116,
            child: Text(
              spec.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              spec.value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
