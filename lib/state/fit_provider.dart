import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// How close to the body the shopper likes their clothes.
enum FitPreference {
  snug('Snug', 'Close to the body'),
  regular('Regular', 'As the size run intends'),
  relaxed('Relaxed', 'Room to move');

  const FitPreference(this.label, this.description);

  final String label;
  final String description;

  static FitPreference byName(String? name) => FitPreference.values.firstWhere(
    (FitPreference f) => f.name == name,
    orElse: () => FitPreference.regular,
  );
}

/// What the shopper told us about themselves, once, for every product.
///
/// Kept on the device like everything else, and asked for once rather than
/// per product: the answers don't change between a shirt and a coat.
@immutable
class FitProfile {
  const FitProfile({
    this.heightCm,
    this.weightKg,
    this.preference = FitPreference.regular,
  });

  final int? heightCm;
  final int? weightKg;
  final FitPreference preference;

  bool get isComplete => heightCm != null && weightKg != null;

  FitProfile copyWith({
    int? heightCm,
    int? weightKg,
    FitPreference? preference,
  }) => FitProfile(
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    preference: preference ?? this.preference,
  );
}

class FitProfileNotifier extends Notifier<FitProfile> {
  static const String _heightKey = 'fit.heightCm';
  static const String _weightKey = 'fit.weightKg';
  static const String _preferenceKey = 'fit.preference';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  FitProfile build() => FitProfile(
    heightCm: _prefs.getInt(_heightKey),
    weightKg: _prefs.getInt(_weightKey),
    preference: FitPreference.byName(_prefs.getString(_preferenceKey)),
  );

  Future<void> save(FitProfile profile) async {
    state = profile;
    final int? height = profile.heightCm;
    final int? weight = profile.weightKg;
    if (height != null) await _prefs.setInt(_heightKey, height);
    if (weight != null) await _prefs.setInt(_weightKey, weight);
    await _prefs.setString(_preferenceKey, profile.preference.name);
  }

  Future<void> clear() async {
    state = const FitProfile();
    await _prefs.remove(_heightKey);
    await _prefs.remove(_weightKey);
    await _prefs.remove(_preferenceKey);
  }
}

final NotifierProvider<FitProfileNotifier, FitProfile> fitProfileProvider =
    NotifierProvider<FitProfileNotifier, FitProfile>(FitProfileNotifier.new);

/// The letter sizes this calculator knows, smallest first.
const List<String> kApparelRun = <String>['XS', 'S', 'M', 'L', 'XL', 'XXL'];

/// Suggests a size from a body and a preference.
///
/// A rule of thumb, not a measurement: it works off body mass index, which
/// is the only thing height and weight together can honestly say. The result
/// is clamped to the sizes the product actually stocks, so it can never
/// recommend something that cannot be bought.
String? recommendedSize(FitProfile profile, List<String> stocked) {
  final int? height = profile.heightCm;
  final int? weight = profile.weightKg;
  if (height == null || weight == null || height <= 0) return null;

  // Only letter runs. A shoe size has nothing to do with body mass.
  final List<String> run = <String>[
    for (final String size in stocked)
      if (kApparelRun.contains(size.toUpperCase())) size,
  ];
  if (run.isEmpty) return null;

  final double metres = height / 100;
  final double bmi = weight / (metres * metres);

  final int base = switch (bmi) {
    < 18.5 => 0, // XS
    < 21.5 => 1, // S
    < 25 => 2, // M
    < 28.5 => 3, // L
    < 32 => 4, // XL
    _ => 5, // XXL
  };

  final int shifted =
      base +
      switch (profile.preference) {
        FitPreference.snug => -1,
        FitPreference.regular => 0,
        FitPreference.relaxed => 1,
      };

  // Walk to the nearest size the product actually has.
  final int wanted = shifted.clamp(0, kApparelRun.length - 1);
  final String target = kApparelRun[wanted];
  if (run.contains(target)) return target;

  int bestDistance = kApparelRun.length;
  String? best;
  for (final String size in run) {
    final int distance = (kApparelRun.indexOf(size.toUpperCase()) - wanted)
        .abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = size;
    }
  }
  return best;
}
