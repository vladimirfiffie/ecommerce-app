import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';

/// `−  2  +` control used in the cart and on the product page.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    super.key,
    this.min = 1,
    this.max = 99,
    this.dense = false,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int min;
  final int max;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double size = dense ? 30 : 36;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: quantity <= min
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            size: size,
            onTap: () {
              HapticFeedback.selectionClick();
              onDecrement();
            },
            tooltip: quantity <= min
                ? AppL10n.of(context).removeItem
                : AppL10n.of(context).decreaseQuantity,
          ),
          SizedBox(
            width: dense ? 26 : 32,
            // Between two unlabelled buttons, a bare number reads as a bare
            // number — it needs to say what it counts.
            child: Semantics(
              label: AppL10n.of(context).quantityLabel,
              value: '$quantity',
              excludeSemantics: true,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            enabled: quantity < max,
            onTap: () {
              HapticFeedback.selectionClick();
              onIncrement();
            },
            tooltip: AppL10n.of(context).increaseQuantity,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      // The tooltip and the semantic label would otherwise both be announced,
      // giving "Decrease quantity, Decrease quantity".
      excludeFromSemantics: true,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: enabled,
        // Carried on this node because excluding the descendants takes the
        // ink response's own tap action with them.
        onTap: enabled ? onTap : null,
        excludeSemantics: true,
        child: InkResponse(
          onTap: enabled ? onTap : null,
          radius: size / 2 + 4,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.52,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
