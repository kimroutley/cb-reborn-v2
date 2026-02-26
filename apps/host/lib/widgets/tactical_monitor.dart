import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';

class TacticalMonitor extends StatefulWidget {
  final GameState gameState;

  const TacticalMonitor({super.key, required this.gameState});

  @override
  State<TacticalMonitor> createState() => _TacticalMonitorState();
}

class _TacticalMonitorState extends State<TacticalMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildWinPredictions(),
        const SizedBox(height: 24),
        _buildHealthRail(),
        const SizedBox(height: 24),
        _buildLiveIntel(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWinPredictions() {
    final alive = widget.gameState.players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;

    double staffProb = alive.isEmpty ? 0.5 : (staff / alive.length) * 1.1;
    staffProb = staffProb.clamp(0.05, 0.95);
    final paProb = 1.0 - staffProb;

    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return CBPanel(
          borderColor: scheme.primary.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CBSectionHeader(
                title: "WIN PREDICTIONS",
                icon: Icons.analytics,
                color: scheme.primary.withValues(alpha: _glowAnimation.value),
              ),
              const SizedBox(height: CBSpace.x4),
              _buildOddsBar("CLUB STAFF", staffProb, scheme.secondary),
              const SizedBox(height: 16),
              _buildOddsBar("PARTY ANIMALS", paProb, scheme.tertiary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOddsBar(String team, double probability, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              team,
              style: textTheme.labelSmall!.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
            Text(
              "${(probability * 100).round()}%",
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                shadows: CBColors.textGlow(color, intensity: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: probability,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthRail() {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "PLAYER HEALTH RAIL",
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.gameState.players.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final player = widget.gameState.players[index];
              return Column(
                children: [
                  Stack(
                    children: [
                      CBRoleAvatar(
                        assetPath: player.role.assetPath,
                        color: player.isAlive
                            ? CBColors.fromHex(player.role.colorHex)
                            : scheme.error,
                        size: 54,
                        pulsing:
                            player.isAlive && player.role.id != 'unassigned',
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(player),
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    player.name.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 8,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(Player p) {
    final scheme = Theme.of(context).colorScheme;
    if (!p.isAlive) return scheme.error;
    if (p.isSinBinned) return scheme.secondary;
    if (p.isShadowBanned) return scheme.tertiary;
    return scheme.tertiary;
  }

  Widget _buildLiveIntel() {
    final scheme = Theme.of(context).colorScheme;
    final alive = widget.gameState.players.where((p) => p.isAlive).length;

    return CBPanel(
      borderColor: scheme.tertiary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: "LIVE INTEL",
            icon: Icons.security,
            color: scheme.tertiary,
          ),
          const SizedBox(height: CBSpace.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIntelStat("ALIVE", "$alive", scheme.tertiary),
              _buildIntelStat(
                "DAY",
                "${widget.gameState.dayCount}",
                scheme.primary,
              ),
              _buildIntelStat(
                "STABILITY",
                alive == 0
                    ? "0%"
                    : "${(alive / widget.gameState.players.length * 100).round()}%",
                scheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntelStat(String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.displayMedium!.copyWith(
            color: color,
            fontSize: 28,
            shadows: CBColors.textGlow(color, intensity: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            fontSize: 9,
            color: scheme.onSurface.withValues(alpha: 0.45),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
