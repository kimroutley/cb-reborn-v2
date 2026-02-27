import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/custom_drawer.dart';

/// Privacy Policy screen displaying data collection and usage information.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CBPrismScaffold(
      title: 'PRIVACY POLICY',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            CBFadeSlide(
              child: _buildSection(
                context,
                'DATA COLLECTION',
                'Club Blackout Reborn collects minimal data necessary for gameplay. '
                    'In local mode, all data is stored on your device. In cloud mode, '
                    'game state is synchronized via Firebase Firestore.',
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 60),
              child: _buildSection(
                context,
                'GAME DATA',
                'Player names, role assignments, game actions, and chat messages '
                    'are stored temporarily during active games. This data is deleted '
                    'when you delete a game or clear app data.',
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 120),
              child: _buildSection(
                context,
                'ANALYTICS',
                'We may collect anonymous usage statistics to improve the game. '
                    'This includes screen views, button clicks, and crash reports. '
                    'No personally identifiable information is collected.',
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 180),
              child: _buildSection(
                context,
                'THIRD-PARTY SERVICES',
                'This app uses Firebase (Google) for cloud synchronization and '
                    'analytics. Please review Google\'s Privacy Policy for details on '
                    'how they handle data.',
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 240),
              child: _buildSection(
                context,
                'YOUR RIGHTS',
                'You can delete your game data at any time by clearing the app\'s '
                    'storage in your device settings. For cloud games, deleting the '
                    'game will remove it from Firebase.',
              ),
            ),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                context,
                'CONTACT',
                'For privacy concerns or data deletion requests, please contact '
                    'the developer through the app store page.',
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CBPanel(
      margin: const EdgeInsets.only(bottom: 16),
      borderColor: scheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge!.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
