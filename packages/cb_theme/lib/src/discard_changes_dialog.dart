import 'package:flutter/material.dart';

Future<bool> showCBDiscardChangesDialog(
  BuildContext context, {
  String title = 'Discard Changes?',
  String message = 'You have unsaved edits. Leave without saving?',
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Discard',
}) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return shouldDiscard ?? false;
}
