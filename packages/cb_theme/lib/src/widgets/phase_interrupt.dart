import 'dart:ui';
import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// A high-impact, full-screen overlay for phase transitions.
/// Ported from the "Legacy" PhaseCard style with modern polish.
class CBPhaseInterrupt extends StatefulWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const CBPhaseInterrupt({
    super.key,
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<CBPhaseInterrupt> createState() => _CBPhaseInterruptState();
}

class _CBPhaseInterruptState extends State<CBPhaseInterrupt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Frosted Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: CBColors.voidBlack.withValues(alpha: 0.78),
                ),
              ),
            ),

            // Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Massive Icon with Radial Glow
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: widget.accentColor, width: 3),
                          boxShadow: CBColors.circleGlow(widget.accentColor,
                              intensity: 1.5),
                        ),
                        child: Icon(widget.icon,
                            size: 100, color: widget.accentColor),
                      ),
                      const SizedBox(height: 48),

                      // Phase Title (Hyperwave)
                      Text(
                        widget.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 4,
                              shadows: CBColors.textGlow(widget.accentColor,
                                  intensity: 2.0),
                            ),
                      ),

                      const SizedBox(height: 16),

                      // Decorative Line - Replaced gradient with solid color
                      Container(
                        width: 200,
                        height: 2,
                        color: widget.accentColor.withValues(alpha: 0.4),
                      ),

                      const SizedBox(height: 64),

                      // Tap to Continue Prompt
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          "TAP TO START",
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    letterSpacing: 3,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
