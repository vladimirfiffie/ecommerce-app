import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// The account name the OS knows the user by, when there is one.
///
/// Desktop only: `USER` / `USERNAME` / `LOGNAME` are meaningful there, whereas
/// on Android the environment holds process-level values like `root` that
/// would be worse than no name at all. Mobile therefore starts blank and the
/// greeting simply omits the name until one is set.
String? systemUserName() {
  if (kIsWeb) return null;
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    return null;
  }
  try {
    for (final String key in const <String>['USER', 'USERNAME', 'LOGNAME']) {
      final String value = Platform.environment[key]?.trim() ?? '';
      if (value.isNotEmpty && value != 'root') return value;
    }
  } on Object {
    // Some sandboxes deny environment access; a missing name is not an error.
  }
  return null;
}

/// The shopper's display name. Empty means "not set" — the greeting drops the
/// name rather than inventing one.
class DisplayNameNotifier extends Notifier<String> {
  static const String _key = 'profile.displayName';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  String build() {
    final String stored = _prefs.getString(_key)?.trim() ?? '';
    if (stored.isNotEmpty) return stored;
    return systemUserName() ?? '';
  }

  /// Blank clears the override, falling back to the OS name if there is one.
  Future<void> set(String value) async {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_key);
      state = systemUserName() ?? '';
      return;
    }
    state = trimmed;
    await _prefs.setString(_key, trimmed);
  }
}

final NotifierProvider<DisplayNameNotifier, String> displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String>(DisplayNameNotifier.new);

/// Just the first word — "Good morning, Alex" reads better than the full name.
/// Empty when no name is known.
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

/// The full line shown on Home: `Good morning, bbo`, or just `Good morning`
/// when no name is known.
String greetingLine(DateTime time, String name) {
  final String greeting = greetingFor(time);
  return name.isEmpty ? greeting : '$greeting, $name';
}

/// The complete line for the current moment.
final Provider<String> greetingProvider = Provider<String>(
  (Ref ref) => greetingLine(DateTime.now(), ref.watch(firstNameProvider)),
);
