import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sheets/single_player_role_sheet.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);

    final connectedHumans = gameState.players.where((p) => !p.isBot).length;
    final confirmedHumans = session.roleConfirmedPlayerIds
        .where((id) => gameState.players.any((p) => p.id == id && !p.isBot))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── ROSTER METRICS ──
        CBFadeSlide(
          child: CBGlassTile(
            padding: const EdgeInsets.all(CBSpace.x4),
            borderColor:
                confirmedHumans >= connectedHumans && connectedHumans > 0
                    ? scheme.tertiary.withValues(alpha: 0.5)
                    : scheme.secondary.withValues(alpha: 0.4),
            isPrismatic:
                confirmedHumans >= connectedHumans && connectedHumans > 0,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    color: (confirmedHumans >= connectedHumans &&
                                connectedHumans > 0
                            ? scheme.tertiary
                            : scheme.secondary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    size: 20,
                    color: confirmedHumans >= connectedHumans &&
                            connectedHumans > 0
                        ? scheme.tertiary
                        : scheme.secondary,
                  ),
                ),
                const SizedBox(width: CBSpace.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURE UPLINK STATUS',
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$confirmedHumans / $connectedHumans OPERATIVES VERIFIED',
                        style: textTheme.titleSmall!.copyWith(
                          color: confirmedHumans >= connectedHumans &&
                                  connectedHumans > 0
                              ? scheme.tertiary
                              : scheme.secondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: CBSpace.x4),
        const CBFeedSeparator(label: 'UPLINK STREAM'),
        const SizedBox(height: CBSpace.x2),

        // ── PLAYER JOIN FEED ──
        if (gameState.players.isEmpty)
          Expanded(
            child: Center(
              child: CBFadeSlide(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CBBreathingSpinner(size: 48),
                    const SizedBox(height: CBSpace.x6),
                    Text(
                      'SCANNING FOR SIGNALS...',
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge!.copyWith(
                        color: scheme.primary.withValues(alpha: 0.5),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: CBSpace.x8),
              itemCount: gameState.players.length,
              itemBuilder: (context, idx) {
                final player = gameState.players[idx];
                final profileAsync = player.authUid != null
                    ? ref.watch(userProfileProvider(player.authUid!))
                    : null;

                final profile = profileAsync?.maybeWhen(
                  data: (data) => data,
                  orElse: () => null,
                );
                final profileUsername =
                    (profile?['username'] as String?)?.trim();
                final displayName =
                    (profileUsername != null && profileUsername.isNotEmpty)
                        ? profileUsername
                        : player.name;

                final isConfirmed =
                    session.roleConfirmedPlayerIds.contains(player.id);

                return CBFadeSlide(
                  delay: Duration(milliseconds: 40 * idx.clamp(0, 15)),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: CBSpace.x3),
                    child: CBGlassTile(
                      borderColor: isConfirmed
                          ? scheme.tertiary.withValues(alpha: 0.4)
                          : scheme.outlineVariant.withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(CBSpace.x3),
                      child: Row(
                        children: [
                          CBRoleAvatar(
                            color:
                                isConfirmed ? scheme.tertiary : scheme.primary,
                            size: 40,
                            icon: player.isBot
                                ? Icons.smart_toy_rounded
                                : Icons.person_rounded,
                            pulsing: !isConfirmed,
                          ),
                          const SizedBox(width: CBSpace.x4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.toUpperCase(),
                                  style: textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontFamily: 'RobotoMono',
                                    color: isConfirmed
                                        ? scheme.tertiary
                                        : scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  player.isBot
                                      ? 'BOT EMULATION ACTIVE'
                                      : (isConfirmed
                                          ? 'BIOMETRICS VERIFIED'
                                          : 'AWAITING UPLINK...'),
                                  style: textTheme.labelSmall!.copyWith(
                                    color: (isConfirmed
                                            ? scheme.tertiary
                                            : scheme.onSurface)
                                        .withValues(alpha: 0.4),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: CBSpace.x2),
                          _LobbyActionIcon(
                            icon: Icons.assignment_ind_rounded,
                            tooltip: 'ASSIGN ROLE',
                            color: scheme.tertiary,
                            onTap: () {
                              HapticService.selection();
                              showThemedBottomSheet(
                                context: context,
                                child: SinglePlayerRoleSheet(
                                  playerId: player.id,
                                  playerName: player.name,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: CBSpace.x2),
                          _LobbyActionIcon(
                            icon: Icons.edit_note_rounded,
                            tooltip: 'RENAME',
                            color: scheme.primary,
                            onTap: () async {
                              final renamed = await _showRenamePlayerDialog(
                                context,
                                initialName: player.name,
                              );
                              if (renamed != null &&
                                  renamed.trim().isNotEmpty) {
                                controller.updatePlayerName(
                                    player.id, renamed.trim());
                              }
                            },
                          ),
                          const SizedBox(width: CBSpace.x2),
                          _LobbyActionIcon(
                            icon: Icons.close_rounded,
                            tooltip: 'EJECT',
                            color: scheme.error,
                            onTap: () {
                              HapticService.heavy();
                              controller.removePlayer(player.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'IDENTITY UPDATE',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: CBColors.textGlow(scheme.primary),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x6),
          CBTextField(
            controller: controller,
            autofocus: true,
            hintText: 'ENTER NEW IDENTIFIER',
            monospace: true,
          ),
          const SizedBox(height: CBSpace.x8),
          Row(
            children: [
              Expanded(
                child: CBGhostButton(
                  label: 'ABORT',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: CBPrimaryButton(
                  label: 'CONFIRM',
                  onPressed: () => Navigator.pop(context, controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LobbyActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _LobbyActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: tooltip.toUpperCase(),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(CBRadius.xs),
          child: Container(
            padding: const EdgeInsets.all(CBSpace.x2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CBRadius.xs),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
