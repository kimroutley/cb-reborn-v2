import 'package:flutter/material.dart';

/// Status overlay card (ELIMINATED, SILENCED, etc.).
class CBStatusOverlay extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String detail;

  const CBStatusOverlay({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: accentColor),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.displaySmall!.copyWith(color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!,
          ),
        ],
      ),
    );
  }
}
