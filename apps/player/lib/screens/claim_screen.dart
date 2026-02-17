import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';

class ClaimScreen extends ConsumerStatefulWidget {
  const ClaimScreen({super.key});

  @override
  ConsumerState<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends ConsumerState<ClaimScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;

    final availablePlayers = gameState.players
        .where((p) => p.isAlive && !gameState.claimedPlayerIds.contains(p.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('IDENTITY SELECTION'),
      ),
      body: CBNeonBackground(
        child: Column(
          children: [
            const SizedBox(height: CBSpace.x4),
            CBSectionHeader(
              title: 'AVAILABLE IDENTITIES',
              color: scheme.primary,
            ),
            const SizedBox(height: CBSpace.x3),
            Expanded(
              child: availablePlayers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(CBSpace.x6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CBBreathingLoader(size: 40),
                            const SizedBox(height: CBSpace.x3),
                            Text(
                              gameState.players.isEmpty
                                  ? 'LOADING IDENTITIES...'
                                  : 'WAITING FOR AN OPEN IDENTITY...',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: scheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: CBInsets.screenH,
                      itemCount: availablePlayers.length,
                      itemBuilder: (context, index) {
                        final player = availablePlayers[index];
                        final isSelected = player.id == _selectedId;

                        return CBFadeSlide(
                          delay: Duration(milliseconds: 30 * index),
                          child: CBGlassTile(
                            onTap: () {
                              setState(() => _selectedId = player.id);
                            },
                            borderColor:
                                isSelected ? scheme.primary : scheme.outlineVariant,
                            child: ListTile(
                              title: Text(player.name),
                            ),
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
                        activeBridge.actions.claimPlayer(_selectedId!); // Trigger the claim
                        // Navigator.pop is not needed because GameRouter listens to state
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
