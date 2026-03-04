import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// A premium, glassmorphic player card for the host roster.
class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.player,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);
    final accent = player.isAlive ? roleColor : scheme.error;

    return CBFadeSlide(
      child: Container(
        margin: const EdgeInsets.only(bottom: CBSpace.x3),
        child: CBGlassTile(
          borderColor: accent.withValues(alpha: 0.4),
          isPrismatic: player.isAlive && !player.isSinBinned,
          padding: const EdgeInsets.all(CBSpace.x4),
          onTap: () {
            HapticService.selection();
            onTap?.call();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CBRoleAvatar(
                    assetPath: player.role.id == 'unassigned'
                        ? null
                        : player.role.assetPath,
                    color: accent,
                    size: 48,
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
                            color: player.isAlive ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontFamily: 'RobotoMono',
                            decoration: player.isAlive ? null : TextDecoration.lineThrough,
                            shadows: player.isAlive ? CBColors.textGlow(roleColor, intensity: 0.3) : null,
                          ),
                        ),
                        const SizedBox(height: CBSpace.x1),
                        CBMiniTag(
                          text: player.role.name.toUpperCase(),
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: scheme.error.withValues(alpha: 0.6), size: 22),
                      onPressed: () {
                        HapticService.heavy();
                        onDelete?.call();
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: CBSpace.x4),
              Row(
                children: [
                  if (!player.isAlive)
                    CBBadge(text: 'DE-ACTIVATED', color: scheme.error, icon: Icons.cancel_rounded)
                  else ...[
                    if (player.isSinBinned)
                      Padding(
                        padding: const EdgeInsets.only(right: CBSpace.x2),
                        child: CBBadge(
                            text: 'SIN BIN', color: scheme.error, icon: Icons.timer_rounded),
                      ),
                    if (player.isShadowBanned)
                      Padding(
                        padding: const EdgeInsets.only(right: CBSpace.x2),
                        child: CBBadge(text: 'SHADOWED', color: scheme.secondary, icon: Icons.visibility_off_rounded),
                      ),
                    if (player.isMuted)
                      Padding(
                        padding: const EdgeInsets.only(right: CBSpace.x2),
                        child: CBBadge(text: 'MUTED', color: scheme.secondary, icon: Icons.volume_off_rounded),
                      ),
                    const Spacer(),
                    Text(
                      switch (player.alliance) {
                        Team.clubStaff => 'STAFF',
                        Team.partyAnimals => 'PARTY',
                        Team.neutral => 'NEUTRAL',
                        Team.unknown => 'UNKNOWN',
                      },
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
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
}
