import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GodModeControls extends ConsumerWidget {
  final GameState gameState;

  const GodModeControls({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    final alivePlayerIds =
        gameState.players.where((p) => p.isAlive).map((p) => p.id).toSet();
    final pendingDramaSwapTargetIds = <String>{};
    for (final dramaQueen in gameState.players.where(
      (p) => p.role.id == RoleIds.dramaQueen && p.isAlive,
    )) {
      final targetAId = dramaQueen.dramaQueenTargetAId;
      final targetBId = dramaQueen.dramaQueenTargetBId;
      if (targetAId == null || targetBId == null) continue;
      if (targetAId == targetBId) continue;
      if (targetAId == dramaQueen.id || targetBId == dramaQueen.id) continue;
      if (!alivePlayerIds.contains(targetAId) ||
          !alivePlayerIds.contains(targetBId)) {
        continue;
      }
      pendingDramaSwapTargetIds
        ..add(targetAId)
        ..add(targetBId);
    }

    return CBPanel(
      borderColor: scheme.error.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: scheme.error, shadows: CBColors.iconGlow(scheme.error)),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  'GOD MODE PROTOCOLS',
                  style: textTheme.titleMedium!.copyWith(
                    color: scheme.error,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w900,
                    shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: CBSpace.x2),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CBRadius.sm),
              border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: scheme.error),
                const SizedBox(width: CBSpace.x2),
                Expanded(
                  child: Text(
                    'AUTHORIZED HOST INTERVENTIONS ONLY. USE WITH EXTREME PREJUDICE.',
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.error,
                      fontSize: 8,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x5),
          if (alivePlayers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CBSpace.x6),
                child: Text(
                  'NO ACTIVE TARGETS DETECTED',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            ...alivePlayers.map((player) => Padding(
                  padding: const EdgeInsets.only(bottom: CBSpace.x3),
                  child: _buildPlayerControlTile(
                    context,
                    ref,
                    player,
                    hasPendingDramaSwap:
                        pendingDramaSwapTargetIds.contains(player.id),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildPlayerControlTile(
    BuildContext context,
    WidgetRef ref,
    Player player, {
    required bool hasPendingDramaSwap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
        ),
        boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -2)],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: roleColor.withValues(alpha: 0.1),
          highlightColor: roleColor.withValues(alpha: 0.05),
        ),
        child: ExpansionTile(
          iconColor: roleColor,
          collapsedIconColor: roleColor.withValues(alpha: 0.5),
          tilePadding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x1),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)],
            ),
            child: CBRoleAvatar(
              assetPath: player.role.assetPath,
              color: roleColor,
              size: 40,
              pulsing: player.isAlive && !player.isSinBinned,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  player.name.toUpperCase(),
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontFamily: 'RobotoMono',
                    color: scheme.onSurface,
                    shadows: CBColors.textGlow(roleColor, intensity: 0.5),
                  ),
                ),
              ),
              if (hasPendingDramaSwap)
                Padding(
                  padding: const EdgeInsets.only(left: CBSpace.x2),
                  child: CBBadge(
                    text: 'DRAMA',
                    color: scheme.secondary,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            player.role.name.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: roleColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(CBRadius.md)),
              ),
              padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x3, CBSpace.x4, CBSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          roleColor.withValues(alpha: 0.0),
                          roleColor.withValues(alpha: 0.4),
                          roleColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.terminal_rounded, size: 14, color: scheme.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: CBSpace.x2),
                      Text(
                        'AVAILABLE INTERVENTIONS',
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ActionChip(
                        label: 'TERMINATE',
                        icon: Icons.dangerous_rounded,
                        color: scheme.error,
                        onTap: () => _confirmKill(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isMuted ? 'RESTORE VOICE' : 'SILENCE',
                        icon: player.isMuted
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: player.isMuted ? CBColors.success : scheme.secondary,
                        onTap: () => _toggleMute(context, ref, player),
                      ),
                      _ActionChip(
                        label:
                            player.hasHostShield ? 'DISPEL SHIELD' : 'DEPLOY SHIELD',
                        icon: Icons.shield_rounded,
                        color: scheme.primary,
                        onTap: () => _grantShield(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isSinBinned ? 'RELEASE' : 'SIN BIN',
                        icon: Icons.timer_rounded,
                        color: CBColors.alertOrange,
                        onTap: () => _toggleSinBin(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isShadowBanned ? 'LIFT SHADOW' : 'SHADOW BAN',
                        icon: Icons.visibility_off_rounded,
                        color: CBColors.yellow,
                        onTap: () => _toggleShadowBan(context, ref, player),
                      ),
                      _ActionChip(
                        label: 'EJECT NODE',
                        icon: Icons.output_rounded,
                        color: scheme.error,
                        onTap: () => _kickPlayer(context, ref, player),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmKill(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TERMINATION PROTOCOL',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.error,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          Text(
            'FORCE ELIMINATION OF OPERATIVE ${player.name.toUpperCase()}? THIS BYPASSES ALL PROTECTIONS AND TRIGGERS GLOBAL DEATH EFFECTS.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () {
                    HapticService.light();
                    Navigator.pop(context);
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
                    ref.read(gameProvider.notifier).forceKillPlayer(player.id);
                    Navigator.pop(context);
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

  void _toggleMute(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    HapticService.medium();
    ref
        .read(gameProvider.notifier)
        .togglePlayerMute(player.id, !player.isMuted);
    showThemedSnackBar(context,
        'OPERATIVE ${player.name.toUpperCase()} ${player.isMuted ? 'UNMUTED' : 'MUTED'}.',
        accentColor: scheme.secondary);
  }

  void _grantShield(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    HapticService.selection();
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AEGIS SHIELD PROTOCOL',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.primary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'GRANT HIGH-PRIORITY IMMUNITY TO OPERATIVE ${player.name.toUpperCase()}.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          DropdownButtonFormField<int>(
            initialValue: 1,
            dropdownColor: scheme.surfaceContainerHigh,
            style: textTheme.bodyLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono'),
            decoration: InputDecoration(
              labelText: 'SHIELD DURATION',
              labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CBRadius.xs), borderSide: BorderSide(color: scheme.primary)),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 NIGHT CYCLE')),
              DropdownMenuItem(value: 2, child: Text('2 NIGHT CYCLES')),
              DropdownMenuItem(value: 3, child: Text('3 NIGHT CYCLES')),
            ],
            onChanged: (days) {
              if (days == null) return;
              HapticService.heavy();
              Navigator.pop(context);
              ref.read(gameProvider.notifier).grantHostShield(player.id, days);
              showThemedSnackBar(
                context,
                'AEGIS SHIELD DEPLOYED TO ${player.name.toUpperCase()} FOR $days CYCLES.',
                accentColor: scheme.primary,
              );
            },
          ),
          const SizedBox(height: CBSpace.x6),
          CBGhostButton(
            label: 'ABORT',
            onPressed: () {
              HapticService.light();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _toggleSinBin(BuildContext context, WidgetRef ref, Player player) {
    HapticService.medium();
    ref.read(gameProvider.notifier).setSinBin(player.id, !player.isSinBinned);
    showThemedSnackBar(context,
        'OPERATIVE ${player.name.toUpperCase()} ${player.isSinBinned ? 'RELEASED' : 'QUARANTINED'}.',
        accentColor: Theme.of(context).colorScheme.outline);
  }

  void _toggleShadowBan(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    HapticService.selection();
    showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            player.isShadowBanned
                ? 'LIFT SHADOW PROTOCOL'
                : 'INITIATE SHADOW BAN',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.secondary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.secondary, intensity: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          Text(
            player.isShadowBanned
                ? 'RESTORE FULL TRANSMISSION RIGHTS TO OPERATIVE ${player.name.toUpperCase()}?'
                : 'RESTRICT TRANSMISSIONS FROM OPERATIVE ${player.name.toUpperCase()}? THEIR ACTIONS WILL BE SILENTLY DISCARDED.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBPrimaryButton(
                  label: player.isShadowBanned ? 'RESTORE' : 'EXECUTE',
                  backgroundColor: scheme.secondary,
                  onPressed: () {
                    HapticService.heavy();
                    ref
                        .read(gameProvider.notifier)
                        .setShadowBan(player.id, !player.isShadowBanned);
                    Navigator.pop(context);
                    showThemedSnackBar(context,
                        'OPERATIVE ${player.name.toUpperCase()} ${player.isShadowBanned ? 'UNBANNED' : 'SHADOW BANNED'}.',
                        accentColor: scheme.secondary);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _kickPlayer(BuildContext context, WidgetRef ref, Player player) {
    String reason = '';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    HapticService.selection();
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NODE EJECTION PROTOCOL',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.error,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x4),
          Text(
            'PERMANENTLY DISCONNECT OPERATIVE ${player.name.toUpperCase()} FROM THE CLUB NETWORK?',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          CBTextField(
            hintText: 'SPECIFY EJECTION REASON (OPTIONAL)',
            onChanged: (value) => reason = value,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBPrimaryButton(
                  label: 'EJECT',
                  backgroundColor: scheme.error,
                  onPressed: () {
                    HapticService.heavy();
                    ref.read(gameProvider.notifier).kickPlayer(player.id,
                        reason.isEmpty ? 'Violated club protocol' : reason);
                    Navigator.pop(context);
                    showThemedSnackBar(
                        context, 'OPERATIVE ${player.name.toUpperCase()} EJECTED FROM SYSTEM.',
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

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CBRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x3, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(CBRadius.sm),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color, shadows: CBColors.iconGlow(color, intensity: 0.4)),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  shadows: CBColors.textGlow(color, intensity: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
