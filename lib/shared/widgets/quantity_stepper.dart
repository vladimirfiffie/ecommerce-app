import 'dart:async';

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

  /// True while a button is repeating under a held finger.
  bool _repeating = false;

  void _setRepeating(bool value) {
    if (_repeating != value) setState(() => _repeating = value);
  }

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
            onStep: widget.onDecrement,
            onRepeatingChanged: _setRepeating,
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
                instant: _repeating,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            enabled: widget.quantity < widget.max,
            onStep: widget.onIncrement,
            onRepeatingChanged: _setRepeating,
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
    required this.instant,
    this.style,
  });

  final int value;
  final int direction;
  final TextStyle? style;

  /// Set while the button is repeating under a held finger, where rolling
  /// each number in turn is a blur nobody can read.
  final bool instant;

  @override
  Widget build(BuildContext context) {
    // Honour "reduce motion": the number still updates, it just stops moving.
    final bool still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ClipRect(
      child: AnimatedSwitcher(
        // Short: this is a nudge in the direction of travel, not a journey.
        // It used to run half again as long over three times the distance,
        // which on a two-character box looked like the number was falling.
        duration: still || instant
            ? Duration.zero
            : const Duration(milliseconds: 120),
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
                begin: Offset(0, dy * 0.28),
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
    required this.onStep,
    required this.onRepeatingChanged,
    required this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final double size;

  /// One step up or down. Called once per tap, and repeatedly while held.
  final VoidCallback onStep;

  /// Raised while a hold is running, so the count can stop rolling through
  /// every number a fast repeat passes.
  final ValueChanged<bool> onRepeatingChanged;

  final String tooltip;
  final bool enabled;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  /// How long a press has to be held before it starts repeating. Long enough
  /// that an ordinary tap never trips it.
  static const Duration _holdDelay = Duration(milliseconds: 350);

  /// Repeat rate: the first few steps are readable, then it speeds up, so
  /// going from 1 to 30 is a hold rather than thirty taps.
  static const Duration _firstInterval = Duration(milliseconds: 160);
  static const Duration _fastInterval = Duration(milliseconds: 55);
  static const int _stepsBeforeFast = 5;

  /// A buzz per step at the fast rate is a rattle, so most of them are
  /// dropped once it gets going.
  static const int _hapticEveryNSteps = 4;

  Timer? _timer;
  int _steps = 0;

  @override
  void didUpdateWidget(_StepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hitting the stock ceiling switches the button off mid-hold; the finger
    // is still down, so nothing else would stop the repeat.
    //
    // The counting stops here and now. Saying so has to wait for the frame
    // to finish, because this runs inside one and both halves of _endHold
    // call setState.
    if (!widget.enabled && _timer != null) {
      _timer!.cancel();
      _timer = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _endHold();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// One step, with the haptic that belongs to it.
  void _step({required bool repeated}) {
    if (!widget.enabled) {
      _endHold();
      return;
    }
    if (!repeated || _steps % _hapticEveryNSteps == 0) {
      HapticFeedback.selectionClick();
    }
    widget.onStep();
  }

  void _beginHold() {
    _timer = Timer(_holdDelay, _repeat);
  }

  void _repeat() {
    if (!mounted || !widget.enabled) {
      _endHold();
      return;
    }
    _steps++;
    if (_steps == 1) widget.onRepeatingChanged(true);
    _step(repeated: true);
    _timer = Timer(
      _steps < _stepsBeforeFast ? _firstInterval : _fastInterval,
      _repeat,
    );
  }

  void _endHold() {
    _timer?.cancel();
    _timer = null;
    if (_steps > 0) {
      _steps = 0;
      widget.onRepeatingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Duration settle = still
        ? Duration.zero
        : const Duration(milliseconds: 200);

    // No tooltip wrapper here, adaptive or Material.
    //
    // A tooltip has to register a long-press recogniser, and on this button
    // the long press is hold-to-repeat: the recogniser wins the arena half a
    // second in, cancels the tap underneath and kills the hold after a single
    // step. The Material tooltip was already set to triggerMode.manual to
    // give that gesture back, which meant it never appeared on a touch
    // screen — on Android and iOS it drew nothing and cost a widget. The
    // name is still announced, by the Semantics node below.
    return Semantics(
      label: widget.tooltip,
      button: true,
      enabled: widget.enabled,
      // Carried on this node because excluding the descendants takes the
      // ink response's own tap action with them.
      onTap: widget.enabled ? () => _step(repeated: false) : null,
      excludeSemantics: true,
      child: InkResponse(
        // A tap that turned into a hold has already counted its steps, so
        // releasing must not add one more on top.
        onTap: widget.enabled
            ? () {
                if (_steps == 0) _step(repeated: false);
                _endHold();
              }
            : null,
        onTapDown: widget.enabled ? (TapDownDetails _) => _beginHold() : null,
        onTapCancel: widget.enabled ? _endHold : null,
        radius: widget.size / 2 + 4,
        child: SizedBox(
          // No press animation of its own: the ink ripple spreading from
          // the touch is the feedback. Scaling the glyph and fading a
          // circle behind it were both read as a pulse, which is the
          // wrong note for a button you tap repeatedly or lean on.
          width: widget.size,
          height: widget.size,
          child: Center(
            child: AnimatedOpacity(
              // A button that switches off at the stock ceiling should
              // fade out of reach rather than blink into a paler color.
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
