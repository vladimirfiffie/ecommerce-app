import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A titled group of settings rows.
///
/// The settings screen was a flat pile of switches and tiles; grouping gives
/// each concern a heading you can scan for.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.title,
    required this.children,
    super.key,
    this.caption,
  });

  final String title;
  final String? caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        // Material rather than a colored Container: the rows are ListTiles,
        // which paint their ink on the nearest Material ancestor.
        Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// A single navigable row inside a [SettingsGroup].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    // A Material ListTile: every settings row is a navigation target, and
    // the adaptive tile does not take a tap across the whole row the way
    // this one does — the hit test lands past the text.
    return ListTile(
      leading: Icon(
        icon,
        color: destructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(color: tint),
      ),
      // Styled on the Text rather than through subtitleTextStyle, which is
      // a ListTileTheme hook the adaptive tile has no equivalent for.
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing:
          trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );
  }
}

/// A switch row that lines up with [SettingsRow].
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // A tile with a switch in its trailing slot rather than
    // SwitchListTile: that draws a Material switch on iOS too, and the row
    // itself is what iOS styles differently — separators inset to the text,
    // no ink, a taller touch target.
    return AdaptiveListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      enabled: onChanged != null,
      // Tapping the row is the same as flicking the switch, which is what
      // SwitchListTile gave for free and a plain tile does not.
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: AdaptiveSwitch(
        value: value,
        onChanged: onChanged ?? (bool _) {},
      ),
    );
  }
}
