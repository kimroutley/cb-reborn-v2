import 'package:cb_theme/cb_theme.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../active_bridge.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';

class GameInProgressBanner extends ConsumerStatefulWidget {
  const GameInProgressBanner({super.key});

  @override
  ConsumerState<GameInProgressBanner> createState() =>
      _GameInProgressBannerState();
}

class _GameInProgressBannerState extends ConsumerState<GameInProgressBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  static const Set<String> _activePhases = {
    'lobby',
    'setup',
    'night',
    'day',
    'resolution',
    'endGame',
  };

  static const Set<PlayerDestination> _hiddenDestinations = {
    PlayerDestination.game,
    PlayerDestination.lobby,
    PlayerDestination.transition,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(activeBridgeProvider);
    final state = bridge.state;
    final destination = ref.watch(playerNavigationProvider);
    final phase = state.phase;
    final connected = state.isConnected;

    final shouldShow = connected &&
        _activePhases.contains(phase) &&
        !_hiddenDestinations.contains(destination);
    if (!shouldShow) return const SizedBox.shrink();

    final nav = ref.read(playerNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final phaseColor = _phaseColor(scheme, phase);
    final phaseLabel = _phaseLabel(phase, state.dayCount);
    final latestMessage = _latestMessagePreview(state.bulletinBoard);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Semantics(
        button: true,
        label: 'Return to game',
        child: CBGlassTile(
          borderColor: phaseColor.withValues(alpha: 0.6),
          child: InkWell(
            onTap: () {
              HapticService.selection();
              nav.setDestination(
                phase == 'lobby' || phase == 'setup'
                    ? PlayerDestination.lobby
                    : PlayerDestination.game,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final intensity = 0.45 + (_pulse.value * 0.55);
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: phaseColor.withValues(alpha: intensity),
                          boxShadow: [
                            BoxShadow(
                              color: phaseColor.withValues(
                                alpha: 0.25 + (_pulse.value * 0.45),
                              ),
                              blurRadius: 8 + (_pulse.value * 6),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          phaseLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: phaseColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _phaseColor(ColorScheme scheme, String phase) {
    switch (phase) {
      case 'lobby':
      case 'setup':
        return scheme.primary;
      case 'night':
        return scheme.secondary;
      case 'day':
        return scheme.tertiary;
      case 'resolution':
      case 'endGame':
        return scheme.error;
      default:
        return scheme.primary;
    }
  }

  String _phaseLabel(String phase, int dayCount) {
    final normalizedPhase = phase.toUpperCase();
    final daySegment = dayCount > 0 ? ' • DAY $dayCount' : '';
    return '$normalizedPhase$daySegment IN PROGRESS';
  }

  String _latestMessagePreview(List<BulletinEntry> entries) {
    if (entries.isEmpty) return 'Tap to return';
    final content = entries.last.content.trim();
    if (content.isEmpty) return 'Tap to return';
    const int maxLength = 40;
    return content.length <= maxLength
        ? content
        : '${content.substring(0, maxLength - 1)}…';
  }
}
