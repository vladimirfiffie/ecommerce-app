import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/l10n/enum_labels.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../data/models/order_line.dart';
import '../../l10n/generated/app_localizations.dart';

/// Renders a receipt as a PDF document.
///
/// A separate rendering from the plain-text one rather than a wrapper around
/// it: a page has a header, a table and totals, and pretending otherwise
/// would produce a PDF of a text file.
///
/// Pure and synchronous apart from the encode, so a test can hold the bytes
/// without a screen or a platform channel in sight.
Future<Uint8List> buildInvoicePdf(
  Order order,
  List<OrderLine> items,
  AppL10n l10n,
) async {
  final pw.Document document = pw.Document(
    title: 'Aster receipt ${order.id}',
    author: 'Aster',
  );

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('ASTER', style: pw.TextStyle(fontSize: 22, letterSpacing: 3)),
          pw.SizedBox(height: 2),
          pw.Text('Receipt', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 18),
          _line('Order', order.id),
          _line('Placed', formatDate(order.placedAt)),
          _line('Status', order.status.labelIn(l10n)),
          _line('Ships to', order.shippingAddress),
          _line('Paid with', _drawable(order.paymentLabel)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: <String>['Qty', 'Item', 'Total'],
            cellAlignments: <int, pw.Alignment>{
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: <List<String>>[
              for (final OrderLine item in items)
                <String>[
                  '${item.quantity}',
                  item.variantLabel == null
                      ? item.displayNameIn(l10n)
                      : '${item.displayNameIn(l10n)} (${item.variantLabel})',
                  formatPrice(item.lineTotal),
                ],
            ],
          ),
          pw.SizedBox(height: 16),
          _total('Subtotal', formatPrice(order.subtotal)),
          if (order.discount > 0)
            _total('Discount', '-${formatPrice(order.discount)}'),
          _total(
            'Shipping',
            order.shipping == 0 ? 'Free' : formatPrice(order.shipping),
          ),
          _total('Total', formatPrice(order.total), bold: true),
          pw.Spacer(),
          pw.Text(
            'Aster is a demo storefront. No payment was taken.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    ),
  );

  return document.save();
}

/// Swaps characters the built-in PDF fonts cannot draw.
///
/// A masked card reads "Visa •••• 4242" on screen, but Helvetica has no
/// bullet: left alone those four characters come out as gaps, and the
/// receipt looks like it lost the card number rather than hiding it.
String _drawable(String value) => value.replaceAll('•', '*');

pw.Widget _line(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Row(
    children: <pw.Widget>[
      pw.SizedBox(
        width: 80,
        child: pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ),
      pw.Expanded(
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ),
    ],
  ),
);

pw.Widget _total(String label, String value, {bool bold = false}) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: <pw.Widget>[
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: bold ? 12 : 10,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: bold ? 12 : 10,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    ],
  ),
);
