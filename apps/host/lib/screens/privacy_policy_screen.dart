import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import '../widgets/simulation_mode_badge_action.dart';

/// Privacy Policy screen displaying data collection and usage information.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CBPrismScaffold(
      title: 'Privacy Policy',
      actions: const [SimulationModeBadgeAction()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              context,
              'Data Collection',
              'Club Blackout Reborn collects minimal data necessary for gameplay. '
                  'In local mode, all data is stored on your device. In cloud mode, '
                  'game state is synchronized via Firebase Firestore.',
            ),
            _buildSection(
              context,
              'Game Data',
              'Player names, role assignments, game actions, and chat messages '
                  'are stored temporarily during active games. This data is deleted '
                  'when you delete a game or clear app data.',
            ),
            _buildSection(
              context,
              'Analytics',
              'We may collect anonymous usage statistics to improve the game. '
                  'This includes screen views, button clicks, and crash reports. '
                  'No personally identifiable information is collected.',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              'This app uses Firebase (Google) for cloud synchronization and '
                  'analytics. Please review Google\'s Privacy Policy for details on '
                  'how they handle data.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'You can delete your game data at any time by clearing the app\'s '
                  'storage in your device settings. For cloud games, deleting the '
                  'game will remove it from Firebase.',
            ),
            _buildSection(
              context,
              'Contact',
              'For privacy concerns or data deletion requests, please contact '
                  'the developer through the app store page.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CBPanel(
          margin: const EdgeInsets.only(bottom: 16),
          borderColor: scheme.primary.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge!.copyWith(
                  color: scheme.primary,
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
