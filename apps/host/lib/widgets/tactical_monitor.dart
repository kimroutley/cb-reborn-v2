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
    _glowAnimation =
        Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x4, CBSpace.x4, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        CBFadeSlide(child: _buildWinPredictions()),
        const SizedBox(height: CBSpace.x6),
        CBFadeSlide(delay: const Duration(milliseconds: 100), child: _buildHealthRail()),
        const SizedBox(height: CBSpace.x6),
        CBFadeSlide(delay: const Duration(milliseconds: 200), child: _buildLiveIntel()),
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
          padding: const EdgeInsets.all(CBSpace.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CBSectionHeader(
                title: "PROBABILITY MATRIX",
                icon: Icons.analytics_rounded,
                color: scheme.primary.withValues(alpha: _glowAnimation.value + 0.2),
              ),
              const SizedBox(height: CBSpace.x6),
              _buildOddsBar("DEALER CONTROL", staffProb, scheme.secondary),
              const SizedBox(height: CBSpace.x4),
              _buildOddsBar("PARTY STABILITY", paProb, scheme.tertiary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOddsBar(String team, double probability, Color color) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(team.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                )),
            Text("${(probability * 100).round()}%",
                style: textTheme.labelLarge!.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'RobotoMono',
                  shadows: CBColors.textGlow(color, intensity: 0.4),
                )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
            ),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutExpo,
                  widthFactor: probability,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          child: Text("OPERATIVE STATUS RAIL",
              style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 10)),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.gameState.players.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final player = widget.gameState.players[index];
              final roleColor = CBColors.fromHex(player.role.colorHex);
              final statusColor = _getStatusColor(player);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: player.isAlive ? roleColor.withValues(alpha: 0.4) : scheme.onSurface.withValues(alpha: 0.1),
                            width: 1.5
                          ),
                        ),
                        child: CBRoleAvatar(
                          assetPath: player.role.assetPath,
                          color: roleColor,
                          size: 48,
                          pulsing: player.isAlive && player.role.id != 'unassigned',
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                            boxShadow: CBColors.circleGlow(statusColor, intensity: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    player.name.toUpperCase().split(' ').first,
                    style: textTheme.labelSmall!.copyWith(
                        fontSize: 8,
                        color: player.isAlive ? scheme.onSurface.withValues(alpha: 0.7) : scheme.onSurface.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontFamily: 'RobotoMono',
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
    if (p.isSinBinned) return scheme.error.withValues(alpha: 0.5);
    if (p.isShadowBanned) return scheme.secondary;
    return scheme.tertiary;
  }

  Widget _buildLiveIntel() {
    final scheme = Theme.of(context).colorScheme;
    final alive = widget.gameState.players.where((p) => p.isAlive).length;

    return CBPanel(
      borderColor: scheme.tertiary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: "SESSION METRICS",
            icon: Icons.security_rounded,
            color: scheme.tertiary,
          ),
          const SizedBox(height: CBSpace.x6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIntelStat("ACTIVE", "$alive", scheme.tertiary),
              _buildIntelStat(
                  "CYCLE", "${widget.gameState.dayCount}", scheme.primary),
              _buildIntelStat(
                  "STABILITY",
                  alive == 0
                      ? "0%"
                      : "${(alive / widget.gameState.players.length * 100).round()}%",
                  scheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntelStat(String label, String value, Color color) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Text(value,
            style: textTheme.headlineMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFamily: 'RobotoMono',
                shadows: CBColors.textGlow(color, intensity: 0.4))),
        const SizedBox(height: 6),
        Text(label.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
                fontSize: 9,
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
      ],
    );
  }
}
