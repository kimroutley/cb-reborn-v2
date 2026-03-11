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
          const SizedBox(height: CBSpace.x6),

          // ── STEP INDICATOR ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6),
            child: Row(
              children: [
                _buildStepDot(scheme.tertiary, true, '1', 'CONNECTED'),
                Expanded(child: Container(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.2))),
                _buildStepDot(scheme.primary, true, '2', 'CLAIM ID'),
                Expanded(child: Container(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.2))),
                _buildStepDot(scheme.onSurfaceVariant.withValues(alpha: 0.35), false, '3', 'PLAY'),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x6),

          // ── HERO SECTION ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.2),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 48,
                    color: scheme.primary,
                    shadows: CBColors.iconGlow(scheme.primary),
                  ),
                ),
                const SizedBox(height: CBSpace.x5),
                Text(
                  'BIOMETRIC BINDING',
                  style: textTheme.headlineMedium!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
                  ),
                ),
                const SizedBox(height: CBSpace.x2),
                Text(
                  'SELECT AN OPEN IDENTITY TO BIND YOUR DEVICE TO THIS SESSION.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x6),

          // ── STATUS BAR ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4),
            child: CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.32),
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: CBSpace.x3),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: CBMotion.transition,
                      switchInCurve: CBMotion.emphasizedCurve,
                      switchOutCurve: CBMotion.emphasizedCurve,
                      child: Text(
                        selectedPlayer == null
                            ? 'AVAILABLE IDENTITIES: ${availablePlayers.length}'
                            : 'SELECTED: ${selectedPlayer.name.toUpperCase()}',
                        key:
                            ValueKey('${availablePlayers.length}|$_selectedId'),
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          Expanded(
            child: availablePlayers.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(CBSpace.x8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CBBreathingLoader(size: 48),
                          const SizedBox(height: CBSpace.x6),
                          Text(
                            gameState.players.isEmpty
                                ? 'LOADING IDENTITIES...'
                                : 'WAITING FOR OPEN IDENTITY...',
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge!.copyWith(
                              color: scheme.primary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w900,
                              shadows: CBColors.textGlow(scheme.primary),
                            ),
                          ),
                          if (gameState.players.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: CBSpace.x3),
                              child: Text(
                                'PLEASE WAIT FOR THE HOST TO ADD YOU.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall!.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4),
                    physics: const BouncingScrollPhysics(),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      final isSelected = player.id == _selectedId;

                      return CBFadeSlide(
                        delay: Duration(milliseconds: 30 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: CBSpace.x3),
                          child: CBGlassTile(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _selectedId = player.id);
                            },
                            isPrismatic: isSelected,
                            isSelected: isSelected,
                            borderColor: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.3),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(CBSpace.x2),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? scheme.primary.withValues(alpha: 0.1)
                                          : scheme.onSurface.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? scheme.primary.withValues(alpha: 0.5)
                                            : scheme.outlineVariant.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: isSelected
                                          ? scheme.primary
                                          : scheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(width: CBSpace.x4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player.name.toUpperCase(),
                                          style: textTheme.titleMedium!.copyWith(
                                            color: isSelected
                                                ? scheme.primary
                                                : scheme.onSurface,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            fontFamily: 'RobotoMono',
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'TARGET ACQUIRED',
                                            style: textTheme.labelSmall?.copyWith(
                                              fontSize: 8,
                                              color: scheme.primary.withValues(alpha: 0.7),
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.fingerprint_rounded,
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
          Container(
            padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x4, CBSpace.x6, CBSpace.x8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CBColors.transparent,
                  scheme.scrim.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: CBPrimaryButton(
                label: _selectedId == null
                    ? 'SELECT AN IDENTITY'
                    : 'CONFIRM IDENTITY',
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
        ],
      ),
    );
  }

  Widget _buildStepDot(Color color, bool isActive, String number, String label) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(color: color, width: isActive ? 2 : 1),
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)]
                : null,
          ),
          alignment: Alignment.center,
          child: isActive && number == '1'
              ? Icon(Icons.check_rounded, size: 14, color: color)
              : Text(
                  number,
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
        ),
        const SizedBox(height: CBSpace.x1),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 8,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
