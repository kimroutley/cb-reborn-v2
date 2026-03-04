import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RosterTile extends ConsumerWidget {
  final Player player;
  final bool showKill;
  final bool isClaimed;
  final bool hasPendingDramaSwap;

  const RosterTile({
    super.key,
    required this.player,
    this.showKill = false,
    this.isClaimed = false,
    this.hasPendingDramaSwap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);
    final allianceColor = switch (player.alliance) {
      Team.clubStaff => scheme.secondary,
      Team.partyAnimals => scheme.primary,
      Team.neutral => scheme.tertiary,
      Team.unknown => scheme.onSurface.withValues(alpha: 0.4),
    };
    final allianceLabel = switch (player.alliance) {
      Team.clubStaff => 'STAFF',
      Team.partyAnimals => 'PARTY',
      Team.neutral => 'NEUTRAL',
      Team.unknown => 'UNKNOWN',
    };
    final isDead = !player.isAlive;

    return CBFadeSlide(
      child: Container(
        margin: const EdgeInsets.only(bottom: CBSpace.x2),
        child: CBGlassTile(
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
          borderColor: isDead ? scheme.error.withValues(alpha: 0.4) : allianceColor.withValues(alpha: 0.3),
          isPrismatic: player.isAlive && !player.isSinBinned,
          child: Row(
            children: [
              CBRoleAvatar(
                assetPath: player.role.id == 'unassigned' ? null : player.role.assetPath,
                color: isDead ? scheme.error : roleColor,
                size: 44,
                pulsing: player.isAlive && !player.isSinBinned,
              ),
              const SizedBox(width: CBSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: textTheme.titleMedium!.copyWith(
                        color: isDead ? scheme.onSurface.withValues(alpha: 0.4) : scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontFamily: 'RobotoMono',
                        decoration: isDead ? TextDecoration.lineThrough : null,
                        shadows: isDead ? null : CBColors.textGlow(roleColor, intensity: 0.3),
                      ),
                    ),
                    const SizedBox(height: CBSpace.x1),
                    Row(
                      children: [
                        CBMiniTag(
                          text: player.role.name.toUpperCase(),
                          color: isDead ? scheme.error : roleColor,
                        ),
                        if (player.isAlive) ...[
                          if (player.hasRumour) ...[
                            const SizedBox(width: 6),
                            CBBadge(text: 'RUMOUR', color: scheme.secondary, icon: Icons.campaign_rounded),
                          ],
                          if (player.alibiDay != null) ...[
                            const SizedBox(width: 6),
                            CBBadge(text: 'ALIBI', color: scheme.tertiary, icon: Icons.fingerprint_rounded),
                          ],
                          if (hasPendingDramaSwap) ...[
                            const SizedBox(width: 6),
                            CBBadge(text: 'DRAMA', color: scheme.secondary, icon: Icons.swap_horiz_rounded),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CBBadge(
                    text: allianceLabel,
                    color: allianceColor,
                  ),
                  if (isClaimed) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CLAIMED',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticService.heavy();
                            ref.read(sessionProvider.notifier).releasePlayer(player.id);
                          },
                          child: Icon(Icons.link_off_rounded, size: 16, color: scheme.error.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ],
                  if (showKill && !isDead) ...[
                    const SizedBox(height: CBSpace.x2),
                    IconButton(
                      icon: Icon(Icons.dangerous_rounded,
                          color: scheme.error.withValues(alpha: 0.8), size: 24),
                      onPressed: () => _confirmElimination(context, ref),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmElimination(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TERMINATION PROTOCOL',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.error,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.6),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          Text(
            'CONFIRM FORCED ELIMINATION OF OPERATIVE ${player.name.toUpperCase()}? THIS ACTION IS IRREVERSIBLE.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () {
                    HapticService.light();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBPrimaryButton(
                  label: 'EXECUTE',
                  backgroundColor: scheme.error,
                  onPressed: () {
                    HapticService.heavy();
                    ref
                        .read(gameProvider.notifier)
                        .forceKillPlayer(player.id);
                    Navigator.of(context).pop();
                    showThemedSnackBar(context, 'OPERATIVE ${player.name.toUpperCase()} TERMINATED.',
                        accentColor: scheme.error);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
