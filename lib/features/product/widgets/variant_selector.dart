import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../state/haptics_provider.dart';

/// The size, as a dropdown. Nothing is preselected — the shopper has to
/// choose, which is what the add-to-bag validation checks for.
///
/// This was a wrap of chips. Chips read well for three or four sizes and
/// badly for a shoe run, where a dozen of them take four lines and push the
/// price and the buy button off the screen. A dropdown is one line whatever
/// the product offers, and it is the control the platform already gives a
/// screen reader and a keyboard a way through.
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
        Text('Size', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          // Null until chosen, so the field shows its hint rather than
          // quietly standing behind a size nobody picked.
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            hintText: 'Select a size',
            // The one thing the chips said that a dropdown doesn't: that
            // this is a choice still to be made.
            helperText: selected == null ? 'Needed before adding to bag' : null,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          items: <DropdownMenuItem<String>>[
            for (final String size in sizes)
              DropdownMenuItem<String>(value: size, child: Text(size)),
          ],
          onChanged: (String? value) {
            if (value == null) return;
            unawaited(ref.read(hapticsProvider).selection());
            onSelected(value);
          },
        ),
      ],
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
