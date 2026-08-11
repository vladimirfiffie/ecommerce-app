import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Five-star display with an optional `4.6 (1.2k)` label.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    super.key,
    this.reviewCount,
    this.size = 15,
    this.showValue = true,
  });

  final double rating;
  final int? reviewCount;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color starColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFC53D)
        : const Color(0xFFF5A623);

    // Five stars plus labels don't fit a narrow card (two-pane lists, small
    // phones). Below a threshold, collapse to a single star and the number —
    // still legible, never clipped.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double needed =
            size * 5 + (showValue ? 34 : 0) + (reviewCount != null ? 40 : 0);
        final bool compact =
            constraints.hasBoundedWidth && constraints.maxWidth < needed;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (compact)
              Icon(Icons.star_rounded, size: size, color: starColor)
            else
              for (int i = 0; i < 5; i++)
                Icon(
                  rating >= i + 1
                      ? Icons.star_rounded
                      : rating >= i + 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
                  size: size,
                  color: starColor,
                ),
            if (showValue || compact) ...<Widget>[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  rating.toStringAsFixed(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
            if (reviewCount != null) ...<Widget>[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '(${formatCount(reviewCount!)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
