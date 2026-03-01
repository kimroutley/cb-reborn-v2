import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cb_models/cb_models.dart';
import '../active_bridge.dart';
import '../player_bridge.dart';
import '../player_onboarding_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/full_role_reveal_content.dart';
import '../widgets/notifications_prompt_banner.dart';
import '../widgets/player_profile_panel_content.dart';
import 'player_home_shell.dart';
import 'role_reveal_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  static const int _minimumPlayersHintThreshold = 4;
  final TextEditingController _chatController = TextEditingController();
  String? _lastRevealedRoleId;
  PlayerSnapshot? _selectedPlayerForPanel;
  bool _isPlayerPanelOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final seenGuide = prefs.getBool('player_guide_seen') ?? false;
        if (!seenGuide && mounted) {
          await _showPlayerGuideDialog(context);
          await prefs.setBool('player_guide_seen', true);
        }
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final bridgeState = ref.read(activeBridgeProvider).state;
    final player = bridgeState.myPlayerSnapshot;
    final myId = bridgeState.myPlayerId;
    final isConfirmed =
        myId != null && bridgeState.roleConfirmedPlayerIds.contains(myId);

    if (player == null) {
      ref.read(activeBridgeProvider).actions.sendBulletin(
            title: 'LOUNGE',
            floatContent: text,
            roleId: null,
          );
    } else if (isConfirmed && player.roleId != 'unassigned') {
      ref.read(activeBridgeProvider).actions.sendBulletin(
            title: player.roleName,
            floatContent: text,
            roleId: player.roleId,
          );
    } else {
      ref.read(activeBridgeProvider).actions.sendBulletin(
            title: player.name,
            floatContent: text,
            roleId: null,
          );
    }

    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showRoleReveal(PlayerSnapshot player) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bridge = ref.read(activeBridgeProvider).actions;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RoleRevealScreen(
          player: player,
          onConfirm: () {
            bridge.confirmRole(playerId: player.id);
            ref.read(confirmGameStartProvider.notifier).trigger();
          },
        ),
      );
    });
  }

  Future<void> _showPlayerGuideDialog(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showThemedDialog(
      context: context,
      accentColor: scheme.secondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WELCOME, PATRON',
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 32),
          _buildGuideRow(
            context,
            Icons.chat_bubble_outline_rounded,
            'STAY INFORMED',
            'Watch the feed for game events, narrative clues, and voting results.',
          ),
          const SizedBox(height: 20),
          _buildGuideRow(
            context,
            Icons.fingerprint_rounded,
            'YOUR IDENTITY',
            'When the game starts, hold your identity card to reveal your secret role.',
          ),
          const SizedBox(height: 20),
          _buildGuideRow(
            context,
            Icons.menu_rounded,
            'THE BLACKBOOK',
            'Check the side menu for role guides and game rules at any time.',
          ),
          const SizedBox(height: 40),
          CBPrimaryButton(
            label: 'ACKNOWLEDGED',
            backgroundColor: scheme.secondary.withValues(alpha: 0.2),
            foregroundColor: scheme.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(
      BuildContext context, IconData icon, String title, String description) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: scheme.secondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Phase-aware helper text so players know what to expect.
  String _buildLobbyHelperCopy({
    required String phase,
    required bool hasRole,
    required bool isRoleConfirmed,
  }) {
    if (isRoleConfirmed) {
      return 'Identity acknowledged. Wait for the host to start the game.';
    }
    if (hasRole && phase != 'lobby') {
      return 'Your character is below. Read it and tap ACKNOWLEDGE IDENTITY. '
          'Others are waiting once everyone has acknowledged.';
    }
    if (phase != 'lobby' && phase.isNotEmpty) {
      return 'Roles are being assigned. Stay here; your role will appear below '
          'when the host assigns it.';
    }
    return 'You\'re in the room. Chat with others and wait for the host. '
        'Your role will arrive shortly — be ready to read and accept.';
  }

  /// Players with a role but not yet in roleConfirmedPlayerIds.
  ({int total, int confirmed, List<String> pendingNames}) _roleAcknowledgementTally(
      PlayerGameState gameState) {
    final withRole = gameState.players
        .where((p) => p.roleId.isNotEmpty && p.roleId != 'unassigned')
        .toList();
    final total = withRole.length;
    final confirmed = withRole
        .where((p) => gameState.roleConfirmedPlayerIds.contains(p.id))
        .length;
    final pendingNames = withRole
        .where((p) => !gameState.roleConfirmedPlayerIds.contains(p.id))
        .map((p) => p.name)
        .toList();
    return (total: total, confirmed: confirmed, pendingNames: pendingNames);
  }

  ({String title, String detail, _LobbyStatusTone tone}) _buildLobbyStatus({
    required int playerCount,
    required bool awaitingStartConfirmation,
    required String phase,
  }) {
    if (awaitingStartConfirmation) {
      return (
        title: 'READY TO JOIN',
        detail: 'Host started the game. Confirm your join now.',
        tone: _LobbyStatusTone.readyToJoin,
      );
    }

    if (playerCount < _minimumPlayersHintThreshold) {
      return (
        title: 'WAITING FOR MORE PLAYERS',
        detail:
            'Need at least $_minimumPlayersHintThreshold players for a full session.',
        tone: _LobbyStatusTone.waitingPlayers,
      );
    }

    if (phase == 'setup') {
      return (
        title: 'ASSIGNING ROLES',
        detail: 'The host is assigning roles. Prepare for entry.',
        tone: _LobbyStatusTone.setup,
      );
    }

    return (
      title: 'LOBBY OPEN',
      detail: 'Review the Game Bible in the side drawer while you wait.',
      tone: _LobbyStatusTone.waitingHost,
    );
  }

  Widget _buildInThisGameRow(
    BuildContext context,
    List<PlayerSnapshot> players,
    List<String> roleConfirmedPlayerIds,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'IN THIS GAME',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: players.map((p) {
              final isMe = ref.read(activeBridgeProvider).state.myPlayerId == p.id;
              final hasRole =
                  p.roleId.isNotEmpty && p.roleId != 'unassigned';
              final isConfirmed = roleConfirmedPlayerIds.contains(p.id);
              final roleColor = hasRole
                  ? (roleCatalogMap[p.roleId] != null
                      ? CBColors.fromHex(
                          roleCatalogMap[p.roleId]!.colorHex)
                      : scheme.primary)
                  : scheme.primary;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CBFilterChip(
                  label: p.name,
                  selected: isMe,
                  onSelected: () {
                    HapticService.selection();
                    setState(() {
                      _selectedPlayerForPanel = p;
                      _isPlayerPanelOpen = true;
                    });
                  },
                  color: roleColor,
                  dense: true,
                  icon: hasRole && isConfirmed
                      ? Icons.check_circle_rounded
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(activeBridgeProvider).state;
    final authState = ref.watch(authProvider);
    final onboarding = ref.watch(playerOnboardingProvider);

    final myPlayer = gameState.myPlayerSnapshot;
    final myId = gameState.myPlayerId;
    final hasRole = myPlayer != null && myPlayer.roleId != 'unassigned';
    final isRoleConfirmed =
        myId != null && gameState.roleConfirmedPlayerIds.contains(myId);
    final isPastLobby = gameState.phase != 'lobby';

    if (isPastLobby &&
        hasRole &&
        !isRoleConfirmed &&
        _lastRevealedRoleId != myPlayer.roleId) {
      _lastRevealedRoleId = myPlayer.roleId;
      _showRoleReveal(myPlayer);
    }
    if (!hasRole) {
      _lastRevealedRoleId = null;
    }

    Color? roleColor;
    if (hasRole) {
      final hexStr = myPlayer.roleColorHex.replaceAll('#', '');
      roleColor = Color(int.parse('ff$hexStr', radix: 16));
    }

    final preferredName = gameState.myPlayerSnapshot?.name.trim();
    final profileName = authState.user?.displayName?.trim();
    final displayName = (preferredName != null && preferredName.isNotEmpty)
        ? preferredName.toUpperCase()
        : (profileName != null && profileName.isNotEmpty
            ? profileName.toUpperCase()
            : 'UNKNOWN PATRON');

    final status = _buildLobbyStatus(
      playerCount: gameState.players.length,
      awaitingStartConfirmation: onboarding.awaitingStartConfirmation,
      phase: gameState.phase,
    );

    final (statusIcon, statusColor) = switch (status.tone) {
      _LobbyStatusTone.readyToJoin => (Icons.bolt_rounded, scheme.tertiary),
      _LobbyStatusTone.waitingPlayers => (
          Icons.groups_3_rounded,
          scheme.secondary
        ),
      _LobbyStatusTone.setup => (Icons.badge_rounded, scheme.primary),
      _LobbyStatusTone.waitingHost => (
          Icons.hourglass_top_rounded,
          scheme.onSurfaceVariant
        ),
    };

    return CBPrismScaffold(
      title: 'THE LOUNGE',
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                const NotificationsPromptBanner(),
                const SizedBox(height: 12),

                // ── STATUS CARD ──
                CBFadeSlide(
                  child: CBGlassTile(
                    isPrismatic: status.tone == _LobbyStatusTone.readyToJoin,
                    borderColor: statusColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(statusIcon, color: statusColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.title,
                                style: textTheme.labelLarge?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          status.detail,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── ACKNOWLEDGEMENT TALLY (prominent when roles are assigned) ──
                if (!onboarding.awaitingStartConfirmation)
                  Builder(
                    builder: (context) {
                      final tally = _roleAcknowledgementTally(gameState);
                      if (tally.total == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CBGlassTile(
                          borderColor: (tally.confirmed >= tally.total
                                  ? scheme.tertiary
                                  : scheme.primary)
                              .withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    tally.confirmed >= tally.total
                                        ? Icons.check_circle_rounded
                                        : Icons.pending_rounded,
                                    size: 16,
                                    color: tally.confirmed >= tally.total
                                        ? scheme.tertiary
                                        : scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ACKNOWLEDGED: ${tally.confirmed}/${tally.total}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              if (tally.pendingNames.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Waiting: ${tally.pendingNames.join(', ')}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // ── HELPER: what to expect ──
                if (!onboarding.awaitingStartConfirmation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CBGlassTile(
                      borderColor: scheme.primary.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _buildLobbyHelperCopy(
                                phase: gameState.phase,
                                hasRole: hasRole,
                                isRoleConfirmed: isRoleConfirmed,
                              ),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.85),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── FULL CHARACTER CARD (when role assigned, not yet confirmed) ──
                if (!onboarding.awaitingStartConfirmation &&
                    hasRole &&
                    myPlayer != null &&
                    !isRoleConfirmed) ...[
                  const SizedBox(height: 8),
                  CBGlassTile(
                    borderColor: (roleColor ?? scheme.primary)
                        .withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(20),
                    child: FullRoleRevealContent(
                      player: myPlayer,
                      onConfirm: () {
                        ref.read(activeBridgeProvider).actions.confirmRole(
                            playerId: myPlayer.id);
                        ref.read(confirmGameStartProvider.notifier).trigger();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── COMPACT IDENTITY (when no role yet or already confirmed) ──
                if (!onboarding.awaitingStartConfirmation &&
                    !(hasRole && !isRoleConfirmed)) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRoleConfirmed ? 'ROLE IDENTITY' : 'CURRENT IDENTITY',
                        style: textTheme.labelSmall?.copyWith(
                          color: isRoleConfirmed
                              ? (roleColor ?? scheme.primary)
                              : scheme.primary,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'EDIT PROFILE',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CBGlassTile(
                    isPrismatic: isRoleConfirmed,
                    borderColor: isRoleConfirmed && roleColor != null
                        ? roleColor!.withValues(alpha: 0.4)
                        : null,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (isRoleConfirmed && roleColor != null && myPlayer != null)
                          CBRoleAvatar(
                            assetPath: 'assets/roles/${myPlayer.roleId}.png',
                            color: roleColor!,
                            size: 48,
                            breathing: true,
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(Icons.person_rounded,
                                color: scheme.primary, size: 24),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontFamily: 'RobotoMono',
                                  color: isRoleConfirmed && roleColor != null
                                      ? roleColor
                                      : scheme.onSurface,
                                  shadows: isRoleConfirmed && roleColor != null
                                      ? CBColors.textGlow(roleColor!,
                                          intensity: 0.3)
                                      : null,
                                ),
                              ),
                              if (isRoleConfirmed && myPlayer != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: CBMiniTag(
                                    text: myPlayer.roleName.toUpperCase(),
                                    color: roleColor ?? scheme.primary,
                                  ),
                                )
                              else
                                Text(
                                  'SESSION ACCESS GRANTED',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.4),
                                    fontSize: 9,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── THE LOUNGE (group chat; continues into game) ──
                _buildInThisGameRow(
                  context,
                  gameState.players,
                  gameState.roleConfirmedPlayerIds,
                  scheme,
                  textTheme,
                ),
                const SizedBox(height: 24),
                const CBFeedSeparator(label: 'THE LOUNGE'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Chat and intel here. This channel continues after the game starts.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...buildBulletinList(
                    gameState, gameState.myPlayerSnapshot, scheme,
                    includeSeparator: false),
                const SizedBox(height: 32),
              ],
            ),
          ),

          CBSlidingPanel(
            isOpen: _isPlayerPanelOpen,
            onClose: () => setState(() {
              _isPlayerPanelOpen = false;
              _selectedPlayerForPanel = null;
            }),
            title: _selectedPlayerForPanel?.name.toUpperCase() ?? 'PROFILE',
            width: 380,
            accentColor: _selectedPlayerForPanel != null &&
                    _selectedPlayerForPanel!.roleId.isNotEmpty &&
                    _selectedPlayerForPanel!.roleId != 'unassigned'
                ? (roleCatalogMap[_selectedPlayerForPanel!.roleId] != null
                    ? CBColors.fromHex(
                        roleCatalogMap[_selectedPlayerForPanel!.roleId]!.colorHex)
                    : null)
                : null,
            child: _selectedPlayerForPanel != null
                ? PlayerProfilePanelContent(player: _selectedPlayerForPanel!)
                : const SizedBox(),
          ),

          // ── CHAT INPUT ──
          if (!onboarding.awaitingStartConfirmation)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ChatInputBar(
                controller: _chatController,
                onSend: _sendMessage,
                roleColor: scheme.primary,
              ),
            ),

          // ── ACTION BUTTON ──
          if (onboarding.awaitingStartConfirmation)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: CBPrimaryButton(
                label: 'CONFIRM & JOIN',
                icon: Icons.fingerprint_rounded,
                onPressed: () {
                  HapticService.heavy();
                  ref.read(confirmGameStartProvider.notifier).trigger();
                },
              ),
            ),
        ],
      ),
    );
  }
}

enum _LobbyStatusTone {
  waitingPlayers,
  waitingHost,
  setup,
  readyToJoin,
}

List<Widget> buildBulletinList(
    PlayerGameState gameState, PlayerSnapshot? myPlayer, ColorScheme scheme,
    {bool includeSeparator = true}) {
  var entries =
      PlayerGameState.sanitizePublicBulletinEntries(gameState.bulletinBoard);
  entries = entries
      .where((e) =>
          e.targetRoleId == null || e.targetRoleId == myPlayer?.roleId)
      .toList();
  if (entries.isEmpty) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.speaker_notes_off_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.1), size: 32),
              const SizedBox(height: 16),
              Text(
                'CHANNEL SECURE. NO ACTIVE INTEL.',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      )
    ];
  }

  final widgets = <Widget>[];
  if (includeSeparator) {
    widgets.add(const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: CBFeedSeparator(label: 'GROUP CHAT'),
    ));
  }

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final prevEntry = i > 0 ? entries[i - 1] : null;
    final nextEntry = i < entries.length - 1 ? entries[i + 1] : null;

    final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
    final color = entry.roleId != null
        ? CBColors.fromHex(role.colorHex)
        : (entry.type == 'system' ? scheme.secondary : scheme.primary);

    String senderName = entry.title;
    if (entry.roleId != null) {
      try {
        final senderPlayer =
            gameState.players.firstWhere((p) => p.roleId == entry.roleId);
        senderName = senderPlayer.name;
      } catch (_) {
        senderName = role.id == 'unassigned' ? entry.title : role.name;
      }
    }

    final isPrevSameSender =
        prevEntry != null && prevEntry.roleId == entry.roleId;
    final isNextSameSender =
        nextEntry != null && nextEntry.roleId == entry.roleId;

    CBMessageGroupPosition groupPos = CBMessageGroupPosition.single;
    if (isPrevSameSender && isNextSameSender) {
      groupPos = CBMessageGroupPosition.middle;
    } else if (isPrevSameSender && !isNextSameSender) {
      groupPos = CBMessageGroupPosition.bottom;
    } else if (!isPrevSameSender && isNextSameSender) {
      groupPos = CBMessageGroupPosition.top;
    }

    widgets.add(CBMessageBubble(
      sender: senderName,
      message: entry.content,
      style: entry.type == 'system'
          ? CBMessageStyle.system
          : CBMessageStyle.narrative,
      color: color,
      avatarAsset: entry.roleId != null ? role.assetPath : null,
      groupPosition: groupPos,
    ));
  }
  return widgets;
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color roleColor;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            scheme.scrim.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: CBGlassTile(
          borderColor: roleColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Send message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Send message',
                icon: Icon(Icons.send_rounded, color: roleColor, size: 20),
                onPressed: onSend,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
