import 'package:flutter/material.dart';

/// Material 3 window size classes, trimmed to the three the app reacts to.
enum WindowSize {
  /// Phones in portrait. Bottom navigation, single column.
  compact,

  /// Small tablets, phones in landscape, split-screen. Wider grids.
  medium,

  /// Tablets and desktop. Navigation rail and two-pane layouts.
  expanded;

  bool get isCompact => this == WindowSize.compact;

  /// True once there's room for a rail and side-by-side panes.
  bool get isWide => this == WindowSize.expanded;

  /// True for anything roomier than a phone in portrait.
  bool get isAtLeastMedium => this != WindowSize.compact;
}

/// Layout thresholds and the derived sizing the whole app shares, so a tablet
/// never ends up with phone-width gutters on one screen and tablet ones on
/// the next.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// Longest comfortable line length for body content on a wide screen.
  static const double maxContentWidth = 1100;

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static WindowSize fromWidth(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Product-grid columns for the available [width].
  static int gridColumns(double width) {
    if (width >= 1500) return 6;
    if (width >= 1200) return 5;
    if (width >= expanded) return 4;
    if (width >= medium) return 3;
    return 2;
  }

  /// Horizontal page padding, growing with the window.
  static double gutter(WindowSize size) => switch (size) {
    WindowSize.compact => 20,
    WindowSize.medium => 28,
    WindowSize.expanded => 32,
  };
}

/// Centers and width-limits page content so text lines stay readable on a
/// wide window instead of stretching edge to edge.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    required this.child,
    super.key,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
