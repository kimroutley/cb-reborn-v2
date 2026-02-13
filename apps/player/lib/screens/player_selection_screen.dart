import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class PlayerSelectionScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: step.isVote ? 'VOTE CASTING' : 'SELECT TARGET',
      body: ListView.builder(
        padding: CBInsets.screen,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          // Use CBGlassTile for consistent look
          return CBFadeSlide(
            delay: Duration(milliseconds: 30 * index),
            child: CBGlassTile(
              isPrismatic: true, // Use Shimmer/Biorefraction theme
              title: player.name,
              subtitle: player.roleName,
              accentColor: scheme.primary,
              icon: CBRoleAvatar(
                assetPath: 'assets/roles/${player.roleId}.png',
                size: 40,
                color: scheme.primary,
              ),
              onTap: () => onPlayerSelected(player.id),
              content: const SizedBox.shrink(),
            ),
          );
        },
      ),
      bottomNavigationBar: step.isVote ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: CBInsets.panel,
      child: CBPrimaryButton(
        label: 'ABSTAIN / SKIP',
        onPressed: () => onPlayerSelected('abstain'),
        icon: Icons.block_flipped,
      ),
    );
  }
}
