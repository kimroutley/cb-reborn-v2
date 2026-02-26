import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import '../colors.dart';
import 'cb_panel.dart';
import 'cb_role_avatar.dart';

/// A high-fidelity, interactive alliance graph.
class CBAllianceGraph extends StatelessWidget {
  final List<Role> roles;
  final String? activeRoleId;

  const CBAllianceGraph({
    super.key,
    required this.roles,
    this.activeRoleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    // Logic: Group roles by alliance for a clean layout
    final staff = roles.where((r) => r.alliance == Team.clubStaff).toList();
    final animals = roles.where((r) => r.alliance == Team.partyAnimals).toList();
    final neutral = roles.where((r) => r.alliance == Team.neutral).toList();

    return CBPanel(
      padding: const EdgeInsets.all(24),
      borderColor: scheme.primary.withValues(alpha: 0.15),
      child: Column(
        children: [
          _buildTeamSection(context, "THE DEALERS (KILLERS)", staff, scheme.error),
          const SizedBox(height: 32),
          _buildTeamSection(context, "THE PARTY ANIMALS", animals, scheme.primary),
          if (neutral.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildTeamSection(context, "THE WILDCARDS", neutral, scheme.tertiary),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, String title, List<Role> roles, Color titleColor) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: CBColors.boxGlow(titleColor, intensity: 0.2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: roles.map((role) {
            final isActive = role.id == activeRoleId;
            final isLinked = _isMvpLinked(activeRoleId, role.id);
            final roleColor = CBColors.fromHex(role.colorHex);

            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? roleColor : (isLinked ? roleColor.withValues(alpha: 0.6) : Colors.transparent),
                  width: 2,
                ),
                boxShadow: isActive ? CBColors.boxGlow(roleColor, intensity: 0.4) : null,
              ),
              child: CBRoleAvatar(
                assetPath: role.assetPath,
                color: roleColor,
                size: 32,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isMvpLinked(String? sourceId, String targetId) {
    if (sourceId == null) return false;
    final links = {
      RoleIds.allyCat: [RoleIds.bouncer],
      RoleIds.bouncer: [RoleIds.allyCat, RoleIds.medic],
      RoleIds.medic: [RoleIds.bouncer, RoleIds.wallflower],
      RoleIds.dealer: [RoleIds.whore, RoleIds.silverFox],
      RoleIds.whore: [RoleIds.dealer],
      RoleIds.wallflower: [RoleIds.bouncer],
    };
    return links[sourceId]?.contains(targetId) ?? false;
  }
}
