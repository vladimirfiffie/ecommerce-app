import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/release_notes.dart';
import 'app_providers.dart';

/// What the app remembers about showing release notes.
@immutable
class WhatsNewState {
  const WhatsNewState({required this.lastSeenVersion, required this.muted});

  /// Null on a first install — nothing has been seen yet.
  final String? lastSeenVersion;

  /// The shopper ticked "don't show this again".
  final bool muted;
}

class WhatsNewNotifier extends Notifier<WhatsNewState> {
  static const String _seenKey = 'whatsNew.lastSeenVersion';
  static const String _mutedKey = 'whatsNew.muted';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  WhatsNewState build() => WhatsNewState(
    lastSeenVersion: _prefs.getString(_seenKey),
    muted: _prefs.getBool(_mutedKey) ?? false,
  );

  /// Whether the update sheet should appear on this launch.
  ///
  /// A fresh install never sees it: someone opening the app for the first
  /// time doesn't need to be told what changed since a version they never
  /// ran. The current version is recorded silently instead.
  bool get shouldShow {
    if (state.muted) return false;
    if (state.lastSeenVersion == null) return false;
    return compareVersions(currentReleaseVersion, state.lastSeenVersion!) > 0;
  }

  /// Notes to display — everything newer than what was last seen.
  List<ReleaseNote> get pending => releaseNotesSince(state.lastSeenVersion);

  /// Records the current version without showing anything. Used on first run.
  Future<void> markSeen({bool mute = false}) async {
    state = WhatsNewState(
      lastSeenVersion: currentReleaseVersion,
      muted: mute || state.muted,
    );
    await _prefs.setString(_seenKey, currentReleaseVersion);
    if (mute) await _prefs.setBool(_mutedKey, true);
  }

  /// Re-enables the sheet for future updates.
  Future<void> unmute() async {
    state = WhatsNewState(lastSeenVersion: state.lastSeenVersion, muted: false);
    await _prefs.setBool(_mutedKey, false);
  }
}

final NotifierProvider<WhatsNewNotifier, WhatsNewState> whatsNewProvider =
    NotifierProvider<WhatsNewNotifier, WhatsNewState>(WhatsNewNotifier.new);
