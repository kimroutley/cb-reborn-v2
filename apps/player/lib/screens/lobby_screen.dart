import 'package:cb_player/services/web_push_service.dart';
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

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  static const int _minimumPlayersHintThreshold = 4;
  final TextEditingController _chatController = TextEditingController();
  String? _lastRevealedRoleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        ref.read(webPushServiceProvider.notifier).checkPermissionStatus();
        ref.read(webPushServiceProvider.notifier).initPwaInstallPrompt();
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
    HapticService.medium();

    final player = ref.read(activeBridgeProvider).state.myPlayerSnapshot;
    if (player == null) {
      ref.read(activeBridgeProvider).actions.sendBulletin(
            title: 'LOUNGE',
            floatContent: text,
            roleId: null,
          );
    } else {
      ref.read(activeBridgeProvider).actions.sendBulletin(
            title: player.roleName,
            floatContent: text,
            roleId: player.roleId,
          );
    }

    _chatController.clear();
    FocusScope.of(context).unfocus();
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
              letterSpacing: 1.5,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          _buildGuideRow(
            context,
            Icons.chat_bubble_outline_rounded,
            'STAY INFORMED',
            'Watch the feed for game events, narrative clues, and voting results.',
          ),
          const SizedBox(height: CBSpace.x4),
          _buildGuideRow(
            context,
            Icons.fingerprint_rounded,
            'YOUR IDENTITY',
            'When the game starts, hold your identity card to reveal your secret role.',
          ),
          const SizedBox(height: CBSpace.x4),
          _buildGuideRow(
            context,
            Icons.menu_rounded,
            'THE BLACKBOOK',
            'Check the side menu for role guides and game rules at any time.',
          ),
          const SizedBox(height: CBSpace.x8),
          CBPrimaryButton(
            label: 'ACKNOWLEDGED',
            backgroundColor: scheme.secondary.withValues(alpha: 0.2),
            foregroundColor: scheme.secondary,
            onPressed: () {
              HapticService.light();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(
      BuildContext context, IconData icon, String title, String description) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.secondary, size: 24),
        const SizedBox(width: CBSpace.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: textTheme.labelMedium!.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: CBSpace.x1),
              Text(
                description.toUpperCase(),
                style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildLobbyHelperCopy({
    required String phase,
    required bool hasRole,
    required bool isRoleConfirmed,
  }) {
    if (phase == 'setup' && !hasRole) {
      return "ROLES ARE BEING ASSIGNED. STAY HERE; YOUR ROLE WILL APPEAR BELOW WHEN THE HOST ASSIGNS IT.";
    }
    if (hasRole && !isRoleConfirmed) {
      return "YOUR CHARACTER IS BELOW. READ IT AND TAP ACKNOWLEDGE IDENTITY. OTHERS ARE WAITING ONCE EVERYONE HAS ACKNOWLEDGED.";
    }
    if (isRoleConfirmed) {
      return "IDENTITY ACKNOWLEDGED. WAIT FOR THE HOST TO START THE GAME.";
    }
    return "YOU'RE IN THE ROOM. CHAT WITH OTHERS AND WAIT FOR THE HOST. YOUR ROLE WILL ARRIVE SHORTLY — BE READY TO READ AND ACCEPT.";
  }

  Widget _buildPwaInstallTile(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x6),
      child: CBGlassTile(
        borderColor: scheme.secondary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(CBSpace.x4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x2),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CBRadius.xs),
              ),
              child: Icon(Icons.download_rounded,
                  color: scheme.secondary, size: 24),
            ),
            const SizedBox(width: CBSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSTALL TERMINAL',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ADD TO HOME SCREEN FOR FULLSCREEN EXPERIENCE.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CBSpace.x2),
            CBPrimaryButton(
              label: 'INSTALL',
              onPressed: () {
                HapticService.selection();
                ref.read(webPushServiceProvider.notifier).promptPwaInstall();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPermissionTile(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x6),
      child: CBGlassTile(
        borderColor: scheme.tertiary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(CBSpace.x4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x2),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CBRadius.xs),
              ),
              child: Icon(Icons.notifications_active_rounded,
                  color: scheme.tertiary, size: 24),
            ),
            const SizedBox(width: CBSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENABLE UPLINK',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GET NOTIFIED WHEN IT’S YOUR TURN OR WHEN PHASE CHANGES.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CBSpace.x2),
            CBPrimaryButton(
              label: 'ALLOW',
              onPressed: () {
                HapticService.selection();
                ref.read(webPushServiceProvider.notifier).requestPermission();
              },
            ),
          ],
        ),
      ),
    );
  }

  ({String title, String detail, _LobbyStatusTone tone}) _buildLobbyStatus({
    required int playerCount,
    required bool awaitingStartConfirmation,
    required String phase,
  }) {
    if (awaitingStartConfirmation) {
      return (
        title: 'READY TO JOIN',
        detail: 'HOST STARTED THE GAME. CONFIRM YOUR JOIN NOW.',
        tone: _LobbyStatusTone.readyToJoin,
      );
    }

    if (playerCount < _minimumPlayersHintThreshold) {
      return (
        title: 'WAITING FOR MORE PLAYERS',
        detail:
            'NEED AT LEAST $_minimumPlayersHintThreshold PLAYERS FOR A FULL SESSION.',
        tone: _LobbyStatusTone.waitingPlayers,
      );
    }

    if (phase == 'setup') {
      return (
        title: 'WAITING FOR HOST TO ASSIGN YOU A ROLE',
        detail: 'ROLE CARDS ARE BEING ASSIGNED. STAY READY.',
        tone: _LobbyStatusTone.setup,
      );
    }

    return (
      title: 'WAITING FOR HOST TO START',
      detail: 'REVIEW THE GAME BIBLE IN THE SIDE DRAWER WHILE YOU WAIT.',
      tone: _LobbyStatusTone.waitingHost,
    );
  }

  ({int totalWithRole, int confirmedWithRole, List<String> pendingNames})
      _tallyRoleAcknowledgements(
    List<PlayerSnapshot> players,
    List<String> roleConfirmedPlayerIds,
  ) {
    final humanPlayers = players.where((p) => !p.isBot).toList();
    final withRole = humanPlayers
        .where((p) => p.roleId.isNotEmpty && p.roleId != 'unassigned')
        .toList();
    final totalWithRole = withRole.length;
    final confirmedWithRole =
        withRole.where((p) => roleConfirmedPlayerIds.contains(p.id)).length;
    final pendingNames = withRole
        .where((p) => !roleConfirmedPlayerIds.contains(p.id))
        .map((p) => p.name.isNotEmpty ? p.name : 'UNKNOWN')
        .toList();
    return (
      totalWithRole: totalWithRole,
      confirmedWithRole: confirmedWithRole,
      pendingNames: pendingNames
    );
  }

  Widget _buildPlayerRoster(
    BuildContext context,
    List<PlayerSnapshot> players,
    List<String> roleConfirmedPlayerIds,
    ColorScheme scheme,
    TextTheme textTheme,
    String phase,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();

    final humanPlayers = players.where((p) => !p.isBot).toList();
    final totalHumans = humanPlayers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x1),
          child: Text(
            'IN THIS GAME ($totalHumans)',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: CBSpace.x3),
        Wrap(
          spacing: CBSpace.x2,
          runSpacing: CBSpace.x2,
          children: players.map((p) {
            final isMe =
                p.id == ref.read(activeBridgeProvider).state.myPlayerId;
            final isConfirmed = roleConfirmedPlayerIds.contains(p.id);
            final hasRole = p.roleId.isNotEmpty && p.roleId != 'unassigned';

            return CBFilterChip(
              label: p.name.isEmpty ? 'UNKNOWN' : p.name.toUpperCase(),
              selected: isMe,
              onSelected: () {
                HapticService.selection();
              },
              icon: hasRole && isConfirmed
                  ? Icons.check_circle_rounded
                  : (p.isBot ? Icons.smart_toy_rounded : null),
              color: isMe
                  ? scheme.primary
                  : (isConfirmed ? scheme.tertiary : null),
            );
          }).toList(),
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
    final pushState = ref.watch(webPushServiceProvider);



    final myPlayer = gameState.myPlayerSnapshot;
    final hasRole =
        myPlayer?.roleId != null && myPlayer?.roleId != 'unassigned';
    final isRoleConfirmed =
        gameState.roleConfirmedPlayerIds.contains(myPlayer?.id ?? '');

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

    final isMobile = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 2,
      child: CBPrismScaffold(
        title: 'THE LOUNGE',
        drawer: const CustomDrawer(),
        appBarBottom: isMobile
            ? TabBar(
                indicatorColor: scheme.primary,
                labelColor: scheme.primary,
                tabs: const [
                  Tab(text: 'STATUS', icon: Icon(Icons.hub_rounded, size: 18)),
                  Tab(text: 'LOUNGE', icon: Icon(Icons.chat_bubble_outline_rounded, size: 18)),
                ],
              )
            : null,
        body: isMobile
            ? TabBarView(
                children: [
                  _buildStatusTab(
                    context: context,
                    scheme: scheme,
                    textTheme: textTheme,
                    gameState: gameState,
                    onboarding: onboarding,
                    pushState: pushState,
                    status: status,
                    statusIcon: statusIcon,
                    statusColor: statusColor,
                    hasRole: hasRole,
                    isRoleConfirmed: isRoleConfirmed,
                    myPlayer: myPlayer,
                    displayName: displayName,
                  ),
                  _buildLoungeTab(
                    context: context,
                    scheme: scheme,
                    gameState: gameState,
                    onboarding: onboarding,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildStatusTab(
                      context: context,
                      scheme: scheme,
                      textTheme: textTheme,
                      gameState: gameState,
                      onboarding: onboarding,
                      pushState: pushState,
                      status: status,
                      statusIcon: statusIcon,
                      statusColor: statusColor,
                      hasRole: hasRole,
                      isRoleConfirmed: isRoleConfirmed,
                      myPlayer: myPlayer,
                      displayName: displayName,
                    ),
                  ),
                  Expanded(
                    child: _buildLoungeTab(
                      context: context,
                      scheme: scheme,
                      gameState: gameState,
                      onboarding: onboarding,
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: onboarding.awaitingStartConfirmation
            ? Padding(
                padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x2, CBSpace.x6, CBSpace.x6),
                child: SafeArea(
                  top: false,
                  child: CBPrimaryButton(
                    label: 'CONFIRM & JOIN',
                    icon: Icons.fingerprint_rounded,
                    onPressed: () {
                      HapticService.heavy();
                      ref
                          .read(playerOnboardingProvider.notifier)
                          .setAwaitingStartConfirmation(true);
                    },
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// STATUS tab — connection status, identity, roster, and role reveal.
  Widget _buildStatusTab({
    required BuildContext context,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required PlayerGameState gameState,
    required dynamic onboarding,
    required dynamic pushState,
    required ({String title, String detail, _LobbyStatusTone tone}) status,
    required IconData statusIcon,
    required Color statusColor,
    required bool hasRole,
    required bool isRoleConfirmed,
    required PlayerSnapshot? myPlayer,
    required String displayName,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        const NotificationsPromptBanner(),

        if (pushState.isSupported &&
            pushState.permissionStatus ==
                WebNotificationPermission.defaultStatus)
          _buildNotificationPermissionTile(
              context, scheme, textTheme, ref),

        if (pushState.canInstallPwa)
          _buildPwaInstallTile(context, scheme, textTheme, ref),

        CBGlassTile(
          isPrismatic: status.tone == _LobbyStatusTone.readyToJoin,
          borderColor: statusColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(CBSpace.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: CBSpace.x2),
                  Expanded(
                    child: Text(
                      'PROTOCOL: ${status.title}',
                      style: textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: CBColors.textGlow(statusColor, intensity: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CBSpace.x3),
              Text(
                status.detail,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        if (!onboarding.awaitingStartConfirmation &&
            gameState.players.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final tally = _tallyRoleAcknowledgements(
                gameState.players,
                gameState.roleConfirmedPlayerIds,
              );
              final showTally = gameState.phase == 'setup' ||
                  tally.totalWithRole > 0;

              if (!showTally) return const SizedBox.shrink();

              if (tally.totalWithRole == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: CBSpace.x3),
                  child: CBGlassTile(
                    padding: const EdgeInsets.symmetric(
                        horizontal: CBSpace.x4, vertical: CBSpace.x3),
                    borderColor: scheme.primary.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Icon(Icons.pending_rounded,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: CBSpace.x2),
                        Text(
                          'NO ROLES ASSIGNED YET.',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final allDone =
                  tally.confirmedWithRole >= tally.totalWithRole;
              return Padding(
                padding: const EdgeInsets.only(top: CBSpace.x3),
                child: CBGlassTile(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CBSpace.x4, vertical: CBSpace.x3),
                  borderColor:
                      (allDone ? scheme.tertiary : scheme.primary)
                          .withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            allDone
                                ? Icons.check_circle_rounded
                                : Icons.checklist_rounded,
                            size: 16,
                            color: allDone
                                ? scheme.tertiary
                                : scheme.primary,
                          ),
                          const SizedBox(width: CBSpace.x2),
                          Text(
                            'ACKNOWLEDGED: ${tally.confirmedWithRole}/${tally.totalWithRole}',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface
                                  .withValues(alpha: 0.95),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      if (tally.pendingNames.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'WAITING: ${tally.pendingNames.join(", ")}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: CBSpace.x6),

        if (!onboarding.awaitingStartConfirmation)
          CBGlassTile(
            padding: const EdgeInsets.symmetric(
                horizontal: CBSpace.x4, vertical: CBSpace.x3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: scheme.primary, size: 20),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    _buildLobbyHelperCopy(
                      phase: gameState.phase,
                      hasRole: hasRole,
                      isRoleConfirmed: isRoleConfirmed,
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: CBSpace.x6),

        if (hasRole &&
            !isRoleConfirmed &&
            !onboarding.awaitingStartConfirmation)
          FullRoleRevealContent(
            player: myPlayer!,
            onConfirm: () {
              HapticService.heavy();
              ref
                  .read(activeBridgeProvider)
                  .actions
                  .confirmRole(playerId: myPlayer.id);
              ref
                  .read(playerOnboardingProvider.notifier)
                  .setAwaitingStartConfirmation(true);
            },
          )
        else if (!onboarding.awaitingStartConfirmation) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT IDENTITY',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticService.light();
                  Scaffold.of(context).openDrawer();
                },
                child: Padding(
                  padding: const EdgeInsets.all(CBSpace.x1),
                  child: Text(
                    'EDIT PROFILE',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          CBGlassTile(
            padding: const EdgeInsets.all(CBSpace.x4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(Icons.person_rounded,
                      color: scheme.primary, size: 22),
                ),
                const SizedBox(width: CBSpace.x4),
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
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'SESSION ACCESS GRANTED',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: CBSpace.x6),

        if (!onboarding.awaitingStartConfirmation)
          _buildPlayerRoster(
              context,
              gameState.players,
              gameState.roleConfirmedPlayerIds,
              scheme,
              textTheme,
              gameState.phase),
      ],
    );
  }

  /// LOUNGE tab — chat feed with input bar.
  Widget _buildLoungeTab({
    required BuildContext context,
    required ColorScheme scheme,
    required PlayerGameState gameState,
    required dynamic onboarding,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, 120),
            physics: const BouncingScrollPhysics(),
            children: [
              ..._buildLoungeFeed(gameState, scheme),
            ],
          ),
        ),
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
      ],
    );
  }
}

enum _LobbyStatusTone {
  waitingPlayers,
  waitingHost,
  setup,
  readyToJoin,
}

List<Widget> _buildLoungeFeed(PlayerGameState gameState, ColorScheme scheme) {
  final entries = gameState.bulletinBoard
      .where((e) =>
          e.targetRoleId == null ||
          e.targetRoleId == gameState.myPlayerSnapshot?.roleId)
      .toList();
  if (entries.isEmpty) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: CBSpace.x12),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.speaker_notes_off_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.1), size: 32),
              const SizedBox(height: CBSpace.x3),
              Text(
                'ENCRYPTED CHANNEL OPEN',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: scheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      )
    ];
  }

  final myPlayer = gameState.myPlayerSnapshot;
  final isClubManager = myPlayer?.roleId == RoleIds.clubManager;

  return [
    const Padding(
      padding: EdgeInsets.only(bottom: CBSpace.x3),
      child: CBFeedSeparator(label: 'LOUNGE FEED'),
    ),
    BulletinFeed(
      entries: entries,
      itemBuilder: (context, i, entry, groupPosition) {
        try {
          final role = roleCatalogMap[entry.roleId] ?? roleCatalog.first;
          final color = entry.roleId != null
              ? CBColors.fromHex(role.colorHex)
              : (entry.type == 'system' ? scheme.secondary : scheme.primary);
          String senderName = role.id == 'unassigned' ? entry.title : role.name;
          if (isClubManager &&
              entry.roleId != null &&
              entry.roleId != myPlayer?.roleId) {
            try {
              final senderPlayer =
                  gameState.players.firstWhere((p) => p.roleId == entry.roleId);
              senderName = '${role.name} (${senderPlayer.name})';
            } catch (_) {}
          }
          return CBMessageBubble(
            sender: senderName.toUpperCase(),
            message: entry.content,
            style: entry.type == 'system'
                ? CBMessageStyle.system
                : CBMessageStyle.narrative,
            color: color,
            avatarAsset: entry.roleId != null ? role.assetPath : null,
            groupPosition: groupPosition,
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      },
    ),
  ];
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CBColors.transparent,
            scheme.scrim.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CBSpace.x3),
        child: SafeArea(
          top: false,
          child: CBGlassTile(
            borderColor: roleColor.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'SEND TRANSMISSION...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: roleColor, size: 20),
                  onPressed: onSend,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
