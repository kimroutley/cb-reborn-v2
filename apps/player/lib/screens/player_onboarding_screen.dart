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
      title: 'JOIN THE CLUB',
      showAppBar: false,
      useSafeArea: false, // PageView items handle layout within safely
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildIntroPage(context),
          PlayerAuthScreen(
            isEmbedded: true,
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

    return Semantics(
      label: 'Club Blackout Reborn. Social deduction game. Trust no one, find the dealer.',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CBFadeSlide(
                child: Hero(
                  tag: 'auth_icon',
                  child: CBRoleAvatar(
                    color: scheme.secondary,
                    size: 100,
                    pulsing: true,
                    icon: Icons.nightlife_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'CLUB BLACKOUT',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    height: 0.9,
                    color: scheme.secondary,
                    shadows: CBColors.textGlow(scheme.secondary, intensity: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CBFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: CBBadge(
                  text: 'REBORN',
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 48),
              CBFadeSlide(
                delay: const Duration(milliseconds: 300),
                child: CBPanel(
                  child: Column(
                    children: [
                      Text(
                        'TRUST NO ONE.\nDECEIVE EVERYONE.\nFIND THE DEALER.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in, then enter a game code to join the lobby and receive your secret role.',
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
                delay: const Duration(milliseconds: 400),
                child: Semantics(
                  button: true,
                  label: 'Enter the club: sign in or create account',
                  child: CBPrimaryButton(
                    label: 'ENTER THE CLUB',
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Join a game. Enter the code from the host screen.',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Enter the code from the host to join the game.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const Expanded(child: ConnectScreen()),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Back to sign in',
                child: CBGhostButton(
                  label: 'BACK TO LOGIN',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
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
      ),
    );
  }
}
