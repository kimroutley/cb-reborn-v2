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
      title: 'Onboarding',
      showAppBar: false,
      body: PageView(
        controller: _pageController,
        children: [
          _buildIntroPage(context),
          const HostAuthScreen(),
          _buildAboutPage(context),
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
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: scheme.primary,
                shadows: CBColors.iconGlow(scheme.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'COMMAND THE NIGHT',
                textAlign: TextAlign.center,
                style: textTheme.displayMedium!.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
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
                borderColor: scheme.primary.withValues(alpha: 0.5),
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
                label: 'CONTINUE',
                icon: Icons.arrow_forward_rounded,
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
        ),
      ),
    );
  }

  Widget _buildAboutPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CBPrismScaffold(
      title: 'About',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Text('ABOUT', style: textTheme.headlineMedium),
            const SizedBox(height: 24),
            CBPanel(
              margin: const EdgeInsets.only(bottom: 16),
              borderColor: scheme.primary.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATA COLLECTION',
                    style: textTheme.labelLarge!.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Club Blackout Reborn collects minimal data necessary for gameplay. '
                    'In local mode, all data is stored on your device. In cloud mode, '
                    'game state is synchronized via Firebase Firestore.',
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 48),
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
