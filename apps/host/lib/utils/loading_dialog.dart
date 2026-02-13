import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

Future<void> showBreathingLoadingDialog(
  BuildContext context,
  String message, {
  Color? accentColor,
}) {
  return showThemedLoadingDialog(
    context: context,
    message: message,
    accentColor: accentColor ?? CBColors.neonBlue,
  );
}
