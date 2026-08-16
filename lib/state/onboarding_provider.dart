import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// Whether the intro has been through once.
///
/// Deliberately separate from the welcome gate: signing out returns you to
/// sign in, but nobody wants to be told what the app is a second time.
class OnboardingNotifier extends Notifier<bool> {
  static const String prefsKey = 'onboarding.seen';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(prefsKey) ?? false;

  /// Marks the intro done, whether it was read or skipped.
  Future<void> markSeen() async {
    state = true;
    await _prefs.setBool(prefsKey, true);
  }

  /// Testing and "show me that again" — not wired to any UI yet.
  Future<void> reset() async {
    state = false;
    await _prefs.remove(prefsKey);
  }
}

final NotifierProvider<OnboardingNotifier, bool> onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
