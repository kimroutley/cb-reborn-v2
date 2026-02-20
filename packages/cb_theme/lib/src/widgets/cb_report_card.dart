import 'package:flutter/material.dart';

/// Report card showing a list of events or results.
class CBReportCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color? color;

  const CBReportCard({
    super.key,
    required this.title,
    required this.lines,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: accentColor,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// ',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
