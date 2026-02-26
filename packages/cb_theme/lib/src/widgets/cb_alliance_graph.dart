import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import '../colors.dart';
import 'cb_panel.dart';
import 'cb_role_avatar.dart';
import 'cb_mini_tag.dart';

/// Interactive alliance graph with MVP linking for every role.
class CBAllianceGraph extends StatelessWidget {
  final List<Role> roles;
  final String? activeRoleId;
  final ValueChanged<Role>? onRoleTap;

  const CBAllianceGraph({
    super.key,
    required this.roles,
    this.activeRoleId,
    this.onRoleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final staff = roles.where((r) => r.alliance == Team.clubStaff).toList();
    final animals = roles.where((r) => r.alliance == Team.partyAnimals).toList();
    final neutral = roles.where((r) => r.alliance == Team.neutral).toList();

    final mvpLinks = _getMvpLinks(activeRoleId);
    final counterLinks = _getCounterLinks(activeRoleId);

    return CBPanel(
      padding: const EdgeInsets.all(20),
      borderColor: scheme.primary.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeRoleId != null && (mvpLinks.isNotEmpty || counterLinks.isNotEmpty)) ...[
            _buildLegend(context, scheme, mvpLinks, counterLinks),
            const SizedBox(height: 16),
          ],
          _buildTeamSection(context, "THE DEALERS", staff, scheme.error, mvpLinks, counterLinks),
          const SizedBox(height: 20),
          _buildTeamSection(context, "THE PARTY ANIMALS", animals, scheme.primary, mvpLinks, counterLinks),
          if (neutral.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTeamSection(context, "THE WILDCARDS", neutral, scheme.tertiary, mvpLinks, counterLinks),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, ColorScheme scheme, Set<String> mvps, Set<String> counters) {
    return Row(
      children: [
        CBMiniTag(text: 'MVP ALLY', color: CBColors.neonGreen),
        const SizedBox(width: 8),
        CBMiniTag(text: 'THREAT', color: scheme.error),
        const SizedBox(width: 8),
        CBMiniTag(text: 'YOU', color: scheme.primary),
      ],
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    String title,
    List<Role> teamRoles,
    Color titleColor,
    Set<String> mvpLinks,
    Set<String> counterLinks,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: CBColors.boxGlow(titleColor, intensity: 0.2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: teamRoles.map((role) {
            final isActive = role.id == activeRoleId;
            final isMvp = mvpLinks.contains(role.id);
            final isCounter = counterLinks.contains(role.id);
            final roleColor = CBColors.fromHex(role.colorHex);

            Color borderColor = Colors.transparent;
            double borderWidth = 1.5;
            List<BoxShadow>? shadow;

            if (isActive) {
              borderColor = roleColor;
              borderWidth = 2.5;
              shadow = CBColors.boxGlow(roleColor, intensity: 0.5);
            } else if (isMvp) {
              borderColor = CBColors.neonGreen.withValues(alpha: 0.8);
              borderWidth = 2.0;
              shadow = CBColors.boxGlow(CBColors.neonGreen, intensity: 0.3);
            } else if (isCounter) {
              borderColor = Colors.red.withValues(alpha: 0.6);
              borderWidth = 2.0;
            }

            return GestureDetector(
              onTap: onRoleTap != null ? () => onRoleTap!(role) : null,
              child: Tooltip(
                message: role.name,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: borderWidth),
                        boxShadow: shadow,
                      ),
                      child: CBRoleAvatar(
                        assetPath: role.assetPath,
                        color: roleColor,
                        size: 30,
                        pulsing: isActive,
                      ),
                    ),
                    if (isMvp)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'MVP',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: CBColors.neonGreen,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    if (isCounter && !isMvp)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.warning_amber_rounded, size: 10, color: Colors.red.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// MVP allies — roles that this role should protect / work with.
  static Set<String> _getMvpLinks(String? sourceId) {
    if (sourceId == null) return {};
    return switch (sourceId) {
      RoleIds.allyCat => {RoleIds.bouncer},
      RoleIds.bouncer => {RoleIds.allyCat, RoleIds.medic, RoleIds.bartender},
      RoleIds.medic => {RoleIds.bouncer, RoleIds.wallflower, RoleIds.sober},
      RoleIds.wallflower => {RoleIds.bouncer, RoleIds.medic},
      RoleIds.roofi => {RoleIds.bouncer, RoleIds.medic},
      RoleIds.sober => {RoleIds.medic, RoleIds.bouncer},
      RoleIds.bartender => {RoleIds.bouncer, RoleIds.medic},
      RoleIds.minor => {RoleIds.medic, RoleIds.sober},
      RoleIds.seasonedDrinker => {RoleIds.medic},
      RoleIds.partyAnimal => {RoleIds.bouncer, RoleIds.medic},
      RoleIds.teaSpiller => {RoleIds.medic},
      RoleIds.predator => {RoleIds.bouncer},
      RoleIds.dramaQueen => {RoleIds.bouncer},
      RoleIds.dealer => {RoleIds.silverFox, RoleIds.whore},
      RoleIds.whore => {RoleIds.dealer, RoleIds.silverFox},
      RoleIds.silverFox => {RoleIds.dealer, RoleIds.whore},
      RoleIds.clinger => {},
      RoleIds.messyBitch => {},
      RoleIds.clubManager => {},
      RoleIds.secondWind => {RoleIds.medic},
      RoleIds.creep => {},
      _ => {},
    };
  }

  /// Threats — roles that counter or endanger this role.
  static Set<String> _getCounterLinks(String? sourceId) {
    if (sourceId == null) return {};
    return switch (sourceId) {
      RoleIds.dealer => {RoleIds.bouncer, RoleIds.roofi, RoleIds.bartender, RoleIds.medic},
      RoleIds.whore => {RoleIds.bouncer, RoleIds.bartender},
      RoleIds.silverFox => {RoleIds.bouncer, RoleIds.bartender},
      RoleIds.bouncer => {RoleIds.roofi, RoleIds.silverFox, RoleIds.whore, RoleIds.dealer},
      RoleIds.medic => {RoleIds.roofi, RoleIds.dealer},
      RoleIds.roofi => {RoleIds.dealer},
      RoleIds.sober => {RoleIds.dealer},
      RoleIds.wallflower => {RoleIds.dealer},
      RoleIds.allyCat => {RoleIds.dealer},
      RoleIds.minor => {RoleIds.bouncer},
      RoleIds.bartender => {RoleIds.silverFox, RoleIds.dealer},
      RoleIds.seasonedDrinker => {RoleIds.dealer},
      RoleIds.lightweight => {RoleIds.dealer},
      RoleIds.teaSpiller => {RoleIds.dealer},
      RoleIds.predator => {RoleIds.roofi},
      RoleIds.dramaQueen => {RoleIds.dealer},
      RoleIds.messyBitch => {RoleIds.dealer, RoleIds.bouncer},
      RoleIds.clubManager => {RoleIds.dealer},
      RoleIds.clinger => {RoleIds.dealer},
      RoleIds.secondWind => {RoleIds.dealer},
      RoleIds.creep => {RoleIds.dealer},
      _ => {},
    };
  }
}
