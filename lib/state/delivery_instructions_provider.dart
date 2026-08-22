import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/drop_off.dart';
import 'app_providers.dart';

/// What the courier should do, and anything else worth telling them.
@immutable
class DeliveryInstructions {
  const DeliveryInstructions({this.dropOff = DropOff.handToMe, this.note = ''});

  final DropOff dropOff;
  final String note;

  bool get isDefault => dropOff.isDefault && note.trim().isEmpty;

  DeliveryInstructions copyWith({DropOff? dropOff, String? note}) =>
      DeliveryInstructions(
        dropOff: dropOff ?? this.dropOff,
        note: note ?? this.note,
      );
}

/// Remembered between orders, unlike the gift options next to it.
///
/// A gift is about one order; where to leave a parcel is about the door, and
/// a shopper who has a porch on Tuesday still has one on Friday. Retyping the
/// gate code every time is the kind of small tax that makes people stop
/// bothering — and an instruction nobody bothers with is a parcel on the
/// street.
class DeliveryInstructionsNotifier extends Notifier<DeliveryInstructions> {
  static const String _dropOffKey = 'checkout.dropOff';
  static const String _noteKey = 'checkout.deliveryNote';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  DeliveryInstructions build() => DeliveryInstructions(
    dropOff: DropOff.byId(_prefs.getString(_dropOffKey)),
    note: _prefs.getString(_noteKey) ?? '',
  );

  Future<void> setDropOff(DropOff value) async {
    state = state.copyWith(dropOff: value);
    await _prefs.setString(_dropOffKey, value.id);
  }

  Future<void> setNote(String value) async {
    final String trimmed = value.length > DropOff.maxNoteLength
        ? value.substring(0, DropOff.maxNoteLength)
        : value;
    state = state.copyWith(note: trimmed);
    await _prefs.setString(_noteKey, trimmed);
  }

  Future<void> clear() async {
    state = const DeliveryInstructions();
    await _prefs.remove(_dropOffKey);
    await _prefs.remove(_noteKey);
  }
}

final NotifierProvider<DeliveryInstructionsNotifier, DeliveryInstructions>
deliveryInstructionsProvider =
    NotifierProvider<DeliveryInstructionsNotifier, DeliveryInstructions>(
      DeliveryInstructionsNotifier.new,
    );
