import 'package:flutter/material.dart';

/// A filled button in the error colour, for the action that deletes,
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
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 8)
            : null,
        textStyle: dense ? theme.textTheme.labelLarge : null,
      ),
      child: Text(label),
    );
  }
}

/// Asks before something irreversible, with the confirming button in red.
///
/// Every destructive flow in the app routes through here so the wording and
/// the colour are the same wherever you meet one — previously each screen
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
  final bool? yes = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        DangerButton(
          dense: true,
          onPressed: () => Navigator.of(context).pop(true),
          label: confirmLabel,
        ),
      ],
    ),
  );
  return yes ?? false;
}
