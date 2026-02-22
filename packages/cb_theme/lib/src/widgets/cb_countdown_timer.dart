import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Countdown timer widget for timed phases.
class CBCountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;
  final Color? color;

  const CBCountdownTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.color, // Allow overriding base color
  });

  @override
  State<CBCountdownTimer> createState() => _CBCountdownTimerState();
}

class _CBCountdownTimerState extends State<CBCountdownTimer> {
  late int _remaining;
  late final Stream<int> _timerStream;
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => widget.seconds - tick - 1,
    ).take(widget.seconds);

    _subscription = _timerStream.listen((seconds) {
      if (mounted) {
        setState(() => _remaining = seconds);
        if (_remaining <= 5) {
          HapticFeedback.lightImpact();
        }
      }
      if (seconds == 0) {
        HapticFeedback.heavyImpact();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isCritical = _remaining <= 30;
    final displayColor = widget.color ??
        (isCritical ? theme.colorScheme.error : theme.colorScheme.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: displayColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.3),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: theme.textTheme.displayLarge?.copyWith(color: displayColor),
          ),
          const SizedBox(height: 8),
          Text(
            (isCritical ? 'TIME RUNNING OUT' : 'TIME REMAINING').toUpperCase(),
            style: theme.textTheme.labelMedium!.copyWith(color: displayColor),
          ),
        ],
      ),
    );
  }
}
