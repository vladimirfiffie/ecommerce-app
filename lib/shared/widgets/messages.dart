import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Re-exported so a screen saying something needs one import, not two.
export 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveSnackBarType;

/// Says something in passing, in whatever form the platform uses for it.
///
/// Android gets the SnackBar it always did, from the bottom. iOS has no
/// snackbar at all — the convention there is a banner that slides in at the
/// top and can be tapped away — so the package draws that instead. Routing
/// every message through here is what makes that one decision rather than
/// twenty-four.
///
/// Clears whatever is on screen first. Two of these stacked is one of them
/// unread, and the second is nearly always the one that matters.
void showMessage(
  BuildContext context,
  String message, {
  String? action,
  VoidCallback? onAction,
  AdaptiveSnackBarType type = AdaptiveSnackBarType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  AdaptiveSnackBar.show(
    context,
    message: message,
    type: type,
    duration: duration,
    action: action,
    onActionPressed: onAction,
  );
}
