import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

void showRoleDetailDialog(BuildContext context, Role role) {
  final roleColor = CBColors.fromHex(role.colorHex);
  showThemedDialog(
    context: context,
    child: Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: CBRoleAvatar(
                  assetPath: role.assetPath,
                  color: roleColor,
                  size: 120,
                  breathing: true,
                ),
              ),
              const SizedBox(height: 24),
              CBFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  role.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium!.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    shadows: [
                      Shadow(
                        color: roleColor.withValues(alpha: 0.8),
                        blurRadius: 12,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CBFadeSlide(
                delay: const Duration(milliseconds: 250),
                child: CBBadge(
                  text: 'STRATEGIC CLASS: ${role.type}',
                  color: roleColor,
                ),
              ),
              const SizedBox(height: 32),
              CBFadeSlide(
                delay: const Duration(milliseconds: 350),
                child: CBPanel(
                  borderColor: roleColor.withValues(alpha: 0.2),
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CBSectionHeader(
                        title: 'DOSSIER',
                        icon: Icons.description_outlined,
                        color: roleColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        role.description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (role.tacticalTip.isNotEmpty) ...[
                const SizedBox(height: 16),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 450),
                  child: CBPanel(
                    borderColor: scheme.secondary.withValues(alpha: 0.2),
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CBSectionHeader(
                          title: 'TACTICAL TIP',
                          icon: Icons.lightbulb_outline_rounded,
                          color: scheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          role.tacticalTip,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CBFadeSlide(
                delay: const Duration(milliseconds: 550),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDetailStat(
                        context,
                        'WAKE PRIORITY',
                        'LVL ${role.nightPriority}',
                        roleColor,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailStat(
                        context,
                        'ALLIANCE',
                        _allianceName(role.alliance),
                        roleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    ),
  );
}

String _allianceName(Team t) => switch (t) {
      Team.clubStaff => 'THE DEALERS',
      Team.partyAnimals => 'PARTY ANIMALS',
      Team.neutral => 'WILDCARDS',
      _ => 'UNKNOWN',
    };

Widget _buildDetailStat(
    BuildContext context, String label, String value, Color color) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        Container(width: 40, height: 1, color: color.withValues(alpha: 0.2)),
      ],
    ),
  );
}
