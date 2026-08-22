import 'package:material_ui/material_ui.dart';

/// A named seed color the shopper can pick when they aren't using the
/// wallpaper palette.
///
/// Only the seed is stored — Material 3 derives the full scheme for both
/// brightnesses from it, so a preset can never produce an unreadable pairing
/// the way a hand-picked palette might.
@immutable
class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.label,
    required this.seed,
  });

  /// Persisted key. Stable — renaming one would reset everyone's choice.
  final String id;

  final String label;
  final Color seed;

  /// A representative swatch for the picker, in the given brightness.
  Color swatch(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness).primary;
}

/// The built-in palettes. `aster` is the brand default and must stay first —
/// it's the fallback when a stored id is no longer recognized.
const List<ThemePreset> kThemePresets = <ThemePreset>[
  ThemePreset(id: 'aster', label: 'Aster', seed: Color(0xFF6C4DF6)),
  ThemePreset(id: 'ocean', label: 'Ocean', seed: Color(0xFF0B6E99)),
  ThemePreset(id: 'forest', label: 'Forest', seed: Color(0xFF2E7D5B)),
  ThemePreset(id: 'sunset', label: 'Sunset', seed: Color(0xFFE4572E)),
  ThemePreset(id: 'rose', label: 'Rose', seed: Color(0xFFC2185B)),
  ThemePreset(id: 'amber', label: 'Amber', seed: Color(0xFFB07D18)),
  ThemePreset(id: 'slate', label: 'Slate', seed: Color(0xFF4A5568)),
  ThemePreset(id: 'plum', label: 'Plum', seed: Color(0xFF7B4397)),
];

/// Looks a preset up by id, falling back to the brand default.
ThemePreset presetById(String? id) {
  for (final ThemePreset p in kThemePresets) {
    if (p.id == id) return p;
  }
  return kThemePresets.first;
}
