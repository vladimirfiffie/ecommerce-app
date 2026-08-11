import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/for_you_provider.dart';
import '../../../shared/widgets/app_image.dart';

/// The things the app already knows about you, surfaced on home.
///
/// Renders nothing at all when there's nothing to say — a permanent empty
/// "For you" heading is worse than no heading.
class ForYouCard extends ConsumerWidget {
  const ForYouCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<ForYouItem> items = ref.watch(forYouProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'For you',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < items.length; i++)
              _ForYouRow(item: items[i])
                  .animate(delay: (i * 70).ms)
                  .fadeIn(duration: 240.ms)
                  .moveX(begin: -8, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _ForYouRow extends StatelessWidget {
  const _ForYouRow({required this.item});

  final ForYouItem item;

  IconData get _icon => switch (item.kind) {
    ForYouKind.backInStock => Icons.inventory_2_outlined,
    ForYouKind.priceDrop => Icons.trending_down_rounded,
    ForYouKind.inBag => Icons.shopping_bag_outlined,
    ForYouKind.pickUpWhereYouLeftOff => Icons.history_rounded,
  };

  void _open(BuildContext context) {
    switch (item.kind) {
      case ForYouKind.inBag:
        context.go(Routes.cart);
      case ForYouKind.priceDrop when item.count > 1:
        context.go(Routes.favorites);
      case ForYouKind.backInStock:
      case ForYouKind.priceDrop:
      case ForYouKind.pickUpWhereYouLeftOff:
        final String? id = item.product?.id;
        if (id != null) context.push(Routes.product(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            // The product's own picture when there is one; the kind's icon
            // otherwise, so bag and multi-item rows still read at a glance.
            if (item.product != null)
              SizedBox(
                width: 40,
                height: 40,
                child: AppImage(
                  url: item.product!.thumbnail,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(_icon, size: 19, color: theme.colorScheme.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
