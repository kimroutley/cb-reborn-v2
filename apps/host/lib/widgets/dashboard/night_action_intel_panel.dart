import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NightActionIntelPanel extends ConsumerWidget {
  final GameState gameState;

  const NightActionIntelPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playersById = {for (final p in gameState.players) p.id: p};

    final actionEntries = gameState.actionLog.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    final hasPrivateMessages = gameState.privateMessages.values
        .any((msgs) => msgs.isNotEmpty);

    // Pending actions: steps in the queue that have no entry in actionLog yet
    final pendingSteps = gameState.scriptQueue
        .where((s) =>
            s.actionType == ScriptActionType.selectPlayer ||
            s.actionType == ScriptActionType.selectTwoPlayers ||
            s.actionType == ScriptActionType.binaryChoice)
        .where((s) =>
            !gameState.actionLog.containsKey(s.id) ||
            gameState.actionLog[s.id]!.isEmpty)
        .toList();

    if (actionEntries.isEmpty &&
        gameState.lastNightReport.isEmpty &&
        !hasPrivateMessages &&
        pendingSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return CBPanel(
      borderColor: scheme.secondary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'NIGHT INTEL DOSSIER',
            color: scheme.secondary,
            icon: Icons.nightlight_round,
          ),
          const SizedBox(height: 12),
          Text(
            '// CLASSIFIED — ACTION LOG & INTERCEPTED COMMS.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.secondary.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Pending Actions
          if (pendingSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// AWAITING RESPONSE',
              style: textTheme.labelSmall!.copyWith(
                color: CBColors.alertOrange.withValues(alpha: 0.7),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...pendingSteps.map((step) {
              final roleId = step.roleId;
              final roleColor = roleId != null
                  ? CBColors.fromHex(
                      roleCatalogMap[roleId]?.colorHex ?? '#4CC9F0')
                  : CBColors.alertOrange;
              final roleName =
                  roleCatalogMap[roleId]?.name.toUpperCase() ?? 'UNKNOWN';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBGlassTile(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  borderColor:
                      CBColors.alertOrange.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$roleName — PENDING',
                          style: textTheme.labelSmall!.copyWith(
                            color: CBColors.alertOrange,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Last Night Report
          if (gameState.lastNightReport.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// RESOLUTION SUMMARY',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...gameState.lastNightReport.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: scheme.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          line.toUpperCase(),
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Action Log with Override buttons
          if (actionEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// ACTION LOG — WHO TARGETED WHOM',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...actionEntries.map((entry) {
              final stepId = entry.key;
              final targetId = entry.value;
              final roleId = _extractRoleId(stepId);
              final actorPlayer = _findActorForStep(stepId, playersById);
              final targetPlayer = playersById[targetId];
              final roleColor = roleId != null
                  ? CBColors.fromHex(
                      roleCatalogMap[roleId]?.colorHex ?? '#4CC9F0')
                  : scheme.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBGlassTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  borderColor: roleColor.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              actorPlayer != null
                                  ? '${actorPlayer.name.toUpperCase()} (${actorPlayer.role.name.toUpperCase()})'
                                  : _formatStepId(stepId),
                              style: textTheme.labelSmall!.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '→ ${targetPlayer?.name.toUpperCase() ?? targetId.toUpperCase()}',
                              style: textTheme.labelSmall!.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Override button
                      if (gameState.phase == GamePhase.night)
                        _OverrideButton(
                          stepId: stepId,
                          currentTargetId: targetId,
                          players: gameState.players,
                          roleColor: roleColor,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Private Messages
          if (hasPrivateMessages) ...[
            const SizedBox(height: 16),
            Text(
              '// INTERCEPTED PRIVATE COMMS',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.tertiary.withValues(alpha: 0.6),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            ...gameState.privateMessages.entries
                .where((e) => e.value.isNotEmpty)
                .map((entry) {
              final player = playersById[entry.key];
              final messages = entry.value;
              final roleColor = player != null
                  ? CBColors.fromHex(player.role.colorHex)
                  : scheme.tertiary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CBGlassTile(
                  padding: const EdgeInsets.all(10),
                  borderColor: roleColor.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO: ${player?.name.toUpperCase() ?? entry.key.toUpperCase()}',
                        style: textTheme.labelSmall!.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...messages.map((msg) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              msg.toUpperCase(),
                              style: textTheme.labelSmall!.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 8,
                                height: 1.3,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String? _extractRoleId(String stepId) {
    for (final role in roleCatalog) {
      if (stepId.contains(role.id)) return role.id;
    }
    return null;
  }

  Player? _findActorForStep(
      String stepId, Map<String, Player> playersById) {
    for (final p in playersById.values) {
      if (stepId.contains(p.id)) return p;
    }
    return null;
  }

  String _formatStepId(String stepId) {
    return stepId
        .replaceAll('_', ' ')
        .toUpperCase()
        .replaceAll(RegExp(r'\d+$'), '')
        .trim();
  }
}

class _OverrideButton extends ConsumerWidget {
  final String stepId;
  final String currentTargetId;
  final List<Player> players;
  final Color roleColor;

  const _OverrideButton({
    required this.stepId,
    required this.currentTargetId,
    required this.players,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: 'Override target',
        child: InkWell(
          onTap: () => _showOverrideDialog(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.edit_note_rounded,
              size: 16,
              color: scheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  void _showOverrideDialog(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alivePlayers =
        players.where((p) => p.isAlive && p.id != currentTargetId).toList();

    showThemedDialog<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OVERRIDE TARGET',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a new target for this action.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: alivePlayers.map((player) {
                  final pColor = CBColors.fromHex(player.role.colorHex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: CBPrimaryButton(
                      label: player.name.toUpperCase(),
                      backgroundColor: pColor.withValues(alpha: 0.15),
                      foregroundColor: pColor,
                      onPressed: () {
                        HapticService.medium();
                        ref
                            .read(gameProvider.notifier)
                            .overrideNightAction(stepId, player.id);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CBGhostButton(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
