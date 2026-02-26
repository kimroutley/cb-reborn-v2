import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoleRevealScreen extends StatelessWidget {
  final PlayerSnapshot player;
  final VoidCallback onConfirm;

  const RoleRevealScreen({
    super.key,
    required this.player,
    required this.onConfirm,
  });

  String _allianceName(Team t) => switch (t) {
        Team.clubStaff => 'THE DEALERS (KILLERS)',
        Team.partyAnimals => 'THE PARTY ANIMALS (INNOCENTS)',
        Team.neutral => 'WILDCARDS (VARIABLES)',
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Hero(
                    tag: 'role_avatar_${player.roleName}',
                    child: CBRoleAvatar(
                      assetPath: role.assetPath,
                      color: roleColor,
                      size: 160,
                      breathing: true,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    player.roleName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: roleColor.withValues(alpha: 0.8),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Center(
                    child: CBBadge(
                      text: 'STRATEGIC CLASS: ${role.type}',
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 400),
                  child: CBPanel(
                    borderColor: roleColor.withValues(alpha: 0.2),
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
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge!.copyWith(
                            height: 1.8,
                            fontSize: 15,
                            color: scheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (role.tacticalTip.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  CBFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: CBPanel(
                      borderColor: scheme.secondary.withValues(alpha: 0.2),
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
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 600),
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
                const SizedBox(height: 32),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 700),
                  child: Center(
                    child: _buildDetailStat(
                      context,
                      'MISSION OBJECTIVE',
                      _winConditionFor(role),
                      roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CBFadeSlide(
                delay: const Duration(milliseconds: 800),
                child: CBPrimaryButton(
                  label: 'CONFIRM IDENTITY',
                  icon: Icons.fingerprint_rounded,
                  backgroundColor: roleColor,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
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
