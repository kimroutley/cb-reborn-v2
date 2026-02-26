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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CBPanel(
        borderColor: (player.isAlive ? roleColor : scheme.error).withValues(
          alpha: 0.4,
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBRoleAvatar(
                    assetPath: player.role.id == 'unassigned'
                        ? null
                        : player.role.assetPath,
                    color: player.isAlive ? roleColor : scheme.error,
                    size: 40,
                    pulsing: player.isAlive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: textTheme.headlineSmall!.copyWith(
                            color: player.isAlive ? roleColor : scheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          player.role.name.toUpperCase(),
                          style: textTheme.bodySmall!.copyWith(
                            color: (player.isAlive ? roleColor : scheme.error)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: scheme.error,
                        size: 20,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!player.isAlive)
                    CBBadge(text: 'ELIMINATED', color: scheme.error),
                  if (player.isAlive) ...[
                    if (player.isSinBinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CBBadge(
                          text: 'SIN BINNED',
                          color: scheme.secondary,
                        ),
                      ),
                    if (player.isShadowBanned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CBBadge(text: 'GHOSTED', color: scheme.tertiary),
                      ),
                    Text(
                      switch (player.alliance) {
                        Team.clubStaff => 'STAFF',
                        Team.partyAnimals => 'PARTY ANIMAL',
                        Team.neutral => 'NEUTRAL',
                        Team.unknown => 'UNKNOWN',
                      },
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 10,
                        letterSpacing: 1.0,
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
