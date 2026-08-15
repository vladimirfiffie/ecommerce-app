import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';

/// `−  2  +` control used in the cart and on the product page.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    super.key,
    this.min = 1,
    this.max = 99,
    this.dense = false,
    this.removeAtMin = false,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int min;
  final int max;
  final bool dense;

  /// Whether decrementing at [min] removes the thing being counted.
  ///
  /// True in the bag, where going below one takes the line out — the button
  /// becomes a bin, because that's what it does. False on the product page,
  /// where quantity is clamped and there is nothing to remove: showing a bin
  /// there promises a destructive action and then does nothing at all.
  final bool removeAtMin;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  /// +1 counting up, -1 counting down. Decides which way the digits roll.
  int _direction = 1;

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      _direction = widget.quantity > oldWidget.quantity ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL10n l10n = AppL10n.of(context);
    final double size = widget.dense ? 30 : 36;
    final bool atMin = widget.quantity <= widget.min;
    final bool removes = atMin && widget.removeAtMin;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: removes ? Icons.delete_outline_rounded : Icons.remove_rounded,
            size: size,
            // Without [removeAtMin] there is nothing below the minimum to go
            // to, so the button switches off rather than sitting there live
            // and inert.
            enabled: removes || !atMin,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onDecrement();
            },
            tooltip: removes ? l10n.removeItem : l10n.decreaseQuantity,
          ),
          SizedBox(
            width: widget.dense ? 26 : 32,
            // Between two unlabelled buttons, a bare number reads as a bare
            // number — it needs to say what it counts.
            child: Semantics(
              label: l10n.quantityLabel,
              value: '${widget.quantity}',
              excludeSemantics: true,
              child: _RollingCount(
                value: widget.quantity,
                direction: _direction,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            enabled: widget.quantity < widget.max,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onIncrement();
            },
            tooltip: l10n.increaseQuantity,
          ),
        ],
      ),
    );
  }
}

/// The count, rolling the way it is counting.
///
/// A digit that simply swaps gives no sense of direction, which on a control
/// whose whole job is "up or down" is the one thing worth showing. The new
/// number arrives from the side the count is heading and the old one leaves
/// opposite it, the way a dial turns.
class _RollingCount extends StatelessWidget {
  const _RollingCount({
    required this.value,
    required this.direction,
    this.style,
  });

  final int value;
  final int direction;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Honour "reduce motion": the number still updates, it just stops moving.
    final bool still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ClipRect(
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 170),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        // Both digits occupy the same spot mid-roll rather than the default
        // stack sizing itself to the pair.
        layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
          alignment: Alignment.center,
          children: <Widget>[...previous, ?current],
        ),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // The outgoing child runs this animation in reverse, so flipping
          // the sign for it sends it out the far side instead of retreating
          // the way the incoming one came.
          final bool incoming = child.key == ValueKey<int>(value);
          final double dy = (incoming ? 1 : -1) * (direction > 0 ? 1.0 : -1.0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, dy * 0.9),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          '$value',
          key: ValueKey<int>(value),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
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
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Duration press = still
        ? Duration.zero
        : const Duration(milliseconds: 110);
    final Duration settle = still
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Tooltip(
      message: widget.tooltip,
      // The tooltip and the semantic label would otherwise both be announced,
      // giving "Decrease quantity, Decrease quantity".
      excludeFromSemantics: true,
      child: Semantics(
        label: widget.tooltip,
        button: true,
        enabled: widget.enabled,
        // Carried on this node because excluding the descendants takes the
        // ink response's own tap action with them.
        onTap: widget.enabled ? widget.onTap : null,
        excludeSemantics: true,
        child: InkResponse(
          onTap: widget.enabled ? widget.onTap : null,
          // The ripple alone doesn't read on a 20dp glyph, and the tap
          // already fires a selection haptic — this gives that click
          // something to look like.
          onTapDown: widget.enabled
              ? (TapDownDetails _) => _setPressed(true)
              : null,
          onTapUp: widget.enabled
              ? (TapUpDetails _) => _setPressed(false)
              : null,
          onTapCancel: widget.enabled ? () => _setPressed(false) : null,
          radius: widget.size / 2 + 4,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: AnimatedScale(
                scale: _pressed ? 0.72 : 1,
                duration: _pressed ? press : settle,
                // Springs back past 1 on release, so a quick tap feels like
                // a button and not a still image.
                curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
                child: AnimatedOpacity(
                  // A button that switches off at the stock ceiling should
                  // fade out of reach rather than blink into a paler colour.
                  opacity: widget.enabled ? 1 : 0.3,
                  duration: settle,
                  child: _SwappingIcon(
                    icon: widget.icon,
                    size: widget.size * 0.52,
                    color: theme.colorScheme.onSurface,
                    still: still,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cross-fades and turns when the glyph itself changes.
///
/// Only the bag does this — the minus becomes a bin on the last one — and a
/// straight swap there is abrupt enough to read as a glitch.
class _SwappingIcon extends StatelessWidget {
  const _SwappingIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.still,
  });

  final IconData icon;
  final double size;
  final Color color;
  final bool still;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: still ? Duration.zero : const Duration(milliseconds: 220),
    switchInCurve: Curves.easeOutBack,
    transitionBuilder: (Widget child, Animation<double> animation) =>
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
    child: Icon(icon, key: ValueKey<IconData>(icon), size: size, color: color),
  );
}
