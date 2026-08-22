import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../state/for_you_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/models/order.dart';
import '../../../core/l10n/enum_labels.dart';

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
    ForYouKind.orderInTransit => Icons.local_shipping_outlined,
    ForYouKind.orderDelivered => Icons.check_circle_outline_rounded,
    ForYouKind.returnInProgress => Icons.assignment_return_outlined,
    ForYouKind.backInStock => Icons.inventory_2_outlined,
    ForYouKind.priceDrop => Icons.trending_down_rounded,
    ForYouKind.lowStockSaved => Icons.hourglass_bottom_rounded,
    ForYouKind.inBag => Icons.shopping_bag_outlined,
    ForYouKind.pickUpWhereYouLeftOff => Icons.history_rounded,
  };

  /// Order rows lead with the kind's icon even though no product is attached,
  /// and a delivered parcel earns green rather than the card's usual accent.
  Color _iconColor(ThemeData theme) => switch (item.kind) {
    ForYouKind.orderDelivered => AppTheme.success,
    ForYouKind.lowStockSaved => theme.colorScheme.error,
    _ => theme.colorScheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            // The product's own picture when there is one; the kind's icon
            // otherwise, so bag and order rows still read at a glance.
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
                child: Icon(_icon, size: 19, color: _iconColor(theme)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _subtitle(context, item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.progress
                      case final OrderProgress progress) ...<Widget>[
                    const SizedBox(height: 8),
                    _ProgressTrack(progress: progress, kind: item.kind),
                  ],
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

  /// Order rows carry their status as an enum, so the word for it gets chosen
  /// here rather than in the provider that has no context to choose with.
  static String _subtitle(BuildContext context, ForYouItem item) {
    final OrderStatus? status = item.orderStatus;
    if (status == null) return item.subtitle;
    return '${item.subtitle} · ${status.labelIn(AppL10n.of(context))}';
  }
}

/// Processing → shipped → delivered, as three segments.
///
/// Segments rather than a single bar: the stages are discrete, and a
/// continuous fill would imply the app knows where the van is.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress, required this.kind});

  final OrderProgress progress;
  final ForYouKind kind;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color done = kind == ForYouKind.orderDelivered
        ? AppTheme.success
        : theme.colorScheme.primary;
    final Color todo = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.22,
    );

    return Row(
      children: <Widget>[
        for (int i = 0; i < progress.stageCount; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: i <= progress.stage ? done : todo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
