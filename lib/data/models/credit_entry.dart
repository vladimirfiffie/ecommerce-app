import 'package:flutter/foundation.dart';

/// Why a line exists on the store-credit ledger.
enum CreditKind {
  /// A gift card the shopper redeemed.
  redeemed,

  /// Credit spent on an order.
  spent,

  /// Credit handed back when a return was refunded.
  refunded,
}

/// One movement on the store-credit ledger.
///
/// The balance is the sum of these rather than a number kept somewhere and
/// edited, so "you have $35" is always something the app can show its working
/// for — and a spend that never reached disk can't leave a balance claiming
/// money that has already been used.
@immutable
class CreditEntry {
  const CreditEntry({
    required this.at,
    required this.kind,
    required this.amount,
    required this.reference,
  });

  factory CreditEntry.fromJson(Map<String, dynamic> json) => CreditEntry(
    at: DateTime.parse(json['at'] as String),
    kind: CreditKind.values.firstWhere(
      (CreditKind k) => k.name == json['kind'],
      orElse: () => CreditKind.redeemed,
    ),
    amount: (json['amount'] as num).toDouble(),
    reference: json['reference'] as String? ?? '',
  );

  final DateTime at;
  final CreditKind kind;

  /// Signed: positive puts credit on the account, negative takes it off.
  final double amount;

  /// The gift card code, or the order the movement belongs to.
  final String reference;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'at': at.toIso8601String(),
    'kind': kind.name,
    'amount': amount,
    'reference': reference,
  };
}

/// A gift card this build will accept, and what it is worth.
///
/// A real shop would ask its backend. There isn't one, so the demo carries a
/// short list — the same way [kPromos] carries the promo codes.
const Map<String, double> kGiftCards = <String, double>{
  'ASTER-GIFT-10': 10,
  'ASTER-GIFT-25': 25,
  'ASTER-GIFT-50': 50,
  'ASTER-GIFT-100': 100,
};
