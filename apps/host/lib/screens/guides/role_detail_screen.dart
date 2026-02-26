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
            CBPanel(
              borderColor: accent.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.name.toUpperCase(),
                              style: textTheme.headlineSmall!.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${role.type.toUpperCase()} • ${role.alliance.name.toUpperCase()}',
                              style: textTheme.labelMedium!.copyWith(
                                color: accent.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CBRoleAvatar(
                        assetPath: role.assetPath,
                        color: accent,
                        size: 48,
                        breathing: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
            if (role.tacticalTip.isNotEmpty) ...[
              CBSectionHeader(
                title: 'HOST NOTES',
                icon: Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              CBPanel(
                borderColor: accent.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.tacticalTip,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    if (role.hasBinaryChoiceAtStart &&
                        role.choices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'STARTING CHOICE',
                        style: textTheme.labelLarge?.copyWith(
                          color: accent,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'At the start of the game, this player will choose between: ${role.choices.join(' or ')}.',
                        style: textTheme.bodyMedium,
                      ),
                    ]
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
