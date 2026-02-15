import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../../widgets/simulation_mode_badge_action.dart';

class RoleDetailScreen extends StatelessWidget {
  final Role role;

  const RoleDetailScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final accent = CBColors.fromHex(role.colorHex);
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: role.name,
      actions: const [SimulationModeBadgeAction()],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          CBGlassTile(
            title: role.name.toUpperCase(),
            subtitle:
                '${role.type.toUpperCase()} • ${role.alliance.name.toUpperCase()}',
            accentColor: accent,
            shimmerBaseColor: accent,
            isPrismatic: true,
            icon: CBRoleAvatar(
              assetPath: role.assetPath,
              color: accent,
              size: 48,
              breathing: true,
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBBadge(
                  text: 'OPERATIVE CLASS: ${role.type}',
                  color: accent,
                ),
                const SizedBox(height: 12),
                Text(
                  role.description,
                  style: textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 12),
                if ((role.ability ?? '').isNotEmpty) ...[
                  Text(
                    'ABILITY',
                    style: textTheme.labelLarge?.copyWith(
                      color: accent,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role.ability!,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CBSectionHeader(
            title: 'HOST NOTES',
            icon: Icons.visibility,
            color: CBColors.electricCyan,
          ),
          const SizedBox(height: 12),
          CBPanel(
            borderColor: accent.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Night priority: ${role.nightPriority}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start alliance: ${(role.startAlliance ?? role.alliance).name.toUpperCase()}',
                  style: textTheme.bodyMedium,
                ),
                if (role.deathAlliance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alliance on death: ${role.deathAlliance!.name.toUpperCase()}',
                    style: textTheme.bodyMedium,
                  ),
                ],
                if (role.hasBinaryChoiceAtStart && role.choices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'START CHOICE',
                    style: textTheme.labelLarge?.copyWith(
                      color: CBColors.hotPink,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...role.choices.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $c', style: textTheme.bodyMedium),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
