import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../cloud_host_bridge.dart';
import '../host_bridge.dart';
import '../providers/lobby_profiles_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  Future<void> _setSyncMode(
    WidgetRef ref,
    Game controller,
    SyncMode newMode,
  ) async {
    controller.setSyncMode(newMode);

    if (newMode == SyncMode.cloud) {
      await ref.read(hostBridgeProvider).stop();
      await ref.read(cloudHostBridgeProvider).start();
      return;
    }

    await ref.read(cloudHostBridgeProvider).stop();
    await ref.read(hostBridgeProvider).start();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final session = ref.watch(sessionProvider);
    final isCloud = gameState.syncMode == SyncMode.cloud;
    final bridge = ref.read(hostBridgeProvider);
    final canStart = gameState.players.length >= 5;
    final profilesAsync = ref.watch(lobbyProfilesProvider);

    return CBPrismScaffold(
      title: 'LOBBY',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      floatingActionButton: canStart
          ? CBPrimaryButton(
              label: "START SESSION",
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                HapticService.heavy();
                controller.startGame();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: const EdgeInsets.symmetric(
            vertical: CBSpace.x6, horizontal: CBSpace.x5),
        children: [
          // ── SYSTEM: SESSION CREATED ──
          CBMessageBubble(
            variant: CBMessageVariant.system,
            content: "SESSION BROADCAST ACTIVE. STANDBY FOR HANDSHAKE.",
            accentColor:
                theme.colorScheme.primary, // Migrated from CBColors.neonBlue
          ),

          const SizedBox(height: 16),

          // ── ACCESS CODE TILE ──
          _buildAccessCodeTile(context, ref, bridge, isCloud, session,
              theme.colorScheme.primary),

          const SizedBox(height: 24),

          // ── SYSTEM: CONFIGURATION ──
          CBSectionHeader(
            title: "NETWORK PROTOCOLS",
            color: theme
                .colorScheme.secondary, // Migrated from CBColors.neonPurple
          ),

          const SizedBox(height: 12),

          _buildConfigTile(context, gameState, controller, ref,
              theme.colorScheme.primary, theme.colorScheme.secondary),

          const SizedBox(height: 32),

          // ── GAMES NIGHT BANNER ──
          _buildGamesNightMessage(ref, context),

          const SizedBox(height: 32),

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

            // PERFORMANCE: Use batch-fetched profiles to avoid N+1 Firestore reads
            final profile = profilesAsync.maybeWhen(
              data: (profiles) => player.authUid != null ? profiles[player.authUid] : null,
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

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildAccessCodeTile(
      BuildContext context,
      WidgetRef ref,
      HostBridge bridge,
      bool isCloud,
      SessionState session,
      Color primaryColor) {
    final scheme = Theme.of(context).colorScheme;
    final port = bridge.port;

    return CBGlassTile(
      title: "ACCESS CODE",
      subtitle: isCloud ? "CLOUD SYNC ENABLED" : "LOCAL BROADCAST ACTIVE",
      accentColor: primaryColor,
      isPrismatic: true,
      icon: Icon(
          isCloud ? Icons.cloud_done_outlined : Icons.wifi_tethering_rounded,
          color: primaryColor),
      content: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PATRONS ENTER THIS CODE TO CONNECT",
                  style: CBTypography.labelSmall.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 8,
                      letterSpacing: 2.0),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: primaryColor.withValues(
                            alpha: 0.3)), // Migrated from CBColors.neonBlue
                  ),
                  child: Text(
                    session.joinCode,
                    style: CBTypography.code.copyWith(
                      color: primaryColor, // Migrated from CBColors.neonBlue
                      fontSize: 32,
                      letterSpacing: 12,
                      shadows: CBColors.textGlow(
                          primaryColor), // Migrated from CBColors.neonBlue
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildJoinQrCode(context, ref, session, isCloud, port),
        ],
      ),
    );
  }

  Widget _buildJoinQrCode(
    BuildContext context,
    WidgetRef ref,
    SessionState session,
    bool isCloud,
    int port,
  ) {
    if (isCloud) {
      final cloudJoinUrl =
          'https://cb-reborn.web.app/join?mode=cloud&code=${session.joinCode}';
      return _buildQrWidget(context, cloudJoinUrl, 'SCAN CLOUD LINK');
    }

    final ipsAsync = ref.watch(localIpsProvider);
    return ipsAsync.when(
      data: (ips) {
        if (ips.isEmpty) {
          return const SizedBox.shrink();
        }
        final ip = ips.first;
        final host = Uri.encodeComponent('ws://$ip:$port');
        final joinUrl =
            'https://cb-reborn.web.app/join?mode=local&host=$host&code=${session.joinCode}';
        return _buildQrWidget(context, joinUrl, 'SCAN LOCAL LINK');
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildQrWidget(BuildContext context, String url, String caption) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.onSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: CBColors.boxGlow(scheme.onSurface, intensity: 0.3),
          ),
          child: QrImageView(
            data: url,
            version: QrVersions.auto,
            size: 90,
            gapless: false,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: CBColors.voidBlack,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: CBTypography.labelSmall.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.4),
            fontSize: 7,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigTile(
      BuildContext context,
      GameState gameState,
      Game controller,
      WidgetRef ref,
      Color primaryColor,
      Color secondaryColor) {
    return CBGlassTile(
      title: "PROTOCOL SETTINGS",
      accentColor: secondaryColor,
      isPrismatic: true,
      icon: Icon(Icons.settings_input_component_rounded, color: secondaryColor),
      content: Row(
        children: [
          _buildConfigOption(
              context, "SYNC", gameState.syncMode.name, primaryColor, () {
            HapticService.selection();
            final newMode = gameState.syncMode == SyncMode.local
                ? SyncMode.cloud
                : SyncMode.local;
            unawaited(_setSyncMode(ref, controller, newMode));
          }),
          const SizedBox(width: 12),
          _buildConfigOption(
              context, "STYLE", gameState.gameStyle.label, secondaryColor, () {
            HapticService.selection();
            controller.setGameStyle(gameState.gameStyle == GameStyle.chaos
                ? GameStyle.offensive
                : GameStyle.chaos);
          }),
        ],
      ),
    );
  }

  Widget _buildConfigOption(BuildContext context, String label, String value,
      Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: CBColors.boxGlow(color, intensity: 0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: CBTypography.labelSmall.copyWith(
                      fontSize: 8,
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(value.toUpperCase(),
                  style: CBTypography.labelSmall.copyWith(
                      color: color, // Migrated from CBColors.neonBlue
                      fontWeight: FontWeight.w900,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesNightMessage(WidgetRef ref, BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(gamesNightProvider);
    if (session == null || !session.isActive) {
      return CBMessageBubble(
        variant: CBMessageVariant.narrative,
        senderName: "PROMOTER",
        accentColor: theme.colorScheme.tertiary,
        content:
            "Hosting a full session? Start a Games Night to track multiple rounds and get a recap.",
        avatar: CBRoleAvatar(
            color: theme.colorScheme.tertiary,
            size: 32,
            pulsing: true), // Migrated from CBColors.matrixGreen
        actions: [
          CBCompactPlayerChip(
            name: "START GAMES NIGHT",
            color: theme
                .colorScheme.tertiary, // Migrated from CBColors.matrixGreen
            onTap: () async {
              final name = await _showStartSessionDialog(context);
              if (name == null || name.trim().isEmpty) return;

              await ref
                  .read(gamesNightProvider.notifier)
                  .startSession(name.trim());

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Games Night started.'),
                  backgroundColor: theme.colorScheme
                      .tertiary, // Migrated from CBColors.matrixGreen
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      );
    }

    return CBMessageBubble(
      variant: CBMessageVariant.result,
      content:
          "GAMES NIGHT ACTIVE: ${session.sessionName} (GAME #${session.gameIds.length + 1})",
      accentColor: theme.colorScheme.tertiary,
    );
  }

  Future<String?> _showStartSessionDialog(BuildContext context) async {
    final controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    return showThemedDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'START GAMES NIGHT',
            style: CBTypography.headlineSmall.copyWith(
              color: scheme.tertiary, // Migrated from CBColors.matrixGreen
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(
                  scheme.tertiary), // Migrated from CBColors.matrixGreen
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CONNECT MULTIPLE ROUNDS FOR A FULL RECAP',
            style: CBTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          CBTextField(
            controller: controller,
            autofocus: true,
            textStyle: CBTypography.bodyLarge.copyWith(color: scheme.onSurface),
            decoration: InputDecoration(
              labelText: 'SESSION NAME',
              labelStyle: CBTypography.bodyMedium.copyWith(
                  color: scheme.tertiary.withValues(
                      alpha: 0.7)), // Migrated from CBColors.matrixGreen
              hintText: 'e.g. SATURDAY NIGHT FEVER',
              hintStyle: CBTypography.bodyMedium
                  .copyWith(color: scheme.onSurface.withValues(alpha: 0.2)),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color:
                        scheme.tertiary), // Migrated from CBColors.matrixGreen
              ),
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
                label: 'INITIALIZE',
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context, controller.text);
                  }
                },
              ),
            ],
          )
        ],
      ),
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
