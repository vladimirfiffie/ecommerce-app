import 'package:flutter/material.dart';

enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('American Express'),
  discover('Discover'),
  unknown('Card');

  const CardBrand(this.label);

  final String label;

  IconData get icon => switch (this) {
    CardBrand.amex => Icons.credit_score_rounded,
    CardBrand.unknown => Icons.credit_card_outlined,
    _ => Icons.credit_card_rounded,
  };

  /// Amex prints 4 CVV digits on the front; everyone else prints 3 on the back.
  int get cvvLength => this == CardBrand.amex ? 4 : 3;

  /// Amex is 15 digits, the rest are 16.
  int get numberLength => this == CardBrand.amex ? 15 : 16;
}

/// A saved card.
///
/// **The card number is never stored.** Only the last four digits are kept, so
/// the shopper can tell their cards apart. The CVV is never persisted at all —
/// storing it is forbidden by PCI DSS even for real processors, and there is
/// nothing here that could legitimately use it later.
@immutable
class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.holder,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
    id: json['id'] as String,
    brand: CardBrand.values.firstWhere(
      (CardBrand b) => b.name == json['brand'],
      orElse: () => CardBrand.unknown,
    ),
    last4: json['last4'] as String,
    expiryMonth: json['expiryMonth'] as int,
    expiryYear: json['expiryYear'] as int,
    holder: json['holder'] as String? ?? '',
  );

  final String id;
  final CardBrand brand;

  /// Exactly four digits. Never the full number.
  final String last4;

  final int expiryMonth;

  /// Four digits, e.g. 2028.
  final int expiryYear;

  final String holder;

  String get label => '${brand.label} •••• $last4';

  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear % 100}';

  /// A card is good through the last day of its expiry month.
  bool get isExpired {
    final DateTime now = DateTime.now();
    final DateTime endOfMonth = DateTime(expiryYear, expiryMonth + 1);
    return !now.isBefore(endOfMonth);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'brand': brand.name,
    'last4': last4,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'holder': holder,
  };
}

/// Card-entry validation. Pure functions so the rules can be tested without
/// building a form.
abstract final class CardValidator {
  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// The Luhn checksum every major card network uses. Catches single-digit
  /// typos and most transpositions before anything is saved.
  static bool passesLuhn(String number) {
    final String digits = digitsOnly(number);
    if (digits.length < 12) return false;
    int sum = 0;
    bool doubleIt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int d = digits.codeUnitAt(i) - 0x30;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  /// Identifies the network from the leading digits (IIN ranges).
  static CardBrand brandOf(String number) {
    final String d = digitsOnly(number);
    if (d.isEmpty) return CardBrand.unknown;
    if (d.startsWith('4')) return CardBrand.visa;
    if (d.length >= 2) {
      final int two = int.parse(d.substring(0, 2));
      if (two == 34 || two == 37) return CardBrand.amex;
      if (two >= 51 && two <= 55) return CardBrand.mastercard;
      if (two == 65) return CardBrand.discover;
    }
    if (d.length >= 4) {
      final int four = int.parse(d.substring(0, 4));
      if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
      if (four == 6011) return CardBrand.discover;
    }
    return CardBrand.unknown;
  }

  /// `4242 4242 4242 4242` — grouped for legibility while typing.
  static String format(String number) {
    final String d = digitsOnly(number);
    final CardBrand brand = brandOf(d);
    final List<int> groups = brand == CardBrand.amex
        ? <int>[4, 6, 5]
        : <int>[4, 4, 4, 4];

    final StringBuffer out = StringBuffer();
    int index = 0;
    for (final int size in groups) {
      if (index >= d.length) break;
      if (out.isNotEmpty) out.write(' ');
      out.write(d.substring(index, (index + size).clamp(0, d.length)));
      index += size;
    }
    if (index < d.length) out.write(' ${d.substring(index)}');
    return out.toString();
  }

  /// Null when acceptable, otherwise the reason.
  static String? validateNumber(String number) {
    final String d = digitsOnly(number);
    if (d.isEmpty) return 'Enter your card number';
    final CardBrand brand = brandOf(d);
    if (d.length != brand.numberLength) {
      return 'That should be ${brand.numberLength} digits';
    }
    if (!passesLuhn(d)) return 'That card number doesn’t look right';
    return null;
  }

  /// Accepts `MM/YY` or `MMYY`.
  static String? validateExpiry(String input, {DateTime? now}) {
    final String d = digitsOnly(input);
    if (d.length != 4) return 'Use MM/YY';
    final int month = int.parse(d.substring(0, 2));
    if (month < 1 || month > 12) return 'That month doesn’t exist';

    final DateTime today = now ?? DateTime.now();
    final int year = 2000 + int.parse(d.substring(2));
    if (!today.isBefore(DateTime(year, month + 1))) return 'That card expired';
    if (year > today.year + 25) return 'Check the expiry year';
    return null;
  }

  static String? validateCvv(String cvv, CardBrand brand) {
    final String d = digitsOnly(cvv);
    if (d.length != brand.cvvLength) {
      return '${brand.cvvLength} digits';
    }
    return null;
  }

  static String? validateHolder(String name) =>
      name.trim().length < 2 ? 'Enter the name on the card' : null;

  /// Builds a storable card from validated input, keeping only last4.
  static PaymentCard toCard({
    required String number,
    required String expiry,
    required String holder,
    String? id,
  }) {
    final String d = digitsOnly(number);
    final String e = digitsOnly(expiry);
    return PaymentCard(
      id:
          id ??
          'card-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      brand: brandOf(d),
      last4: d.substring(d.length - 4),
      expiryMonth: int.parse(e.substring(0, 2)),
      expiryYear: 2000 + int.parse(e.substring(2)),
      holder: holder.trim(),
    );
  }
}
