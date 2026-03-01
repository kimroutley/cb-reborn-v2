import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Full character card content: avatar, name, class, dossier, tactical intel,
/// priority/alliance/mission. Used inline in the lobby and in the role-reveal dialog.
/// When [onConfirm] is non-null, shows an "ACKNOWLEDGE IDENTITY" button at the bottom.
class FullRoleRevealContent extends StatelessWidget {
  final PlayerSnapshot player;
  final VoidCallback? onConfirm;

  const FullRoleRevealContent({
    super.key,
    required this.player,
    this.onConfirm,
  });

  String _allianceName(Team t) => switch (t) {
        Team.clubStaff => 'THE DEALERS',
        Team.partyAnimals => 'THE PARTY ANIMALS',
        Team.neutral => 'WILDCARDS',
        _ => 'UNKNOWN',
      };

  String _winConditionFor(Role role) {
    return switch (role.alliance) {
      Team.clubStaff => 'ELIMINATE ALL PARTY ANIMALS',
      Team.partyAnimals => 'EXPOSE AND EXILE ALL DEALERS',
      Team.neutral => 'FULFILL PERSONAL SURVIVAL GOALS',
      _ => 'SURVIVE THE NIGHT',
    };
  }

  Widget _buildDetailStat(
      BuildContext context, String label, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = CBColors.fromHex(player.roleColorHex);
    final role = roleCatalog.firstWhere((r) => r.id == player.roleId,
        orElse: () => roleCatalog.first);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CBFadeSlide(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: CBColors.circleGlow(roleColor, intensity: 0.4),
            ),
            child: CBRoleAvatar(
              assetPath: role.assetPath,
              color: roleColor,
              size: 100,
              breathing: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CBFadeSlide(
          delay: const Duration(milliseconds: 50),
          child: Text(
            player.roleName.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
              shadows: CBColors.textGlow(roleColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CBFadeSlide(
          delay: const Duration(milliseconds: 100),
          child: CBBadge(
            text: 'CLASS: ${role.type.toUpperCase()}',
            color: roleColor,
          ),
        ),
        const SizedBox(height: 24),
        CBFadeSlide(
          delay: const Duration(milliseconds: 150),
          child: CBPanel(
            borderColor: roleColor.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CBSectionHeader(
                  title: 'DOSSIER',
                  icon: Icons.assignment_ind_rounded,
                  color: roleColor,
                ),
                const SizedBox(height: 12),
                Text(
                  role.description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge!.copyWith(
                    height: 1.6,
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (role.tacticalTip.isNotEmpty) ...[
          const SizedBox(height: 16),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBPanel(
              borderColor: scheme.secondary.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'TACTICAL INTEL',
                    icon: Icons.tips_and_updates_rounded,
                    color: scheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role.tacticalTip,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        CBFadeSlide(
          delay: const Duration(milliseconds: 250),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailStat(
                context,
                'PRIORITY',
                'LEVEL ${role.nightPriority}',
                roleColor,
              ),
              _buildDetailStat(
                context,
                'ALLIANCE',
                _allianceName(role.alliance),
                roleColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CBFadeSlide(
          delay: const Duration(milliseconds: 300),
          child: _buildDetailStat(
            context,
            'MISSION OBJECTIVE',
            _winConditionFor(role),
            roleColor,
          ),
        ),
        if (onConfirm != null) ...[
          const SizedBox(height: 28),
          CBFadeSlide(
            delay: const Duration(milliseconds: 350),
            child: CBPrimaryButton(
              label: 'ACKNOWLEDGE IDENTITY',
              icon: Icons.fingerprint_rounded,
              backgroundColor: roleColor,
              onPressed: () {
                HapticService.heavy();
                onConfirm!();
              },
            ),
          ),
        ],
      ],
    );
  }
}
