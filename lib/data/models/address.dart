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
