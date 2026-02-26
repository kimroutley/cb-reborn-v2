import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/player_auth_screen.dart';
import 'connect_screen.dart';

class PlayerOnboardingScreen extends ConsumerStatefulWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  ConsumerState<PlayerOnboardingScreen> createState() =>
      _PlayerOnboardingScreenState();
}

class _PlayerOnboardingScreenState
    extends ConsumerState<PlayerOnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CBPrismScaffold(
      title: 'Onboarding',
      showAppBar: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildIntroPage(context),
          PlayerAuthScreen(
            onSignedIn: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          _buildConnectPage(context),
        ],
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBNeonBackground(
      showOverlay: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.nightlife_rounded,
                size: 80,
                color: scheme.secondary,
                shadows: CBColors.iconGlow(scheme.secondary),
              ),
              const SizedBox(height: 32),
              Text(
                'SURVIVE THE NIGHT',
                textAlign: TextAlign.center,
                style: textTheme.displayMedium!.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CLUB BLACKOUT REBORN',
                style: textTheme.labelLarge!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 48),
              CBPanel(
                borderColor: scheme.secondary.withValues(alpha: 0.5),
                child: Column(
                  children: [
                    Text(
                      'TRUST NO ONE. DECEIVE EVERYONE. FIND THE DEALER.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge!.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join the lobby, receive your secret role, and use your abilities to outwit the competition. The party ends when you say it does.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CBPrimaryButton(
                label: 'ENTER THE CLUB',
                icon: Icons.login_rounded,
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: scheme.secondary.withValues(alpha: 0.2),
                foregroundColor: scheme.secondary,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectPage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ConnectScreen(),
            const SizedBox(height: 24),
            CBGhostButton(
              label: 'BACK TO LOGIN',
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
