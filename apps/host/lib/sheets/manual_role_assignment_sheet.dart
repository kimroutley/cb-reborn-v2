import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'single_player_role_sheet.dart';

class ManualRoleAssignmentSheet extends ConsumerWidget {
  const ManualRoleAssignmentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final assignableRoles =
        roleCatalog.where((role) => role.id != 'unassigned').toList();

    // Sort roles: Staff -> Party -> Neutral -> Unknown
    assignableRoles.sort((a, b) {
      if (a.alliance == b.alliance) return a.name.compareTo(b.name);
      if (a.alliance == Team.clubStaff) return -1;
      if (b.alliance == Team.clubStaff) return 1;
      if (a.alliance == Team.partyAnimals) return -1;
      if (b.alliance == Team.partyAnimals) return 1;
      return 0;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CBBottomSheetHandle(),
          const SizedBox(height: 16),
          CBSectionHeader(
            title: 'ROLE MATRIX',
            icon: Icons.assignment_ind_rounded,
            color: scheme.secondary,
          ),
          const SizedBox(height: 16),

          _TeamBalanceBar(players: currentState.players),

          const SizedBox(height: 20),

          // Role Source (Draggable)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: assignableRoles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final role = assignableRoles[index];
                final roleColor = CBColors.fromHex(role.colorHex);

                return Draggable<String>(
                  data: role.id,
                  feedback: Material(
                    type: MaterialType.transparency,
                    child: _RoleChip(
                        role: role, color: roleColor, isDragging: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _RoleChip(role: role, color: roleColor),
                  ),
                  child: _RoleChip(role: role, color: roleColor),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Player Targets
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: currentState.players.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = currentState.players[index];
                return _PlayerTargetTile(
                  player: player,
                  controller: controller,
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          CBPrimaryButton(
            label: 'FINALIZE ROSTER',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _TeamBalanceBar extends StatelessWidget {
  final List<Player> players;
  const _TeamBalanceBar({required this.players});

  @override
  Widget build(BuildContext context) {
    final staff =
        players.where((p) => p.role.alliance == Team.clubStaff).length;
    final party =
        players.where((p) => p.role.alliance == Team.partyAnimals).length;
    final wild = players
        .where((p) =>
            p.role.alliance == Team.neutral ||
            (p.role.alliance == Team.unknown && p.role.id != 'unassigned'))
        .length;
    final unassigned = players.where((p) => p.role.id == 'unassigned').length;

    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
            child: _StatPill(
                label: 'STAFF', count: staff, color: scheme.secondary)),
        const SizedBox(width: 8),
        Expanded(
            child:
                _StatPill(label: 'PARTY', count: party, color: scheme.primary)),
        const SizedBox(width: 8),
        Expanded(
            child:
                _StatPill(label: 'WILD', count: wild, color: scheme.tertiary)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatPill(
                label: 'EMPTY',
                count: unassigned,
                color: scheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'RobotoMono',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final Role role;
  final Color color;
  final bool isDragging;

  const _RoleChip({
    required this.role,
    required this.color,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDragging ? CBColors.voidBlack : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging ? color : color.withValues(alpha: 0.3),
          width: isDragging ? 2 : 1,
        ),
        boxShadow: isDragging
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_rounded, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            role.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTargetTile extends StatelessWidget {
  final Player player;
  final Game controller;

  const _PlayerTargetTile({required this.player, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasRole = player.role.id != 'unassigned';
    final roleColor = hasRole
        ? CBColors.fromHex(player.role.colorHex)
        : scheme.outlineVariant;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != player.role.id,
      onAcceptWithDetails: (details) {
        HapticService.medium();
        controller.assignRole(player.id, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () {
            // Functional improvement: Tap to select role
            showThemedBottomSheet<void>(
              context: context,
              accentColor: scheme.secondary,
              child: SinglePlayerRoleSheet(
                playerId: player.id,
                playerName: player.name,
              ),
            );
          },
          child: CBGlassTile(
            isPrismatic: isHovering || hasRole,
            borderColor: isHovering
                ? scheme.secondary
                : (hasRole ? roleColor : scheme.outline.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Avatar
                CBRoleAvatar(
                  assetPath: hasRole ? player.role.assetPath : null,
                  color: roleColor,
                  size: 40,
                  pulsing: isHovering,
                ),
                const SizedBox(width: 16),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name.toUpperCase(),
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      hasRole
                          ? CBMiniTag(
                              text: player.role.name.toUpperCase(),
                              color: roleColor)
                          : Text(
                              'TAP OR DRAG ROLE HERE',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.3),
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ],
                  ),
                ),

                // Clear button
                if (hasRole)
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18,
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: () =>
                        controller.assignRole(player.id, 'unassigned'),
                  )
                else
                  Icon(Icons.add_circle_outline_rounded,
                      size: 20, color: scheme.onSurface.withValues(alpha: 0.2)),
              ],
            ),
          ),
        );
      },
    );
  }
}
