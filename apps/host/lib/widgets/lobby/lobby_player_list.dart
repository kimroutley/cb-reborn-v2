import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('user_profiles')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data());
});

class LobbyPlayerList extends ConsumerWidget {
  const LobbyPlayerList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);
    final connectedHumans = gameState.players.where((p) => !p.isBot).length;
    final confirmedHumans = session.roleConfirmedPlayerIds
        .where((id) => gameState.players.any((p) => p.id == id && !p.isBot))
        .length;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── SYSTEM: ROSTER STATUS ──
        Row(
          children: [
            Expanded(
              child: CBSectionHeader(
                title: gameState.players.isEmpty
                    ? "WAITING FOR PATRONS..."
                    : "ROSTER ACTIVE: ${gameState.players.length}/${Game.maxPlayers} PATRONS",
                color: scheme.tertiary,
                icon: Icons.group_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  HapticService.light();
                  controller.addBot();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scheme.tertiary.withValues(alpha: 0.3)),
                    boxShadow:
                        CBColors.boxGlow(scheme.tertiary, intensity: 0.1),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: scheme.tertiary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        CBGlassTile(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderColor: confirmedHumans >= connectedHumans && connectedHumans > 0
              ? scheme.tertiary.withValues(alpha: 0.5)
              : scheme.secondary.withValues(alpha: 0.5),
          child: Row(
            children: [
              Icon(
                Icons.security_update_good_rounded,
                size: 16,
                color: confirmedHumans >= connectedHumans && connectedHumans > 0
                    ? scheme.tertiary
                    : scheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SETUP STATUS: $confirmedHumans / $connectedHumans ROLE CONFIRMATIONS RECEIVED',
                  style: textTheme.labelSmall!.copyWith(
                    color: confirmedHumans >= connectedHumans &&
                            connectedHumans > 0
                        ? scheme.tertiary
                        : scheme.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (confirmedHumans >= connectedHumans && connectedHumans > 0)
                Icon(Icons.check_circle_rounded,
                    color: scheme.tertiary, size: 16),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── PLAYER JOIN FEED ──
        if (gameState.players.isEmpty)
          CBPanel(
            borderColor: scheme.tertiary.withValues(alpha: 0.2),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CBBreathingLoader(size: 48),
                    const SizedBox(height: 24),
                    Text(
                      'WAITING FOR INCOMING CONNECTIONS...',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.tertiary,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w800,
                        shadows:
                            CBColors.textGlow(scheme.tertiary, intensity: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BROADCASTING JOIN CODE: ${session.joinCode}',
                      style: textTheme.bodySmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ...gameState.players.asMap().entries.map((entry) {
          final idx = entry.key;
          final player = entry.value;
          final profileAsync = player.authUid != null
              ? ref.watch(userProfileProvider(player.authUid!))
              : null;

          final profile = profileAsync?.maybeWhen(
            data: (data) => data,
            orElse: () => null,
          );
          final profileUsername = (profile?['username'] as String?)?.trim();
          final emailMasked = (profile?['emailMasked'] as String?)?.trim();
          final displayName =
              (profileUsername != null && profileUsername.isNotEmpty)
                  ? profileUsername
                  : player.name;
          final descriptor = (emailMasked != null && emailMasked.isNotEmpty)
              ? '$displayName ($emailMasked)'
              : displayName;
          final hasPendingDramaSwap =
              pendingDramaSwapTargetIds.contains(player.id);

          return CBFadeSlide(
            key: ValueKey('host_lobby_join_${player.id}'),
            delay: Duration(milliseconds: 30 * idx.clamp(0, 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBMessageBubble(
                    sender: "SECURITY",
                    message: player.isBot
                        ? "${player.name.toUpperCase()} (BOT) DEPLOYED TO SECTOR."
                        : "${descriptor.toUpperCase()} HAS PASSED BIOMETRIC CHECK.",
                    color: scheme.tertiary,
                    avatarAsset: player.isBot
                        ? 'assets/roles/bot_avatar.png'
                        : 'assets/roles/security.png',
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasPendingDramaSwap)
                          _LobbyActionChip(
                            label: 'PENDING SWAP',
                            icon: Icons.swap_horiz_rounded,
                            color: scheme.secondary,
                            onTap: () {},
                          ),
                        _LobbyActionChip(
                          label: "RENAME",
                          icon: Icons.edit_rounded,
                          color: scheme.primary,
                          onTap: () async {
                            final renamed = await _showRenamePlayerDialog(
                              context,
                              initialName: player.name,
                            );
                            if (renamed == null || renamed.trim().isEmpty) {
                              return;
                            }
                            controller.updatePlayerName(
                                player.id, renamed.trim());
                          },
                        ),
                        if (gameState.players.length > 1)
                          _LobbyActionChip(
                            label: "MERGE",
                            icon: Icons.merge_type_rounded,
                            color: scheme.secondary,
                            onTap: () async {
                              final targetId = await _showMergePlayerDialog(
                                context,
                                players: gameState.players,
                                sourcePlayer: player,
                              );
                              if (targetId == null) {
                                return;
                              }
                              controller.mergePlayers(
                                sourceId: player.id,
                                targetId: targetId,
                              );
                            },
                          ),
                        _LobbyActionChip(
                          label: "EJECT",
                          icon: Icons.logout_rounded,
                          color: scheme.error,
                          onTap: () {
                            HapticService.heavy();
                            controller.removePlayer(player.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<String?> _showRenamePlayerDialog(
    BuildContext context, {
    required String initialName,
  }) async {
    final controller = TextEditingController(text: initialName);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: IDENTITY UPDATE',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          CBTextField(
            controller: controller,
            autofocus: true,
            hintText: 'New Identity Handle',
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
                label: 'CONFIRM',
                onPressed: () => Navigator.pop(context, controller.text),
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _showMergePlayerDialog(
    BuildContext context, {
    required List<Player> players,
    required Player sourcePlayer,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final choices = players.where((p) => p.id != sourcePlayer.id).toList();
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL: NEURAL MERGE',
            style: textTheme.labelLarge!.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Merging ${sourcePlayer.name.toUpperCase()} into another node...',
            style: textTheme.bodySmall!
                .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: choices
                    .map(
                      (choice) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CBPrimaryButton(
                          label: choice.name,
                          backgroundColor:
                              scheme.secondary.withValues(alpha: 0.2),
                          foregroundColor: scheme.secondary,
                          onPressed: () => Navigator.pop(context, choice.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CBGhostButton(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _LobbyActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LobbyActionChip({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
