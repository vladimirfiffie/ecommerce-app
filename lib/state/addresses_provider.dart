import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/address.dart';
import 'app_providers.dart';

const Address _defaultAddress = Address(
  id: 'home',
  label: 'Home',
  recipient: 'Alex Rivera',
  line1: '218 Marlowe Street, Apt 4B',
  city: 'Portland, OR',
  postcode: '97205',
  country: 'United States',
);

/// Saved shipping addresses. Seeded with one so checkout works out of the box.
class AddressesNotifier extends Notifier<List<Address>> {
  static const String _key = 'addresses.list';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<Address> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <Address>[_defaultAddress];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<Address> parsed = <Address>[
        for (final Object? a in decoded)
          Address.fromJson(a! as Map<String, dynamic>),
      ];
      return parsed.isEmpty ? const <Address>[_defaultAddress] : parsed;
    } on FormatException {
      return const <Address>[_defaultAddress];
    }
  }

  Future<void> _persist(List<Address> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((Address a) => a.toJson()).toList()),
    );
  }

  Future<void> upsert(Address address) async {
    final List<Address> next = <Address>[...state];
    final int i = next.indexWhere((Address a) => a.id == address.id);
    if (i >= 0) {
      next[i] = address;
    } else {
      next.add(address);
    }
    await _persist(next);
  }

  Future<void> remove(String id) async {
    if (state.length <= 1) return;
    await _persist(<Address>[
      for (final Address a in state)
        if (a.id != id) a,
    ]);
  }
}

final NotifierProvider<AddressesNotifier, List<Address>> addressesProvider =
    NotifierProvider<AddressesNotifier, List<Address>>(AddressesNotifier.new);

/// The address checkout will ship to.
class SelectedAddressNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final NotifierProvider<SelectedAddressNotifier, String?>
selectedAddressIdProvider = NotifierProvider<SelectedAddressNotifier, String?>(
  SelectedAddressNotifier.new,
);

/// Resolves the selection, falling back to the first saved address.
final Provider<Address?> selectedAddressProvider = Provider<Address?>((
  Ref ref,
) {
  final List<Address> all = ref.watch(addressesProvider);
  if (all.isEmpty) return null;
  final String? id = ref.watch(selectedAddressIdProvider);
  for (final Address a in all) {
    if (a.id == id) return a;
  }
  return all.first;
});

/// The payment method checkout will charge.
class SelectedPaymentNotifier extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => kPaymentMethods.first;

  void select(PaymentMethod method) => state = method;
}

final NotifierProvider<SelectedPaymentNotifier, PaymentMethod>
selectedPaymentProvider =
    NotifierProvider<SelectedPaymentNotifier, PaymentMethod>(
      SelectedPaymentNotifier.new,
    );
