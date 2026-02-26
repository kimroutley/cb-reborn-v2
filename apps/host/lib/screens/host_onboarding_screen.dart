import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/host_auth_screen.dart';
import 'package:cb_theme/cb_theme.dart';

class HostOnboardingScreen extends ConsumerStatefulWidget {
  const HostOnboardingScreen({super.key});

  @override
  ConsumerState<HostOnboardingScreen> createState() => _HostOnboardingScreenState();
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
      title: 'Host Onboarding',
      showAppBar: false,
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Hero(
            tag: 'host_auth_icon',
            child: CBRoleAvatar(
              color: scheme.primary,
              size: 100,
              pulsing: true,
              icon: Icons.admin_panel_settings_rounded,
            ),
          ),
          const SizedBox(height: 32),
          Text(
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
          const SizedBox(height: 16),
          CBBadge(
            text: 'HOST PROTOCOL',
            color: scheme.primary,
          ),
          const SizedBox(height: 48),
          CBPanel(
            borderColor: scheme.primary.withValues(alpha: 0.3),
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
                const SizedBox(height: 16),
                Text(
                  'Manage roles, trigger narrative events, and control the chaos from your dashboard. Keep the party alive... or watch it burn.',
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
            label: 'INITIALIZE SYSTEM',
            backgroundColor: scheme.primary,
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAboutPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              'LEGAL & DATA PROTOCOLS',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                shadows: CBColors.textGlow(scheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            CBPanel(
              margin: const EdgeInsets.only(bottom: 24),
              borderColor: scheme.primary.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded, color: scheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'DATA COLLECTION',
                        style: textTheme.titleSmall!.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Club Blackout Reborn collects minimal data necessary for gameplay. '
                    'In local mode, all data is stored on your device. In cloud mode, '
                    'game state is synchronized via Firebase Firestore.',
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            CBPanel(
              margin: const EdgeInsets.only(bottom: 32),
              borderColor: scheme.secondary.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.terminal_rounded,
                          color: scheme.secondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'SYSTEM STABILITY',
                        style: textTheme.titleSmall!.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This software is provided as-is. We are not responsible for '
                    'broken friendships or emotional distress caused by betrayal.',
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CBGhostButton(
              label: 'BACK TO SYSTEM ACCESS',
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
