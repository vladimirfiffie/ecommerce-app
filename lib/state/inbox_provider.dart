import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/formatters.dart';
import '../data/models/app_notification.dart';
import '../data/models/order.dart';
import 'app_providers.dart';
import 'orders_provider.dart';

/// Which notifications have been opened.
///
/// The only part of the inbox that is written down. The notifications
/// themselves are read off the orders — see [inboxProvider].
class ReadNotificationsNotifier extends Notifier<Set<String>> {
  static const String _key = 'inbox.read';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  Future<void> _persist(Set<String> next) async {
    state = next;
    await _prefs.setStringList(_key, next.toList());
  }

  Future<void> markRead(String id) async {
    if (state.contains(id)) return;
    await _persist(<String>{...state, id});
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final Set<String> next = <String>{...state, ...ids};
    if (next.length == state.length) return;
    await _persist(next);
  }

  Future<void> clear() async {
    state = const <String>{};
    await _prefs.remove(_key);
  }
}

final NotifierProvider<ReadNotificationsNotifier, Set<String>>
readNotificationsProvider =
    NotifierProvider<ReadNotificationsNotifier, Set<String>>(
      ReadNotificationsNotifier.new,
    );

/// Everything the app has told the shopper, newest first.
///
/// The OS notifications are fire-and-forget: swipe one away and it is gone,
/// and one posted while the phone was face-down was never seen at all. So the
/// inbox is not a log of what was *posted* — it is derived from the orders
/// themselves, the same way the status tracker is, and says what has actually
/// happened whether or not a notification survived to say it.
///
/// Anything still in the future is left out. An order that shipped an hour ago
/// has a shipping notice; one placed a minute ago does not yet.
final Provider<List<AppNotification>> inboxProvider =
    Provider<List<AppNotification>>((Ref ref) {
      // Time is what moves an order along, so the inbox has to keep up with it.
      ref.watch(orderClockProvider);

      final DateTime now = DateTime.now();
      final List<AppNotification> out = <AppNotification>[];

      void add({
        required String suffix,
        required DateTime at,
        required NotificationKind kind,
        required String title,
        required String body,
        required String orderId,
      }) {
        if (at.isAfter(now)) return;
        out.add(
          AppNotification(
            id: '$orderId:$suffix',
            at: at,
            kind: kind,
            title: title,
            body: body,
            orderId: orderId,
          ),
        );
      }

      for (final Order order in ref.watch(ordersProvider)) {
        final String items =
            '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}';

        add(
          suffix: 'placed',
          at: order.placedAt,
          kind: NotificationKind.orderPlaced,
          title: 'Order confirmed',
          body: '${order.id} · $items · ${formatPrice(order.total)}',
          orderId: order.id,
        );

        if (order.cancelledAt case final DateTime at) {
          add(
            suffix: 'cancelled',
            at: at,
            kind: NotificationKind.orderCancelled,
            title: 'Order cancelled',
            body: '${order.id} was cancelled before it shipped.',
            orderId: order.id,
          );
          // Nothing after this happened, so nothing after this is announced.
          continue;
        }

        add(
          suffix: 'shipped',
          at: order.shippedAt,
          kind: NotificationKind.orderShipped,
          title: 'Your order has shipped',
          body:
              '${order.id} is on its way — arriving by '
              '${formatDeliveryDate(order.estimatedDelivery)}.',
          orderId: order.id,
        );
        add(
          suffix: 'delivered',
          at: order.deliveredAt,
          kind: NotificationKind.orderDelivered,
          title: 'Delivered',
          body:
              '${order.id} should have arrived. You have '
              '${Order.returnWindow.inDays} days to send anything back.',
          orderId: order.id,
        );

        if (order.returnRequest case final ReturnRequest request) {
          add(
            suffix: 'return',
            at: request.requestedAt,
            kind: NotificationKind.returnFiled,
            title: 'Return started',
            body:
                'We’ll refund ${formatPrice(request.refundAmount)} once your '
                'parcel is collected.',
            orderId: order.id,
          );
          add(
            suffix: 'refund',
            at: request.expectedRefundBy,
            kind: NotificationKind.refundPaid,
            title: 'Refund paid',
            body:
                '${formatPrice(request.refundAmount)} is on its way back to '
                'you for ${order.id}.',
            orderId: order.id,
          );
        }
      }

      out.sort((AppNotification a, AppNotification b) => b.at.compareTo(a.at));
      return out;
    });

/// How many are still unopened — the number on the bell.
final Provider<int> unreadInboxCountProvider = Provider<int>((Ref ref) {
  final Set<String> read = ref.watch(readNotificationsProvider);
  int count = 0;
  for (final AppNotification n in ref.watch(inboxProvider)) {
    if (!read.contains(n.id)) count++;
  }
  return count;
});
