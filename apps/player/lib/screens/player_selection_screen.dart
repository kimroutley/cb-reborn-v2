import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';

class PlayerSelectionScreen extends StatefulWidget {
  final List<PlayerSnapshot> players;
  final StepSnapshot step;
  final List<String> disabledIds;
  final Function(String) onPlayerSelected;

  const PlayerSelectionScreen({
    super.key,
    required this.players,
    required this.step,
    this.disabledIds = const [],
    required this.onPlayerSelected,
  });

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final List<String> _selectedIds = [];

  bool get _isMultiSelect =>
      widget.step.actionType == ScriptActionType.selectTwoPlayers.name;

  void _onTap(String id) {
    if (widget.disabledIds.contains(id)) {
      HapticService.error();
      return;
    }

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
        }
      }
    });
  }

  void _confirmSelection() {
    if (_selectedIds.length == 2) {
      widget.onPlayerSelected(_selectedIds.join(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: widget.step.isVote ? 'VOTE CASTING' : 'SELECT TARGET',
      body: Column(
        children: [
          if (_isMultiSelect)
            Padding(
              padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x4, CBSpace.x4, 0),
              child: CBMessageBubble(
                sender: 'SYSTEM',
                message:
                    'SELECT 2 PLAYERS TO COMPARE (${_selectedIds.length}/2)',
                style: CBMessageStyle.system,
                color: scheme.tertiary,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x6),
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                final isSelected = _selectedIds.contains(player.id);
                final isDisabled = widget.disabledIds.contains(player.id);
                final roleColor = CBColors.fromHex(player.roleColorHex);

                return CBFadeSlide(
                  delay: Duration(milliseconds: 30 * index),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: CBSpace.x3),
                    child: Opacity(
                      opacity: isDisabled ? 0.4 : 1.0,
                      child: CBGlassTile(
                        isPrismatic: isSelected,
                        isSelected: isSelected,
                        borderColor: isSelected
                            ? scheme.primary
                            : isDisabled
                                ? scheme.onSurface.withValues(alpha: 0.1)
                                : roleColor.withValues(alpha: 0.3),
                        onTap: isDisabled ? null : () => _onTap(player.id),
                        child: Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: 'assets/roles/${player.roleId}.png',
                              size: 40,
                              color: isDisabled ? scheme.onSurface : roleColor,
                              pulsing: isSelected,
                            ),
                            const SizedBox(width: CBSpace.x4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        player.name.toUpperCase(),
                                        style: textTheme.labelLarge!.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                          color: isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                        ),
                                      ),
                                      if (isDisabled) ...[
                                        const SizedBox(width: CBSpace.x2),
                                        Icon(Icons.lock_outline_rounded,
                                            size: 14,
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.5)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDisabled
                                        ? 'VOTING RESTRICTED'
                                        : player.roleName.toUpperCase(),
                                    style: textTheme.labelSmall!.copyWith(
                                      color: isDisabled
                                          ? scheme.error.withValues(alpha: 0.7)
                                          : roleColor.withValues(alpha: 0.7),
                                      fontSize: 9,
                                      fontWeight: isDisabled ? FontWeight.w900 : null,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                                shadows: CBColors.iconGlow(scheme.primary),
                              ),
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
            label: 'CONFIRM TARGETS',
            onPressed: _selectedIds.length == 2 ? _confirmSelection : null,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: CBInsets.panel,
        child: CBPrimaryButton(
          label: 'ABSTAIN / SKIP',
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          foregroundColor: scheme.onSurfaceVariant,
          onPressed: () => widget.onPlayerSelected('abstain'),
          icon: Icons.block_flipped,
        ),
      ),
    );
  }
}
