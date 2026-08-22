import 'package:material_ui/material_ui.dart';

/// Small rounded label used for `-30%`, `NEW`, order status, and similar.
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    super.key,
    this.background,
    this.foreground,
    this.icon,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = background ?? theme.colorScheme.primary;
    final Color fg = foreground ?? theme.colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: icon == null ? 9 : 8,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            // Flexible so a long label ellipsizes instead of overflowing a
            // narrow parent (product card badges, banner copy).
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
