import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/review.dart';
import '../../../shared/widgets/rating_stars.dart';

/// Rating summary, star histogram, and the review list.
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (product.reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Reviews', style: theme.textTheme.titleLarge),
              const SizedBox(width: 8),
              Text(
                '(${formatCount(product.reviewCount)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    RatingStars(
                      rating: product.rating,
                      showValue: false,
                      size: 14,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCount(product.reviewCount)} ratings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(child: _Histogram(rating: product.rating)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final Review review in product.reviews)
            _ReviewTile(review: review),
        ],
      ),
    );
  }
}

/// Approximates a star distribution from the average, which is all the mock
/// catalog carries. Purely presentational.
class _Histogram extends StatelessWidget {
  const _Histogram({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<double> weights = <double>[
      for (int star = 5; star >= 1; star--)
        (1 - ((rating - star).abs() / 4)).clamp(0.03, 1).toDouble(),
    ];
    final double sum = weights.fold(0, (double a, double b) => a + b);

    return Column(
      children: <Widget>[
        for (int i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 12,
                  child: Text(
                    '${5 - i}',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: weights[i] / sum,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 17,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  review.initials,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(review.author, style: theme.textTheme.titleSmall),
                    Text(
                      review.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              RatingStars(rating: review.rating, size: 13, showValue: false),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
