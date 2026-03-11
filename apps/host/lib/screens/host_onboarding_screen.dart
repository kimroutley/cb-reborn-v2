import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cb_theme/cb_theme.dart';
import '../shared_prefs_provider.dart';

class HostOnboardingScreen extends ConsumerWidget {
  const HostOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CBPrismScaffold(
      title: 'Onboarding',
      showAppBar: false,
      body: _buildIntroPage(context, ref),
    );
  }

  Widget _buildIntroPage(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBNeonBackground(
      showOverlay: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CBFadeSlide(
                child: Hero(
                  tag: 'host_auth_icon',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CBRadius.md),
                    child: Image.asset(
                      'assets/images/neon_x_brand.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x8),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'COMMAND THE NIGHT',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x4),
              CBFadeSlide(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'CLUB BLACKOUT REBORN',
                  style: textTheme.labelLarge!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 4.0,
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x12),
              CBFadeSlide(
                delay: const Duration(milliseconds: 250),
                child: CBPanel(
                  borderColor: scheme.primary.withValues(alpha: 0.5),
                  padding: CBInsets.panel,
                  child: Column(
                    children: [
                      Text(
                        'YOU ARE THE HOST. THE DIRECTOR. THE GOD OF THIS CLUB.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        'VERIFY YOUR CLEARANCE TO MANAGE ROLES, TRIGGER EVENTS, AND CONTROL THE CHAOS.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              CBFadeSlide(
                delay: const Duration(milliseconds: 350),
                child: CBPrimaryButton(
                  label: 'INITIATE UPLINK',
                  icon: Icons.login_rounded,
                  onPressed: () async {
                    HapticService.heavy();
                    final prefs = ref.read(sharedPrefsProvider);
                    await prefs.setBool('hasSeenHostIntro', true);
                    ref.read(hostIntroSeenProvider.notifier).setSeen(true);
                  },
                ),
              ),
              const SizedBox(height: CBSpace.x6),
            ],
          ),
        ),
      ),
    );
  }
}
