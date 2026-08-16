import 'dart:typed_data';

import 'package:ecommerce_app/data/models/cart_entry.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/features/orders/invoice_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  OrderLine line(String id, String name, double price, {int quantity = 1}) =>
      OrderLine(
        entry: CartEntry(productId: id, quantity: quantity, size: 'M'),
        name: name,
        brand: 'Aster',
        imageUrl: '',
        unitPrice: price,
      );

  Order orderOf(List<OrderLine> lines, {double discount = 0}) => Order(
    id: 'A-1042',
    placedAt: DateTime(2026, 8, 16, 10, 30),
    lines: lines,
    subtotal: lines.fold<double>(
      0,
      (double sum, OrderLine l) => sum + l.lineTotal,
    ),
    shipping: 0,
    discount: discount,
    total:
        lines.fold<double>(0, (double sum, OrderLine l) => sum + l.lineTotal) -
        discount,
    shippingAddress: 'Bbo, 1 Street, Town',
    paymentLabel: 'Visa •••• 4242',
  );

  test('it renders a PDF, not an empty file', () async {
    final Order order = orderOf(<OrderLine>[line('a', 'Wool Coat', 120)]);

    final Uint8List bytes = await buildInvoicePdf(order, order.lines, testL10n);

    expect(bytes, isNotEmpty);
    // Every PDF starts with %PDF and ends with an end-of-file marker.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(String.fromCharCodes(bytes.skip(bytes.length - 6)), contains('EOF'));
  });

  test('a longer order makes a bigger document', () async {
    final Order small = orderOf(<OrderLine>[line('a', 'Wool Coat', 120)]);
    final Order large = orderOf(<OrderLine>[
      for (int i = 0; i < 12; i++)
        line('p$i', 'Product number $i', 20 + i.toDouble()),
    ]);

    final Uint8List one = await buildInvoicePdf(small, small.lines, testL10n);
    final Uint8List many = await buildInvoicePdf(large, large.lines, testL10n);

    expect(many.length, greaterThan(one.length));
  });

  test('a discounted order still renders', () async {
    final Order order = orderOf(<OrderLine>[
      line('a', 'Wool Coat', 120),
    ], discount: 12);

    final Uint8List bytes = await buildInvoicePdf(order, order.lines, testL10n);
    expect(bytes, isNotEmpty);
  });

  test('an order with no lines does not throw', () async {
    final Order order = orderOf(const <OrderLine>[]);

    await expectLater(buildInvoicePdf(order, order.lines, testL10n), completes);
  });
}
