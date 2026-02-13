import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_player/screens/player_selection_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_models/cb_models.dart' hide PlayerSnapshot, BulletinEntry;
import '../widgets/custom_drawer.dart';

class GameScreen extends ConsumerStatefulWidget {
  final PlayerBridgeActions bridge;
  final PlayerGameState gameState;
  final PlayerSnapshot player;
  final String playerId;

  const GameScreen({
    super.key,
    required this.bridge,
    required this.gameState,
    required this.player,
    required this.playerId,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String? _lastStepId;

  // Strobe/Flash Effect
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flashAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newStep = widget.gameState.currentStep;
    final canAct = newStep != null &&
        (newStep.roleId == widget.player.roleId || newStep.isVote);

    if (newStep != null && newStep.id != _lastStepId && canAct) {
      _lastStepId = newStep.id;
      HapticService.alertDispatch();
      _scrollToBottom();
    } else if (newStep == null) {
      _lastStepId = null;
    }

    // Check for STIM commands (Director Mode)
    if (widget.gameState.bulletinBoard.length >
        oldWidget.gameState.bulletinBoard.length) {
      final newEntries = widget.gameState.bulletinBoard
          .sublist(oldWidget.gameState.bulletinBoard.length);
      for (final entry in newEntries) {
        if (entry.content.startsWith('STIM:')) {
          _triggerStim(entry.content.substring(5).trim());
        }
      }
    }
  }

  void _triggerStim(String command) {
    // Haptic kick
    HapticService.heavy();
    final scheme = Theme.of(context).colorScheme;

    if (command == 'NEON FLICKER') {
      setState(() => _flashColor = scheme.primary);
      _flashController.forward().then((_) => _flashController.reverse());
    } else if (command == 'SYSTEM GLITCH') {
      setState(() => _flashColor = scheme.tertiary);
      _flashController.repeat(reverse: true);
      Future.delayed(
          const Duration(milliseconds: 800), () => _flashController.stop());
    } else if (command == 'BASS DROP') {
      // Blackout then flash
      setState(() => _flashColor = scheme.onSurface);
      Future.delayed(const Duration(milliseconds: 500), () {
        _flashController.forward().then((_) => _flashController.reverse());
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.player.isAlive) {
      return _buildGhostLounge();
    }

    final step = widget.gameState.currentStep;
    final roleColor = CBColors.fromHex(widget.player.roleColorHex);
    final canAct =
        step != null && (step.roleId == widget.player.roleId || step.isVote);

    // Apply dynamic theme for the role
    return Theme(
      data: CBTheme.buildTheme(CBTheme.buildColorScheme(roleColor)),
      child: Stack(
        children: [
          CBPrismScaffold(
            title: 'GAME FEED',
            drawer: const CustomDrawer(),
            body: Column(
              children: [
                // ── BIOMETRIC IDENTITY HEADER ──
                _BiometricIdentityHeader(
                  player: widget.player,
                  roleColor: roleColor,
                  isMyTurn: canAct,
                ),

                // ── CHAT FEED ──
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      // 1. Current Phase Header
                      CBMessageBubble(
                        variant: CBMessageVariant.system,
                        content:
                            "${widget.gameState.phase.toUpperCase()} - DAY ${widget.gameState.dayCount}",
                        accentColor: roleColor,
                      ),

                      // 2. Bulletin History (Public events)
                      ...widget.gameState.bulletinBoard.map((entry) {
                        final role =
                            roleCatalogMap[entry.roleId] ?? roleCatalog.first;
                        final color = entry.roleId != null
                            ? CBColors.fromHex(role.colorHex)
                            : theme.colorScheme.primary; // Use theme color

                        return CBMessageBubble(
                          variant: entry.type == 'system'
                              ? CBMessageVariant.system
                              : CBMessageVariant.narrative,
                          content: entry.content,
                          senderName:
                              role.id == 'unassigned' ? entry.title : role.name,
                          accentColor: color,
                          avatar: entry.roleId != null
                              ? CBRoleAvatar(
                                  assetPath: role.assetPath,
                                  color: color,
                                  size: 32)
                              : null,
                        );
                      }),

                      // 3. Private Intel (The "Secret" Chat)
                      if (widget.gameState.privateMessages
                          .containsKey(widget.playerId))
                        ...widget.gameState.privateMessages[widget.playerId]!
                            .map((msg) => CBMessageBubble(
                                  variant: CBMessageVariant.directive,
                                  content: msg,
                                  accentColor: theme.colorScheme.tertiary,
                                )),

                      // 4. Current Directive
                      if (step != null) ...[
                        CBMessageBubble(
                          variant: CBMessageVariant.narrative,
                          senderName: "DIRECTIVE",
                          content: step.readAloudText,
                          accentColor: roleColor,
                          avatar: CBRoleAvatar(
                              assetPath:
                                  'assets/roles/${widget.player.roleId}.png',
                              color: roleColor,
                              size: 34,
                              pulsing: true),
                        ),

                        // 5. Action Tile (Interactive)
                        if (canAct) _buildDynamicActionTile(step, roleColor),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── VISUAL STIM OVERLAY ──
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Container(
                  color: _flashColor.withValues(
                      alpha: _flashAnimation.value * 0.3),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMiniIdentity(Color roleColor) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.72),
            border: Border(
                bottom: BorderSide(color: roleColor.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              CBRoleAvatar(
                  assetPath: 'assets/roles/${widget.player.roleId}.png',
                  color: roleColor,
                  size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.player.name.toUpperCase(),
                      style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  Text(widget.player.roleName.toUpperCase(),
                      style: textTheme.labelSmall!
                          .copyWith(color: roleColor, fontSize: 9)),
                ],
              ),
              const Spacer(),
              CBBadge(text: "ALIVE", color: Theme.of(context).colorScheme.tertiary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicActionTile(StepSnapshot step, Color roleColor) {
    String title;
    IconData icon;

    if (step.isVote) {
      title = "CRITICAL VOTE";
      icon = Icons.how_to_vote_rounded;
    } else if (step.actionType == ScriptActionType.selectPlayer.name ||
        step.actionType == ScriptActionType.selectTwoPlayers.name) {
      title = "SELECT TARGET";
      icon = Icons.gps_fixed_rounded;
    } else if (step.actionType == ScriptActionType.binaryChoice.name) {
      title = "MAKE A CHOICE";
      icon = Icons.alt_route_rounded;
    } else {
      title = "OPERATIVE ACTION";
      icon = Icons.flash_on_rounded;
    }

    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return CBGlassTile(
          isPrismatic: true, // Use Shimmer/Biorefraction theme
          title: title,
          subtitle: step.instructionText.isNotEmpty
              ? step.instructionText
              : "INPUT REQUIRED",
          accentColor: roleColor,
          isCritical: step.isVote,
          icon: Icon(icon, color: scheme.onSurface, size: 20),
          onTap: () => _handleActionTap(step, roleColor),
          content: Column(
            children: [
              Text(
                "WAKE UP, ${widget.player.name.toUpperCase()}. THE CLUB IS WAITING.",
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                Icons.touch_app,
                color: scheme.onSurface.withValues(alpha: 0.24),
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleActionTap(StepSnapshot step, Color roleColor) {
    if (step.isVote ||
        step.actionType == ScriptActionType.selectPlayer.name ||
        step.actionType == ScriptActionType.selectTwoPlayers.name) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerSelectionScreen(
            players: widget.gameState.players.where((p) => p.isAlive).toList(),
            step: step,
            onPlayerSelected: (targetId) {
              if (step.isVote) {
                widget.bridge
                    .vote(voterId: widget.playerId, targetId: targetId);
              } else {
                widget.bridge.sendAction(stepId: step.id, targetId: targetId);
              }
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (step.actionType == ScriptActionType.binaryChoice.name) {
      showThemedBottomSheet<void>(
        context: context,
        accentColor: roleColor,
        child: Builder(
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  step.title.toUpperCase(),
                  style: textTheme.headlineSmall!.copyWith(
                    color: roleColor,
                    shadows: CBColors.textGlow(roleColor),
                  ),
                ),
                const SizedBox(height: 24),
                ...step.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CBPrimaryButton(
                      label: option.toUpperCase(),
                      onPressed: () {
                        widget.bridge
                            .sendAction(stepId: step.id, targetId: option);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildGhostLounge() {
    final aliveTargets =
        widget.gameState.players.where((p) => p.isAlive).toList();
    final currentBetTarget = widget.player.currentBetTargetId == null
        ? null
        : widget.gameState.players
            .where((p) => p.id == widget.player.currentBetTargetId)
            .map((p) => p.name)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);

    final roster = widget.gameState.players
        .map((p) => (
              name: p.name,
              role: p.roleName,
              color: CBColors.fromHex(p.roleColorHex),
              isAlive: p.isAlive,
            ))
        .toList();

    return CBPrismScaffold(
      title: "GHOST LOUNGE",
      drawer: const CustomDrawer(),
      body: CBGhostLoungeView(
        playerRoster: roster,
        lastWords: widget.player.deathDay != null
            ? "ELIMINATED ON DAY ${widget.player.deathDay}"
            : "SILENCED FROM BEYOND",
        currentBetTargetName: currentBetTarget,
        bettingHistory: widget.player.penalties
            .where((entry) => entry.contains('[DEAD POOL]'))
            .toList(),
        ghostMessages: widget.gameState.ghostChatMessages,
        onPlaceBet: aliveTargets.isEmpty
            ? null
            : () {
                showThemedBottomSheet<void>(
                  context: context,
                  accentColor: Theme.of(context).colorScheme.error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PLACE DEAD POOL BET',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ...aliveTargets.map(
                        (target) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CBPrimaryButton(
                            label: target.name.toUpperCase(),
                            onPressed: () {
                              widget.bridge.placeDeadPoolBet(
                                playerId: widget.playerId,
                                targetPlayerId: target.id,
                              );
                              Navigator.pop(context);
                              HapticService.selection();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        onSendGhostMessage: (text) {
          widget.bridge.sendGhostChat(
            playerId: widget.playerId,
            playerName: widget.player.name,
            message: text,
          );
          HapticService.selection();
        },
      ),
    );
  }
}

/// A "Hold to Reveal" role identity header for secure, dramatic role checking.
class _BiometricIdentityHeader extends StatefulWidget {
  final PlayerSnapshot player;
  final Color roleColor;
  final bool isMyTurn;

  const _BiometricIdentityHeader({
    required this.player,
    required this.roleColor,
    required this.isMyTurn,
  });

  @override
  State<_BiometricIdentityHeader> createState() =>
      _BiometricIdentityHeaderState();
}

class _BiometricIdentityHeaderState extends State<_BiometricIdentityHeader>
    with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isRevealed) {
      _revealController.forward();
      HapticService.selection();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_revealController.value < 1.0) {
      _revealController.reverse();
    } else {
      setState(() => _isRevealed = true);
      HapticService.heavy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
          border: Border(
            bottom: BorderSide(
              color: widget.roleColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CBRoleAvatar(
                  assetPath: _isRevealed
                      ? 'assets/roles/${widget.player.roleId}.png'
                      : null,
                  color: widget.roleColor,
                  size: 48,
                  pulsing: widget.isMyTurn,
                ),
                if (!_isRevealed)
                  AnimatedBuilder(
                    animation: _revealAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _revealAnimation.value,
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.roleColor),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.player.name.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isRevealed)
                    Text(
                      widget.player.roleName.toUpperCase(),
                      style: textTheme.labelSmall!.copyWith(
                        color: widget.roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    )
                  else
                    Text(
                      "HOLD TO SCAN BIOMETRICS",
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 8,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isMyTurn)
              CBBadge(text: "YOUR TURN", color: widget.roleColor)
            else
              CBBadge(text: "ALIVE", color: Theme.of(context).colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}
