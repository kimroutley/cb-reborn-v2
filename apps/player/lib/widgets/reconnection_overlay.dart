import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

/// Simple reconnection overlay shown when connection to cloud game is lost.
class ReconnectionOverlay extends StatelessWidget {
  final bool isReconnecting;

  const ReconnectionOverlay({
    super.key,
    required this.isReconnecting,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (!isReconnecting) return const SizedBox.shrink();

    return Container(
      color: CBColors.voidBlack.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CBBreathingSpinner(size: 48),
            const SizedBox(height: 24),
            Text(
              'Reconnecting to game...',
              style: textTheme.displaySmall!,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we restore your connection',
              style: textTheme.bodyMedium!,
            ),
          ],
        ),
      ),
    );
  }
}
