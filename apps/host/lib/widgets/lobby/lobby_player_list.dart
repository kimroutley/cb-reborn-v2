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
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── SYSTEM: ROSTER STATUS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CBSectionHeader(
                title: gameState.players.isEmpty
                    ? "WAITING FOR PATRONS..."
                    : "ROSTER ACTIVE: ${gameState.players.length} PATRONS",
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                HapticService.light();
                controller.addBot();
              },
              tooltip: 'Add Bot Player',
              icon: Icon(
                Icons.smart_toy_rounded,
                color: theme.colorScheme.tertiary,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.tertiary.withValues(alpha: 0.1),
                side: BorderSide(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── PLAYER JOIN FEED ──
        if (gameState.players.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CBBreathingSpinner(),
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

          return CBFadeSlide(
            key: ValueKey('host_lobby_join_${player.id}'),
            delay: Duration(milliseconds: 24 * idx.clamp(0, 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: CBSpace.x3),
              child: CBMessageBubble(
                variant: CBMessageVariant.narrative,
                senderName: "SECURITY",
                content: player.isBot
                    ? "${player.name.toUpperCase()} (BOT) HAS BEEN ACTIVATED."
                    : "${descriptor.toUpperCase()} HAS ENTERED THE CLUB.",
                accentColor: theme.colorScheme
                    .tertiary, // Migrated from CBColors.matrixGreen
                avatar: CBRoleAvatar(
                  color: theme.colorScheme
                      .tertiary, // Migrated from CBColors.matrixGreen
                  size: 32,
                  breathing: true,
                  // assetPath: player.isBot ? 'assets/roles/bot_avatar.png' : null, // Future polish
                ),
                actions: [
                  CBCompactPlayerChip(
                    name: "EDIT",
                    color: theme.colorScheme.primary,
                    onTap: () async {
                      final renamed = await _showRenamePlayerDialog(
                        context,
                        initialName: player.name,
                      );
                      if (renamed == null || renamed.trim().isEmpty) {
                        return;
                      }
                      controller.updatePlayerName(player.id, renamed.trim());
                    },
                  ),
                  if (gameState.players.length > 1)
                    CBCompactPlayerChip(
                      name: "MERGE",
                      color: theme.colorScheme.secondary,
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
                  CBCompactPlayerChip(
                    name: "REJECT",
                    color: theme
                        .colorScheme.error, // Migrated from CBColors.dead
                    onTap: () {
                      HapticService.heavy();
                      controller.removePlayer(player.id);
                    },
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
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE PLAYER',
            style: CBTypography.headlineSmall.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: CBSpace.x4),
          CBTextField(
            controller: controller,
            autofocus: true,
            hintText: 'Username',
          ),
          const SizedBox(height: CBSpace.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: CBSpace.x3),
              CBPrimaryButton(
                label: 'SAVE',
                onPressed: () => Navigator.pop(context, controller.text),
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
    final choices = players.where((p) => p.id != sourcePlayer.id).toList();
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MERGE ${sourcePlayer.name.toUpperCase()} INTO',
            style: CBTypography.headlineSmall.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: CBSpace.x4),
          ...choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: CBSpace.x2),
              child: CBPrimaryButton(
                label: choice.name,
                backgroundColor: scheme.secondary,
                onPressed: () => Navigator.pop(context, choice.id),
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x2),
          CBGhostButton(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
