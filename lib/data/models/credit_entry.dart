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

/// Punctuation and layout of a gift card code, worked out from the codes the
/// shop actually issues rather than written down twice.
abstract final class GiftCardFormat {
  /// The sizes of each dash-separated group, taken from the issued codes.
  ///
  /// Every code shares a shape — five letters, four letters, then the value —
  /// so a code being typed can be punctuated before it is complete. Derived
  /// so that adding a differently shaped code to [kGiftCards] can't leave the
  /// field formatting to a pattern the shop no longer uses.
  static final List<int> groupSizes = _groupSizes();

  static List<int> _groupSizes() {
    final Set<String> shapes = <String>{
      for (final String code in kGiftCards.keys)
        code
            .split('-')
            // The last group is the value and varies in length, so the shape
            // is only the fixed groups in front of it.
            .take(code.split('-').length - 1)
            .map((String part) => part.length.toString())
            .join(','),
    };
    if (shapes.length != 1 || shapes.single.isEmpty) return const <int>[];
    return shapes.single.split(',').map(int.parse).toList();
  }

  /// Strips a code back to the characters that carry meaning.
  static String bare(String value) =>
      value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// Punctuates [value] as it is typed: upper case, dashes where the issued
  /// codes put them, and no trailing dash until there is something after it.
  static String format(String value) {
    final String bareValue = bare(value);
    if (bareValue.isEmpty || groupSizes.isEmpty) return bareValue;

    final StringBuffer out = StringBuffer();
    int index = 0;
    for (final int size in groupSizes) {
      if (index >= bareValue.length) break;
      if (out.isNotEmpty) out.write('-');
      final int end = (index + size).clamp(0, bareValue.length);
      out.write(bareValue.substring(index, end));
      index = end;
    }
    if (index < bareValue.length) {
      out
        ..write('-')
        ..write(bareValue.substring(index));
    }
    return out.toString();
  }
}
