import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/credit_entry.dart';
import '../data/models/order.dart';
import 'app_providers.dart';
import 'cart_provider.dart';
import 'orders_provider.dart';

/// Gift cards the shopper has redeemed.
///
/// Only redemptions are written down. What has been *spent* is read off the
/// orders that spent it, and what has come *back* is read off the returns that
/// were refunded — see [creditHistoryProvider]. A balance kept as a stored
/// number would have to be edited in step with every order placed, cancelled
/// and refunded, and any write that didn't land would leave it quietly wrong.
class CreditLedgerNotifier extends Notifier<List<CreditEntry>> {
  static const String _key = 'credit.redeemed';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<CreditEntry> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <CreditEntry>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <CreditEntry>[
        for (final Object? e in decoded)
          CreditEntry.fromJson(e! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <CreditEntry>[];
    }
  }

  /// Adds a gift card to the account.
  ///
  /// Returns null on success, or a reason the code was refused.
  Future<String?> redeem(String code) async {
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return 'Enter a gift card code';

    final double? value = kGiftCards[normalized];
    if (value == null) return 'That code isn’t a gift card we recognise';

    for (final CreditEntry e in state) {
      if (e.reference == normalized) {
        return 'That card is already on your account';
      }
    }

    final List<CreditEntry> next = <CreditEntry>[
      ...state,
      CreditEntry(
        at: DateTime.now(),
        kind: CreditKind.redeemed,
        amount: value,
        reference: normalized,
      ),
    ];
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((CreditEntry e) => e.toJson()).toList()),
    );
    return null;
  }

  Future<void> clear() async {
    state = const <CreditEntry>[];
    await _prefs.remove(_key);
  }
}

final NotifierProvider<CreditLedgerNotifier, List<CreditEntry>>
creditLedgerProvider =
    NotifierProvider<CreditLedgerNotifier, List<CreditEntry>>(
      CreditLedgerNotifier.new,
    );

/// Every movement on the account, newest first.
///
/// Redemptions come off disk; spends and refunds are read off the orders, so
/// a cancelled order hands its credit straight back and a refunded return
/// returns the share of the refund that was paid with credit in the first
/// place. Nothing has to be reconciled after the fact.
final Provider<List<CreditEntry>> creditHistoryProvider =
    Provider<List<CreditEntry>>((Ref ref) {
      // The clock, because an order becomes refunded by time passing rather
      // than by anything the shopper does — see [Order.status].
      ref.watch(orderClockProvider);

      final List<CreditEntry> entries = <CreditEntry>[
        ...ref.watch(creditLedgerProvider),
      ];

      for (final Order order in ref.watch(ordersProvider)) {
        if (order.creditApplied <= 0) continue;

        // A cancelled order was never paid for, so it never spent anything.
        if (order.status == OrderStatus.cancelled) continue;

        entries.add(
          CreditEntry(
            at: order.placedAt,
            kind: CreditKind.spent,
            amount: -order.creditApplied,
            reference: order.id,
          ),
        );

        final ReturnRequest? request = order.returnRequest;
        if (request == null || order.status != OrderStatus.refunded) continue;

        // A refund goes back the way it was paid. The share of the order that
        // credit covered comes back as credit; the rest is the card's.
        final double share = order.total <= 0
            ? 0
            : order.creditApplied / order.total;
        final double back = request.refundAmount * share;
        if (back <= 0) continue;
        entries.add(
          CreditEntry(
            at: request.expectedRefundBy,
            kind: CreditKind.refunded,
            amount: back,
            reference: order.id,
          ),
        );
      }

      entries.sort((CreditEntry a, CreditEntry b) => b.at.compareTo(a.at));
      return entries;
    });

/// What the account is worth right now.
final Provider<double> storeCreditProvider = Provider<double>((Ref ref) {
  final double balance = ref
      .watch(creditHistoryProvider)
      .fold(0, (double sum, CreditEntry e) => sum + e.amount);
  // Rounding noise from pro-rata refund shares can leave a few thousandths of
  // a cent behind, which would show as a balance of $0.00 that isn't zero.
  return balance < 0.005 ? 0 : balance;
});

/// Whether checkout should put the balance towards this order.
///
/// Not persisted, and defaulted on: credit is the shopper's money and holding
/// it back by default only makes them pay twice. The review step says how much
/// is going on and lets them keep it for another time.
class UseStoreCreditNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;

  void reset() => state = true;
}

final NotifierProvider<UseStoreCreditNotifier, bool> useStoreCreditProvider =
    NotifierProvider<UseStoreCreditNotifier, bool>(UseStoreCreditNotifier.new);

/// An order total with store credit taken off it.
///
/// Kept apart from [CartSummary] on purpose: the summary is what the order
/// *costs*, and that is the number a promo code has to be judged on. Credit is
/// how some of that cost is being settled, which is a different question and
/// comes after.
@immutable
class CheckoutTotal {
  const CheckoutTotal({required this.summary, required this.creditApplied});

  final CartSummary summary;

  /// How much of the balance this order takes.
  final double creditApplied;

  /// What the card is actually charged.
  double get amountDue => summary.total - creditApplied;

  bool get usesCredit => creditApplied > 0;

  /// True when credit covers the order outright and no card is needed.
  bool get paidEntirelyByCredit => summary.total > 0 && amountDue < 0.005;
}

final Provider<CheckoutTotal> checkoutTotalProvider = Provider<CheckoutTotal>((
  Ref ref,
) {
  final CartSummary summary = ref.watch(cartSummaryProvider);
  final bool use = ref.watch(useStoreCreditProvider);
  final double balance = ref.watch(storeCreditProvider);
  final double applied = !use || summary.total <= 0
      ? 0
      : balance.clamp(0, summary.total);
  return CheckoutTotal(summary: summary, creditApplied: applied);
});
