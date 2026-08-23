import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/confirm.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/rating_stars.dart';
import '../../state/app_providers.dart';
import '../../state/reviews_provider.dart';

/// Everything this device has written, in one place.
///
/// Reviews were only ever visible on the product they were about, which
/// meant the only way to find one again was to remember what it was for.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button would have
  /// nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<UserReview> mine = ref.watch(userReviewsProvider);
    final Catalog catalog = ref.watch(catalogDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your reviews'),
        automaticallyImplyLeading: !embedded,
      ),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              message:
                  'Once an order arrives you can say what you thought of it. '
                  'Anything you write shows up here.',
              actionLabel: 'Your orders',
              onAction: () => context.push(Routes.orders),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: mine.length,
              separatorBuilder: (BuildContext context, int _) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) => _MyReviewCard(
                review: mine[i],
                // A product that has left the catalog still has a review
                // worth showing — it just can't be opened any more.
                product: catalog.byId(mine[i].productId),
              ),
            ),
    );
  }
}

class _MyReviewCard extends ConsumerWidget {
  const _MyReviewCard({required this.review, required this.product});

  final UserReview review;
  final Product? product;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Delete this review?',
      message: 'It comes off the product page as well.',
      confirmLabel: 'Delete',
    );
    if (yes) {
      await ref.read(userReviewsProvider.notifier).delete(review.productId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Product? item = product;

    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (item != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: AppImage(url: item.thumbnail),
                    ),
                  ),
                if (item != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item?.name ?? 'A product we no longer carry',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      RatingStars(
                        rating: review.rating,
                        size: 13,
                        showValue: false,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            if (review.title.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(review.title, style: theme.textTheme.titleSmall),
            ],
            if (review.body.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                review.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (review.photos.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photos.length,
                  separatorBuilder: (BuildContext _, int _) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext _, int i) => SizedBox(
                    width: 64,
                    child: AppImage(
                      url: review.photos[i],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  review.toReview().timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (item != null)
                  TextButton(
                    onPressed: () => context.push(Routes.product(item.id)),
                    child: const Text('Open product'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
