import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/cart_provider.dart';
import '../../../state/profile_provider.dart';

/// Greeting + brand mark + a tap-through search field.
class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int cartCount = ref.watch(cartCountProvider);
    final String greeting = ref.watch(greetingProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Nova',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => context.push(Routes.orders),
                  tooltip: 'Your orders',
                  icon: const Icon(Icons.receipt_long_rounded),
                ),
                const SizedBox(width: 8),
                Badge.count(
                  count: cartCount,
                  isLabelVisible: cartCount > 0,
                  backgroundColor: theme.colorScheme.error,
                  textColor: theme.colorScheme.onError,
                  child: IconButton.filledTonal(
                    onPressed: () => context.go(Routes.cart),
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SearchBarButton(onTap: () => context.push(Routes.search)),
          ],
        ),
      ),
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search products, brands…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
