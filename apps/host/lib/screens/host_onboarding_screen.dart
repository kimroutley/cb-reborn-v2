import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/host_auth_screen.dart';
import 'package:cb_theme/cb_theme.dart';

class HostOnboardingScreen extends ConsumerStatefulWidget {
  const HostOnboardingScreen({super.key});

  @override
  ConsumerState<HostOnboardingScreen> createState() =>
      _HostOnboardingScreenState();
}

class _HostOnboardingScreenState extends ConsumerState<HostOnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CBPrismScaffold(
      title: 'HOST ONBOARDING',
      showAppBar: false,
      useSafeArea: false, // PageView items handle layout within safely
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
        children: [
          _buildIntroPage(context),
          HostAuthScreen(
            isEmbedded: true,
            onSignedIn: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          _buildAboutPage(context),
        ],
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CBSpace.x6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CBFadeSlide(
              child: Hero(
                tag: 'host_auth_icon',
                child: Container(
                  padding: const EdgeInsets.all(CBSpace.x6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.4),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: CBSpace.x16 * 1.25,
                    color: scheme.primary,
                    shadows: CBColors.iconGlow(scheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x10),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'COMMAND\nTHE NIGHT',
                textAlign: TextAlign.center,
                style: textTheme.displayMedium!.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  letterSpacing: 4.0,
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: CBBadge(
                text: 'HOST PROTOCOL',
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: CBSpace.x12),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(CBSpace.x6),
                child: Column(
                  children: [
                    Text(
                      'SECURITY CLEARANCE REQUIRED',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge!.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: CBSpace.x4),
                    Text(
                      'MANAGE ROLES, RESOLVE NIGHT ACTIONS, AND ORCHESTRATE THE ULTIMATE SOCIAL DEDUCTION EXPERIENCE.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: CBPrimaryButton(
                label: 'INITIALIZE HOST PROTOCOL',
                icon: Icons.fingerprint_rounded,
                onPressed: () {
                  HapticService.heavy();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            const SizedBox(height: CBSpace.x6),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x8, CBSpace.x6, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            CBFadeSlide(
              child: Text(
                'LEGAL & DATA PROTOCOLS',
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: CBColors.textGlow(scheme.primary),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x8),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: CBPanel(
                margin: const EdgeInsets.only(bottom: CBSpace.x6),
                borderColor: scheme.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(CBSpace.x6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CBSectionHeader(
                      title: 'DATA COLLECTION',
                      icon: Icons.shield_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: CBSpace.x4),
                    Text(
                      'CLUB BLACKOUT REBORN COLLECTS MINIMAL DATA NECESSARY FOR GAMEPLAY. '
                      'IN LOCAL MODE, ALL DATA IS STORED ON YOUR DEVICE. IN CLOUD MODE, '
                      'GAME STATE IS SYNCHRONIZED VIA FIREBASE FIRESTORE.',
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: CBPanel(
                margin: const EdgeInsets.only(bottom: CBSpace.x8),
                borderColor: scheme.secondary.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(CBSpace.x6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CBSectionHeader(
                      title: 'SYSTEM STABILITY',
                      icon: Icons.terminal_rounded,
                      color: scheme.secondary,
                    ),
                    const SizedBox(height: CBSpace.x4),
                    Text(
                      'THIS SOFTWARE IS PROVIDED AS-IS. WE ARE NOT RESPONSIBLE FOR '
                      'BROKEN FRIENDSHIPS OR EMOTIONAL DISTRESS CAUSED BY BETRAYAL.',
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: CBGhostButton(
                label: 'BACK TO SYSTEM ACCESS',
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  HapticService.medium();
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
