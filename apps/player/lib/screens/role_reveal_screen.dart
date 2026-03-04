import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class RoleRevealScreen extends StatelessWidget {
  final PlayerSnapshot player;
  final VoidCallback onConfirm;

  const RoleRevealScreen({
    super.key,
    required this.player,
    required this.onConfirm,
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
    final roleColor =
        Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));
    final role = roleCatalog.firstWhere((r) => r.id == player.roleId,
        orElse: () => roleCatalog.first);

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return CBPrismScaffold(
          title: 'IDENTITY ASSIGNED',
          showAppBar: true,
          body: Semantics(
            label:
                'Your assigned role: ${player.roleName}. Dossier and mission. Confirm to continue.',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  CBFadeSlide(
                    child: Hero(
                      tag: 'role_avatar_${player.roleName}',
                      child: Container(
                        padding: const EdgeInsets.all(CBSpace.x1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow:
                              CBColors.circleGlow(roleColor, intensity: 0.4),
                        ),
                        child: CBRoleAvatar(
                          assetPath: role.assetPath,
                          color: roleColor,
                          size: 140,
                          breathing: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      player.roleName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall!.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        shadows: CBColors.textGlow(roleColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: CBBadge(
                      text: 'CLASS: ${role.type.toUpperCase()}',
                      color: roleColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: CBPanel(
                      borderColor: roleColor.withValues(alpha: 0.3),
                      padding: CBInsets.panel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CBSectionHeader(
                            title: 'DOSSIER',
                            icon: Icons.assignment_ind_rounded,
                            color: roleColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            role.description,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge!.copyWith(
                              height: 1.6,
                              fontSize: 15,
                              color: scheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (role.tacticalTip.isNotEmpty) ...[
                    CBFadeSlide(
                      delay: const Duration(milliseconds: 400),
                      child: CBPanel(
                        borderColor: scheme.secondary.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CBSectionHeader(
                              title: 'TACTICAL INTEL',
                              icon: Icons.tips_and_updates_rounded,
                              color: scheme.secondary,
                            ),
                            const SizedBox(height: 12),
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
                    const SizedBox(height: 48),
                  ],
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 500),
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
                  const SizedBox(height: 32),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: _buildDetailStat(
                      context,
                      'MISSION OBJECTIVE',
                      _winConditionFor(role),
                      roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(CBSpace.x6),
              child: CBFadeSlide(
                delay: const Duration(milliseconds: 700),
                child: CBPrimaryButton(
                  label: 'ACKNOWLEDGE IDENTITY',
                  icon: Icons.fingerprint_rounded,
                  backgroundColor: roleColor,
                  onPressed: () {
                    HapticService.heavy();
                    onConfirm();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
