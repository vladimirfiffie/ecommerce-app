import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../state/price_history_provider.dart';

/// What this product has cost while the app has been watching it.
///
/// Only ever says what it has actually seen. There is no backend keeping a
/// year of prices, so the section leads with how long the record is rather
/// than drawing a line that implies more history than exists.
class PriceHistorySection extends ConsumerWidget {
  const PriceHistorySection({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PriceHistory history = ref.watch(priceHistoryForProvider(product.id));
    if (history.isEmpty) return const SizedBox.shrink();

    final int days = history.daysTracked;

    // One reading is a price, not a history. Until there are two, the only
    // thing that can honestly be said is that the watching has started.
    final String headline = switch (history) {
      PriceHistory(atLowest: true) => 'Lowest price we’ve seen',
      PriceHistory(hasMoved: true, changeSinceStart: final double d)
          when d < 0 =>
        'Down ${formatPrice(-d)} since we started watching',
      PriceHistory(hasMoved: true, changeSinceStart: final double d)
          when d > 0 =>
        'Up ${formatPrice(d)} since we started watching',
      PriceHistory(hasMoved: true) => 'It has moved, and come back',
      _ when days <= 1 => 'Watching this price from today',
      _ => 'The price hasn’t moved in $days days',
    };
    final String period = days <= 1
        ? 'watching since today'
        : 'watching for $days days';

    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                history.atLowest
                    ? Icons.trending_down_rounded
                    : Icons.show_chart_rounded,
                size: 19,
                color: history.atLowest
                    ? AppTheme.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: history.atLowest ? AppTheme.success : null,
                  ),
                ),
              ),
            ],
          ),
          if (history.hasMoved) ...<Widget>[
            const SizedBox(height: 14),
            Semantics(
              // The line itself says nothing to a screen reader, so the
              // numbers it is drawn from are said instead.
              label:
                  'Price history, $period. '
                  'Lowest ${formatPrice(history.lowest)}, '
                  'highest ${formatPrice(history.highest)}, '
                  'now ${formatPrice(history.currentPrice)}.',
              excludeSemantics: true,
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    history: history,
                    line: theme.colorScheme.primary,
                    fill: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _Stat(label: 'Lowest', value: formatPrice(history.lowest)),
                const SizedBox(width: 24),
                _Stat(label: 'Highest', value: formatPrice(history.highest)),
                const Spacer(),
                _Stat(label: 'Now', value: formatPrice(history.currentPrice)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            // The honest caveat, said once: the record starts when you first
            // look, because that is the only moment the app can see a price.
            'Aster notes the price each day you open this page — $period.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

/// A price line, drawn against calendar days rather than reading order.
///
/// Spacing points evenly would draw a fortnight's gap the same width as an
/// overnight one, which is the one thing a price chart must not do.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.history,
    required this.line,
    required this.fill,
  });

  final PriceHistory history;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final List<PricePoint> points = history.points;
    if (points.length < 2) return;

    final int firstDay = points.first.day;
    final int span = points.last.day - firstDay;
    final double low = history.lowest;
    final double range = history.highest - low;

    Offset at(PricePoint p) => Offset(
      span == 0 ? size.width : (p.day - firstDay) / span * size.width,
      range == 0
          ? size.height / 2
          : size.height - (p.price - low) / range * size.height,
    );

    final Path path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final PricePoint p in points.skip(1)) {
      final Offset o = at(p);
      path.lineTo(o.dx, o.dy);
    }

    final Path area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(at(points.first).dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(at(points.last), 3.5, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.history.points != history.points ||
      old.line != line ||
      old.fill != fill;
}
