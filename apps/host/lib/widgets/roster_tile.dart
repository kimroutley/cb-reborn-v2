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
    final allianceColor = switch (player.alliance) {
      Team.clubStaff => scheme.primary,
      Team.partyAnimals => scheme.secondary,
      Team.neutral => scheme.tertiary,
      Team.unknown => scheme.onSurface.withValues(alpha: 0.4),
    };
    final allianceLabel = switch (player.alliance) {
      Team.clubStaff => 'STAFF',
      Team.partyAnimals => 'PA',
      Team.neutral => 'NEU',
      Team.unknown => 'UNK',
    };
    final isDead = !player.isAlive;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDead ? scheme.error.withValues(alpha: 0.1) : scheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isDead
              ? scheme.error.withValues(alpha: 0.3)
              : allianceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: isDead
                ? Icon(Icons.cancel, size: 20, color: scheme.error)
                : Image.asset(
                    player.role.assetPath,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.circle, size: 12, color: allianceColor),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: textTheme.bodyLarge!.copyWith(
                color: isDead ? scheme.error : null,
                fontWeight: FontWeight.w700,
                decoration: isDead ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            player.role.name.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: allianceColor.withValues(alpha: isDead ? 0.4 : 0.8),
            ),
          ),
          // Status badges
          if (player.hasRumour && player.isAlive) ...[
            const SizedBox(width: 4),
            MiniTag(text: 'R', color: scheme.secondary, tooltip: 'Rumour'),
          ],
          if (player.alibiDay != null && player.isAlive) ...[
            const SizedBox(width: 4),
            MiniTag(text: 'A', color: scheme.tertiary, tooltip: 'Alibi'),
          ],
          if (player.creepTargetId != null && player.isAlive) ...[
            const SizedBox(width: 4),
            MiniTag(text: 'C', color: scheme.secondary, tooltip: 'Creep'),
          ],
          if (player.clingerPartnerId != null && player.isAlive) ...[
            const SizedBox(width: 4),
            MiniTag(text: 'L', color: scheme.primary, tooltip: 'Clinger'),
          ],
          if (hasPendingDramaSwap && player.isAlive) ...[
            const SizedBox(width: 4),
            MiniTag(
              text: 'DQ',
              color: scheme.secondary,
              tooltip: 'Pending Drama Queen swap',
            ),
          ],
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: allianceColor.withValues(alpha: 0.15),
            ),
            child: Text(
              allianceLabel,
              style: textTheme.labelSmall!.copyWith(
                color: allianceColor,
                fontSize: 9,
              ),
            ),
          ),
          if (isClaimed) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.15),
              ),
              child: Text(
                'CLAIMED',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.tertiary,
                  fontSize: 8,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                ref.read(sessionProvider.notifier).releasePlayer(player.id);
                Navigator.pop(context);
              },
              child: Icon(Icons.link_off, size: 16, color: scheme.error),
            ),
          ],
          if (showKill && !isDead) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showThemedDialog(
                  context: context,
                  accentColor: scheme.error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FORCE ELIMINATE',
                        style: textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.error,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.bold,
                          shadows: CBColors.textGlow(
                            theme.colorScheme.error,
                            intensity: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Are you sure you want to eliminate ${player.name}?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.75),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CBGhostButton(
                            label: 'CANCEL',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          CBPrimaryButton(
                            fullWidth: false,
                            label: 'ELIMINATE',
                            backgroundColor: theme.colorScheme.error,
                            onPressed: () {
                              ref
                                  .read(gameProvider.notifier)
                                  .forceKillPlayer(player.id);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: Icon(
                Icons.dangerous,
                size: 18,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  final String tooltip;

  const MiniTag({
    super.key,
    required this.text,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
