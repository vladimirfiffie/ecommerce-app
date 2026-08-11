import 'package:flutter/foundation.dart';

/// A saved shipping destination.
@immutable
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.recipient,
    required this.line1,
    required this.city,
    required this.postcode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    label: json['label'] as String,
    recipient: json['recipient'] as String,
    line1: json['line1'] as String,
    city: json['city'] as String,
    postcode: json['postcode'] as String,
    country: json['country'] as String,
  );

  final String id;

  /// `Home`, `Work`, …
  final String label;
  final String recipient;
  final String line1;
  final String city;
  final String postcode;
  final String country;

  String get oneLine => '$line1, $city $postcode, $country';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'recipient': recipient,
    'line1': line1,
    'city': city,
    'postcode': postcode,
    'country': country,
  };
}

/// Field rules for the address form, kept beside the model so the form and
/// its tests agree on what "valid" means.
///
/// Deliberately forgiving about *format* and strict about obvious nonsense:
/// addresses worldwide are far too varied to pattern-match, but a name with no
/// letters in it or a ZIP with the wrong digit count is a typo every time.
abstract final class AddressValidator {
  /// Long enough for real names and streets, short enough to stop a paste of
  /// an entire document ending up in storage.
  static const int maxShortField = 60;
  static const int maxLine = 120;
  static const int maxPostcode = 12;

  // Unicode-aware throughout: plenty of real names and countries are not
  // spelled in ASCII — Côte d'Ivoire, Türkiye, 東京 — and an [a-zA-Z] rule
  // rejects the people it should be helping.
  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _usZip = RegExp(r'^\d{5}(-\d{4})?$');
  static final RegExp _genericPostcode = RegExp(
    r'^[\p{L}\p{N}][\p{L}\p{N} -]*$',
    unicode: true,
  );
  static final RegExp _countryShape = RegExp(r"^[\p{L} .'’-]+$", unicode: true);

  /// The names people actually type for the US, since country is free text.
  static const Set<String> _unitedStates = <String>{
    'us',
    'usa',
    'u.s.',
    'u.s.a.',
    'united states',
    'united states of america',
  };

  static bool isUnitedStates(String country) =>
      _unitedStates.contains(country.trim().toLowerCase());

  static String? validateLabel(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Give it a name, like Home';
    if (v.length > 24) return 'Keep it short';
    return null;
  }

  static String? validateRecipient(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Who is it going to?';
    if (v.length < 2) return 'That looks too short';
    if (!_hasLetter.hasMatch(v)) return 'Enter the recipient’s name';
    if (v.length > maxShortField) return 'That looks too long';
    return null;
  }

  static String? validateLine1(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Enter the street address';
    if (v.length < 4) return 'That looks too short';
    if (v.length > maxLine) return 'That looks too long';
    return null;
  }

  static String? validateCity(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Enter the city';
    if (!_hasLetter.hasMatch(v)) return 'That doesn’t look like a city';
    if (v.length > maxShortField) return 'That looks too long';
    return null;
  }

  /// US ZIPs are checked properly; everywhere else only has to be plausible,
  /// because postcode formats differ in every country that has them.
  static String? validatePostcode(String value, {required String country}) {
    final String v = value.trim();
    if (v.isEmpty) return 'Enter the postcode';

    if (isUnitedStates(country)) {
      return _usZip.hasMatch(v) ? null : 'Use 5 digits, or ZIP+4';
    }
    if (v.length > maxPostcode) return 'That looks too long';
    return _genericPostcode.hasMatch(v) ? null : 'That doesn’t look right';
  }

  static String? validateCountry(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Enter the country';
    if (v.length < 2) return 'That looks too short';
    if (!_countryShape.hasMatch(v)) return 'Letters only';
    if (v.length > maxShortField) return 'That looks too long';
    return null;
  }
}

/// A stored card / wallet. Mocked — no real payment data is ever handled.
@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  final String id;
  final String brand;
  final String last4;
  final String expiry;

  String get label => '$brand •••• $last4';
}

const List<PaymentMethod> kPaymentMethods = <PaymentMethod>[
  PaymentMethod(id: 'visa', brand: 'Visa', last4: '4242', expiry: '09/28'),
  PaymentMethod(
    id: 'mastercard',
    brand: 'Mastercard',
    last4: '8210',
    expiry: '02/27',
  ),
  PaymentMethod(id: 'applepay', brand: 'Wallet', last4: '0000', expiry: '—'),
];
