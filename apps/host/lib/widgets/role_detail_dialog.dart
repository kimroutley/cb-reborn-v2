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
              CBRoleAvatar(
                assetPath: role.assetPath,
                color: roleColor,
                size: 120,
                breathing: true,
              ),
              const SizedBox(height: 24),
              Text(
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
              const SizedBox(height: 12),
              CBBadge(
                text: 'STRATEGIC CLASS: ${role.type}',
                color: roleColor,
              ),
              const SizedBox(height: 32),
              CBPanel(
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
              if (role.tacticalTip.isNotEmpty) ...[
                const SizedBox(height: 16),
                CBPanel(
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
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    ),
  );
}
