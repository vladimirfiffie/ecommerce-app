import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tick that draws itself inside a ring that sweeps closed.
///
/// Deliberately finite — it plays once and stops. A looping success animation
/// would hang every `pumpAndSettle` in the test suite, and reads as a spinner
/// rather than a confirmation.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({
    required this.color,
    super.key,
    this.size = 108,
    this.duration = const Duration(milliseconds: 900),
  });

  final Color color;
  final double size;
  final Duration duration;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// The ring closes first, then the tick is drawn inside it, then a soft
  /// halo expands out — sequenced rather than simultaneous so the eye has
  /// something to follow.
  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _halo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CheckPainter(
          color: widget.color,
          ring: _ring.value,
          tick: _tick.value,
          halo: _halo.value,
        ),
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.color,
    required this.ring,
    required this.tick,
    required this.halo,
  });

  final Color color;

  /// 0–1 progress of the ring sweep, the tick stroke, and the halo.
  final double ring;
  final double tick;
  final double halo;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double radius = size.width / 2 - size.width * 0.06;

    // Halo: expands past the ring and fades out as it goes.
    if (halo > 0 && halo < 1) {
      canvas.drawCircle(
        centre,
        radius * (1 + halo * 0.35),
        Paint()
          ..color = color.withValues(alpha: 0.18 * (1 - halo))
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = color.withValues(alpha: 0.14 * ring),
    );

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.055;

    // Ring sweeps from 12 o'clock.
    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2,
        2 * math.pi * ring,
        false,
        stroke,
      );
    }

    if (tick <= 0) return;

    // Tick geometry as fractions of the box, so it scales with `size`.
    final Offset start = Offset(size.width * 0.30, size.height * 0.52);
    final Offset elbow = Offset(size.width * 0.44, size.height * 0.66);
    final Offset end = Offset(size.width * 0.72, size.height * 0.37);

    final double shortLeg = (elbow - start).distance;
    final double longLeg = (end - elbow).distance;
    final double drawn = (shortLeg + longLeg) * tick;

    final Path path = Path()..moveTo(start.dx, start.dy);
    if (drawn <= shortLeg) {
      final Offset p = Offset.lerp(start, elbow, drawn / shortLeg)!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(elbow.dx, elbow.dy);
      final Offset p = Offset.lerp(elbow, end, (drawn - shortLeg) / longLeg)!;
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.ring != ring ||
      old.tick != tick ||
      old.halo != halo ||
      old.color != color;
}
