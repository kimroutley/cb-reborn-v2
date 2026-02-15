import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class StimEffectOverlay extends StatefulWidget {
  final Widget child;
  final List<BulletinEntry> bulletinBoard;

  const StimEffectOverlay({
    super.key,
    required this.child,
    required this.bulletinBoard,
  });

  @override
  State<StimEffectOverlay> createState() => _StimEffectOverlayState();
}

class _StimEffectOverlayState extends State<StimEffectOverlay>
    with SingleTickerProviderStateMixin {
  // Strobe/Flash Effect
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flashAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StimEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for STIM commands (Director Mode)
    if (widget.bulletinBoard.length > oldWidget.bulletinBoard.length) {
      final newEntries =
          widget.bulletinBoard.sublist(oldWidget.bulletinBoard.length);
      for (final entry in newEntries) {
        if (entry.content.startsWith('STIM:')) {
          _triggerStim(entry.content.substring(5).trim());
        }
      }
    }
  }

  void _triggerStim(String command) {
    // Haptic kick
    HapticService.heavy();
    final scheme = Theme.of(context).colorScheme;

    if (command == 'NEON FLICKER') {
      setState(() => _flashColor = scheme.primary);
      _flashController.forward().then((_) => _flashController.reverse());
    } else if (command == 'SYSTEM GLITCH') {
      setState(() => _flashColor = scheme.tertiary);
      _flashController.repeat(reverse: true);
      Future.delayed(
          const Duration(milliseconds: 800), () => _flashController.stop());
    } else if (command == 'BASS DROP') {
      // Blackout then flash
      setState(() => _flashColor = scheme.onSurface);
      Future.delayed(const Duration(milliseconds: 500), () {
        _flashController.forward().then((_) => _flashController.reverse());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // ── VISUAL STIM OVERLAY ──
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              return Container(
                color: _flashColor.withValues(
                    alpha: _flashAnimation.value * 0.3),
              );
            },
          ),
        ),
      ],
    );
  }
}
