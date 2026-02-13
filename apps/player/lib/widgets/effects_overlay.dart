import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import '../room_effects_provider.dart';

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
          _buildFlickerEffect(context, effectState.activeEffectPayload),
        if (effectState.activeEffect == EFFECT_GLITCH)
          _buildGlitchEffect(context, effectState.activeEffectPayload),
        if (effectState.activeEffect == EFFECT_TOAST)
          _buildToastEffect(context, effectState.activeEffectPayload),
      ],
    );
  }

  Widget _buildFlickerEffect(
      BuildContext context, Map<String, dynamic>? payload) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 0.3), // Black overlay opacity
        duration: const Duration(milliseconds: 100), // Quick flash
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Container(color: Colors.black),
          );
        },
        onEnd: () {
          // Reset effect state after animation
          // This is handled by RoomEffectsNotifier's triggerEffect delayed clearing.
        },
      ),
    );
  }

  Widget _buildGlitchEffect(
      BuildContext context, Map<String, dynamic>? payload) {
    // A simple color overlay for now. More complex shaders would be ideal.
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 0.2), // Green overlay opacity
        duration: const Duration(milliseconds: 50),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Container(color: Theme.of(context).colorScheme.tertiary),
          );
        },
        onEnd: () {
          // Handled by RoomEffectsNotifier
        },
      ),
    );
  }

  Widget _buildToastEffect(
      BuildContext context, Map<String, dynamic>? payload) {
    final textTheme = Theme.of(context).textTheme;
    final message = payload?['message'] as String? ?? 'Host Announcement';
    // Using a basic overlay that fades out
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
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                      ),
                      boxShadow: CBColors.boxGlow(
                        Theme.of(context).colorScheme.primary,
                        intensity: 0.12,
                      ),
                    ),
                    child: Text(
                      message,
                      style: textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
