import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.gridView = true,
  });

  final ThemeMode themeMode;

  /// Follow the Android wallpaper palette when the platform offers one.
  final bool useDynamicColor;

  /// Catalog layout preference: grid vs list.
  final bool gridView;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    bool? gridView,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    gridView: gridView ?? this.gridView,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _themeKey = 'settings.themeMode';
  static const String _dynamicKey = 'settings.dynamicColor';
  static const String _gridKey = 'settings.gridView';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final SharedPreferences prefs = _prefs;
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (ThemeMode m) => m.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      ),
      useDynamicColor: prefs.getBool(_dynamicKey) ?? true,
      gridView: prefs.getBool(_gridKey) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setDynamicColor(bool value) async {
    state = state.copyWith(useDynamicColor: value);
    await _prefs.setBool(_dynamicKey, value);
  }

  Future<void> setGridView(bool value) async {
    state = state.copyWith(gridView: value);
    await _prefs.setBool(_gridKey, value);
  }
}

final NotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
