import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/review.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../state/reviews_provider.dart';
import 'write_review_sheet.dart';

/// Rating summary, star histogram, and the review list.
class ReviewsSection extends ConsumerStatefulWidget {
  const ReviewsSection({
    required this.product,
    super.key,
    this.showAll = false,
  });

  final Product product;

  /// The product page shows the first few and links onwards; the reviews
  /// page shows the lot.
  final bool showAll;

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  /// Null means everything. Otherwise a tag, or [_photosFilter].
  String? _filter;

  /// Not a tag: "show me the ones with pictures".
  static const String _photosFilter = 'With photos';

  /// How many reviews the product page shows before handing over.
  static const int _previewCount = 3;

  bool _matches(Review review) => switch (_filter) {
    null => true,
    _photosFilter => review.photos.isNotEmpty,
    final String tag => review.tags.contains(tag),
  };

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    final ThemeData theme = Theme.of(context);
    final List<Review> reviews = ref.watch(productReviewsProvider(product));
    final ({double rating, int count}) summary = ref.watch(
      productRatingProvider(product),
    );
    final UserReview? mine = ref.watch(myReviewProvider(product.id));
    final bool purchased = ref.watch(canReviewProvider(product.id));
    final List<Review> matching = reviews.where(_matches).toList();
    final bool trimmed = !widget.showAll && matching.length > _previewCount;
    final List<Review> shown = trimmed
        ? matching.take(_previewCount).toList()
        : matching;

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
          _FilterRow(
            reviews: reviews,
            selected: _filter,
            photosLabel: _photosFilter,
            onSelected: (String? value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 4),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'No reviews mention that yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (int i = 0; i < shown.length; i++)
            _ReviewTile(
              review: shown[i],
              isMine: mine != null && shown[i] == reviews.first && i == 0,
            ),
          if (trimmed) ...<Widget>[
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => context.push(Routes.productReviews(product.id)),
              child: Text('See all ${matching.length} reviews'),
            ),
            const SizedBox(height: 8),
          ],
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
                        if (review.verified && !isMine) ...<Widget>[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Bought this from the shop',
                            child: Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      review.verified && !isMine
                          ? '${review.timeAgo} · Verified buyer'
                          : review.timeAgo,
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
          if (review.tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String tag in review.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(tag, style: theme.textTheme.labelSmall),
                  ),
              ],
            ),
          ],
          if (review.photos.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (BuildContext context, int _) =>
                    const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int i) => GestureDetector(
                  onTap: () => _openPhoto(context, review.photos, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: AppImage(url: review.photos[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Full-bleed look at a customer photo, dismissed by tapping it.
  void _openPhoto(BuildContext context, List<String> photos, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, Animation<double> animation, _) =>
            FadeTransition(
              opacity: animation,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: AppImage(
                        url: photos[index],
                        fit: BoxFit.contain,
                        backgroundColor: Colors.transparent,
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

/// Chips for the subjects this product's reviews actually cover.
///
/// Built from the reviews in hand rather than the full tag list: offering a
/// filter that can only ever return nothing is worse than not offering it.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.reviews,
    required this.selected,
    required this.photosLabel,
    required this.onSelected,
  });

  final List<Review> reviews;
  final String? selected;
  final String photosLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = <String, int>{};
    for (final Review review in reviews) {
      for (final String tag in review.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final int withPhotos = reviews
        .where((Review r) => r.photos.isNotEmpty)
        .length;
    if (counts.isEmpty && withPhotos == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ChoiceChip(
              label: Text('All ${reviews.length}'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final String tag in Review.allTags)
              if (counts[tag] case final int n)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text('$tag $n'),
                    selected: selected == tag,
                    onSelected: (bool on) => onSelected(on ? tag : null),
                  ),
                ),
            if (withPhotos > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  avatar: const Icon(Icons.photo_outlined, size: 16),
                  label: Text('$photosLabel $withPhotos'),
                  selected: selected == photosLabel,
                  onSelected: (bool on) => onSelected(on ? photosLabel : null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
