import 'package:flutter/foundation.dart';

import 'delivery_option.dart';
import 'order_line.dart';

enum OrderStatus {
  processing,
  shipped,
  delivered,
  cancelled,
  returnRequested,
  refunded;

  /// The three stages the progress tracker draws.
  bool get isInTransit =>
      this == processing || this == shipped || this == delivered;

  bool get isClosed => this == cancelled || this == refunded;
}

/// Why an order was sent back. Some reasons are the shop's fault, which is
/// what decides who pays return postage.
enum ReturnReason {
  wrongSize(sellerAtFault: false),
  notAsDescribed(sellerAtFault: true),
  damaged(sellerAtFault: true),
  wrongItem(sellerAtFault: true),
  changedMind(sellerAtFault: false),
  other(sellerAtFault: false);

  const ReturnReason({required this.sellerAtFault});

  /// When true the shop covers return shipping and refunds it too.
  final bool sellerAtFault;
}

/// A requested return, covering some or all of an order's lines.
@immutable
class ReturnRequest {
  const ReturnRequest({
    required this.requestedAt,
    required this.reason,
    required this.lineIds,
    required this.refundAmount,
    this.note = '',
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) => ReturnRequest(
    requestedAt: DateTime.parse(json['requestedAt'] as String),
    reason: ReturnReason.values.firstWhere(
      (ReturnReason r) => r.name == json['reason'],
      orElse: () => ReturnReason.other,
    ),
    lineIds: <String>[
      for (final Object? id in json['lineIds'] as List<dynamic>? ?? <dynamic>[])
        id! as String,
    ],
    refundAmount: (json['refundAmount'] as num).toDouble(),
    note: json['note'] as String? ?? '',
  );

  final DateTime requestedAt;
  final ReturnReason reason;

  /// [CartEntry.lineId]s being sent back — a return can be partial.
  final List<String> lineIds;

  final double refundAmount;
  final String note;

  /// Refunds land a few days after the parcel is collected.
  DateTime get expectedRefundBy => requestedAt.add(const Duration(days: 5));

  Map<String, dynamic> toJson() => <String, dynamic>{
    'requestedAt': requestedAt.toIso8601String(),
    'reason': reason.name,
    'lineIds': lineIds,
    'refundAmount': refundAmount,
    'note': note,
  };
}

/// A placed order, persisted locally so the Orders tab survives restarts.
///
/// Each line carries its own snapshot of what was bought — see [OrderLine] for
/// why an order can't be a join against the live catalog.
@immutable
class Order {
  const Order({
    required this.id,
    required this.placedAt,
    required this.lines,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.shippingAddress,
    required this.paymentLabel,
    this.deliveryId = 'standard',
    this.creditApplied = 0,
    this.cancelledAt,
    this.returnRequest,
    this.giftMessage = '',
    this.giftWrapped = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    placedAt: DateTime.parse(json['placedAt'] as String),
    // Key kept as `entries` so orders written by earlier versions still load;
    // those decode with no snapshot and are resolved against the catalog.
    lines: <OrderLine>[
      for (final Object? e in json['entries'] as List<dynamic>? ?? <dynamic>[])
        OrderLine.fromJson(e! as Map<String, dynamic>),
    ],
    subtotal: (json['subtotal'] as num).toDouble(),
    shipping: (json['shipping'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    shippingAddress: json['shippingAddress'] as String,
    paymentLabel: json['paymentLabel'] as String,
    deliveryId: json['deliveryId'] as String? ?? 'standard',
    creditApplied: (json['creditApplied'] as num?)?.toDouble() ?? 0,
    cancelledAt: json['cancelledAt'] == null
        ? null
        : DateTime.parse(json['cancelledAt'] as String),
    returnRequest: json['returnRequest'] == null
        ? null
        : ReturnRequest.fromJson(
            json['returnRequest']! as Map<String, dynamic>,
          ),
    giftMessage: json['giftMessage'] as String? ?? '',
    giftWrapped: json['giftWrapped'] as bool? ?? false,
  );

  /// How long after delivery a return can still be started.
  static const Duration returnWindow = Duration(days: 30);

  final String id;
  final DateTime placedAt;
  final List<OrderLine> lines;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final String shippingAddress;
  final String paymentLabel;

  /// Which [DeliveryOption] was chosen, so the tracker can use its timeline.
  final String deliveryId;

  /// How much of [total] was settled with store credit rather than the card.
  ///
  /// Snapshotted like everything else on an order: the balance moves on, and a
  /// receipt has to keep saying what was paid at the time.
  final double creditApplied;

  final DateTime? cancelledAt;
  final ReturnRequest? returnRequest;
  final String giftMessage;
  final bool giftWrapped;

  DeliveryOption get delivery => DeliveryOption.byId(deliveryId);

  /// What the card was charged, once credit had been taken off.
  double get cardCharged => total - creditApplied;

  int get itemCount =>
      lines.fold(0, (int sum, OrderLine l) => sum + l.quantity);

  DateTime get estimatedDelivery => delivery.estimatedArrival(placedAt);

  /// How long an order sits with the shop before the courier has it.
  Duration get _toShipped =>
      Duration(hours: delivery == DeliveryOption.express ? 2 : 8);

  /// When the courier took it. Derived, like [status] — nothing pushes it.
  DateTime get shippedAt => placedAt.add(_toShipped);

  /// When the parcel actually landed, for return-window maths.
  DateTime get deliveredAt => estimatedDelivery;

  /// Progresses on its own as time passes, so the Orders tab feels live
  /// without a backend pushing updates. The pace follows the delivery method
  /// chosen — express shouldn't crawl like standard. Cancellations and
  /// returns are explicit and override the timeline.
  OrderStatus get status {
    if (cancelledAt != null) return OrderStatus.cancelled;
    if (returnRequest != null) {
      return DateTime.now().isAfter(returnRequest!.expectedRefundBy)
          ? OrderStatus.refunded
          : OrderStatus.returnRequested;
    }

    final Duration age = DateTime.now().difference(placedAt);
    if (age < _toShipped) return OrderStatus.processing;
    if (age < Duration(days: delivery.maxDays)) return OrderStatus.shipped;
    return OrderStatus.delivered;
  }

  /// Cancellable only before it ships — once it's with the courier it has to
  /// come back as a return instead.
  bool get canCancel => status == OrderStatus.processing;

  /// How long after placing an order it can still be undone without going
  /// through the order screen — the "wait, no" window.
  static const Duration changeWindow = Duration(minutes: 5);

  /// Whether that window is still open.
  bool get inChangeWindow =>
      canCancel && DateTime.now().difference(placedAt) < changeWindow;

  /// What's left of it, or zero once it has closed.
  Duration get changeWindowLeft {
    final Duration gone = DateTime.now().difference(placedAt);
    final Duration left = changeWindow - gone;
    return left.isNegative || !canCancel ? Duration.zero : left;
  }

  /// Returnable once delivered, until the window closes.
  bool get canReturn =>
      status == OrderStatus.delivered &&
      DateTime.now().isBefore(deliveredAt.add(returnWindow));

  /// Days left to start a return; zero once closed.
  int get returnDaysLeft {
    if (status != OrderStatus.delivered) return 0;
    final int days = deliveredAt
        .add(returnWindow)
        .difference(DateTime.now())
        .inDays;
    return days < 0 ? 0 : days;
  }

  Order copyWith({
    DateTime? cancelledAt,
    ReturnRequest? returnRequest,
    String? shippingAddress,
    bool clearReturn = false,
  }) => Order(
    id: id,
    placedAt: placedAt,
    lines: lines,
    subtotal: subtotal,
    shipping: shipping,
    discount: discount,
    total: total,
    shippingAddress: shippingAddress ?? this.shippingAddress,
    paymentLabel: paymentLabel,
    deliveryId: deliveryId,
    creditApplied: creditApplied,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    returnRequest: clearReturn ? null : (returnRequest ?? this.returnRequest),
    giftMessage: giftMessage,
    giftWrapped: giftWrapped,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'placedAt': placedAt.toIso8601String(),
    'entries': lines.map((OrderLine l) => l.toJson()).toList(),
    'subtotal': subtotal,
    'shipping': shipping,
    'discount': discount,
    'total': total,
    'shippingAddress': shippingAddress,
    'paymentLabel': paymentLabel,
    'deliveryId': deliveryId,
    if (creditApplied > 0) 'creditApplied': creditApplied,
    if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    if (returnRequest != null) 'returnRequest': returnRequest!.toJson(),
    'giftMessage': giftMessage,
    'giftWrapped': giftWrapped,
  };
}
