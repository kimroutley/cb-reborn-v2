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

    setState(() {
      HapticService.selection();
      if (!_isMultiSelect) {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.clear();
          _selectedIds.add(id);
        }
      } else {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          if (_selectedIds.length < 2) {
            _selectedIds.add(id);
          }
        }
      }
    });
  }

  void _confirmSelection() {
    final isValid = _isMultiSelect ? _selectedIds.length == 2 : _selectedIds.length == 1;
    if (isValid) {
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
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isValidSelection =
        _isMultiSelect ? _selectedIds.length == 2 : _selectedIds.length == 1;

    String selectedText = 'AWAITING SELECTION...';
    if (_selectedIds.isNotEmpty) {
      final names = _selectedIds
          .map((id) => widget.players.firstWhere((p) => p.id == id).name)
          .join(', ');
      selectedText = 'TARGET: ${names.toUpperCase()}';
    }

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.only(
        left: CBSpace.x2,
        right: CBSpace.x2,
        top: CBSpace.x2,
        bottom: MediaQuery.of(context).padding.bottom + CBSpace.x2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Abstain / Skip button (left)
          if (widget.step.isVote)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
              child: IconButton(
                icon: Icon(Icons.block_flipped,
                    color: scheme.onSurfaceVariant, size: 28),
                tooltip: 'Abstain / Skip',
                onPressed: () => widget.onPlayerSelected('abstain'),
                splashRadius: 24,
              ),
            ),

          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.only(left: CBSpace.x4, right: CBSpace.x2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        selectedText,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isValidSelection
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: isValidSelection
                          ? Container(
                              key: const ValueKey('send_btn'),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.5),
                                ),
                                boxShadow: CBColors.circleGlow(scheme.primary,
                                    intensity: 0.3),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send_rounded,
                                    color: scheme.primary, size: 20),
                                onPressed: () {
                                  HapticService.medium();
                                  _confirmSelection();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            )
                          : Container(
                              key: const ValueKey('disabled_btn'),
                              child: IconButton(
                                icon: Icon(Icons.send_rounded,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                    size: 20),
                                onPressed: null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
