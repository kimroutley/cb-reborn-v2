import 'package:cb_models/cb_models.dart';
import 'package:cb_player/widgets/alliance_graph_view.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player_bridge.dart';
import '../strategy/player_strategy_engine.dart';

/// Full-screen draggable bottom sheet showing the Blackbook strategy guide
/// for the player's current role, plus live game-situation intel.
class RoleStrategySheet extends StatefulWidget {
  final PlayerSnapshot player;
  final PlayerGameState gameState;
  final Color roleColor;
  final RoleStrategy? strategy;

  const RoleStrategySheet({
    super.key,
    required this.player,
    required this.gameState,
    required this.roleColor,
    this.strategy,
  });

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required PlayerSnapshot player,
    required PlayerGameState gameState,
    required Color roleColor,
    RoleStrategy? strategy,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleStrategySheet(
        player: player,
        gameState: gameState,
        roleColor: roleColor,
        strategy: strategy,
      ),
    );
  }

  @override
  State<RoleStrategySheet> createState() => _RoleStrategySheetState();
}

class _RoleStrategySheetState extends State<RoleStrategySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['PLAYBOOK', 'DECEPTION', 'LIVE INTEL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.roleColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
              left: BorderSide(color: color.withValues(alpha: 0.15)),
              right: BorderSide(color: color.withValues(alpha: 0.15)),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(scheme, color),
              _buildHeader(theme, scheme, color),
              _buildTabBar(scheme, color),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlaybookTab(scrollController, theme, scheme, color),
                    _buildDeceptionTab(scrollController, theme, scheme, color),
                    _buildLiveIntelTab(scrollController, theme, scheme, color),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(ColorScheme scheme, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CBRoleAvatar(
            assetPath: 'assets/roles/${widget.player.roleId}.png',
            color: color,
            size: 42,
            breathing: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLACKBOOK',
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: color.withValues(alpha: 0.7),
                    letterSpacing: 3,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.player.roleName.toUpperCase(),
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: CBColors.textGlow(color, intensity: 0.5),
                  ),
                ),
              ],
            ),
          ),
          CBBadge(
            text: widget.player.isClubStaff ? 'STAFF' : 'PARTY',
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme scheme, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: color,
        indicatorWeight: 2.5,
        labelColor: color,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.4),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── TAB 1: PLAYBOOK (DOs / DON'Ts + Early/Late Game) ─────────────────

  Widget _buildPlaybookTab(
    ScrollController sc,
    ThemeData theme,
    ColorScheme scheme,
    Color color,
  ) {
    final strategy = widget.strategy;

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        if (strategy != null) ...[
          _buildOverviewCard(strategy.overview, theme, scheme, color),
          const SizedBox(height: 20),
          _buildPhaseStrategy(strategy, theme, scheme, color),
          const SizedBox(height: 24),
        ],

        if (strategy != null && strategy.dos.isNotEmpty) ...[
          _sectionLabel('DO THIS', Icons.check_circle_rounded, CBColors.neonGreen, theme),
          const SizedBox(height: 10),
          ...strategy.dos.map((d) => _buildRuleCard(
                d, CBColors.neonGreen, Icons.check_rounded, scheme, theme)),
          const SizedBox(height: 20),
        ],

        if (strategy != null && strategy.donts.isNotEmpty) ...[
          _sectionLabel('NEVER DO THIS', Icons.cancel_rounded, scheme.error, theme),
          const SizedBox(height: 10),
          ...strategy.donts.map((d) => _buildRuleCard(
                d, scheme.error, Icons.close_rounded, scheme, theme)),
          const SizedBox(height: 20),
        ],

        if (strategy != null &&
            (strategy.counters.isNotEmpty || strategy.synergies.isNotEmpty)) ...[
          _sectionLabel(
              'ALLIANCE NETWORK', Icons.hub_rounded, scheme.tertiary, theme),
          const SizedBox(height: 16),
          AllianceGraphView(
            roleId: strategy.roleId,
            synergies: strategy.synergies,
            counters: strategy.counters,
            roleColor: color,
          ),
          const SizedBox(height: 24),
        ],

        if (strategy == null)
          _buildEmptyState('No Blackbook data available for this role.', scheme, theme),
      ],
    );
  }

  // ── TAB 2: DECEPTION (Tactics + Betrayal) ─────────────────────────────

  Widget _buildDeceptionTab(
    ScrollController sc,
    ThemeData theme,
    ColorScheme scheme,
    Color color,
  ) {
    final strategy = widget.strategy;

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        if (strategy != null && strategy.deceptionTactics.isNotEmpty) ...[
          _sectionLabel('DECEPTION TACTICS', Icons.theater_comedy_rounded, scheme.tertiary, theme),
          const SizedBox(height: 8),
          _sectionSubtitle('Mind games and manipulation strategies for your role.', scheme, theme),
          const SizedBox(height: 12),
          ...strategy.deceptionTactics.asMap().entries.map((e) =>
              _buildNumberedTactic(e.key + 1, e.value, scheme.tertiary, scheme, theme)),
          const SizedBox(height: 28),
        ],

        if (strategy != null && strategy.betrayalAdvice.isNotEmpty) ...[
          _sectionLabel('BETRAYAL PLAYBOOK', Icons.psychology_alt_rounded, color, theme),
          const SizedBox(height: 8),
          _sectionSubtitle('Sneaky moves to gain the upper hand — use at your own risk.', scheme, theme),
          const SizedBox(height: 12),
          ...strategy.betrayalAdvice.asMap().entries.map((e) =>
              _buildNumberedTactic(e.key + 1, e.value, color, scheme, theme)),
        ],

        if (strategy == null ||
            (strategy.deceptionTactics.isEmpty && strategy.betrayalAdvice.isEmpty))
          _buildEmptyState('No deception intel available for this role.', scheme, theme),
      ],
    );
  }

  // ── TAB 3: LIVE INTEL (Dynamic situation analysis) ────────────────────

  Widget _buildLiveIntelTab(
    ScrollController sc,
    ThemeData theme,
    ColorScheme scheme,
    Color color,
  ) {
    final tips = PlayerStrategyEngine.evaluateSituation(
      player: widget.player,
      gameState: widget.gameState,
    );

    if (tips.isEmpty) {
      return _buildEmptyState('No live intel available right now.', scheme, theme);
    }

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _sectionLabel(
          'SITUATION ROOM — DAY ${widget.gameState.dayCount}',
          Icons.radar_rounded,
          color,
          theme,
        ),
        const SizedBox(height: 8),
        _sectionSubtitle(
          'Real-time analysis of the current game state, tailored to your role.',
          scheme,
          theme,
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildSituationCard(tip, scheme, theme)),
      ],
    );
  }

  // ── Shared card builders ──────────────────────────────────────────────

  Widget _buildOverviewCard(
    String text,
    ThemeData theme,
    ColorScheme scheme,
    Color color,
  ) {
    return CBGlassTile(
      borderColor: color.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium!.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.85),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildPhaseStrategy(
    RoleStrategy strategy,
    ThemeData theme,
    ColorScheme scheme,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPhaseCard(
            'EARLY GAME',
            strategy.earlyGame,
            Icons.wb_sunny_rounded,
            color.withValues(alpha: 0.8),
            scheme,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPhaseCard(
            'LATE GAME',
            strategy.lateGame,
            Icons.nights_stay_rounded,
            scheme.error.withValues(alpha: 0.8),
            scheme,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseCard(
    String title,
    String text,
    IconData icon,
    Color accentColor,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.labelSmall!.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _sectionSubtitle(String text, ColorScheme scheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Text(
        text,
        style: theme.textTheme.bodySmall!.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.4),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildRuleCard(
    String text,
    Color accentColor,
    IconData icon,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Unused _buildMatchupRow removed


  Widget _buildNumberedTactic(
    int index,
    String text,
    Color accentColor,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall!.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSituationCard(
    SituationTip tip,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    final (Color tipColor, IconData tipIcon) = switch (tip.type) {
      TipType.critical => (scheme.error, Icons.warning_amber_rounded),
      TipType.warning => (Colors.amber, Icons.shield_rounded),
      TipType.opportunity => (CBColors.neonGreen, Icons.local_fire_department_rounded),
      TipType.strategy => (scheme.primary, Icons.lightbulb_outline_rounded),
      TipType.deception => (scheme.tertiary, Icons.theater_comedy_rounded),
      TipType.survival => (Colors.blueAccent, Icons.favorite_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tipColor.withValues(alpha: tip.priority <= 1 ? 0.4 : 0.15),
          width: tip.priority == 0 ? 1.5 : 1.0,
        ),
        boxShadow: tip.priority == 0
            ? [BoxShadow(color: tipColor.withValues(alpha: 0.1), blurRadius: 12)]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tipIcon, size: 20, color: tipColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tipTypeLabel(tip.type),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: tipColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.text,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tipTypeLabel(TipType type) => switch (type) {
        TipType.critical => 'CRITICAL',
        TipType.warning => 'WARNING',
        TipType.opportunity => 'OPPORTUNITY',
        TipType.strategy => 'STRATEGY',
        TipType.deception => 'DECEPTION',
        TipType.survival => 'SURVIVAL',
      };

  Widget _buildEmptyState(String text, ColorScheme scheme, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
