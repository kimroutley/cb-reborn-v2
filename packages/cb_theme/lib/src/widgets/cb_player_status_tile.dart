import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// Unified player status tile for the host feed.
class CBPlayerStatusTile extends StatelessWidget {
  final String playerName;
  final String roleName;
  final String? assetPath;
  final Color? roleColor;
  final bool isAlive;
  final List<String> statusEffects;

  const CBPlayerStatusTile({
    super.key,
    required this.playerName,
    required this.roleName,
    this.assetPath,
    this.roleColor,
    this.isAlive = true,
    this.statusEffects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accentColor = roleColor ?? scheme.primary;

    return CBFadeSlide(
      child: CBGlassTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: accentColor.withValues(alpha: 0.3),
        child: Row(
          children: [
            CBRoleAvatar(
              assetPath: assetPath,
              color: accentColor,
              size: 36,
              breathing: isAlive && statusEffects.isNotEmpty,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playerName.toUpperCase(),
                    style: textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFamily: 'RobotoMono',
                      color: isAlive
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.5),
                      decoration: isAlive ? null : TextDecoration.lineThrough,
                      shadows: isAlive
                          ? CBColors.textGlow(accentColor, intensity: 0.3)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CBMiniTag(
                    text: roleName.toUpperCase(),
                    color: accentColor,
                  ),
                ],
              ),
            ),
            if (!isAlive)
              CBBadge(
                  text: 'DE-ACTIVATED',
                  color: scheme.error,
                  icon: Icons.cancel_rounded)
            else if (statusEffects.isNotEmpty)
              Wrap(
                spacing: 6,
                children: statusEffects
                    .map(
                      (effect) => CBBadge(
                        text: effect.toUpperCase(),
                        color: _statusColor(context, effect),
                        icon: _statusIcon(effect),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData? _statusIcon(String effect) {
    return switch (effect.toLowerCase()) {
      'protected' => Icons.shield_rounded,
      'silenced' => Icons.voice_over_off_rounded,
      'id checked' => Icons.badge_rounded,
      'sighted' => Icons.visibility_rounded,
      'alibi' => Icons.fingerprint_rounded,
      'sent home' => Icons.home_rounded,
      'clinging' => Icons.link_rounded,
      'paralysed' || 'paralyzed' => Icons.bolt_rounded,
      _ => null,
    };
  }

  Color _statusColor(BuildContext context, String effect) {
    final scheme = Theme.of(context).colorScheme;
    return switch (effect.toLowerCase()) {
      'protected' => scheme.tertiary,
      'silenced' => CBColors.alertOrange,
      'id checked' => scheme.primary,
      'sighted' => scheme.secondary,
      'alibi' => scheme.primary,
      'sent home' => scheme.secondary,
      'clinging' => scheme.tertiary,
      'paralysed' || 'paralyzed' => scheme.error,
      _ => scheme.outline,
    };
  }
}
