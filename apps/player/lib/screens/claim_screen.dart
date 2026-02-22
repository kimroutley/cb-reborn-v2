import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../widgets/custom_drawer.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final activeBridge = ref.watch(activeBridgeProvider);
    final gameState = activeBridge.state;

    final availablePlayers = gameState.players
        .where((p) => p.isAlive && !gameState.claimedPlayerIds.contains(p.id))
        .toList();
    final selectedPlayer = _selectedId == null
        ? null
        : () {
            for (final player in availablePlayers) {
              if (player.id == _selectedId) {
                return player;
              }
            }
            return null;
          }();

    return CBPrismScaffold(
      title: 'ENTRY TERMINAL',
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SELECT IDENTITY',
              style: textTheme.headlineMedium!.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'CHOOSE YOUR ASSIGNED IDENTITY FROM THE LIST BELOW.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.32),
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Text(
                        selectedPlayer == null
                            ? 'AVAILABLE IDENTITIES: ${availablePlayers.length}'
                            : 'SELECTED: ${selectedPlayer.name.toUpperCase()}',
                        key:
                            ValueKey('${availablePlayers.length}|$_selectedId'),
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: availablePlayers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CBBreathingLoader(size: 48),
                          const SizedBox(height: 24),
                          Text(
                            gameState.players.isEmpty
                                ? 'LOADING IDENTITIES...'
                                : 'WAITING FOR AN OPEN IDENTITY...',
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge!.copyWith(
                              color: scheme.primary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (gameState.players.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Please wait for the Host to add you.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium!.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      final isSelected = player.id == _selectedId;

                      return CBFadeSlide(
                        delay: Duration(milliseconds: 30 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CBGlassTile(
                            onTap: () {
                              setState(() => _selectedId = player.id);
                              HapticService.selection();
                            },
                            isPrismatic: isSelected,
                            isSelected: isSelected,
                            borderColor: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.3),
                            child: Row(
                              children: [
                                CBRoleAvatar(
                                  size: 40,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    player.name.toUpperCase(),
                                    style: textTheme.titleMedium!.copyWith(
                                      color: isSelected
                                          ? scheme.primary
                                          : scheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.normal,
                                      letterSpacing: 1.0,
                                    ),
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
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CBPrimaryButton(
                label: _selectedId == null
                    ? 'SELECT AN IDENTITY'
                    : 'CONFIRM IDENTITY',
                icon: Icons.fingerprint_rounded,
                onPressed: _selectedId == null
                    ? null
                    : () {
                        HapticService.medium();
                        activeBridge.actions.claimPlayer(_selectedId!);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
