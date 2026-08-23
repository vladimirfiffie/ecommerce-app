import 'package:flutter_animate/flutter_animate.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../core/theme/app_theme.dart';
import '../../state/haptics_provider.dart';
import 'dart:math' as math;
import 'dart:async';

/// Adaptive wrappers around `haptic_kit`'s widgets.
///
/// Several of them ([HapticToggle], [HapticSlider], [HapticStepper],
/// [HapticRating], [SlideToConfirm], [PressAndHoldToConfirm]) fire haptics
/// internally with no way to switch that off, and they call into a plugin that
/// only exists on Android and iOS. Each wrapper below therefore renders the
/// haptic version only when the relevant channel is live, and a plain Material
/// equivalent otherwise — so the settings screen's master switch actually
/// silences the app instead of muting only half of it.

/// Switch that ticks on flip.
class AsterToggle extends ConsumerWidget {
  const AsterToggle({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HapticService haptics = ref.watch(hapticsProvider);
    if (!haptics.isOn(HapticChannel.selection) || onChanged == null) {
      return Switch.adaptive(value: value, onChanged: onChanged);
    }
    return HapticToggle(
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Slider that ticks as it crosses detents.
class AsterSlider extends ConsumerWidget {
  const AsterSlider({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    super.key,
    this.divisions,
    this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HapticService haptics = ref.watch(hapticsProvider);
    final double safeValue = value.clamp(min, max);

    if (!haptics.isOn(HapticChannel.selection)) {
      return AdaptiveSlider(
        value: safeValue,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      );
    }
    return HapticSlider(
      value: safeValue,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      activeColor: Theme.of(context).colorScheme.primary,
      tickStyle: haptics.scale(HapticImpactStyle.light),
      endTickStyle: haptics.scale(HapticImpactStyle.medium),
      onChanged: onChanged,
    );
  }
}

/// Star rating with a cascading fill.
class AsterRating extends ConsumerStatefulWidget {
  const AsterRating({
    required this.value,
    required this.onChanged,
    super.key,
    this.starCount = 5,
    this.size = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int starCount;
  final double size;

  @override
  ConsumerState<AsterRating> createState() => _AsterRatingState();
}

/// Star rating that animates the same way whether or not haptics are on.
///
/// It draws its own stars rather than delegating to haptic_kit's widget: that
/// one only appears when haptics are enabled, so the control jumped between
/// two different animations depending on a settings toggle. Haptic feedback
/// still goes through [HapticService], so nothing is lost with haptics on.
class _AsterRatingState extends ConsumerState<AsterRating>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFF5A623);

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  /// The rating before the last change, so only newly-lit stars pop.
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _previous = widget.value;
  }

  @override
  void didUpdateWidget(AsterRating old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previous = old.value;
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _set(int stars) {
    if (stars == widget.value) return;
    unawaited(ref.read(hapticsProvider).selection());
    widget.onChanged(stars);
  }

  /// Which star sits under [dx], so a drag across the row rates continuously.
  int _starAt(double dx, double width) {
    final double each = width / widget.starCount;
    return (dx / each).floor().clamp(0, widget.starCount - 1) + 1;
  }

  /// Scale for star [i], popping in sequence as the rating rises.
  double _scaleFor(int i) {
    if (i <= _previous || i > widget.value) return 1;
    final int position = i - _previous - 1;
    final double start = (position * 0.1).clamp(0.0, 0.6);
    final double t = ((_pop.value - start) / 0.4).clamp(0.0, 1.0);
    // A single sine hump: 1 → 1.3 → 1, with no overshoot past the ends.
    return 1 + 0.3 * math.sin(math.pi * t);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double totalWidth = widget.size * widget.starCount;

    return Semantics(
      slider: true,
      value: '${widget.value} of ${widget.starCount} stars',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails d) =>
            _set(_starAt(d.localPosition.dx, totalWidth)),
        onHorizontalDragUpdate: (DragUpdateDetails d) =>
            _set(_starAt(d.localPosition.dx, totalWidth)),
        child: SizedBox(
          width: totalWidth,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _pop,
            builder: (BuildContext context, Widget? child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 1; i <= widget.starCount; i++)
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Center(
                      child: Transform.scale(
                        scale: _scaleFor(i),
                        child: Icon(
                          i <= widget.value
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: widget.size * 0.86,
                          color: i <= widget.value
                              ? _gold
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slide-to-confirm pill, falling back to a plain button.
///
/// Once it has been slid it stays confirmed — green, with a tick — rather
/// than snapping back to an idle control. Placing an order takes a beat, and
/// a slider that looks untouched while it happens invites a second slide.
class AsterSlideToConfirm extends ConsumerStatefulWidget {
  const AsterSlideToConfirm({
    required this.label,
    required this.fallbackLabel,
    required this.onConfirmed,
    super.key,
  });

  final String label;

  /// Shown on the plain button when sliding isn't available.
  final String fallbackLabel;
  final VoidCallback onConfirmed;

  @override
  ConsumerState<AsterSlideToConfirm> createState() =>
      _AsterSlideToConfirmState();
}

class _AsterSlideToConfirmState extends ConsumerState<AsterSlideToConfirm> {
  bool _confirmed = false;

  void _confirm() {
    if (_confirmed) return;
    setState(() => _confirmed = true);
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (_confirmed) {
      return _ConfirmedPill(label: widget.label);
    }

    final HapticService haptics = ref.watch(hapticsProvider);
    if (!haptics.isOn(HapticChannel.buttons)) {
      return FilledButton.icon(
        onPressed: _confirm,
        icon: const Icon(Icons.lock_outline_rounded, size: 18),
        label: Text(widget.fallbackLabel),
      );
    }
    return SlideToConfirm(
      label: widget.label,
      onConfirmed: _confirm,
      trackColor: scheme.primaryContainer,
      handleColor: scheme.primary,
      textColor: scheme.onPrimaryContainer,
    );
  }
}

/// What the slider becomes once it has been slid.
class _ConfirmedPill extends StatelessWidget {
  const _ConfirmedPill({required this.label});

  /// Kept for the screen reader, which should hear what was confirmed rather
  /// than only that something was.
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    enabled: false,
    liveRegion: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.success,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Center(
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 26)
            .animate()
            .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              duration: 260.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 160.ms),
      ),
    ),
  );
}

/// Hold-to-confirm target for destructive actions. Without haptics it becomes
/// a normal button — the caller still confirms via dialog either way.
class AsterHoldToConfirm extends ConsumerWidget {
  const AsterHoldToConfirm({
    required this.onConfirm,
    required this.label,
    required this.icon,
    super.key,
    this.holdDuration = const Duration(milliseconds: 1400),
    this.destructive = false,
  });

  final VoidCallback onConfirm;
  final String label;
  final IconData icon;
  final Duration holdDuration;
  final bool destructive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final HapticService haptics = ref.watch(hapticsProvider);
    final Color color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final Widget face = Container(
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            haptics.isOn(HapticChannel.buttons) ? 'Hold to $label' : label,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );

    if (!haptics.isOn(HapticChannel.buttons)) {
      return InkWell(
        onTap: onConfirm,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: face,
      );
    }
    return PressAndHoldToConfirm(
      onConfirm: onConfirm,
      holdDuration: holdDuration,
      ringColor: color,
      child: face,
    );
  }
}

/// −/+ counter that bounces and ticks.
class AsterStepper extends ConsumerWidget {
  const AsterStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 99,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HapticService haptics = ref.watch(hapticsProvider);
    if (!haptics.isOn(HapticChannel.selection)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.filledTonal(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      );
    }
    return HapticStepper(
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
    );
  }
}

/// Tap wrapper with a squash-and-settle bounce.
///
/// [HapticBounce] takes a `haptics` flag, so this only has to forward the
/// setting rather than swap the widget out.
class AsterBounce extends ConsumerWidget {
  const AsterBounce({
    required this.child,
    super.key,
    this.onTap,
    this.bounceOnRelease = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool bounceOnRelease;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HapticBounce(
    onTap: onTap,
    bounceOnRelease: bounceOnRelease,
    haptics: ref.watch(hapticsProvider).isOn(HapticChannel.buttons),
    child: child,
  );
}
