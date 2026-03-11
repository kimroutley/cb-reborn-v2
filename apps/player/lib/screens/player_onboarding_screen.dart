import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
// conditional import to not break Android builds:
import 'package:universal_html/html.dart' as web;

import '../shared_prefs_provider.dart';

class PlayerOnboardingScreen extends ConsumerWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CBPrismScaffold(
      title: 'JOIN THE CLUB',
      showAppBar: false,
      useSafeArea: false,
      body: _buildIntroPage(context, ref),
    );
  }

  Widget _buildIntroPage(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      label:
          'Club Blackout Reborn. Social deduction game. Trust no one, find the dealer.',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CBFadeSlide(
                child: Hero(
                  tag: 'auth_icon',
                  child: Container(
                    padding: const EdgeInsets.all(CBSpace.x6),
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.secondary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow:
                          CBColors.circleGlow(scheme.secondary, intensity: 0.4),
                    ),
                    child: Icon(
                      Icons.nightlife_rounded,
                      size: 80,
                      color: scheme.secondary,
                      shadows: CBColors.iconGlow(scheme.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x10),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: Column(
                  children: [
                    Text(
                      'SURVIVE THE NIGHT',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium!.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        height: 0.9,
                        shadows:
                            CBColors.textGlow(scheme.secondary, intensity: 0.8),
                      ),
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBBadge(
                      text: 'REBORN',
                      color: scheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CBSpace.x12),
              CBFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: CBPanel(
                  borderColor: scheme.secondary.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(CBSpace.x6),
                  child: Column(
                    children: [
                      Text(
                        'TRUST NO ONE. DECEIVE EVERYONE. FIND THE DEALER.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        'JOIN THE LOBBY, SECURE YOUR IDENTITY, AND DEPLOY YOUR SKILLS TO CONTROL THE FLOOR.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              CBFadeSlide(
                delay: const Duration(milliseconds: 300),
                child: CBPrimaryButton(
                  label: 'ENTER THE CLUB',
                  icon: Icons.login_rounded,
                  onPressed: () async {
                    HapticService.heavy();
                    final prefs = ref.read(sharedPrefsProvider);
                    await prefs.setBool('hasSeenPlayerIntro', true);
                    ref.read(playerIntroSeenProvider.notifier).setSeen(true);
                  },
                  backgroundColor: scheme.secondary,
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: CBSpace.x4),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 400),
                  child: TextButton.icon(
                    icon: Icon(Icons.system_update_rounded, size: 16, color: scheme.onSurfaceVariant),
                    label: Text(
                      'FORCE UPDATE / CLEAR CACHE',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: () {
                      HapticService.light();
                      web.window.location.reload();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: CBSpace.x6),
            ],
          ),
        ),
      ),
    );
  }
}
