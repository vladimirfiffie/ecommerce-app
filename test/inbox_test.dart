import 'dart:convert';

import 'package:ecommerce_app/data/models/app_notification.dart';
import 'package:ecommerce_app/data/models/cart_entry.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/state/inbox_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  Order orderPlaced(
    Duration ago, {
    String id = 'NV-1',
    DateTime? cancelledAt,
    ReturnRequest? returnRequest,
    DeliveryOption delivery = DeliveryOption.standard,
  }) {
    final DateTime at = DateTime.now().subtract(ago);
    return Order(
      id: id,
      placedAt: at,
      lines: <OrderLine>[
        OrderLine(
          entry: const CartEntry(productId: 'mug', quantity: 2),
          name: 'Mug',
          brand: 'Aster',
          imageUrl: 'https://example.invalid/1.webp',
          unitPrice: 10,
        ),
      ],
      subtotal: 20,
      shipping: 0,
      discount: 0,
      total: 21.6,
      shippingAddress: 'Ada, 1 Test Way',
      paymentLabel: 'Visa ····4242',
      deliveryId: delivery.id,
      cancelledAt: cancelledAt,
      returnRequest: returnRequest,
    );
  }

  Future<ProviderContainer> withOrders(List<Order> orders) => testContainer(
    initialPrefs: <String, Object>{
      'orders.list': jsonEncode(orders.map((Order o) => o.toJson()).toList()),
    },
  );

  List<String> suffixes(ProviderContainer c) => c
      .read(inboxProvider)
      .map((AppNotification n) => n.id.split(':').last)
      .toList();

  test('a fresh order has been confirmed and nothing else', () async {
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(minutes: 2)),
    ]);
    expect(suffixes(c), <String>['placed']);
  });

  test('nothing is announced before it has happened', () async {
    // Standard delivery hands over after eight hours, so at six there is no
    // shipping notice to give.
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(hours: 6)),
    ]);
    expect(suffixes(c), isNot(contains('shipped')));
  });

  test('shipping shows up once the courier has it', () async {
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(hours: 10)),
    ]);
    expect(suffixes(c), containsAll(<String>['placed', 'shipped']));
    expect(suffixes(c), isNot(contains('delivered')));
  });

  test('express ships sooner, and the inbox agrees', () async {
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(hours: 4), delivery: DeliveryOption.express),
    ]);
    expect(suffixes(c), contains('shipped'));
  });

  test('a delivered order has the full run', () async {
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(days: 9)),
    ]);
    expect(
      suffixes(c),
      containsAll(<String>['placed', 'shipped', 'delivered']),
    );
  });

  test('a cancelled order stops there', () async {
    // Placed long enough ago that it would otherwise have shipped and landed.
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(
        const Duration(days: 9),
        cancelledAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ]);
    expect(suffixes(c), <String>['cancelled', 'placed']);
  });

  test('a return is filed now and refunded later', () async {
    final DateTime filed = DateTime.now().subtract(const Duration(days: 1));
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(
        const Duration(days: 9),
        returnRequest: ReturnRequest(
          requestedAt: filed,
          reason: ReturnReason.changedMind,
          lineIds: const <String>['mug'],
          refundAmount: 21.6,
        ),
      ),
    ]);
    expect(suffixes(c), contains('return'));
    expect(suffixes(c), isNot(contains('refund')));
  });

  test('newest first', () async {
    final ProviderContainer c = await withOrders(<Order>[
      orderPlaced(const Duration(days: 9), id: 'NV-OLD'),
      orderPlaced(const Duration(minutes: 5), id: 'NV-NEW'),
    ]);
    final List<AppNotification> items = c.read(inboxProvider);
    expect(items.first.orderId, 'NV-NEW');
    for (int i = 1; i < items.length; i++) {
      expect(items[i - 1].at.isBefore(items[i].at), isFalse);
    }
  });

  group('read state', () {
    test('everything starts unread', () async {
      final ProviderContainer c = await withOrders(<Order>[
        orderPlaced(const Duration(days: 9)),
      ]);
      expect(c.read(unreadInboxCountProvider), c.read(inboxProvider).length);
    });

    test('opening one leaves the rest', () async {
      final ProviderContainer c = await withOrders(<Order>[
        orderPlaced(const Duration(days: 9)),
      ]);
      final int all = c.read(inboxProvider).length;
      await c
          .read(readNotificationsProvider.notifier)
          .markRead(c.read(inboxProvider).first.id);
      expect(c.read(unreadInboxCountProvider), all - 1);
    });

    test('mark all read clears the badge', () async {
      final ProviderContainer c = await withOrders(<Order>[
        orderPlaced(const Duration(days: 9)),
      ]);
      await c
          .read(readNotificationsProvider.notifier)
          .markAllRead(c.read(inboxProvider).map((AppNotification n) => n.id));
      expect(c.read(unreadInboxCountProvider), 0);
    });

    test('an id read once stays read when a later one arrives', () async {
      // Read state is keyed on a stable id rather than a position, so a new
      // notification at the top must not un-read what is under it.
      final ProviderContainer c = await withOrders(<Order>[
        orderPlaced(const Duration(days: 9), id: 'NV-OLD'),
      ]);
      final String first = c.read(inboxProvider).last.id;
      await c.read(readNotificationsProvider.notifier).markRead(first);

      expect(c.read(readNotificationsProvider), contains(first));
      expect(first, 'NV-OLD:placed');
    });
  });
}
