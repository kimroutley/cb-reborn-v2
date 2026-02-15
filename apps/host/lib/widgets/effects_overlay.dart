import 'dart:ui';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EffectsOverlay extends ConsumerWidget {
  final Widget child;

  const EffectsOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectState = ref.watch(roomEffectsProvider);

    if (effectState.activeEffect == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        if (effectState.activeEffect == EFFECT_FLICKER)
          _buildFlickerEffect(context),
        if (effectState.activeEffect == EFFECT_GLITCH)
          _buildGlitchEffect(context),
        if (effectState.activeEffect == EFFECT_TOAST)
          _buildToastEffect(context, effectState.activeEffectPayload),
      ],
    );
  }

  Widget _buildFlickerEffect(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 0.3),
        duration: const Duration(milliseconds: 100),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Container(color: scheme.surface),
          );
        },
      ),
    );
  }

  Widget _buildGlitchEffect(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 0.2),
        duration: const Duration(milliseconds: 50),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Container(color: scheme.tertiary),
          );
        },
      ),
    );
  }

  Widget _buildToastEffect(
      BuildContext context, Map<String, dynamic>? payload) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final message = payload?['message'] as String? ?? 'Host Announcement';
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      message,
                      style: textTheme.bodyLarge!.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
