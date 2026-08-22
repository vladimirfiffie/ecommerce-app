import 'package:flutter/foundation.dart';

/// What a notification is about, which decides its icon and where tapping it
/// goes.
enum NotificationKind {
  orderPlaced,
  orderShipped,
  orderDelivered,
  orderCancelled,
  returnFiled,
  refundPaid,
}

/// One thing worth telling the shopper, as it appears in the inbox.
///
/// These are derived rather than stored — see `inboxProvider`. The only thing
/// kept on disk is which ids have been read.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.orderId,
  });

  /// Stable across rebuilds, because read state is keyed on it.
  final String id;

  final DateTime at;
  final NotificationKind kind;
  final String title;
  final String body;

  /// The order this is about — every notification the app has is.
  final String orderId;
}
