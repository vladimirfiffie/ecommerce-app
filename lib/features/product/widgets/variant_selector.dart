import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../state/haptics_provider.dart';

/// Size chips. Nothing is preselected — the shopper has to choose, which is
/// what the add-to-bag validation checks for.
class SizeSelector extends ConsumerWidget {
  const SizeSelector({
    required this.sizes,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Size', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              selected == null ? 'Select one' : selected!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final String size in sizes)
              _SizeChip(
                label: size,
                selected: size == selected,
                onTap: () {
                  unawaited(ref.read(hapticsProvider).selection());
                  onSelected(size);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Color swatches with a ring on the active one.
class ColorSelector extends ConsumerWidget {
  const ColorSelector({
    required this.colors,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<ProductColor> colors;
  final ProductColor? selected;
  final ValueChanged<ProductColor> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Color', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              selected?.name ?? 'Select one',
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            for (final ProductColor color in colors)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Semantics(
                  label: color.name,
                  selected: color == selected,
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      unawaited(ref.read(hapticsProvider).selection());
                      onSelected(color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(color.argb),
                        border: Border.all(
                          color: color == selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: color == selected ? 3 : 1,
                        ),
                      ),
                      child: color == selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: _contrastOn(Color(color.argb)),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Picks black or white for the checkmark so it stays visible on any swatch.
  static Color _contrastOn(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
