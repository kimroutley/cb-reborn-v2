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
    final deadPlayers = gameState.players.where((p) => !p.isAlive).toList();
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
      borderColor: scheme.secondary.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'GOD MODE PROTOCOLS',
            color: scheme.secondary,
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            '// AUTHORIZED HOST INTERVENTIONS ONLY. USE WITH EXTREME PREJUDICE.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.secondary.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (alivePlayers.isEmpty && deadPlayers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'NO ACTIVE TARGETS DETECTED',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            )
          else ...[
            ...alivePlayers.map((player) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlayerControlTile(
                    context,
                    ref,
                    player,
                    hasPendingDramaSwap:
                        pendingDramaSwapTargetIds.contains(player.id),
                  ),
                )),
            if (deadPlayers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '// DECEASED ROSTER — REVIVE CANDIDATES',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.error.withValues(alpha: 0.6),
                  fontSize: 8,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...deadPlayers.map((player) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDeadPlayerTile(context, ref, player),
                  )),
            ],
          ],
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

    return CBGlassTile(
      padding: EdgeInsets.zero,
      borderColor: roleColor.withValues(alpha: 0.3),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: roleColor,
          collapsedIconColor: roleColor.withValues(alpha: 0.7),
          leading: CBRoleAvatar(
            assetPath: player.role.assetPath,
            color: roleColor,
            size: 36,
            pulsing: player.isAlive && !player.isSinBinned,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  player.name.toUpperCase(),
                  style: textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: CBColors.textGlow(roleColor, intensity: 0.3),
                  ),
                ),
              ),
              if (hasPendingDramaSwap)
                CBBadge(
                  text: 'PENDING SWAP',
                  color: scheme.secondary,
                ),
            ],
          ),
          subtitle: Text(
            '// ${player.role.name.toUpperCase()}',
            style: textTheme.labelSmall!.copyWith(
              color: roleColor.withValues(alpha: 0.6),
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    'AVAILABLE INTERVENTIONS',
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                        label: 'ELIMINATE',
                        icon: Icons.close_rounded,
                        color: scheme.error,
                        onTap: () => _confirmKill(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isMuted ? 'UNMUTE' : 'MUTE',
                        icon: player.isMuted
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: scheme.secondary,
                        onTap: () => _toggleMute(context, ref, player),
                      ),
                      _ActionChip(
                        label:
                            player.hasHostShield ? 'DISPEL SHIELD' : 'SHIELD',
                        icon: Icons.shield_rounded,
                        color: scheme.primary,
                        onTap: () => _grantShield(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isSinBinned ? 'RELEASE' : 'SIN BIN',
                        icon: Icons.timer_rounded,
                        color: CBColors.coolGrey,
                        onTap: () => _toggleSinBin(context, ref, player),
                      ),
                      _ActionChip(
                        label: player.isShadowBanned ? 'UNBAN' : 'SHADOW BAN',
                        icon: Icons.visibility_off_rounded,
                        color: scheme.secondary,
                        onTap: () => _toggleShadowBan(context, ref, player),
                      ),
                      _ActionChip(
                        label: 'SWAP ROLE',
                        icon: Icons.swap_horizontal_circle_rounded,
                        color: CBColors.alertOrange,
                        onTap: () => _swapRole(context, ref, player),
                      ),
                      _ActionChip(
                        label: 'REVEAL ROLE',
                        icon: Icons.badge_rounded,
                        color: scheme.tertiary,
                        onTap: () => _revealRole(context, ref, player),
                      ),
                      _ActionChip(
                        label: 'EJECT',
                        icon: Icons.person_remove_rounded,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: TERMINATION',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.error,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Force eliminate ${player.name.toUpperCase()}? This bypasses all protections and triggers global death effects.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'EXECUTE',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).forceKillPlayer(player.id);
                  Navigator.pop(context);
                  showThemedSnackBar(context, '${player.name} ELIMINATED',
                      accentColor: scheme.error);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleMute(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    ref
        .read(gameProvider.notifier)
        .togglePlayerMute(player.id, !player.isMuted);
    showThemedSnackBar(context,
        '${player.name.toUpperCase()} ${player.isMuted ? 'UNMUTED' : 'MUTED'}',
        accentColor: scheme.secondary);
  }

  void _grantShield(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: AEGIS SHIELD',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.primary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.primary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grant high-priority immunity to ${player.name.toUpperCase()}.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: 1,
            decoration: const InputDecoration(
              labelText: 'DURATION (NIGHTS)',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 NIGHT')),
              DropdownMenuItem(value: 2, child: Text('2 NIGHTS')),
              DropdownMenuItem(value: 3, child: Text('3 NIGHTS')),
            ],
            onChanged: (days) {
              if (days == null) return;
              Navigator.pop(context);
              ref.read(gameProvider.notifier).grantHostShield(player.id, days);
              showThemedSnackBar(
                context,
                'SHIELD GRANTED TO ${player.name.toUpperCase()} ($days NIGHTS)',
                accentColor: scheme.primary,
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleSinBin(BuildContext context, WidgetRef ref, Player player) {
    ref.read(gameProvider.notifier).setSinBin(player.id, !player.isSinBinned);
    showThemedSnackBar(context,
        '${player.name.toUpperCase()} ${player.isSinBinned ? 'RELEASED' : 'SENT TO SIN BIN'}',
        accentColor: CBColors.coolGrey);
  }

  void _toggleShadowBan(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.isShadowBanned
                ? 'PROTOCOL: LIFT BAN'
                : 'PROTOCOL: SHADOW BAN',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.secondary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.secondary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            player.isShadowBanned
                ? 'Restore full transmission rights to ${player.name.toUpperCase()}?'
                : 'Silence ${player.name.toUpperCase()}? Their actions will be silently discarded while they believe they are active.',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: player.isShadowBanned ? 'RESTORE' : 'EXECUTE',
                backgroundColor: scheme.secondary,
                onPressed: () {
                  ref
                      .read(gameProvider.notifier)
                      .setShadowBan(player.id, !player.isShadowBanned);
                  Navigator.pop(context);
                  showThemedSnackBar(context,
                      '${player.name.toUpperCase()} ${player.isShadowBanned ? 'UNBANNED' : 'SHADOW BANNED'}',
                      accentColor: scheme.secondary);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDeadPlayerTile(
      BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);

    return CBGlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: scheme.error.withValues(alpha: 0.25),
      child: Row(
        children: [
          CBRoleAvatar(
            assetPath: player.role.assetPath,
            color: roleColor.withValues(alpha: 0.4),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.toUpperCase(),
                  style: textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    decoration: TextDecoration.lineThrough,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${player.role.name.toUpperCase()} · ${player.deathReason?.toUpperCase() ?? "UNKNOWN"} · DAY ${player.deathDay ?? "?"}',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.error.withValues(alpha: 0.5),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          _ActionChip(
            label: 'REVIVE',
            icon: Icons.favorite_rounded,
            color: scheme.tertiary,
            onTap: () {
              ref.read(gameProvider.notifier).revivePlayer(player.id);
              showThemedSnackBar(
                context,
                '${player.name.toUpperCase()} RESURRECTED',
                accentColor: scheme.tertiary,
              );
            },
          ),
        ],
      ),
    );
  }

  void _swapRole(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final allRoles = roleCatalog.where((r) => r.id != 'unassigned').toList();
    String? selectedRoleId;

    showThemedDialog(
      context: context,
      accentColor: CBColors.alertOrange,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROTOCOL: ROLE OVERRIDE',
                style: textTheme.labelLarge!.copyWith(
                  color: CBColors.alertOrange,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                  shadows:
                      CBColors.textGlow(CBColors.alertOrange, intensity: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reassign ${player.name.toUpperCase()} to a different role mid-game.',
                style: textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: allRoles.length,
                  itemBuilder: (context, index) {
                    final role = allRoles[index];
                    final roleColor = CBColors.fromHex(role.colorHex);
                    final isSelected = selectedRoleId == role.id;
                    final isCurrent = player.role.id == role.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: isCurrent
                            ? null
                            : () => setDialogState(
                                () => selectedRoleId = role.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? roleColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? roleColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CBRoleAvatar(
                                assetPath: role.assetPath,
                                color: roleColor,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  role.name.toUpperCase(),
                                  style: textTheme.labelSmall!.copyWith(
                                    color: isCurrent
                                        ? scheme.onSurface
                                            .withValues(alpha: 0.3)
                                        : roleColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                CBBadge(
                                    text: 'CURRENT',
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CBGhostButton(
                    label: 'ABORT',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  CBPrimaryButton(
                    fullWidth: false,
                    label: 'OVERRIDE',
                    backgroundColor: CBColors.alertOrange,
                    onPressed: selectedRoleId == null
                        ? null
                        : () {
                            ref
                                .read(gameProvider.notifier)
                                .assignRole(player.id, selectedRoleId!);
                            Navigator.pop(context);
                            final newRoleName =
                                roleCatalogMap[selectedRoleId]?.name ??
                                    selectedRoleId!;
                            showThemedSnackBar(
                              context,
                              '${player.name.toUpperCase()} → ${newRoleName.toUpperCase()}',
                              accentColor: CBColors.alertOrange,
                            );
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _revealRole(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);
    final allianceLabel = switch (player.alliance) {
      Team.clubStaff => 'CLUB STAFF',
      Team.partyAnimals => 'PARTY ANIMALS',
      Team.neutral => 'NEUTRAL',
      Team.unknown => 'UNKNOWN',
    };

    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: ROLE REVEAL',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.tertiary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CBRoleAvatar(
                assetPath: player.role.assetPath,
                color: roleColor,
                size: 48,
                pulsing: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: textTheme.headlineSmall!.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.w900,
                        shadows: CBColors.textGlow(roleColor, intensity: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.role.name.toUpperCase(),
                      style: textTheme.labelMedium!.copyWith(
                        color: roleColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CBGlassTile(
            padding: const EdgeInsets.all(12),
            borderColor: roleColor.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('ALLIANCE', allianceLabel, scheme),
                _infoRow('STATUS', player.isAlive ? 'ALIVE' : 'DEAD', scheme),
                _infoRow('LIVES', '${player.lives}', scheme),
                if (player.hasHostShield) _infoRow('SHIELD', 'ACTIVE', scheme),
                if (player.isSinBinned) _infoRow('SIN BIN', 'YES', scheme),
                if (player.isShadowBanned)
                  _infoRow('SHADOW BAN', 'ACTIVE', scheme),
                if (player.drinksOwed > 0)
                  _infoRow('DRINKS OWED', '${player.drinksOwed}', scheme),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            player.role.description,
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CBGhostButton(
                label: 'BROADCAST TO ALL',
                icon: Icons.campaign_rounded,
                onPressed: () {
                  ref.read(gameProvider.notifier).dispatchBulletin(
                        title: 'ROLE EXPOSED',
                        content:
                            '${player.name.toUpperCase()} has been revealed as ${player.role.name.toUpperCase()} ($allianceLabel)!',
                        type: 'urgent',
                      );
                  Navigator.pop(context);
                  showThemedSnackBar(
                    context,
                    'ROLE REVEAL BROADCAST',
                    accentColor: scheme.tertiary,
                  );
                },
              ),
              CBGhostButton(
                label: 'DISMISS',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _kickPlayer(BuildContext context, WidgetRef ref, Player player) {
    String reason = '';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: NODE EJECTION',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.error,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Permanently eject ${player.name.toUpperCase()} from the club network?',
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          CBTextField(
            hintText: 'REASON FOR EJECTION (OPTIONAL)',
            onChanged: (value) => reason = value,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'ABORT',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'EJECT',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).kickPlayer(player.id,
                      reason.isEmpty ? 'No reason provided' : reason);
                  Navigator.pop(context);
                  showThemedSnackBar(
                      context, '${player.name.toUpperCase()} EJECTED',
                      accentColor: scheme.error);
                },
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
        onTap: () {
          HapticService.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
