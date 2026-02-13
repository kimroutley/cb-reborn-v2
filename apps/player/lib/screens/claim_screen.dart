import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud_player_bridge.dart';
import '../player_bridge.dart';
import '../player_bridge_actions.dart';

class ClaimScreen extends ConsumerStatefulWidget {
  final bool isCloud;

  const ClaimScreen({
    super.key,
    required this.isCloud,
  });

  @override
  ConsumerState<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends ConsumerState<ClaimScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gameState = widget.isCloud
        ? ref.watch(cloudPlayerBridgeProvider)
        : ref.watch(playerBridgeProvider);

    final availablePlayers = gameState.players
        .where((p) => p.isAlive && !gameState.claimedPlayerIds.contains(p.id))
        .toList();

    return CBPrismScaffold(
      title: 'IDENTITY SELECTION',
      body: Column(
        children: [
          const SizedBox(height: CBSpace.x4),
          CBSectionHeader(
            title: 'AVAILABLE IDENTITIES',
            color: scheme.primary,
          ),
          const SizedBox(height: CBSpace.x3),
          Expanded(
            child: ListView.builder(
              padding: CBInsets.screenH,
              itemCount: availablePlayers.length,
              itemBuilder: (context, index) {
                final player = availablePlayers[index];
                final isSelected = player.id == _selectedId;

                return CBFadeSlide(
                  delay: Duration(milliseconds: 30 * index),
                  child: CBGlassTile(
                    title: player.name,
                    accentColor: isSelected ? scheme.primary : scheme.outlineVariant,
                    isResolved: isSelected,
                    onTap: () {
                      setState(() => _selectedId = player.id);
                    },
                    content: const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: CBInsets.screen,
            child: CBPrimaryButton(
              label: 'CLAIM IDENTITY',
              onPressed: _selectedId == null
                  ? null
                  : () {
                      final PlayerBridgeActions bridge = widget.isCloud
                          ? ref.read(cloudPlayerBridgeProvider.notifier)
                          : ref.read(playerBridgeProvider.notifier);
                      bridge.claimPlayer(_selectedId!); // Trigger the claim
                      // Navigator.pop is not needed because GameRouter listens to state
                    },
            ),
          ),
        ],
      ),
    );
  }
}
