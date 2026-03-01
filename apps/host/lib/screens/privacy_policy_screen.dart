import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/custom_drawer.dart';

/// Privacy Policy screen displaying data collection and usage information.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'DATA PROTOCOLS',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CBFadeSlide(
              child: _buildSection(
                context,
                Icons.shield_rounded,
                'DATA COLLECTION',
                'CLUB BLACKOUT REBORN COLLECTS MINIMAL DATA NECESSARY FOR GAMEPLAY. '
                    'IN LOCAL MODE, ALL DATA IS STORED ON YOUR DEVICE. IN CLOUD MODE, '
                    'GAME STATE IS SYNCHRONIZED VIA FIREBASE FIRESTORE.',
                scheme.primary,
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: _buildSection(
                context,
                Icons.gamepad_rounded,
                'GAME DATA',
                'OPERATIVE NAMES, ROLE ASSIGNMENTS, GAME ACTIONS, AND CHAT MESSAGES '
                    'ARE STORED TEMPORARILY DURING ACTIVE SESSIONS. THIS DATA IS DELETED '
                    'WHEN YOU TERMINATE A SESSION OR CLEAR ARCHIVES.',
                scheme.secondary,
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                context,
                Icons.analytics_rounded,
                'ANALYTICS & TELEMETRY',
                'WE MAY COLLECT ANONYMOUS USAGE STATISTICS TO IMPROVE SYSTEM STABILITY. '
                    'THIS INCLUDES SCREEN VIEWS, INTERACTION LOGS, AND CRASH REPORTS. '
                    'NO PERSONALLY IDENTIFIABLE INFORMATION IS COLLECTED.',
                scheme.tertiary,
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                context,
                Icons.cloud_rounded,
                'THIRD-PARTY PROTOCOLS',
                'THIS APPLICATION UTILIZES GOOGLE FIREBASE FOR CLOUD SYNCHRONIZATION AND '
                    'ANALYTICS. PLEASE REVIEW GOOGLE\'S PRIVACY POLICY FOR DATA HANDLING DETAILS.',
                scheme.primary,
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                context,
                Icons.security_rounded,
                'OPERATIVE RIGHTS',
                'YOU RETAIN THE RIGHT TO PURGE YOUR GAME DATA AT ANY TIME VIA THE SETTINGS MENU. '
                    'CLOUD-SYNCHRONIZED DATA CAN BE REMOVED BY TERMINATING SESSIONS.',
                scheme.error,
              ),
            ),
            const SizedBox(height: CBSpace.x4),
            CBFadeSlide(
              delay: const Duration(milliseconds: 500),
              child: _buildSection(
                context,
                Icons.contact_support_rounded,
                'SUPPORT & CONTACT',
                'FOR PROTOCOL CONCERNS OR DATA ERASURE REQUESTS, CONTACT '
                    'KYRIAN CO. SUPPORT VIA THE APPLICATION STORE PAGE.',
                scheme.secondary,
              ),
            ),
            const SizedBox(height: CBSpace.x12),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, IconData icon, String title, String content, Color accentColor) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CBPanel(
      margin: const EdgeInsets.only(bottom: CBSpace.x4),
      borderColor: accentColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CBSpace.x2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.1),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: textTheme.labelLarge!.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: CBColors.textGlow(accentColor, intensity: 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            content.toUpperCase(),
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
