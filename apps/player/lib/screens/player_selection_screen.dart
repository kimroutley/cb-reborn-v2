import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';

class PlayerSelectionScreen extends StatefulWidget {
  final List<PlayerSnapshot> players;
  final StepSnapshot step;
  final Function(String) onPlayerSelected;

  const PlayerSelectionScreen({
    super.key,
    required this.players,
    required this.step,
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          (widget.step.isVote ? 'VOTE CASTING' : 'SELECT TARGET').toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_isMultiSelect)
                Padding(
                  padding: CBInsets.panel,
                  child: CBMessageBubble(
                    sender: 'SYSTEM',
                    message:
                        'SELECT 2 PLAYERS TO COMPARE (${_selectedIds.length}/2)',
                    isSystemMessage: true,
                    color: scheme.tertiary,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: CBInsets.screen,
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    final player = widget.players[index];
                    final isSelected = _selectedIds.contains(player.id);

                    return CBFadeSlide(
                      delay: Duration(milliseconds: 30 * index),
                      child: CBGlassTile(
                        isPrismatic: true,
                        borderColor:
                            isSelected ? scheme.tertiary : scheme.primary,
                        onTap: () => _onTap(player.id),
                        child: Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: 'assets/roles/${player.roleId}.png',
                              size: 40,
                              color:
                                  isSelected ? scheme.tertiary : scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(player.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    player.roleName,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: scheme.tertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.step.isVote || _isMultiSelect)
          ? _buildBottomBar(context)
          : null,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (_isMultiSelect) {
      return Padding(
        padding: CBInsets.panel,
        child: CBPrimaryButton(
          label: 'CONFIRM MIXOLOGY',
          onPressed: _selectedIds.length == 2 ? _confirmSelection : null,
          icon: Icons.check_circle_outline,
        ),
      );
    }

    return Padding(
      padding: CBInsets.panel,
      child: CBPrimaryButton(
        label: 'ABSTAIN / SKIP',
        onPressed: () => widget.onPlayerSelected('abstain'),
        icon: Icons.block_flipped,
      ),
    );
  }
}
