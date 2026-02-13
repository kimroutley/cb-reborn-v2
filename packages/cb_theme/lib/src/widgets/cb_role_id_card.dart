import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

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
    final color = CBColors.roleColorFromHex(role.colorHex);

    return CBGlassTile(
      title: role.name,
      subtitle: _allianceName(role.alliance),
      accentColor: color,
      isPrismatic: true,
      onTap: onTap,
      icon: CBRoleAvatar(
        assetPath: role.assetPath,
        color: color,
        size: 56,
        breathing: true,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CBBadge(text: 'CLASS: ${role.type}', color: color),
              const SizedBox(width: 8),
              CBBadge(
                text: 'PRIORITY: ${role.nightPriority}',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            role.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _allianceName(Team t) => switch (t) {
        Team.clubStaff => "THE DEALERS (KILLERS)",
        Team.partyAnimals => "THE PARTY ANIMALS (INNOCENTS)",
        Team.neutral => "WILDCARDS (VARIABLES)",
        _ => "UNKNOWN",
      };
}
