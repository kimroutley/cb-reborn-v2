import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../../widgets/simulation_mode_badge_action.dart';

class RoleDetailScreen extends StatelessWidget {
  final Role role;

  const RoleDetailScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accent = CBColors.fromHex(role.colorHex);

    return CBPrismScaffold(
      title: 'OPERATIVE DOSSIER',
      actions: const [SimulationModeBadgeAction()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CBFadeSlide(
              child: CBGlassTile(
                borderColor: accent.withValues(alpha: 0.4),
                isPrismatic: true,
                padding: const EdgeInsets.all(CBSpace.x6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(CBSpace.x1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
                            boxShadow: CBColors.circleGlow(accent, intensity: 0.3),
                          ),
                          child: CBRoleAvatar(
                            assetPath: role.assetPath,
                            color: accent,
                            size: 64,
                            breathing: true,
                          ),
                        ),
                        const SizedBox(width: CBSpace.x5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.name.toUpperCase(),
                                style: textTheme.headlineSmall!.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  shadows: CBColors.textGlow(accent, intensity: 0.4),
                                ),
                              ),
                              const SizedBox(height: CBSpace.x1),
                              Text(
                                '${role.type.toUpperCase()} // ${role.alliance.name.toUpperCase()}',
                                style: textTheme.labelSmall!.copyWith(
                                  color: accent.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x6),
                    Row(
                      children: [
                        CBBadge(
                          text: 'PRIORITY: ${role.nightPriority}',
                          color: accent,
                          icon: Icons.speed_rounded,
                        ),
                        const SizedBox(width: 12),
                        CBBadge(
                          text: 'COMPLEXITY: ${role.complexity}/5',
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x6),
                    Container(
                      padding: const EdgeInsets.all(CBSpace.x4),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(CBRadius.sm),
                        border: Border.all(color: accent.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        role.description.toUpperCase(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: CBSpace.x6),

            if (role.ability != null && role.ability!.isNotEmpty) ...[
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: CBSectionHeader(
                  title: 'PRIMARY ABILITY',
                  icon: Icons.bolt_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(height: CBSpace.x3),
              CBFadeSlide(
                delay: const Duration(milliseconds: 150),
                child: CBPanel(
                  borderColor: accent.withValues(alpha: 0.3),
                  child: Text(
                    role.ability!.toUpperCase(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x6),
            ],

            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: CBSectionHeader(
                title: 'TACTICAL ADVISORY',
                icon: Icons.visibility_rounded,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            CBFadeSlide(
              delay: const Duration(milliseconds: 250),
              child: CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      role.tacticalTip.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.6,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (role.hasBinaryChoiceAtStart &&
                        role.choices.isNotEmpty) ...[
                      const SizedBox(height: CBSpace.x5),
                      Text(
                        'INITIALIZATION OPTIONS',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Wrap(
                        spacing: 8,
                        children: role.choices.map((choice) => CBMiniTag(
                          text: choice.toUpperCase(),
                          color: scheme.primary,
                        )).toList(),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
