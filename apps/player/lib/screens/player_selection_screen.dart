import 'package:cb_models/cb_models.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class PlayerSelectionScreen extends StatefulWidget {
  final List<PlayerSnapshot> players;
  final StepSnapshot step;
  final Function(String) onPlayerSelected;
  final List<String> disabledPlayerIds;
  final Map<String, int> voteTally;
  final Map<String, String> votesByVoter;
  final String? currentPlayerId;

  const PlayerSelectionScreen({
    super.key,
    required this.players,
    required this.step,
    required this.onPlayerSelected,
    this.disabledPlayerIds = const [],
    this.voteTally = const {},
    this.votesByVoter = const {},
    this.currentPlayerId,
  });

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final List<String> _selectedIds = [];

  bool get _isMultiSelect =>
      widget.step.actionType == ScriptActionType.selectTwoPlayers.name;

  void _onTap(String id) {
    if (widget.disabledPlayerIds.contains(id)) return;

    HapticService.selection();

    if (!_isMultiSelect) {
      widget.onPlayerSelected(id);
      return;
    }

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else if (_selectedIds.length == 2 &&
            widget.step.actionType == ScriptActionType.selectTwoPlayers.name) {
          // If already 2 selected, replace the older one with new one
          // For now, let's clear the selection if more than 2 are selected
          // Or, only allow if not already two selected.
          // Let's assume we can only select two total, so if user taps a third, it does nothing
        }
      }
    });
  }

  void _confirmSelection() {
    if (_selectedIds.length == 2) {
      HapticService.medium();
      widget.onPlayerSelected(_selectedIds.join(','));
    }
  }

  List<String> _voterNamesForTarget(String targetId) {
    final others = widget.votesByVoter.entries
        .where((entry) => entry.value == targetId)
        .where((entry) => entry.key != widget.currentPlayerId)
        .map((entry) => _playerNameById(entry.key))
        .toList();
    others.sort();
    final currentVotedHere = widget.currentPlayerId != null &&
        widget.votesByVoter[widget.currentPlayerId] == targetId;
    if (currentVotedHere) {
      return [...others, 'YOU'];
    }
    return others;
  }

  String _playerNameById(String id) {
    for (final player in widget.players) {
      if (player.id == id) {
        return player.name.toUpperCase();
      }
    }
    return id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentPlayerName = widget.currentPlayerId != null
        ? _playerNameById(widget.currentPlayerId!)
        : null;

    return CBPrismScaffold(
      title: widget.step.isVote ? 'CAST VOTE' : 'SELECT TARGETS',
      body: Column(
        children: [
          if (widget.step.isVote && currentPlayerName != null)
            CBFadeSlide(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x3, CBSpace.x6, 0),
                child: Row(
                  children: [
                    Text(
                      'VOTING AS ',
                      style: textTheme.labelSmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      currentPlayerName,
                      style: textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.secondary,
                        letterSpacing: 1.0,
                        shadows: CBColors.textGlow(scheme.secondary, intensity: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isMultiSelect)
            CBFadeSlide(
              delay: const Duration(milliseconds: 50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x4, CBSpace.x6, 0),
                child: CBGlassTile(
                  borderColor: scheme.tertiary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(CBSpace.x4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: scheme.tertiary, size: 20),
                      const SizedBox(width: CBSpace.x3),
                      Expanded(
                        child: Text(
                          'SELECT 2 OPERATIVES TO COMPARE (${_selectedIds.length}/2)'.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                final isSelected = _selectedIds.contains(player.id);
                final isDisabled =
                    widget.disabledPlayerIds.contains(player.id);
                final roleColor = CBColors.fromHex(player.roleColorHex);
                final voteCount = widget.voteTally[player.id] ?? 0;
                final voterNames = _voterNamesForTarget(player.id);

                return CBFadeSlide(
                  delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                  child: Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: CBSpace.x3),
                      child: CBGlassTile(
                        isPrismatic: isSelected && !isDisabled,
                        isSelected: isSelected && !isDisabled,
                        borderColor: isDisabled
                            ? scheme.onSurface.withValues(alpha: 0.2)
                            : isSelected
                                ? scheme.primary.withValues(alpha: 0.7)
                                : roleColor.withValues(alpha: 0.3),
                        onTap: isDisabled ? null : () => _onTap(player.id),
                        child: Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: 'assets/roles/${player.roleId}.png',
                              size: 48,
                              color: isDisabled
                                  ? scheme.onSurface.withValues(alpha: 0.2)
                                  : roleColor,
                              pulsing: isSelected && !isDisabled,
                            ),
                            const SizedBox(width: CBSpace.x4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name.toUpperCase(),
                                    style: textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: isDisabled
                                          ? scheme.onSurface.withValues(alpha: 0.4)
                                          : isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                      shadows: isSelected && !isDisabled ? CBColors.textGlow(scheme.primary, intensity: 0.3) : null,
                                    ),
                                  ),
                                  if (isDisabled) ...[
                                    const SizedBox(height: CBSpace.x1),
                                    Text(
                                      'TARGET PROTOCOL LOCKED',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: scheme.error,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ] else if (widget.step.isVote) ...[
                                    const SizedBox(height: CBSpace.x1),
                                    Text(
                                      'ACTIVE VOTES: $voteCount',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.6),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: CBSpace.x1),
                                    Text(
                                      voterNames.isEmpty
                                          ? 'NO OPERATIVES HAVE VOTED YET.'
                                          : 'VOTED BY: ${voterNames.join(', ')}',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.4),
                                        fontSize: 9,
                                        letterSpacing: 0.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else if (!widget.step.isVote) ...[
                                    const SizedBox(height: CBSpace.x1),
                                    Text(
                                      'OPERATIVE PROFILE',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: roleColor.withValues(alpha: 0.7),
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            if (isDisabled)
                              Icon(
                                Icons.lock_rounded,
                                color: scheme.onSurface.withValues(alpha: 0.3),
                                size: 24,
                              )
                            else if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                                shadows: CBColors.iconGlow(scheme.primary),
                                size: 24,
                              ) else if (widget.step.isVote) // For voting, show arrow for unselected but available
                                Icon(Icons.arrow_forward_ios_rounded, color: scheme.onSurface.withValues(alpha: 0.3), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: (widget.step.isVote || _isMultiSelect)
          ? _buildBottomBar(context)
          : null,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isMultiSelect) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x6),
          child: CBPrimaryButton(
            label: 'CONFIRM SELECTION',
            icon: Icons.check_circle_rounded,
            onPressed: _selectedIds.length == 2 ? _confirmSelection : null,
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CBSpace.x6),
        child: CBGhostButton(
          label: 'ABSTAIN / SKIP',
          icon: Icons.block_rounded,
          color: scheme.onSurface.withValues(alpha: 0.5),
          onPressed: () {
            HapticService.light();
            widget.onPlayerSelected('abstain');
          },
        ),
      ),
    );
  }
}
