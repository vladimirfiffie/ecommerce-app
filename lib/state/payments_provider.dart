import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/payment_card.dart';
import 'app_providers.dart';

/// Saved cards, newest last, plus which one checkout should use.
///
/// Only the brand, last four digits, expiry and cardholder name are stored —
/// see [PaymentCard]. Nothing here can reconstruct a card number.
class PaymentCardsNotifier extends Notifier<List<PaymentCard>> {
  static const String _key = 'payments.cards';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<PaymentCard> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <PaymentCard>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <PaymentCard>[
        for (final Object? c in decoded)
          PaymentCard.fromJson(c! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <PaymentCard>[];
    }
  }

  Future<void> _persist(List<PaymentCard> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((PaymentCard c) => c.toJson()).toList()),
    );
  }

  /// Adds a card, or replaces one with the same id.
  Future<void> save(PaymentCard card) async {
    final List<PaymentCard> next = <PaymentCard>[...state];
    final int i = next.indexWhere((PaymentCard c) => c.id == card.id);
    if (i >= 0) {
      next[i] = card;
    } else {
      next.add(card);
    }
    await _persist(next);

    // First card becomes the default without the shopper having to choose.
    if (state.length == 1) {
      await ref.read(selectedCardIdProvider.notifier).select(card.id);
    }
  }

  Future<void> remove(String id) async {
    await _persist(<PaymentCard>[
      for (final PaymentCard c in state)
        if (c.id != id) c,
    ]);
    if (ref.read(selectedCardIdProvider) == id) {
      await ref
          .read(selectedCardIdProvider.notifier)
          .select(state.isEmpty ? null : state.first.id);
    }
  }

  Future<void> clear() async {
    state = const <PaymentCard>[];
    await _prefs.remove(_key);
    await ref.read(selectedCardIdProvider.notifier).select(null);
  }
}

final NotifierProvider<PaymentCardsNotifier, List<PaymentCard>>
paymentCardsProvider =
    NotifierProvider<PaymentCardsNotifier, List<PaymentCard>>(
      PaymentCardsNotifier.new,
    );

/// The card checkout will charge. Persisted so it survives a restart.
class SelectedCardNotifier extends Notifier<String?> {
  static const String _key = 'payments.selectedCard';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  String? build() => _prefs.getString(_key);

  Future<void> select(String? id) async {
    state = id;
    if (id == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, id);
    }
  }
}

final NotifierProvider<SelectedCardNotifier, String?> selectedCardIdProvider =
    NotifierProvider<SelectedCardNotifier, String?>(SelectedCardNotifier.new);

/// Resolves the selection, falling back to the first usable card.
///
/// Expired cards are skipped when picking a fallback but stay in the list, so
/// the shopper can see why checkout is complaining.
final Provider<PaymentCard?> selectedCardProvider = Provider<PaymentCard?>((
  Ref ref,
) {
  final List<PaymentCard> cards = ref.watch(paymentCardsProvider);
  if (cards.isEmpty) return null;

  final String? id = ref.watch(selectedCardIdProvider);
  for (final PaymentCard c in cards) {
    if (c.id == id) return c;
  }
  for (final PaymentCard c in cards) {
    if (!c.isExpired) return c;
  }
  return cards.first;
});

/// True when checkout has something valid to charge.
final Provider<bool> hasUsableCardProvider = Provider<bool>((Ref ref) {
  final PaymentCard? card = ref.watch(selectedCardProvider);
  return card != null && !card.isExpired;
});
