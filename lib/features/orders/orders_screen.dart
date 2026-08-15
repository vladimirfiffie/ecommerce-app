import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_line.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill.dart';
import '../../state/orders_provider.dart';
import 'order_detail_screen.dart';
import '../../core/layout/two_pane.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = ref.watch(ordersProvider);
    final bool twoPane = useTwoPane(context);

    // Default to the newest order so the pane is never pointlessly empty.
    final String? selected = !twoPane || orders.isEmpty
        ? null
        : orders.any((Order o) => o.id == _selectedId)
        ? _selectedId
        : orders.first.id;

    final Widget master = orders.isEmpty
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
                OrderCard(
                      order: orders[index],
                      selected: orders[index].id == selected,
                      onTap: twoPane
                          ? () => setState(() => _selectedId = orders[index].id)
                          : null,
                    )
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 240.ms)
                    .moveY(begin: 12, end: 0),
          );

    if (!twoPane) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your orders')),
        body: master,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: TwoPane(
        list: master,
        detail: selected == null
            ? null
            : DetailPaneSurface(
                child: OrderDetailScreen(
                  key: ValueKey<String>(selected),
                  orderId: selected,
                  embedded: true,
                ),
              ),
        placeholder: const TwoPanePlaceholder(
          icon: Icons.receipt_long_outlined,
          message: 'Choose an order to see its details.',
        ),
      ),
    );
  }
}

/// Summary card: status, thumbnails, total.
class OrderCard extends ConsumerWidget {
  const OrderCard({
    required this.order,
    super.key,
    this.selected = false,
    this.onTap,
  });

  final Order order;

  /// Highlighted as the current order in a two-pane layout.
  final bool selected;

  /// Overrides the default push-a-route behaviour.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<OrderLine> items = ref.watch(orderItemsProvider(order.id));
    // Keeps the status pill honest while the list sits open.
    ref.watch(orderClockProvider);

    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      child: InkWell(
        onTap: onTap ?? () => context.push(Routes.order(order.id)),
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
                    for (final OrderLine item in items.take(4))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 52,
                          child: AppImage(
                            url: item.imageUrl,
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
      // Cancelled and refunded read as red: the order isn't coming.
      OrderStatus.cancelled => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.cancel_outlined,
      ),
      OrderStatus.returnRequested => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.assignment_return_outlined,
      ),
      OrderStatus.refunded => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.replay_circle_filled_rounded,
      ),
    };

    return Pill(
      label: status.labelIn(AppL10n.of(context)).toUpperCase(),
      background: bg,
      foreground: fg,
      icon: icon,
    );
  }
}
