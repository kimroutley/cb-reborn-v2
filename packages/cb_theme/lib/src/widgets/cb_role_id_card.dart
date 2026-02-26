import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import '../colors.dart';
import 'cb_role_avatar.dart';

/// A high-fidelity, interactive role ID card.
class CBRoleIDCard extends StatelessWidget {
  final Role role;
  final VoidCallback? onTap;

  const CBRoleIDCard({
    super.key,
    required this.role,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = CBColors.fromHex(role.colorHex);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'role_avatar_${role.name}',
                  child: CBRoleAvatar(
                    assetPath: role.assetPath,
                    color: color,
                    size: 56,
                    pulsing: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          shadows: CBColors.textGlow(color, intensity: 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              role.type.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (role.nightPriority > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              "PRIORITY ${role.nightPriority}",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
