import 'package:flutter/material.dart';

/// Connection status indicator dot.
class CBConnectionDot extends StatelessWidget {
  final bool isConnected;
  final String? label;

  const CBConnectionDot({super.key, required this.isConnected, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isConnected ? Colors.green : theme.colorScheme.error;
    final text = label ?? (isConnected ? 'LIVE' : 'OFFLINE');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        ),
      ],
    );
  }
}
