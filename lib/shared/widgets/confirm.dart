import 'package:flutter/material.dart';

/// A filled button in the error colour, for the action that deletes,
/// cancels, or otherwise can't be taken back.
class DangerButton extends StatelessWidget {
  const DangerButton({required this.onPressed, required this.label, super.key});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
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
  String cancelLabel = 'Keep',
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
          onPressed: () => Navigator.of(context).pop(true),
          label: confirmLabel,
        ),
      ],
    ),
  );
  return yes ?? false;
}
