import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_line.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/orders_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:printing/printing.dart';

import '../../core/l10n/enum_labels.dart';
import 'invoice_pdf.dart';

/// Builds the plain-text receipt that gets shared or copied.
///
/// Kept separate from the widget so the format can be tested without pumping
/// a screen.
String buildInvoiceText(Order order, List<OrderLine> items, AppL10n l10n) {
  final StringBuffer out = StringBuffer()
    ..writeln(l10n.receiptHeading)
    ..writeln(l10n.receiptOrderLine(order.id))
    ..writeln(formatDate(order.placedAt))
    ..writeln('${l10n.receiptStatus}: ${order.status.labelIn(l10n)}')
    ..writeln()
    ..writeln(l10n.receiptItemsHeading);

  for (final OrderLine item in items) {
    final String variant = item.variantLabel == null
        ? ''
        : ' (${item.variantLabel})';
    out.writeln(
      '${item.quantity} x ${item.displayNameIn(l10n)}$variant  '
      '${formatPrice(item.lineTotal)}',
    );
  }

  // The totals used to be padded by hand, which lines up in exactly one
  // language: the moment "Subtotal" becomes "Zwischensumme" the column walks
  // off the page. Padding is computed from the labels actually in play.
  final List<(String, String)> totals = <(String, String)>[
    (l10n.summarySubtotal, formatPrice(order.subtotal)),
    if (order.discount > 0)
      (l10n.summaryDiscount, '-${formatPrice(order.discount)}'),
    (
      l10n.summaryShipping,
      order.shipping == 0 ? l10n.summaryFree : formatPrice(order.shipping),
    ),
    (l10n.receiptTotalCaps, formatPrice(order.total)),
    if (order.creditApplied > 0) ...<(String, String)>[
      (l10n.summaryStoreCredit, '-${formatPrice(order.creditApplied)}'),
      (l10n.receiptChargedCaps, formatPrice(order.cardCharged)),
    ],
  ];
  final int column = totals.fold(
    0,
    (int widest, (String, String) row) =>
        row.$1.length > widest ? row.$1.length : widest,
  );

  out.writeln();
  for (final (String label, String value) in totals) {
    out.writeln('${label.padRight(column + 3)}$value');
  }

  out
    ..writeln()
    ..writeln('${l10n.receiptDeliveryLabel}: ${order.delivery.labelIn(l10n)}')
    ..writeln('${l10n.receiptShipTo}: ${order.shippingAddress}')
    ..writeln('${l10n.receiptPaidWith}: ${order.paymentLabel}');

  if (order.hasDeliveryInstructions) {
    out.writeln('${l10n.receiptCourier}: ${order.dropOff.labelIn(l10n)}');
    if (order.deliveryNote.isNotEmpty) {
      out.writeln('${l10n.receiptNote}: ${order.deliveryNote}');
    }
  }

  if (order.giftWrapped || order.giftMessage.isNotEmpty) {
    out.writeln();
    if (order.giftWrapped) out.writeln(l10n.orderGiftWrapped);
    if (order.giftMessage.isNotEmpty) {
      out.writeln('${l10n.receiptGiftMessage}: ${order.giftMessage}');
    }
  }

  if (order.returnRequest case final ReturnRequest r) {
    out
      ..writeln()
      ..writeln(
        l10n.receiptReturnLine(
          r.reason.labelIn(l10n),
          formatPrice(r.refundAmount),
        ),
      );
  }

  out
    ..writeln()
    ..writeln(l10n.receiptDemoFooter);
  return out.toString();
}

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(orderId));
    final List<OrderLine> items = ref.watch(orderItemsProvider(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL10n.of(context).receiptTitle)),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: AppL10n.of(context).receiptUnavailableTitle,
          message: AppL10n.of(context).orderNotFoundMessage(orderId),
          actionLabel: AppL10n.of(context).orderAllOrders,
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    final String text = buildInvoiceText(order, items, AppL10n.of(context));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.of(context).receiptTitle),
        actions: <Widget>[
          IconButton(
            tooltip: AppL10n.of(context).receiptCopy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(content: Text(AppL10n.of(context).receiptCopied)),
                );
            },
          ),
          IconButton(
            tooltip: AppL10n.of(context).receiptShare,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: text,
                subject: AppL10n.of(context).receiptShareSubject(order.id),
              ),
            ),
          ),
          IconButton(
            tooltip: AppL10n.of(context).receiptExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            // Handed to the platform's own share and print sheet, which is
            // where a receipt actually needs to go: a mail app, a cloud
            // folder, a printer. Building the document is cheap; deciding
            // where it lands is not this app's business.
            onPressed: () async {
              final Uint8List bytes = await buildInvoicePdf(
                order,
                items,
                AppL10n.of(context),
              );
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'aster-receipt-${order.id}.pdf',
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text('ASTER', style: theme.textTheme.titleLarge),
                      Text(
                        AppL10n.of(context).receiptTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                _Row(AppL10n.of(context).receiptOrder, order.id),
                _Row(
                  AppL10n.of(context).receiptPlaced,
                  formatDate(order.placedAt),
                ),
                _Row(
                  AppL10n.of(context).receiptStatus,
                  order.status.labelIn(AppL10n.of(context)),
                ),
                _Row(
                  AppL10n.of(context).receiptDeliveryLabel,
                  order.delivery.labelIn(AppL10n.of(context)),
                ),
                const Divider(height: 28),

                for (final OrderLine item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.quantity}×',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.displayNameIn(AppL10n.of(context)),
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (item.variantLabel != null)
                                Text(
                                  item.variantLabel!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatPrice(item.lineTotal),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 28),
                _Row(
                  AppL10n.of(context).summarySubtotal,
                  formatPrice(order.subtotal),
                ),
                if (order.discount > 0)
                  _Row(
                    AppL10n.of(context).summaryDiscount,
                    '−${formatPrice(order.discount)}',
                  ),
                _Row(
                  'Shipping',
                  order.shipping == 0 ? 'Free' : formatPrice(order.shipping),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      AppL10n.of(context).summaryTotal,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(order.total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const Divider(height: 28),
                _Row(
                  AppL10n.of(context).receiptShipTo,
                  order.shippingAddress,
                  wrap: true,
                ),
                if (order.creditApplied > 0) ...<Widget>[
                  _Row(
                    AppL10n.of(context).summaryStoreCredit,
                    '−${formatPrice(order.creditApplied)}',
                  ),
                  _Row(
                    AppL10n.of(context).orderCharged,
                    formatPrice(order.cardCharged),
                  ),
                ],
                _Row(AppL10n.of(context).receiptPaidWith, order.paymentLabel),
                if (order.hasDeliveryInstructions)
                  _Row(
                    'Courier',
                    <String>[
                      order.dropOff.labelIn(AppL10n.of(context)),
                      if (order.deliveryNote.isNotEmpty) order.deliveryNote,
                    ].join(' — '),
                  ),
                if (order.returnRequest case final ReturnRequest r) ...<Widget>[
                  const Divider(height: 28),
                  _Row(
                    AppL10n.of(context).receiptReturn,
                    r.reason.labelIn(AppL10n.of(context)),
                  ),
                  _Row(
                    AppL10n.of(context).receiptRefund,
                    formatPrice(r.refundAmount),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    AppL10n.of(context).receiptDemoFooter,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.wrap = false});

  final String label;
  final String value;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: wrap ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
