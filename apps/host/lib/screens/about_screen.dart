import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'ABOUT',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          const CBSectionHeader(
            title: 'CLUB BLACKOUT: REBORN',
            icon: Icons.info_outline,
            color: CBColors.electricCyan,
          ),
          const SizedBox(height: 12),
          CBPanel(
            borderColor: CBColors.electricCyan.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOST CONTROL APP',
                  style: textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2.0,
                    color: CBColors.hotPink,
                    shadows:
                        CBColors.textGlow(CBColors.hotPink, intensity: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0+1',
                  style: textTheme.bodyMedium?.copyWith(
                    color: CBColors.textDim,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Runs the lobby, scripting engine, tactical dashboard, and session recaps.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CBSectionHeader(
            title: 'PRIVACY',
            icon: Icons.privacy_tip_outlined,
            color: CBColors.matrixGreen,
          ),
          const SizedBox(height: 12),
          CBGlassTile(
            title: 'PRIVACY POLICY',
            subtitle: 'DATA COLLECTION + CLOUD SYNC DETAILS',
            accentColor: CBColors.matrixGreen,
            isPrismatic: true,
            icon: const Icon(Icons.chevron_right_rounded,
                color: CBColors.matrixGreen),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
            content: Text(
              'View what is stored locally, what is synced in cloud mode, and how to clear your data.',
              style: textTheme.bodySmall?.copyWith(
                color: CBColors.textDim,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
