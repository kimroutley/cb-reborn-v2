import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../sheets/single_player_role_sheet.dart';
import '../sheets/game_settings_sheet.dart';

class HostGameSetupScreen extends ConsumerStatefulWidget {
  const HostGameSetupScreen({super.key});

  @override
  ConsumerState<HostGameSetupScreen> createState() =>
      _HostGameSetupScreenState();
}

class _HostGameSetupScreenState extends ConsumerState<HostGameSetupScreen> {
  void _showSnack(String message, {bool isError = false}) {
    showThemedSnackBar(
      context,
      message.toUpperCase(),
      accentColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.tertiary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final players = gameState.players;
    final allAssigned = players.every((p) => p.role.id != 'unassigned');
    final assignedCount =
        players.where((p) => p.role.id != 'unassigned').length;
    final isManualStyle = gameState.gameStyle == GameStyle.manual;

    final humanPlayers = players.where((p) => !p.isBot).toList();
    final confirmedCount = session.roleConfirmedPlayerIds
        .where((id) => players.any((p) => p.id == id && !p.isBot))
        .length;
    final allRoleConfirmed =
        humanPlayers.isEmpty ||
        confirmedCount >= humanPlayers.length;
    final canStart = allAssigned &&
        (allRoleConfirmed || session.forceStartOverride);

    return CBPrismScaffold(
      title: 'GAME SETUP',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Configure Session',
          onPressed: () => showThemedBottomSheet(
            context: context,
            child: const GameSettingsSheet(),
          ),
        ),
      ],
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  CBFadeSlide(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CBGhostButton(
                        label: 'BACK TO LOBBY',
                        icon: Icons.arrow_back_rounded,
                        fullWidth: false,
                        onPressed: () {
                          HapticService.light();
                          nav.setDestination(HostDestination.lobby);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CBFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _GameStyleSection(
                      currentStyle: gameState.gameStyle,
                      onChanged: (style) {
                        HapticService.selection();
                        controller.setGameStyle(style);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  CBFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _RoleActionsBar(
                      isManualStyle: isManualStyle,
                      hasAssigned:
                          players.any((p) => p.role.id != 'unassigned'),
                      onAutoAssign: () {
                        HapticService.medium();
                        final ok = controller.autoAssignRoles();
                        if (!ok) {
                          _showSnack(
                            'NEED AT LEAST ${Game.minPlayers} PLAYERS',
                            isError: true,
                          );
                        } else {
                          _showSnack('ROLES ASSIGNED SUCCESSFULLY');
                        }
                      },
                      onClear: () {
                        HapticService.light();
                        controller.clearRoleAssignments();
                        _showSnack('ROLE ASSIGNMENTS CLEARED');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  const CBFeedSeparator(label: 'ASSIGNMENT PROGRESS'),
                  const SizedBox(height: 12),

                  CBFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: CBGlassTile(
                      isPrismatic: allAssigned,
                      borderColor: allAssigned
                          ? scheme.tertiary.withValues(alpha: 0.5)
                          : scheme.onSurfaceVariant.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (allAssigned ? scheme.tertiary : scheme.secondary).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              allAssigned
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 18,
                              color: allAssigned
                                  ? scheme.tertiary
                                  : scheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              allAssigned ? 'ALL ROLES SECURED' : 'PENDING ASSIGNMENTS',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Text(
                            '$assignedCount / ${players.length}',
                            style: textTheme.titleMedium?.copyWith(
                              color: allAssigned
                                  ? scheme.tertiary
                                  : scheme.secondary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'RobotoMono',
                              shadows: allAssigned ? CBColors.textGlow(scheme.tertiary, intensity: 0.3) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const CBFeedSeparator(label: 'PLAYER ROSTER'),
                  const SizedBox(height: 12),

                  if (players.isEmpty)
                    CBFadeSlide(
                      child: CBGlassTile(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'NO OPERATIVES IN LOBBY',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    CBFadeSlide(
                      delay: const Duration(milliseconds: 400),
                      child: CBPanel(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: players.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 64,
                            color: scheme.outlineVariant.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final player = players[index];
                            return _SetupPlayerTile(
                              player: player,
                              index: index,
                              onTap: () => showThemedBottomSheet<void>(
                                context: context,
                                accentColor: scheme.secondary,
                                child: SinglePlayerRoleSheet(
                                  playerId: player.id,
                                  playerName: player.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            _SetupLaunchBar(
              allAssigned: allAssigned,
              canStart: canStart,
              playerCount: players.length,
              humanCount: humanPlayers.length,
              confirmedCount: confirmedCount,
              forceStartOverride: session.forceStartOverride,
              onForceStartToggle: () {
                HapticService.selection();
                ref.read(sessionProvider.notifier).setForceStartOverride(
                    !session.forceStartOverride);
              },
              onStart: () {
                HapticFeedback.heavyImpact();
                final started = controller.startGame();
                if (started) {
                  nav.setDestination(HostDestination.game);
                } else {
                  _showSnack(
                    allAssigned
                        ? 'WAITING FOR BIOMETRIC CONFIRMATION'
                        : 'ALL ROLES MUST BE ASSIGNED BEFORE START',
                    isError: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameStyleSection extends StatelessWidget {
  final GameStyle currentStyle;
  final ValueChanged<GameStyle> onChanged;

  const _GameStyleSection({
    required this.currentStyle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'GAME STYLE',
            icon: Icons.style_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          ...GameStyle.values.map((style) {
            final isSelected = currentStyle == style;
            final styleColor = switch (style) {
              GameStyle.offensive => scheme.error,
              GameStyle.defensive => scheme.tertiary,
              GameStyle.reactive => scheme.secondary,
              GameStyle.manual => scheme.onSurface.withValues(alpha: 0.6),
              GameStyle.chaos => scheme.primary,
            };
            final styleIcon = switch (style) {
              GameStyle.offensive => Icons.local_fire_department_rounded,
              GameStyle.defensive => Icons.shield_rounded,
              GameStyle.reactive => Icons.psychology_rounded,
              GameStyle.manual => Icons.touch_app_rounded,
              GameStyle.chaos => Icons.casino_rounded,
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CBGlassTile(
                onTap: () => onChanged(style),
                isPrismatic: isSelected,
                isSelected: isSelected,
                borderColor: isSelected
                    ? styleColor
                    : styleColor.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: styleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(styleIcon, size: 20, color: styleColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.label.replaceAll('_', ' ').toUpperCase(),
                            style: textTheme.labelMedium?.copyWith(
                              color: isSelected ? styleColor : scheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            style.description.toUpperCase(),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          size: 20, color: styleColor),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RoleActionsBar extends StatelessWidget {
  final bool isManualStyle;
  final bool hasAssigned;
  final VoidCallback onAutoAssign;
  final VoidCallback onClear;

  const _RoleActionsBar({
    required this.isManualStyle,
    required this.hasAssigned,
    required this.onAutoAssign,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isManualStyle && !hasAssigned) {
      return CBGlassTile(
        borderColor: scheme.onSurface.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'MANUAL MODE: TAP OPERATIVES BELOW TO ASSIGN ROLES',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (!isManualStyle)
          Expanded(
            child: CBPrimaryButton(
              label: 'AUTO ASSIGN',
              icon: Icons.auto_fix_high_rounded,
              onPressed: onAutoAssign,
            ),
          ),
        if (!isManualStyle && hasAssigned) const SizedBox(width: 12),
        if (hasAssigned)
          Expanded(
            child: CBGhostButton(
              label: 'CLEAR ALL',
              icon: Icons.clear_all_rounded,
              color: scheme.error,
              onPressed: onClear,
            ),
          ),
      ],
    );
  }
}

class _SetupPlayerTile extends StatelessWidget {
  final Player player;
  final int index;
  final VoidCallback onTap;

  const _SetupPlayerTile({
    required this.player,
    required this.index,
    required this.onTap,
  });

  bool get _hasRole => player.role.id != 'unassigned';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleColor =
        _hasRole ? CBColors.fromHex(player.role.colorHex) : null;
    final accent =
        roleColor ?? (player.isBot ? scheme.tertiary : scheme.primary);

    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (_hasRole)
              CBRoleAvatar(
                assetPath: player.role.assetPath,
                color: roleColor!,
                size: 44,
                breathing: true,
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    player.isBot
                        ? Icons.smart_toy_rounded
                        : Icons.person_rounded,
                    size: 22,
                    color: accent,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontFamily: 'RobotoMono',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_hasRole)
                    CBMiniTag(
                      text: player.role.name.toUpperCase(),
                      color: roleColor!,
                    )
                  else
                    Text(
                      'UNASSIGNED',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              _hasRole
                  ? Icons.swap_horiz_rounded
                  : Icons.add_circle_outline_rounded,
              size: 20,
              color: _hasRole
                  ? roleColor!.withValues(alpha: 0.5)
                  : scheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupLaunchBar extends StatelessWidget {
  final bool allAssigned;
  final bool canStart;
  final int playerCount;
  final int humanCount;
  final int confirmedCount;
  final bool forceStartOverride;
  final VoidCallback? onForceStartToggle;
  final VoidCallback onStart;

  const _SetupLaunchBar({
    required this.allAssigned,
    required this.canStart,
    required this.playerCount,
    required this.humanCount,
    required this.confirmedCount,
    required this.forceStartOverride,
    this.onForceStartToggle,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final allRoleConfirmed = humanCount == 0 || confirmedCount >= humanCount;
    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (!allAssigned) {
      badgeText = 'ASSIGN ROLES';
      badgeColor = scheme.secondary;
      badgeIcon = Icons.warning_amber_rounded;
    } else if (allRoleConfirmed || forceStartOverride) {
      badgeText = '$playerCount READY';
      badgeColor = scheme.tertiary;
      badgeIcon = Icons.check_circle_rounded;
    } else {
      badgeText = '$confirmedCount/$humanCount CONFIRMED';
      badgeColor = scheme.primary;
      badgeIcon = Icons.how_to_reg_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: (canStart ? scheme.primary : badgeColor).withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allAssigned && !allRoleConfirmed && humanCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WAITING FOR BIOMETRIC CONFIRMATION...',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onForceStartToggle,
                      child: Text(
                        forceStartOverride ? 'CANCEL OVERRIDE' : 'MANUAL OVERRIDE',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 16, color: badgeColor),
                      const SizedBox(width: 8),
                      Text(
                        badgeText,
                        style: textTheme.labelSmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CBPrimaryButton(
                    label: 'START SESSION',
                    icon: Icons.play_arrow_rounded,
                    onPressed: canStart ? onStart : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
