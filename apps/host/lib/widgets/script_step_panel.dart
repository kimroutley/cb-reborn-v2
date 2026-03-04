import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Shows the current script step and real-time completion status for the host.
/// Displays "DATA RECEIVED" when the step has action data, "AWAITING OPERATIVE UPLINK" otherwise,
/// and for multi-target steps shows which players have been selected (e.g. "2/2 targets").
class ScriptStepPanel extends StatelessWidget {
  final GameState gameState;

  const ScriptStepPanel({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final step = gameState.currentStep;
    if (step == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = gameState.actionLog[step.id];
    final isComplete = value != null && value.isNotEmpty;
    final isMulti = step.actionType == ScriptActionType.selectTwoPlayers ||
        step.actionType == ScriptActionType.multiSelect;

    String roleLabel = step.roleId ?? 'HOST';
    if (step.roleId != null) {
      final role = roleCatalogMap[step.roleId];
      if (role != null) roleLabel = role.name.toUpperCase();
    }

    final targetPlayer = step.roleId != null
        ? gameState.players.cast<Player?>().firstWhere(
              (p) => p?.role.id == step.roleId && p!.isAlive,
              orElse: () => null,
            )
        : null;

    List<String> selectedIds = [];
    if (isMulti && value != null) {
      selectedIds = value.split(',').where((s) => s.isNotEmpty).toList();
    }
    final selectedPlayers = selectedIds
        .map((id) => gameState.players.cast<Player?>().firstWhere(
              (p) => p?.id == id,
              orElse: () => null,
            ))
        .whereType<Player>()
        .toList();
    final selectedNames = selectedPlayers.map((p) => p.name).toList();
    const int multiTargetCap = 2; // selectTwoPlayers / multiSelect common cap

    return CBFadeSlide(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: CBGlassTile(
          borderColor: (isComplete ? scheme.primary : scheme.tertiary)
              .withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                    color: isComplete
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.title.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                roleLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isComplete ? scheme.primary : scheme.tertiary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(CBRadius.pill),
                      border: Border.all(
                        color: (isComplete ? scheme.primary : scheme.tertiary)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isComplete)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: scheme.tertiary,
                            ),
                          ),
                        if (!isComplete) const SizedBox(width: 8),
                        Text(
                          isComplete
                              ? 'DATA RECEIVED'
                              : 'AWAITING OPERATIVE UPLINK',
                          style: textTheme.labelSmall?.copyWith(
                            color: isComplete
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMulti && selectedNames.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${selectedNames.length}/$multiTargetCap targets',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                  if (!isComplete && targetPlayer != null) ...[
                    const Spacer(),
                    _UplinkIndicator(
                      isConnected: targetPlayer.authUid != null &&
                          !targetPlayer.isBot,
                    ),
                  ],
                ],
              ),
              if (isMulti && selectedNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedNames.map((name) {
                    return CBMiniTag(
                      text: name.toUpperCase(),
                      color: scheme.primary,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UplinkIndicator extends StatefulWidget {
  final bool isConnected;

  const _UplinkIndicator({required this.isConnected});

  @override
  State<_UplinkIndicator> createState() => _UplinkIndicatorState();
}

class _UplinkIndicatorState extends State<_UplinkIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isConnected) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_UplinkIndicator old) {
    super.didUpdateWidget(old);
    if (widget.isConnected && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isConnected && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = widget.isConnected
        ? CBColors.success
        : scheme.onSurface.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final opacity = widget.isConnected
            ? 0.5 + (_pulse.value * 0.5)
            : 0.4;
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: widget.isConnected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isConnected ? 'UPLINK ACTIVE' : 'UPLINK OFFLINE',
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 8,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
