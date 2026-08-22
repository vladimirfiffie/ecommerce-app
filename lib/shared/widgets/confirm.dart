import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// A filled button in the error color, for the action that deletes,
/// cancels, or otherwise can't be taken back.
class DangerButton extends StatelessWidget {
  const DangerButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.dense = false,
  });

  final VoidCallback? onPressed;
  final String label;

  /// Sized for a dialog's action row rather than a page.
  ///
  /// The app theme gives every filled button a 54px minimum height, which is
  /// right for a full-width call to action and far too heavy sitting next to
  /// a plain "Cancel" in an AlertDialog.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        minimumSize: dense ? const Size(64, 40) : null,
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : null,
        tapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
        textStyle: dense ? theme.textTheme.labelLarge : null,
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Asks before something irreversible, with the confirming button in red.
///
/// Every destructive flow in the app routes through here so the wording and
/// the color are the same wherever you meet one — previously each screen
/// hand-rolled its own dialog with a plain primary button, which made
/// "Remove" look exactly like "Save".
///
/// Returns false when dismissed, so callers can `if (!await confirm...) return;`
/// without null handling.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  // iOS gets the platform's own alert: red destructive text, bold cancel,
  // sheet-style presentation. A Material dialog there is the clearest sign an
  // app was built somewhere else, and this is the control the shopper meets
  // at every irreversible moment.
  //
  // Android keeps the dialog below rather than handing it to the same
  // adaptive widget. What is drawn here is deliberate — a red *filled*
  // confirm button, sized for a dialog rather than a page, with both actions
  // held on one row — and destructive_ui_test.dart exists to keep it that
  // way. The adaptive dialog draws none of it.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    bool confirmed = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      actions: <AlertAction>[
        AlertAction(
          title: cancelLabel,
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: confirmLabel,
          style: AlertActionStyle.destructive,
          onPressed: () => confirmed = true,
        ),
      ],
    );
    return confirmed;
  }

  // Keep both labels short: AlertDialog stacks its actions when they don't
  // fit one row, which put the way out *underneath* the destructive button.
  final ThemeData theme = Theme.of(context);
  final bool? yes = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      // One Row rather than two loose children: AlertDialog's OverflowBar
      // stacks actions the moment they don't fit, and the app theme's button
      // labels are wide enough that even "Cancel" + "Remove" tipped over on a
      // 360px screen — putting the way out *underneath* the destructive
      // button. A Row keeps the order, and the labels ellipsize instead.
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: theme.textTheme.labelLarge,
                ),
                child: Text(
                  cancelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: DangerButton(
                dense: true,
                onPressed: () => Navigator.of(context).pop(true),
                label: confirmLabel,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return yes ?? false;
}
