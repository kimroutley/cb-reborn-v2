import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import '../colors.dart';
import '../haptic_service.dart';
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
  Role? _selectedRoleForTips;
  String _searchQuery = "";
  int _activeMainIndex = 0; // 0: Handbook, 1: Operatives, 2: Strategy
  int _activeHandbookCategoryIndex = 0;

  // Updated for Sliding Panel UI
  bool _isPanelOpen = false;
  Role? _selectedDossierRole;

  @override
  void initState() {
    super.initState();
    _selectedRoleForTips = widget.localPlayer?.role ?? roleCatalog.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CBPrismScaffold(
      title: "THE BLACKBOOK",
      drawer: widget.drawer,
      body: Stack(
        children: [
          Row(
            children: [
              // ── INTEGRATED NAVIGATION RAIL ──
              _buildNavigationRail(scheme, theme),

              // ── CONTENT AREA ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildActiveContent(),
                ),
              ),
            ],
          ),

          // ── SLIDING DETAILS PANEL ──
          CBSlidingPanel(
            isOpen: _isPanelOpen,
            onClose: () => setState(() => _isPanelOpen = false),
            title: _selectedDossierRole?.name ?? "DATA FILE",
            width: 450,
            child: _selectedDossierRole != null
                ? SingleChildScrollView(
                    child:
                        _buildOperativeDetails(context, _selectedDossierRole!),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(ColorScheme scheme, ThemeData theme) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _RailItem(
              icon: Icons.menu_book_rounded,
              label: "MANUAL",
              isActive: _activeMainIndex == 0,
              onTap: () => setState(() {
                _activeMainIndex = 0;
                HapticService.selection();
              }),
            ),
            _RailItem(
              icon: Icons.groups_rounded,
              label: "OPERATIVES",
              isActive: _activeMainIndex == 1,
              onTap: () => setState(() {
                _activeMainIndex = 1;
                HapticService.selection();
              }),
            ),
            _RailItem(
              icon: Icons.psychology_rounded,
              label: "INTEL",
              isActive: _activeMainIndex == 2,
              onTap: () => setState(() {
                _activeMainIndex = 2;
                HapticService.selection();
              }),
            ),
            if (_activeMainIndex == 0) ...[
              const SizedBox(height: 20),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.1),
                indent: 20,
                endIndent: 20,
              ),
              const SizedBox(height: 10),
              // Sub-navigation for Handbook
              ...List.generate(6, (index) {
                final icons = [
                  Icons.nightlife_rounded,
                  Icons.loop_rounded,
                  Icons.groups_rounded,
                  Icons.wine_bar_rounded,
                  Icons.settings_remote_rounded,
                  Icons.smartphone_rounded,
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _RailItem(
                    icon: icons[index],
                    label: "", // Compact for sub-items
                    isActive: _activeHandbookCategoryIndex == index,
                    isSubItem: true,
                    onTap: () => setState(() {
                      _activeHandbookCategoryIndex = index;
                      HapticService.light();
                    }),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeMainIndex) {
      case 0:
        return CBIndexedHandbook(
          gameState: widget.gameState,
          activeCategoryIndex: _activeHandbookCategoryIndex,
          onCategoryChanged: (index) =>
              setState(() => _activeHandbookCategoryIndex = index),
        );
      case 1:
        return CBFadeSlide(child: _buildOperativesTab());
      case 2:
        return CBFadeSlide(child: _buildIntelTab());
      default:
        return const SizedBox();
    }
  }

  // ── Tab 2: Operatives (Interactive Browser) ──
  Widget _buildOperativesTab() {
    // If no roles are loaded, provide a fallback or filter properly
    final allRoles = roleCatalog.isEmpty ? <Role>[] : roleCatalog;

    final filteredRoles = allRoles
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.type
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    if (allRoles.isEmpty) {
      return Center(
          child: Text("NO OPERATIVE DATA FOUND",
              style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }

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
                  onTap: () {
                    HapticService.light();
                    _showOperativeFile(role);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOperativeFile(Role role) {
    setState(() {
      _selectedDossierRole = role;
      _isPanelOpen = true;
    });
  }

  Widget _buildOperativeDetails(BuildContext context, Role role) {
    final color = CBColors.fromHex(role.colorHex);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBRoleAvatar(
              assetPath: role.assetPath,
              color: color,
              size: 160,
              breathing: true,
            ),
          ),
          const SizedBox(height: 32),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Text(
              role.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.displaySmall!.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 12,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: Center(
              child: CBBadge(
                text: "STRATEGIC CLASS: ${role.type}",
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 48),
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBPanel(
              borderColor: color.withValues(alpha: 0.2),
              margin: EdgeInsets.zero,
              child: Text(
                role.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge!.copyWith(
                  height: 1.8,
                  fontSize: 15,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: CBFadeSlide(
                  delay: const Duration(milliseconds: 500),
                  child: _buildDetailStat(
                      "WAKE PRIORITY", "LVL ${role.nightPriority}", color),
                ),
              ),
              Expanded(
                child: CBFadeSlide(
                  delay: const Duration(milliseconds: 600),
                  child: _buildDetailStat(
                      "ALLIANCE", _allianceName(role.alliance), color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CBFadeSlide(
            delay: const Duration(milliseconds: 700),
            child: Center(
              child: _buildDetailStat(
                  "MISSION OBJECTIVE", _winConditionFor(role), color),
            ),
          ),
          const SizedBox(height: 64),
          CBFadeSlide(
            delay: const Duration(milliseconds: 800),
            child: CBPrimaryButton(
              label: "ACKNOWLEDGE DATA",
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
              onPressed: () {
                setState(() => _isPanelOpen = false);
                HapticService.light();
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
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

  // ── Tab 3: Intel (Strategic Analytics & Alliance Mapping) ──
  Widget _buildIntelTab() {
    if (_selectedRoleForTips == null && roleCatalog.isNotEmpty) {
      _selectedRoleForTips = roleCatalog.first;
    }

    if (_selectedRoleForTips == null) {
      return const Center(child: Text("DATA UNAVAILABLE"));
    }

    final tips = _GuideStrategyGenerator.generateTips(
      role: _selectedRoleForTips!,
      state: widget.gameState,
      player: widget.localPlayer,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        CBSectionHeader(
            title: "STRATEGIC INTEL",
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 20),
        _buildRoleSelector(),
        const SizedBox(height: 32),
        
        Text(
          "ALLIANCE NETWORK (MVP LINKING)",
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 3,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 16),
        CBAllianceGraph(
          roles: roleCatalog,
          activeRoleId: _selectedRoleForTips!.id,
        ),
        
        const SizedBox(height: 48),
        Text(
          "TACTICAL ANALYSIS",
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 3,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildBriefingCard(tip)),
        
        if (widget.gameState != null) ...[
          const SizedBox(height: 48),
          Text(
            "SCENARIO SIMULATIONS (WHAT IF...)",
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                  letterSpacing: 3,
                  fontSize: 9,
                ),
          ),
          const SizedBox(height: 16),
          _buildBriefingCard(
            "🛡️ WHAT IF I'M TARGETED? Dealers strike vocal threats. Stay visible as a distraction if you have extra lives, or hide if you are a power role.",
          ),
          _buildBriefingCard(
            "⚠️ WHAT IF I'M BLOCKED? A Roofi can stop your night action. If your report doesn't come in, notify the lounge without revealing your specific role.",
          ),
          _buildBriefingCard(
            "🚨 WHAT IF I'M VORTEXED? If the game flows into a spiral of silence, Dealers are winning. Use your voice to disrupt their comfort zone.",
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final color = CBColors.fromHex(_selectedRoleForTips!.colorHex);
    return CBPanel(
      child: InkWell(
        onTap: () {
          HapticService.medium();
          _showRolePickerModal();
        },
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
                      return CBFadeSlide(
                        delay: Duration(milliseconds: 50 + (index * 25)),
                        child: Padding(
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
                              HapticService.selection();
                              setState(() => _selectedRoleForTips = role);
                              Navigator.pop(context);
                            },
                          ),
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
      ..._logicTips(role.id),
    ];

    if (state != null) {
      final alive = state.players.where((p) => p.isAlive).toList();
      
      // Dynamic logic based on game context
      if (role.id == RoleIds.allyCat &&
          alive.any((p) => p.role.id == RoleIds.bouncer)) {
        tips.add(
          '🎯 MVP LINK: THE BOUNCER is your primary protect target. Their survival ensures you get night vision every time they act.',
        );
      }

      if (role.alliance == Team.clubStaff &&
          !alive.any((p) => p.role.id == RoleIds.medic)) {
        tips.add(
          '🔥 OPPORTUNITY: The Medic has been neutralized. Your kills are now permanent.',
        );
      }

      if (role.id == RoleIds.roofi &&
          alive.where((p) => p.role.alliance == Team.clubStaff).length == 1) {
        tips.add(
          '🛡️ CLUTCH PLAY: If you Roofi the last remaining Dealer, they cannot commit a murder tonight.',
        );
      }
    }

    if (player != null) {
      if (player.lives > 1) {
        tips.add('💎 ASSET: You possess ${player.lives} active lives. Use the extra protection to be a louder voice in the lounge.');
      }
    }

    return tips;
  }

  static String _baseTip(String roleId) {
    switch (roleId) {
      case RoleIds.dealer:
        return 'Coordinate kills to maximize chaos and frame suspicious innocents.';
      case RoleIds.whore:
        return 'Your Scapegoat is your human shield. Keep them alive but keep them suspicious.';
      case RoleIds.silverFox:
        return 'Granting Alibis to "trusted" Party Animals builds your cover as a hero.';
      case RoleIds.bouncer:
        return 'Target the quietest players; Dealers often hide in the shadows of the chat.';
      case RoleIds.roofi:
        return 'Locking down a talkative player silences their influence for an entire day.';
      case RoleIds.medic:
        return 'Prioritize protecting the Bouncer or Wallflower; they are the Dealers\' top targets.';
      case RoleIds.wallflower:
        return 'Stay completely silent after witnessing a kill until the perfect moment to reveal proof.';
      case RoleIds.allyCat:
        return 'You are the Bouncer\'s eyes. If they die, your primary utility is lost—keep them alive.';
      case RoleIds.sober:
        return 'Sending a power role home protects them but also freezes their action—use with caution.';
      case RoleIds.dramaQueen:
        return 'Your death is a reset switch. Use your swap to strip a suspect of a powerful role.';
      default:
        return 'Treat every daytime vote as data extraction. Watch who jumps on bandwagons.';
    }
  }

  static List<String> _logicTips(String roleId) {
    switch (roleId) {
      case RoleIds.dealer:
        return [
          '⚠️ WHAT IF: If you are the last Dealer, favor targets that aren\'t being vocal to avoid detection.',
          '🚨 TACTIC: Vote for your own partner early if the heat is too high—it builds massive "innocent" credit.'
        ];
      case RoleIds.whore:
        return [
          '🛡️ WHAT IF: If your scapegoat dies naturally, you lose your deflection. Choose a robust target.',
          '💎 TIP: A Scapegoat who is a Medic or Bouncer is highly effective because they usually survive longer.'
        ];
      case RoleIds.bouncer:
        return [
          '🔍 INTEL: Share your findings incrementally. Outing every "Innocent" you find makes you a target.',
          '⚠️ WHAT IF: If you find a Dealer, don\'t out them instantly if you suspect a Whore is protecting them.'
        ];
      case RoleIds.allyCat:
        return [
          '🐱 SURVIVAL: You have 9 lives—draw fire from the Bouncer. You can afford to take hits they can\'t.',
          '💬 VOW: Use your limited communication to point out suspicious behavior without over-committing.'
        ];
      case RoleIds.wallflower:
        return [
          '👁️ EYEWITNESS: Memorize multiple faces during the murder phase. One witness is a claim; two is a conviction.',
          '⚠️ ALERT: If you open your eyes and see no one moving, the primary Dealer might be Roofing someone.'
        ];
      default:
        return [
          '📊 STRATEGY: Use the Lounge chat to test reactions. Dealers often react too perfectly to accusations.',
          '🛡️ DEFENSE: If you feel the target on your back, claim your role early to force the Dealers to pivot.'
        ];
    }
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSubItem;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    // Correctly resolve colors from theme
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Adjusted padding/margins - make subitems smaller
          margin: EdgeInsets.symmetric(
              vertical: isSubItem ? 4 : 8, horizontal: isSubItem ? 16 : 12),
          padding: EdgeInsets.symmetric(vertical: isSubItem ? 8 : 12),
          decoration: isActive
              ? BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: isSubItem ? 18 : 24,
                shadows: isActive
                    ? [Shadow(color: activeColor, blurRadius: 8)]
                    : null,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
