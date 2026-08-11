import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'breakpoints.dart';

/// Master–detail layout for wide windows.
///
/// The app already used this shape ad hoc on the product page and the cart;
/// this makes it one component so every list screen behaves the same way:
/// the list keeps its place on the left while the detail changes on the right.
///
/// Callers are responsible for the compact case — on a phone the list should
/// push a route as usual, which keeps the back stack honest.
class TwoPane extends StatelessWidget {
  const TwoPane({
    required this.list,
    required this.detail,
    super.key,
    this.placeholder,
    this.listFlex = 2,
    this.detailFlex = 3,
  });

  final Widget list;

  /// Null when nothing is selected yet.
  final Widget? detail;

  /// Shown in the detail pane before anything is picked.
  final Widget? placeholder;

  final int listFlex;
  final int detailFlex;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(flex: listFlex, child: list),
      const VerticalDivider(width: 1),
      Expanded(
        flex: detailFlex,
        child: detail ?? placeholder ?? const SizedBox.shrink(),
      ),
    ],
  );
}

/// Friendly "nothing selected yet" filler for a detail pane.
class TwoPanePlaceholder extends StatelessWidget {
  const TwoPanePlaceholder({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 34,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a detail pane so it reads as a distinct surface next to the list.
class DetailPaneSurface extends StatelessWidget {
  const DetailPaneSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(AppTheme.radiusMd),
    ),
    child: child,
  );
}

/// True when the window is wide enough for two panes.
bool useTwoPane(BuildContext context) => Breakpoints.of(context).isWide;
