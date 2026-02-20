import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../layout.dart';

/// Dark input field with glassmorphism styling.
class CBTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final InputDecoration? decoration;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final bool monospace;
  final bool hapticOnChange;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const CBTextField({
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.decoration,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.monospace = false,
    this.hapticOnChange = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Base style for the glass field
    final borderRadius = BorderRadius.circular(12);
    final fillColor = scheme.surfaceContainerHighest.withValues(alpha: 0.15);
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.3);
    final activeColor = scheme.primary;

    final baseDecoration = decoration ?? const InputDecoration();

    // Merge provided decoration with our glass style
    final effectiveDecoration = baseDecoration.copyWith(
      hintText: hintText ?? baseDecoration.hintText,
      errorText: errorText ?? baseDecoration.errorText,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: activeColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: scheme.error),
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.4),
      ),
      labelStyle: MaterialStateTextStyle.resolveWith((states) {
        if (states.contains(MaterialState.focused)) {
          return TextStyle(color: activeColor, fontWeight: FontWeight.bold);
        }
        if (states.contains(MaterialState.error)) {
          return TextStyle(color: scheme.error);
        }
        return TextStyle(color: scheme.onSurface.withValues(alpha: 0.6));
      }),
    );

    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: (val) {
        if (hapticOnChange && val.isNotEmpty) {
          HapticFeedback.selectionClick();
        }
        onChanged?.call(val);
      },
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      style: textStyle ??
          (monospace
              ? theme.textTheme.bodyLarge!
                  .copyWith(fontFamily: 'RobotoMono', letterSpacing: 0.5)
              : theme.textTheme.bodyLarge!),
      inputFormatters: [
        ...?inputFormatters,
        if (maxLength == null) LengthLimitingTextInputFormatter(8192),
      ],
      cursorColor: activeColor,
      cursorOpacityAnimates: true,
      decoration: effectiveDecoration,
    );
  }
}
