import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/review.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../state/reviews_provider.dart';
import 'write_review_sheet.dart';

/// Rating summary, star histogram, and the review list.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Review> reviews = ref.watch(productReviewsProvider(product));
    final ({double rating, int count}) summary = ref.watch(
      productRatingProvider(product),
    );
    final UserReview? mine = ref.watch(myReviewProvider(product.id));
    final bool purchased = ref.watch(canReviewProvider(product.id));

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
                '(${formatCount(summary.count)})',
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
                      summary.rating.toStringAsFixed(1),
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    RatingStars(
                      rating: summary.rating,
                      showValue: false,
                      size: 14,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCount(summary.count)} ratings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(child: _Histogram(rating: summary.rating)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _WriteCta(product: product, mine: mine, purchased: purchased),
          const SizedBox(height: 4),
          for (int i = 0; i < reviews.length; i++)
            _ReviewTile(review: reviews[i], isMine: mine != null && i == 0),
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
  const _ReviewTile({required this.review, this.isMine = false});

  final Review review;
  final bool isMine;

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
                    Row(
                      children: <Widget>[
                        Text(review.author, style: theme.textTheme.titleSmall),
                        if (isMine) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Your review',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

/// Prompt to write, or a shortcut to edit what's already there.
class _WriteCta extends StatelessWidget {
  const _WriteCta({
    required this.product,
    required this.mine,
    required this.purchased,
  });

  final Product product;
  final UserReview? mine;

  /// Reviews are limited to shoppers who actually bought the item.
  final bool purchased;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (mine != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => showWriteReviewSheet(context, product),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit your review'),
        ),
      );
    }
    if (!purchased) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.verified_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Only verified buyers can review this item.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        onPressed: () => showWriteReviewSheet(context, product),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text('Write a review'),
      ),
    );
  }
}
