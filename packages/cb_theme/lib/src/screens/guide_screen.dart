import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import '../colors.dart';
import '../widgets.dart';

class CBGuideScreen extends StatefulWidget {
  final GameState? gameState;
  final Player? localPlayer;
  final Widget? drawer;

  const CBGuideScreen({
    super.key,
    this.gameState,
    this.localPlayer,
    this.drawer,
  });

  @override
  State<CBGuideScreen> createState() => _CBGuideScreenState();
}

class _CBGuideScreenState extends State<CBGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Role? _selectedRoleForTips;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedRoleForTips = widget.localPlayer?.role ?? roleCatalog.first;
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
    final topInset =
        MediaQuery.paddingOf(context).top + kToolbarHeight + kTextTabBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withValues(alpha: 0.90),
                scheme.surface.withValues(alpha: 0.60),
                Colors.transparent,
              ],
              stops: const [0.0, 0.78, 1.0],
            ),
          ),
        ),
        title: const Text("CLUB BIBLE"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
          labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
          tabs: const [
            Tab(text: "HANDBOOK"),
            Tab(text: "OPERATIVES"),
            Tab(text: "STRATEGY"),
          ],
        ),
      ),
      drawer: widget.drawer,
      body: CBNeonBackground(
        showRadiance: true,
        blurSigma: 11,
        child: SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.26),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHandbookTab(),
                  _buildOperativesTab(),
                  _buildStrategyTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Handbook (Visual & Structured) ──
  Widget _buildHandbookTab() {
    return CBIndexedHandbook(gameState: widget.gameState);
  }

  // ── Tab 2: Operatives (Interactive Browser) ──
  Widget _buildOperativesTab() {
    final filteredRoles = roleCatalog
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.type.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: CBTextField(
            hintText: "SEARCH DOSSIERS...",
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: filteredRoles.length,
            itemBuilder: (context, index) {
              final role = filteredRoles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CBRoleIDCard(
                  role: role,
                  onTap: () => _showOperativeFile(role),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOperativeFile(Role role) {
    final color = CBColors.fromHex(role.colorHex);
    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: double.maxFinite,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        CBRoleAvatar(
                          assetPath: role.assetPath,
                          color: color,
                          size: 140,
                          breathing: true,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          role.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium!.copyWith(
                            color: scheme.onSurface,
                            letterSpacing: 3.5,
                            shadows: [
                              Shadow(
                                color: color.withValues(alpha: 0.9),
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        CBBadge(text: "CLASS: ${role.type}", color: color),
                        const SizedBox(height: 36),
                        CBPanel(
                          child: Text(
                            role.description,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge!.copyWith(
                              height: 1.7,
                              color: scheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildDetailStat(
                            "WAKE PRIORITY", "LEVEL ${role.nightPriority}", color),
                        _buildDetailStat(
                            "ALLIANCE", _allianceName(role.alliance), color),
                        _buildDetailStat(
                            "MISSION GOAL", _winConditionFor(role), color),
                        const SizedBox(height: 64),
                        CBPrimaryButton(
                          label: "CLOSE DOSSIER",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _allianceName(Team t) => switch (t) {
        Team.clubStaff => "THE DEALERS (KILLERS)",
        Team.partyAnimals => "THE PARTY ANIMALS (INNOCENTS)",
        Team.neutral => "WILDCARDS (VARIABLES)",
        _ => "UNKNOWN",
      };

  String _winConditionFor(Role role) {
    return switch (role.alliance) {
      Team.clubStaff => "ELIMINATE ALL PARTY ANIMALS",
      Team.partyAnimals => "EXPOSE AND EXILE ALL DEALERS",
      Team.neutral => "FULFILL PERSONAL SURVIVAL GOALS",
      _ => "SURVIVE THE NIGHT",
    };
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          Container(width: 40, height: 1, color: color.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  // ── Tab 3: Strategy (Context-Aware Analytics) ──
  Widget _buildStrategyTab() {
    final tips = _GuideStrategyGenerator.generateTips(
      role: _selectedRoleForTips!,
      state: widget.gameState,
      player: widget.localPlayer,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        CBSectionHeader(
            title: "TACTICAL BRIEFING",
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 20),
        _buildRoleSelector(),
        const SizedBox(height: 40),
        Text(
          "FIELD ANALYTICS",
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
                letterSpacing: 3,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildBriefingCard(tip)),
        if (widget.gameState != null) ...[
          const SizedBox(height: 40),
          Text(
            "WHAT IF... SIMULATIONS",
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                  letterSpacing: 3,
                  fontSize: 9,
                ),
          ),
          const SizedBox(height: 16),
          _buildBriefingCard(
            "🛡️ WHAT IF I'M TARGETED? Dealers usually strike talkative players first. Stay visible but guarded.",
          ),
          _buildBriefingCard(
            "⚠️ WHAT IF I'M BLOCKED? A Roofi can stop your night action silently. Pay attention to morning reports.",
          ),
        ],
      ],
    );
  }

  Widget _buildRoleSelector() {
    final color = CBColors.fromHex(_selectedRoleForTips!.colorHex);
    return CBPanel(
      child: InkWell(
        onTap: () => _showRolePickerModal(),
        child: Row(
          children: [
            CBRoleAvatar(
              assetPath: _selectedRoleForTips!.assetPath,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedRoleForTips!.name,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TAP TO CHANGE DATA FEED",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "DATA OVERRIDE",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: roleCatalog.length,
                    itemBuilder: (context, index) {
                      final role = roleCatalog[index];
                      final rColor = CBColors.fromHex(role.colorHex);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          leading: CBRoleAvatar(
                            assetPath: role.assetPath,
                            color: rColor,
                            size: 32,
                          ),
                          title: Text(
                            role.name.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: scheme.onSurface,
                                  fontSize: 11,
                                ),
                          ),
                          onTap: () {
                            setState(() => _selectedRoleForTips = role);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBriefingCard(String tip) {
    final isAlert =
        tip.contains("⚠️") || tip.contains("🚨") || tip.contains("🔥");
    final isStatus = tip.contains("💎") || tip.contains("🔇");

    final theme = Theme.of(context);
    final color = isAlert
        ? theme.colorScheme.error
        : (isStatus ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_tipIcon(tip), color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _tipIcon(String tip) {
    if (tip.contains("⚠️") || tip.contains("🚨")) {
      return Icons.warning_amber_rounded;
    }
    if (tip.contains("🔥")) return Icons.local_fire_department_rounded;
    if (tip.contains("🛡️")) return Icons.shield_rounded;
    if (tip.contains("💎")) return Icons.diamond_rounded;
    if (tip.contains("🔇")) return Icons.mic_off_rounded;
    return Icons.lightbulb_outline_rounded;
  }
}

class _GuideStrategyGenerator {
  _GuideStrategyGenerator._();

  static List<String> generateTips({
    required Role role,
    GameState? state,
    Player? player,
  }) {
    final tips = <String>[
      _baseTip(role.id),
    ];

    if (state != null) {
      final alive = state.players.where((p) => p.isAlive).toList();
      if (state.dayVoteTally.isNotEmpty) {
        final maxVotes =
            state.dayVoteTally.values.reduce((a, b) => a > b ? a : b);
        if (maxVotes >= 2) {
          tips.add(
            '📊 PATTERN: Vote pressure is building. Expect a last-minute pivot before exile.',
          );
        }
      }

      if (role.alliance == Team.clubStaff &&
          !alive.any((p) => p.role.id == RoleIds.medic)) {
        tips.add(
          '🔥 OPPORTUNITY: The Medic is out. Night eliminations are harder to reverse.',
        );
      }

      if (role.id == RoleIds.minor &&
          !alive.any((p) => p.role.id == RoleIds.bouncer)) {
        tips.add(
          '🛡️ WHAT IF: Without the Bouncer alive, your protection window is stronger than usual.',
        );
      }
    }

    if (player != null) {
      if (player.lives > 1) {
        tips.add('💎 STATUS: You still have ${player.lives} lives in reserve.');
      }
      if (state != null && player.silencedDay == state.dayCount) {
        tips.add('🔇 STATUS: You are silenced this day phase.');
      }
    }

    return tips;
  }

  static String _baseTip(String roleId) {
    switch (roleId) {
      case RoleIds.dealer:
        return 'Coordinate quietly and avoid over-leading daytime votes too early.';
      case RoleIds.medic:
        return 'Preserve high-impact roles and avoid predictable protection patterns.';
      case RoleIds.bouncer:
        return 'Prioritize players driving narratives; their alignment reveals momentum.';
      default:
        return 'Survive the night and treat every daytime vote as information.';
    }
  }
}

