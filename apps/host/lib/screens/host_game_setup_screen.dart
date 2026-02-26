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
      message,
      accentColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.tertiary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final players = gameState.players;
    final allAssigned = players.every((p) => p.role.id != 'unassigned');
    final assignedCount =
        players.where((p) => p.role.id != 'unassigned').length;
    final isManualStyle = gameState.gameStyle == GameStyle.manual;

    return CBPrismScaffold(
      title: 'GAME SETUP',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Game config',
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                children: [
                  // -- Back to Lobby --
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CBGhostButton(
                      label: 'BACK TO LOBBY',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        HapticService.light();
                        nav.setDestination(HostDestination.lobby);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Game Style Selector --
                  _GameStyleSection(
                    currentStyle: gameState.gameStyle,
                    onChanged: (style) {
                      HapticService.selection();
                      controller.setGameStyle(style);
                    },
                  ),
                  const SizedBox(height: 20),

                  // -- Role Actions --
                  _RoleActionsBar(
                    isManualStyle: isManualStyle,
                    hasAssigned:
                        players.any((p) => p.role.id != 'unassigned'),
                    onAutoAssign: () {
                      HapticService.medium();
                      final ok = controller.autoAssignRoles();
                      if (!ok) {
                        _showSnack(
                          'Need at least ${Game.minPlayers} players.',
                          isError: true,
                        );
                      } else {
                        _showSnack('Roles assigned!');
                      }
                    },
                    onClear: () {
                      HapticService.light();
                      controller.clearRoleAssignments();
                      _showSnack('Roles cleared.');
                    },
                  ),
                  const SizedBox(height: 20),

                  // -- Assignment Progress --
                  CBGlassTile(
                    isPrismatic: allAssigned,
                    borderColor: allAssigned
                        ? scheme.tertiary.withValues(alpha: 0.5)
                        : scheme.onSurfaceVariant.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          allAssigned
                              ? Icons.check_circle_rounded
                              : Icons.assignment_rounded,
                          size: 18,
                          color: allAssigned
                              ? scheme.tertiary
                              : scheme.secondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ROLE ASSIGNMENTS',
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                scheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$assignedCount / ${players.length}',
                          style: textTheme.titleMedium?.copyWith(
                            color: allAssigned
                                ? scheme.tertiary
                                : scheme.secondary,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // -- Player Roster --
                  if (players.isEmpty)
                    CBGlassTile(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'NO PLAYERS IN LOBBY',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else
                    CBGlassTile(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          itemCount: players.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: scheme.outlineVariant
                                .withValues(alpha: 0.1),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // -- Launch Bar --
            _SetupLaunchBar(
              allAssigned: allAssigned,
              playerCount: players.length,
              onStart: () {
                HapticFeedback.heavyImpact();
                final started = controller.startGame();
                if (started) {
                  nav.setDestination(HostDestination.game);
                } else {
                  _showSnack(
                    'Cannot start — assign all roles first.',
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

// ─── GAME STYLE SECTION ──────────────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'GAME STYLE',
            icon: Icons.style_rounded,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
        ...GameStyle.values.map((style) {
          final isSelected = currentStyle == style;
          final styleColor = switch (style) {
            GameStyle.offensive => scheme.error,
            GameStyle.defensive => scheme.tertiary,
            GameStyle.reactive => scheme.secondary,
            GameStyle.manual => scheme.onSurface.withValues(alpha: 0.7),
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
            padding: const EdgeInsets.only(bottom: 6),
            child: CBGlassTile(
              onTap: () => onChanged(style),
              isPrismatic: isSelected,
              isSelected: isSelected,
              borderColor: isSelected
                  ? styleColor
                  : styleColor.withValues(alpha: 0.15),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(styleIcon, size: 20, color: styleColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.label.replaceAll('_', ' '),
                          style: textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? styleColor
                                : scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          style.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 10,
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

// ─── ROLE ACTIONS BAR ────────────────────────────────────────

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
        if (!isManualStyle && hasAssigned) const SizedBox(width: 10),
        if (hasAssigned)
          CBGhostButton(
            label: 'CLEAR',
            icon: Icons.clear_all_rounded,
            color: scheme.error,
            onPressed: onClear,
          ),
        if (isManualStyle && !hasAssigned)
          Expanded(
            child: CBGlassTile(
              borderColor: scheme.onSurfaceVariant.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'TAP PLAYERS BELOW TO ASSIGN ROLES',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── SETUP PLAYER TILE ──────────────────────────────────────

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

    return CBFadeSlide(
      delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
      child: InkWell(
        onTap: () {
          HapticService.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (_hasRole)
                CBRoleAvatar(
                  assetPath: player.role.assetPath,
                  color: roleColor!,
                  size: 40,
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      player.isBot
                          ? Icons.smart_toy_rounded
                          : Icons.person_rounded,
                      size: 20,
                      color: accent,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (_hasRole)
                      CBMiniTag(
                        text: player.role.name.toUpperCase(),
                        color: roleColor!,
                      )
                    else
                      CBMiniTag(
                        text: 'UNASSIGNED',
                        color: scheme.onSurface.withValues(alpha: 0.3),
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
                    ? roleColor!.withValues(alpha: 0.6)
                    : scheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SETUP LAUNCH BAR ────────────────────────────────────────

class _SetupLaunchBar extends StatelessWidget {
  final bool allAssigned;
  final int playerCount;
  final VoidCallback onStart;

  const _SetupLaunchBar({
    required this.allAssigned,
    required this.playerCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (allAssigned) {
      badgeText = '$playerCount READY';
      badgeColor = scheme.tertiary;
      badgeIcon = Icons.check_circle_rounded;
    } else {
      badgeText = 'ASSIGN ROLES';
      badgeColor = scheme.secondary;
      badgeIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: CBGlassTile(
        isPrismatic: allAssigned,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: allAssigned
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.onSurfaceVariant.withValues(alpha: 0.3),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 16, color: badgeColor),
                    const SizedBox(width: 6),
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
                  label: 'START GAME',
                  icon: Icons.nightlife_rounded,
                  onPressed: allAssigned ? onStart : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
