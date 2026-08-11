import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// The shopper's display name, used for the greeting on Home.
class DisplayNameNotifier extends Notifier<String> {
  static const String _key = 'profile.displayName';
  static const String fallback = 'Alex';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  String build() {
    final String stored = _prefs.getString(_key)?.trim() ?? '';
    return stored.isEmpty ? fallback : stored;
  }

  /// Blank clears back to the default rather than leaving an empty greeting.
  Future<void> set(String value) async {
    final String trimmed = value.trim();
    state = trimmed.isEmpty ? fallback : trimmed;
    if (trimmed.isEmpty) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, trimmed);
    }
  }
}

final NotifierProvider<DisplayNameNotifier, String> displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String>(DisplayNameNotifier.new);

/// Just the first word — "Good morning, Alex" reads better than the full name.
final Provider<String> firstNameProvider = Provider<String>((Ref ref) {
  final String name = ref.watch(displayNameProvider);
  final int space = name.indexOf(' ');
  return space > 0 ? name.substring(0, space) : name;
});

/// Time-of-day greeting. Split out so the home bar and tests agree on the
/// boundaries.
String greetingFor(DateTime time) {
  final int hour = time.hour;
  if (hour < 5) return 'Still up';
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}
