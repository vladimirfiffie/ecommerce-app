import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_presets.dart';
import '../../../state/settings_provider.dart';

/// Row of preset swatches.
///
/// Presets stay tappable while the wallpaper palette is on, but dim, with a
/// note explaining why the app's colours aren't changing — silently ignoring
/// taps would read as a bug.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key, this.dynamicActive = false});

  /// The Material You palette is currently winning.
  final bool dynamicActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final Brightness brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: kThemePresets.length,
            separatorBuilder: (BuildContext c, int i) =>
                const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final ThemePreset preset = kThemePresets[index];
              final bool selected = preset.id == settings.presetId;
              final Color swatch = preset.swatch(brightness);

              return Semantics(
                selected: selected,
                button: true,
                label: '${preset.label} theme',
                child: InkWell(
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setPreset(preset),
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: dynamicActive ? 0.45 : 1,
                    child: SizedBox(
                      width: 62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: swatch,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.outlineVariant,
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: swatch.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (dynamicActive)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Your wallpaper palette is in charge right now — turn it off '
              'below to use a preset.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
