import 'package:cb_models/cb_models.dart' hide PlayerSnapshot;
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_bridge.dart';
import '../player_bridge_actions.dart';
import '../widgets/biometric_identity_header.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/game_action_tile.dart';
import '../widgets/ghost_lounge_content.dart';
import '../widgets/mission_alert_overlay.dart';
import '../widgets/notifications_prompt_banner.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _lastStepId;
  String? _lastPhase;
  int? _lastDayCount;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;
    final bridge = activeBridge.actions;
    final player = gameState.myPlayerSnapshot;
    final playerId = gameState.myPlayerId;

    if (player == null || playerId == null) {
      return CBPrismScaffold(
        title: 'SYNCING...',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CBSpace.x5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CBMessageBubble(
                  sender: 'SYSTEM DIRECTIVE',
                  message: 'WELCOME TO THE MISSION TERMINAL.\n\nPLEASE STAND BY WHILE WE ESTABLISH A SECURE CONNECTION AND VERIFY YOUR IDENTITY.\n\nONCE SYNCED, YOU WILL BE ASSIGNED A ROLE, RECEIVE YOUR DIRECTIVES, AND THE DAILY CYCLE WILL COMMENCE. WORK WITH YOUR ALLIES, OR DECEIVE YOUR ENEMIES. TRUST NO ONE.',
                  color: scheme.primary,
                  style: CBMessageStyle.standard,
                  isSender: false,
                  groupPosition: CBMessageGroupPosition.single,
                ),
                const SizedBox(height: CBSpace.x6),
                const CBBreathingSpinner(),
              ],
            ),
          ),
        ),
      );
    }

    if (gameState.phase == 'endGame') {
      return _buildEndGameScreen(context, gameState, player, scheme, textTheme);
    }

    final newStep = gameState.currentStep;
    final canAct =
        newStep != null && (newStep.roleId == player.roleId || newStep.isVote);

    if (newStep != null && newStep.id != _lastStepId && canAct) {
      _lastStepId = newStep.id;
      HapticService.medium();
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final roleColor =
            Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));
        showMissionAlertOverlay(
          context: context,
          stepTitle: newStep.title,
          accentColor: roleColor,
        );
      });
    } else if (newStep == null) {
      _lastStepId = null;
    }

    if (!player.isAlive && gameState.phase != 'endGame') {
      return GhostLoungeContent(
        gameState: gameState,
        playerId: playerId,
        bridge: bridge,
      );
    }

    // Cinematic phase transition overlay
    final phase = gameState.phase;
    final dayCount = gameState.dayCount;
    if (_lastPhase == null) {
      _lastPhase = phase;
      _lastDayCount = dayCount;
    } else if (_lastPhase != phase || _lastDayCount != dayCount) {
      final showNight = phase == 'night';
      final showDay = phase == 'day';
      final showEnd = phase == 'endGame';
      if (showNight || showDay || showEnd) {
        final label = showEnd
            ? 'MISSION OVER'
            : showNight
                ? 'NIGHT $dayCount FALLS'
                : 'DAWN OF DAY $dayCount';
        final color = showNight
            ? scheme.secondary
            : showEnd
                ? scheme.tertiary
                : scheme.primary;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showPhaseTransitionOverlay(
            context: context,
            title: label,
            subtitle: gameState.currentStep?.title ?? gameState.phase,
            accentColor: color,
          );
        });
      }
      _lastPhase = phase;
      _lastDayCount = dayCount;
    }

    final roleColor =
        Color(int.parse(player.roleColorHex.replaceAll('#', '0xff')));
    final isRoleConfirmed = gameState.roleConfirmedPlayerIds.contains(playerId);

    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: CBPrismScaffold(
        title: 'MISSION TERMINAL',
        drawer: const CustomDrawer(),
        body: CBPhaseOverlay(
          isNight: gameState.phase == 'night',
          child: Column(
          children: [
            BiometricIdentityHeader(
              player: player,
              roleColor: roleColor,
              isMyTurn: canAct,
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: CBSpace.x4, bottom: 200),
                physics: const BouncingScrollPhysics(),
                children: [
                  const NotificationsPromptBanner(),

                  // Phase/Day Header
                  CBFadeSlide(
                    child: CBFeedSeparator(
                      label: "${gameState.phase.toUpperCase()} // CYCLE ${gameState.dayCount}",
                      color: roleColor,
                    ),
                  ),

                  // Role Specific Intel Gaps
                  if (player.roleId == RoleIds.bartender)
                    _buildBartenderIntel(gameState, roleColor),
                  
                  if (player.roleId == RoleIds.clubManager)
                    _buildClubManagerIntel(gameState, roleColor),

                  const SizedBox(height: CBSpace.x4),

                  // Bulletin Board
                  const CBFadeSlide(
                    delay: Duration(milliseconds: 100),
                    child: CBFeedSeparator(label: 'SECURE CHANNEL'),
                  ),
                  
                  _buildBulletinFeed(gameState, player, scheme),

                  // Private Messages
                  if (gameState.privateMessages.containsKey(playerId))
                    ..._buildPrivateMessages(
                        gameState.privateMessages[playerId]!, scheme, roleColor),

                  // Current Step Narration
                  if (newStep != null && newStep.readAloudText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x6, CBSpace.x5, 0),
                      child: CBFadeSlide(
                        delay: const Duration(milliseconds: 200),
                        child: CBMessageBubble(
                          sender: 'SYSTEM DIRECTIVE',
                          message: newStep.readAloudText.toUpperCase(),
                          avatarAsset: 'assets/roles/${player.roleId}.png',
                          color: roleColor,
                          style: CBMessageStyle.standard,
                          isSender: false,
                          groupPosition: CBMessageGroupPosition.single,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
        bottomNavigationBar: (gameState.phase == 'setup' && !isRoleConfirmed)
            ? _buildSetupConfirmBar(context, bridge, playerId, roleColor)
            : canAct
                ? _buildGameActionBar(
                    context,
                    newStep,
                    roleColor,
                    player,
                    gameState,
                    playerId,
                    bridge,
                  )
                : null,
      ),
    );
  }

  Widget _buildBulletinFeed(PlayerGameState gameState, PlayerSnapshot player, ColorScheme scheme) {
    final entries = gameState.bulletinBoard;

    return BulletinFeed(
      entries: entries,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemBuilder: (context, i, entry, groupPosition) {
        final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
        final color = entry.roleId != null
            ? CBColors.fromHex(role.colorHex)
            : scheme.primary;
        final senderName = role.id == 'unassigned' ? entry.title : role.name;
        final isMe = entry.roleId == player.roleId;
        
        return CBFadeSlide(
          delay: Duration(milliseconds: 50 * (i % 5)),
          child: CBMessageBubble(
            sender: senderName.toUpperCase(),
            message: entry.content,
            style: entry.type == 'system'
                ? CBMessageStyle.system
                : CBMessageStyle.narrative,
            color: color,
            isSender: isMe,
            avatarAsset: entry.roleId != null ? role.assetPath : null,
            groupPosition: groupPosition,
          ),
        );
      },
    );
  }

  Widget _buildBartenderIntel(PlayerGameState gameState, Color roleColor) {
    final bartenderMessages = gameState.privateMessages[gameState.myPlayerId] ?? [];
    final alignedPairs = <List<String>>[];
    final nonAlignedPairs = <List<String>>[];

    for (final msg in bartenderMessages) {
      if (msg.contains('ALIGNED')) {
        // Parse "PlayerA and PlayerB are ALIGNED"
        final parts = msg.split(' are ');
        if (parts.length >= 2) {
          final names = parts[0].split(' and ');
          if (names.length >= 2) alignedPairs.add(names);
        }
      } else if (msg.contains('NOT ALIGNED')) {
        final parts = msg.split(' are ');
        if (parts.length >= 2) {
          final names = parts[0].split(' and ');
          if (names.length >= 2) nonAlignedPairs.add(names);
        }
      }
    }

    if (alignedPairs.isEmpty && nonAlignedPairs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x4, CBSpace.x5, 0),
      child: CBFadeSlide(
        child: CBPanel(
          borderColor: roleColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(CBSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CBSectionHeader(
                title: 'ALIGNMENT ARCHIVE',
                icon: Icons.hub_rounded,
                color: roleColor,
              ),
              const SizedBox(height: CBSpace.x4),
              if (alignedPairs.isNotEmpty) ...[
                Text('ALIGNED NODES', style: CBTypography.nano.copyWith(color: CBColors.matrixGreen, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: CBSpace.x2),
                ...alignedPairs.map((pair) => _buildIntelRow(pair[0], pair[1], CBColors.matrixGreen, Icons.link_rounded)),
                const SizedBox(height: CBSpace.x3),
              ],
              if (nonAlignedPairs.isNotEmpty) ...[
                Text('INCOMPATIBLE NODES', style: CBTypography.nano.copyWith(color: CBColors.error, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: CBSpace.x2),
                ...nonAlignedPairs.map((pair) => _buildIntelRow(pair[0], pair[1], CBColors.error, Icons.link_off_rounded)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelRow(String p1, String p2, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x1),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: CBSpace.x2),
          Expanded(child: Text('${p1.toUpperCase()} ↔ ${p2.toUpperCase()}', style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildClubManagerIntel(PlayerGameState gameState, Color roleColor) {
    final managerMessages = gameState.privateMessages[gameState.myPlayerId] ?? [];
    final dossiers = <String, String>{};

    for (final msg in managerMessages) {
      if (msg.contains('role is ')) {
        // Parse "PlayerName's role is RoleName"
        final parts = msg.split('\'s role is ');
        if (parts.length >= 2) {
          dossiers[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    if (dossiers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x4, CBSpace.x5, 0),
      child: CBFadeSlide(
        child: CBPanel(
          borderColor: roleColor.withValues(alpha: 0.4),
          padding: CBInsets.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CBSectionHeader(
                title: 'OPERATIVE DOSSIERS',
                icon: Icons.assignment_ind_rounded,
                color: roleColor,
              ),
              const SizedBox(height: CBSpace.x4),
              ...dossiers.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: CBSpace.x2),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: roleColor),
                    const SizedBox(width: CBSpace.x3),
                    Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const Spacer(),
                    CBMiniTag(text: e.value.toUpperCase(), color: roleColor),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrivateMessages(
      List<String> messages, ColorScheme scheme, Color roleColor) {
    final filtered = messages.where((m) => !m.startsWith('[GHOST]')).toList();
    if (filtered.isEmpty) return [];

    final widgets = <Widget>[];
    widgets.add(const SizedBox(height: CBSpace.x6));
    widgets.add(const CBFadeSlide(child: CBFeedSeparator(label: 'ENCRYPTED INTEL')));
    widgets.add(const SizedBox(height: CBSpace.x2));

    for (int i = 0; i < filtered.length; i++) {
      final msg = filtered[i];
      CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
      if (filtered.length > 1) {
        if (i == 0) {
          groupPos = CBMessageGroupPosition.top;
        } else if (i == filtered.length - 1) {
          groupPos = CBMessageGroupPosition.bottom;
        } else {
          groupPos = CBMessageGroupPosition.middle;
        }
      }

      widgets.add(CBFadeSlide(
        delay: Duration(milliseconds: 50 * i),
        child: CBMessageBubble(
          sender: 'HQ // SECURITY',
          message: msg.toUpperCase(),
          style: CBMessageStyle.standard,
          color: scheme.tertiary,
          isSender: false,
          avatarAsset: 'assets/roles/security.png',
          groupPosition: groupPos,
        ),
      ));
    }
    return widgets;
  }

  Widget _buildSetupConfirmBar(BuildContext context, PlayerBridgeActions bridge,
      String playerId, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(CBSpace.x3, CBSpace.x2, CBSpace.x3, CBSpace.x3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CBColors.transparent, Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: CBFadeSlide(
          child: CBGlassTile(
            borderColor: color.withValues(alpha: 0.5),
            isPrismatic: true,
            padding: CBInsets.screen,
            child: CBPrimaryButton(
              label: 'CONFIRM IDENTITY',
              icon: Icons.fingerprint_rounded,
              backgroundColor: color,
              onPressed: () {
                bridge.confirmRole(playerId: playerId);
                HapticService.heavy();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameActionBar(
    BuildContext context,
    StepSnapshot step,
    Color roleColor,
    PlayerSnapshot player,
    PlayerGameState gameState,
    String playerId,
    PlayerBridgeActions bridge,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(CBSpace.x3, CBSpace.x2, CBSpace.x3, CBSpace.x3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CBColors.transparent, Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GameActionTile(
          step: step,
          roleColor: roleColor,
          player: player,
          gameState: gameState,
          playerId: playerId,
          bridge: bridge,
        ),
      ),
    );
  }

  Widget _buildEndGameScreen(
    BuildContext context,
    PlayerGameState gameState,
    PlayerSnapshot player,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final winner = gameState.winner;
    final winColor = winner == 'clubStaff'
        ? scheme.primary
        : (winner == 'partyAnimals' ? scheme.secondary : scheme.tertiary);

    return CBPrismScaffold(
      title: 'MISSION COMPLETE',
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(CBSpace.x6),
        children: [
          CBStatusOverlay(
            icon: Icons.emoji_events_rounded,
            label: 'GAME OVER',
            color: winColor,
            detail: '${winner?.toUpperCase() ?? "UNKNOWN"} VICTORY',
          ),
          const SizedBox(height: CBSpace.x6),
          CBGlassTile(
            borderColor: winColor.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(CBSpace.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CBSectionHeader(
                  title: 'FINAL REPORT',
                  icon: Icons.summarize_rounded,
                  color: winColor,
                ),
                const SizedBox(height: CBSpace.x4),
                ...gameState.endGameReport.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: CBSpace.x2),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          if (gameState.rematchOffered)
            CBFadeSlide(
              child: CBPrimaryButton(
                label: 'PLAY AGAIN AS NEW ROLE',
                icon: Icons.refresh_rounded,
                backgroundColor: scheme.tertiary,
                onPressed: () {
                  HapticService.heavy();
                  // In cloud mode, the host already kept the player in the roster.
                  // The player just needs to wait for the phase to change to lobby.
                  // We can show a small snackbar or just let the shell handle it.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('REMATCH INITIATED. STAND BY.')),
                  );
                },
              ),
            ),
          const SizedBox(height: CBSpace.x4),
          CBGhostButton(
            label: 'LEAVE SESSION',
            icon: Icons.exit_to_app_rounded,
            onPressed: () {
              HapticService.selection();
              ref.read(activeBridgeProvider).actions.leave();
            },
          ),
        ],
      ),
    );
  }
}
