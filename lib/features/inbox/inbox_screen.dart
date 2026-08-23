import '../../shared/widgets/adaptive_screen.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_notification.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/inbox_provider.dart';

/// What the app has told you, kept rather than thrown away.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AppNotification> items = ref.watch(inboxProvider);
    final Set<String> read = ref.watch(readNotificationsProvider);
    final int unread = ref.watch(unreadInboxCountProvider);

    return AdaptiveScreen(
      title: 'Notifications',
      actions: <Widget>[
        if (unread > 0)
          TextButton(
            onPressed: () => ref
                .read(readNotificationsProvider.notifier)
                .markAllRead(items.map((AppNotification n) => n.id)),
            child: const Text('Mark all read'),
          ),
      ],
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing yet',
              message:
                  'Order confirmations, shipping updates and refunds land '
                  'here — and stay here, whether or not you caught the '
                  'notification at the time.',
              actionLabel: 'Browse the shop',
              onAction: () => context.go(Routes.catalog),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
              itemCount: items.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const Divider(height: 1, indent: 68),
              itemBuilder: (BuildContext context, int index) {
                final AppNotification item = items[index];
                return _NotificationRow(
                  item: item,
                  unread: !read.contains(item.id),
                  onTap: () {
                    ref
                        .read(readNotificationsProvider.notifier)
                        .markRead(item.id);
                    context.push(Routes.order(item.orderId));
                  },
                );
              },
            ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final AppNotification item;
  final bool unread;
  final VoidCallback onTap;

  /// Time for something that happened today, the date for anything older —
  /// "3:04 PM" is only useful while today is still today.
  String get _when {
    final DateTime now = DateTime.now();
    final bool today =
        item.at.year == now.year &&
        item.at.month == now.month &&
        item.at.day == now.day;
    return today ? formatTime(item.at) : formatDate(item.at);
  }

  IconData get _icon => switch (item.kind) {
    NotificationKind.orderPlaced => Icons.receipt_long_rounded,
    NotificationKind.orderShipped => Icons.local_shipping_outlined,
    NotificationKind.orderDelivered => Icons.inventory_2_outlined,
    NotificationKind.orderCancelled => Icons.cancel_outlined,
    NotificationKind.returnFiled => Icons.assignment_return_outlined,
    NotificationKind.refundPaid => Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      button: true,
      // Read out as one sentence rather than four fragments, with the unread
      // state said rather than left to a dot nobody can see.
      label: <String>[
        if (unread) 'Unread',
        item.title,
        item.body,
        _when,
      ].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
              : null,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.7,
                  ),
                ),
                child: Icon(
                  _icon,
                  size: 19,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _when,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bell, with what's waiting on it.
class InboxButton extends ConsumerWidget {
  const InboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadInboxCountProvider);

    return IconButton(
      onPressed: () => context.push(Routes.inbox),
      tooltip: unread == 0 ? 'Notifications' : 'Notifications, $unread unread',
      // count rather than a label: AdaptiveBadge hides itself at zero, which
      // is what isLabelVisible was doing by hand.
      icon: AdaptiveBadge(
        count: unread,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
