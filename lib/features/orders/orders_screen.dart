import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill.dart';
import '../../state/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message:
                  'When you place an order it’ll appear here with its '
                  'delivery status.',
              actionLabel: 'Browse the shop',
              onAction: () => context.go(Routes.catalog),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: orders.length,
              separatorBuilder: (BuildContext c, int i) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) =>
                  OrderCard(order: orders[index])
                      .animate(delay: (index * 50).ms)
                      .fadeIn(duration: 240.ms)
                      .moveY(begin: 12, end: 0),
            ),
    );
  }
}

/// Summary card: status, thumbnails, total.
class OrderCard extends ConsumerWidget {
  const OrderCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<CartItem> items = ref.watch(orderItemsProvider(order.id));

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.order(order.id)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(order.id, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          formatDate(order.placedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: Row(
                  children: <Widget>[
                    for (final CartItem item in items.take(4))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 52,
                          child: AppImage(
                            url: item.product.thumbnail,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    if (items.length > 4)
                      Text(
                        '+${items.length - 4}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatPrice(order.total),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color bg, Color fg, IconData icon) = switch (status) {
      OrderStatus.processing => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        Icons.hourglass_top_rounded,
      ),
      OrderStatus.shipped => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.local_shipping_rounded,
      ),
      OrderStatus.delivered => (
        AppTheme.success.withValues(alpha: 0.16),
        AppTheme.success,
        Icons.check_circle_rounded,
      ),
      OrderStatus.cancelled => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.cancel_outlined,
      ),
      OrderStatus.returnRequested => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.assignment_return_outlined,
      ),
      OrderStatus.refunded => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        Icons.replay_circle_filled_rounded,
      ),
    };

    return Pill(
      label: status.label.toUpperCase(),
      background: bg,
      foreground: fg,
      icon: icon,
    );
  }
}
