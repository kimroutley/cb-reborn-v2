import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_bridge.dart';
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
        : availablePlayers.cast<PlayerSnapshot?>().firstWhere(
            (p) => p?.id == _selectedId,
            orElse: () => null,
          );

    return CBPrismScaffold(
      title: 'SECURITY GATE',
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 24),
          CBFadeSlide(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'IDENTITY SELECTION',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium!.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SECURE AN ASSIGNED IDENTITY TO PROCEED INTO THE CLUB.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          selectedPlayer == null
                              ? 'AVAILABLE PROFILES: ${availablePlayers.length}'
                              : 'IDENTIFIED: ${selectedPlayer.name.toUpperCase()}',
                          key: ValueKey('${availablePlayers.length}|$_selectedId'),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: availablePlayers.isEmpty
                ? Center(
                    child: CBFadeSlide(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CBBreathingSpinner(size: 48),
                          const SizedBox(height: 24),
                          Text(
                            'FETCHING IDENTITIES...',
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge!.copyWith(
                              color: scheme.primary,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wait for the host to initialize profiles.',
                            style: textTheme.bodySmall!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      final isSelected = player.id == _selectedId;

                      return CBFadeSlide(
                        delay: Duration(milliseconds: 40 * index.clamp(0, 10)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CBGlassTile(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _selectedId = player.id);
                            },
                            isPrismatic: isSelected,
                            isSelected: isSelected,
                            borderColor: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.2),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isSelected ? scheme.primary : scheme.onSurface).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 24,
                                    color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    player.name.toUpperCase(),
                                    style: textTheme.titleMedium!.copyWith(
                                      color: isSelected ? scheme.primary : scheme.onSurface,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontFamily: 'RobotoMono',
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.verified_user_rounded,
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
              child: CBFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: CBPrimaryButton(
                  label: _selectedId == null
                      ? 'SELECT PROFILE'
                      : 'ESTABLISH LINK',
                  icon: Icons.fingerprint_rounded,
                  onPressed: _selectedId == null
                      ? null
                      : () {
                          HapticService.heavy();
                          activeBridge.actions.claimPlayer(_selectedId!);
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
