import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/theme_presets.dart';
import 'app_providers.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.gridView = true,
    this.amoled = false,
    this.navLabels = true,
    this.presetId = 'aster',
  });

  final ThemeMode themeMode;

  /// Follow the Android wallpaper palette when the platform offers one.
  final bool useDynamicColor;

  /// Catalog layout preference: grid vs list.
  final bool gridView;

  /// Collapse dark-theme surfaces to true black for OLED panels.
  final bool amoled;

  /// Word the tabs. Off leaves the bottom bar and the rail on icons alone,
  /// which buys the shop a little more height.
  final bool navLabels;

  /// Chosen [ThemePreset] id. Ignored while the wallpaper palette is in use.
  final String presetId;

  ThemePreset get preset => presetById(presetId);

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    bool? gridView,
    bool? amoled,
    bool? navLabels,
    String? presetId,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    gridView: gridView ?? this.gridView,
    amoled: amoled ?? this.amoled,
    navLabels: navLabels ?? this.navLabels,
    presetId: presetId ?? this.presetId,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _themeKey = 'settings.themeMode';
  static const String _dynamicKey = 'settings.dynamicColor';
  static const String _gridKey = 'settings.gridView';
  static const String _amoledKey = 'settings.amoled';
  static const String _navLabelsKey = 'settings.navLabels';
  static const String _presetKey = 'settings.themePreset';

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
      amoled: prefs.getBool(_amoledKey) ?? false,
      navLabels: prefs.getBool(_navLabelsKey) ?? true,
      presetId: presetById(prefs.getString(_presetKey)).id,
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

  Future<void> setAmoled(bool value) async {
    state = state.copyWith(amoled: value);
    await _prefs.setBool(_amoledKey, value);
  }

  Future<void> setNavLabels(bool value) async {
    state = state.copyWith(navLabels: value);
    await _prefs.setBool(_navLabelsKey, value);
  }

  Future<void> setPreset(ThemePreset preset) async {
    state = state.copyWith(presetId: preset.id);
    await _prefs.setString(_presetKey, preset.id);
  }
}

final NotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
