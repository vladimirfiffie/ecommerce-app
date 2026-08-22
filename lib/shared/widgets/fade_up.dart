import 'package:material_ui/material_ui.dart';

/// Fades a child in as it rises the last few pixels into place.
///
/// Entrance only: it plays once, when the widget first appears, and holds
/// there. A rebuild from a badge count changing or a tab being tapped keeps
/// the same [State], so nothing replays underneath the user. [delay] is what
/// staggers a row or a list — one step per item.
class FadeUp extends StatefulWidget {
  const FadeUp({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.rise = 12,
    super.key,
  });

  /// Item [index] of a run, starting one [step] later than the one before it.
  ///
  /// A plain factory rather than a constructor: the delay is computed, so
  /// there is nothing const about it.
  static FadeUp at(
    int index, {
    required Widget child,
    Duration step = const Duration(milliseconds: 55),
    Duration duration = const Duration(milliseconds: 320),
    double rise = 12,
    Key? key,
  }) => FadeUp(
    key: key,
    delay: step * index,
    duration: duration,
    rise: rise,
    child: child,
  );

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far below its resting place the child starts, in logical pixels.
  final double rise;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..forward();

  // The stagger is dead time at the front of the controller rather than a
  // pending timer, so there is nothing to cancel if the item is disposed
  // before its turn comes round.
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour "reduce motion": the child is simply already in place.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _progress,
      // A fully transparent child is dropped from the semantics tree by
      // default, which pulls the tap action out from under a nav item for as
      // long as its turn takes to come round.
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (BuildContext context, Widget? child) => Transform.translate(
          offset: Offset(0, widget.rise * (1 - _progress.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
