import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

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
      useSafeArea: false, // PageView items handle layout safely
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
                  onPressed: () {
                    HapticService.heavy();
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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

  Widget _buildConnectPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Join a game. Enter the code from the host screen.',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CBFadeSlide(
                child: Text(
                  'UPLINK INITIATED',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x2),
              CBFadeSlide(
                delay: const Duration(milliseconds: 50),
                child: Text(
                  'ESTABLISH SECURE LINK VIA JOIN CODE.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Expanded(child: ConnectScreen()),
              const SizedBox(height: CBSpace.x4),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: CBGhostButton(
                  label: 'BACK TO IDENTITY CHECK',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    HapticService.light();
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
