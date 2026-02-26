import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import '../widgets.dart'; // Import to get CBPanel, CBSectionHeader, CBAllianceGraph, etc.

class CBIndexedHandbook extends StatefulWidget {
  final GameState? gameState;
  final int activeCategoryIndex;
  final ValueChanged<int>? onCategoryChanged;

  const CBIndexedHandbook({
    super.key,
    this.gameState,
    this.activeCategoryIndex = 0,
    this.onCategoryChanged,
  });

  @override
  State<CBIndexedHandbook> createState() => _CBIndexedHandbookState();
}

class _CBIndexedHandbookState extends State<CBIndexedHandbook> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  bool _isScrollingManually = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _categories.length; i++) {
      _categoryKeys.add(GlobalKey());
    }
    _scrollController.addListener(_onActiveSectionUpdate);
    
    // Initial scroll after build if index > 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.activeCategoryIndex > 0) {
        _scrollToIndex(widget.activeCategoryIndex);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onActiveSectionUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CBIndexedHandbook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeCategoryIndex != oldWidget.activeCategoryIndex && !_isScrollingManually) {
      _scrollToIndex(widget.activeCategoryIndex);
    }
  }

  void _onActiveSectionUpdate() {
    if (_isScrollingManually) return;
    
    int bestIndex = widget.activeCategoryIndex;
    double minDistance = double.infinity;

    for (int i = 0; i < _categoryKeys.length; i++) {
      final context = _categoryKeys[i].currentContext;
      if (context == null) continue;

      try {
        final keyOffset = _getOffset(context); 
        if (keyOffset == null) continue;
        
        final distance = (keyOffset - _scrollController.offset).abs();
        
        // We prefer the section that is closest to the top
        if (distance < minDistance) {
          minDistance = distance;
          bestIndex = i;
        }
      } catch (e) {
        // Ignore layout errors during scroll
      }
    }

    if (bestIndex != widget.activeCategoryIndex) {
      widget.onCategoryChanged?.call(bestIndex);
    }
  }

  double? _getOffset(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final scrollable = Scrollable.of(context);
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox?;
    if (scrollableBox == null) return null;
    
    final offset = box.localToGlobal(Offset.zero, ancestor: scrollableBox);
    return offset.dy + _scrollController.offset;
  }

  Future<void> _scrollToIndex(int index) async {
    if (index < 0 || index >= _categoryKeys.length) return;
    final context = _categoryKeys[index].currentContext;
    if (context == null) return;

    setState(() => _isScrollingManually = true);
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      alignment: 0.05, // Slight offset from top
    );
    
    // Small delay to prevent scroll listener from firing immediately
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _isScrollingManually = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final phone = screenWidth < 600;
    final hPad = phone ? 14.0 : 24.0;
    final leftAccent = phone ? 12.0 : 20.0;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(hPad, phone ? 12 : 24, hPad, 100),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isActive = index == widget.activeCategoryIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          key: _categoryKeys[index],
          margin: EdgeInsets.only(bottom: phone ? 32 : 48),
          decoration: isActive
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: scheme.primary, width: 2)),
                )
              : const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.transparent, width: 2)),
                ),
          padding: EdgeInsets.only(left: leftAccent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CBSectionHeader(
                title: cat.title,
                icon: cat.icon,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),

              if (index == 0 && widget.gameState != null) ...[
                const SizedBox(height: 12),
                CBAllianceGraph(roles: widget.gameState!.players.map((p) => p.role).toList()),
                const SizedBox(height: 20),
                CBPhaseTimeline(currentPhase: widget.gameState!.phase),
                const SizedBox(height: 24),
              ],

              ...cat.sections.map((sec) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CBGlassTile(
                      isPrismatic: false,
                      borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.title,
                            style: theme.textTheme.titleSmall!.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: phone ? 13 : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sec.content,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.9),
                              height: 1.6,
                              fontSize: phone ? 13 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  // ── STATIC CONTENT DATA ──
  static final List<_HandbookCategory> _categories = [
    _HandbookCategory(
      title: "OVERVIEW",
      anchor: "overview",
      icon: Icons.nightlife_rounded,
      sections: [
        _HandbookSection(
          title: "WELCOME TO BLACKOUT",
          content:
              "Club Blackout is a social deduction game set in a neon-drenched nightclub. Trust is a luxury, and every choice you make could be your last. One group seeks to protect the party; the other seeks to end it.",
        ),
        _HandbookSection(
          title: "GAME OBJECTIVES",
          content:
              "The Party Animals must exile all Dealers to save the club. The Dealers must eliminate the Party Animals until they control the majority of the floor.",
        ),
      ],
    ),
    _HandbookCategory(
      title: "HOW TO PLAY",
      anchor: "loops",
      icon: Icons.loop_rounded,
      sections: [
        _HandbookSection(
          title: "THE GAME CYCLE",
          content:
              "The game flows through a repeated loop of Night, Day, and Vote phases until a victory condition is met.",
        ),
        _HandbookSection(
          title: "NIGHT: THE SHADOWS",
          content:
              "During the night, the club is silent. Roles with active abilities (like the Dealer, Medic, or Predator) choose their targets. Their identities remain hidden from others.",
        ),
        _HandbookSection(
          title: "DAY: THE RECKONING",
          content:
              "At dawn, the AI Narrator delivers the casualty report. Players then have a set amount of time to discuss the events, challenge claims, and identify suspicious behavior.",
        ),
        _HandbookSection(
          title: "VOTING: THE EXILE",
          content:
              "Once discussion ends, the digital ballot opens. Each player casts one secret vote. The player with the most votes is exiled from the club. No one is safe.",
        ),
      ],
    ),
    _HandbookCategory(
      title: "ALLIANCES",
      anchor: "alliances",
      icon: Icons.groups_rounded,
      sections: [
        _HandbookSection(
          title: "THE CLUB STAFF (DEALERS)",
          content:
              "The Dealers know each other's identities. They aim to kill one player every night while blending into the crowd during the day.",
        ),
        _HandbookSection(
          title: "THE PARTY ANIMALS",
          content:
              "The backbone of the club. Most have no information at the start and must rely on deduction. Specialized operatives like the Detective provide critical intel.",
        ),
        _HandbookSection(
          title: "WILDCARDS",
          content:
              "Third-party agents with unique win conditions. The Serial Killer wins alone, while the Wallflower simply tries to survive the chaos.",
        ),
      ],
    ),
    _HandbookCategory(
      title: "THE BAR TAB",
      anchor: "bartab",
      icon: Icons.wine_bar_rounded,
      sections: [
        _HandbookSection(
          title: "LIFE & DEATH",
          content:
              "Death is not the end. Eliminated players move to the Ghost Lounge. While your vote is gone, your debt and your influence remain.",
        ),
        _HandbookSection(
          title: "THE DEAD POOL",
          content:
              "Ghosts use the Dead Pool to bet on future exiles. Correct predictions can clear your Bar Tab, granting you prestige in the afterlife.",
        ),
      ],
    ),
    _HandbookCategory(
      title: "COMMAND CENTER",
      anchor: "host",
      icon: Icons.settings_remote_rounded,
      sections: [
        _HandbookSection(
          title: "THE GOD MODE TOGGLE",
          content:
              "Available only to the Host. Enabling God Mode reveals all hidden roles on the Command Center screen. Use this for monitoring or streaming the game.",
        ),
        _HandbookSection(
          title: "BOT SIMULATION",
          content:
              "Fill empty slots with AI Bots to test mechanics or play with smaller groups. Bots follow the core logic but don't possess human intuition.",
        ),
        _HandbookSection(
          title: "SCRIPTING THE CLUB",
          content:
              "Use 'Session Options' to adjust phase lengths, narrator sass levels, and which specific Operatives appear in the role lottery.",
        ),
      ],
    ),
    _HandbookCategory(
      title: "COMPANION APP",
      anchor: "player",
      icon: Icons.smartphone_rounded,
      sections: [
        _HandbookSection(
          title: "SYNCING YOUR PHONE",
          content:
              "Join via the lobby code. Once the game starts, your phone becomes your private Dossier. Keep your screen away from prying eyes!",
        ),
        _HandbookSection(
          title: "ROLE NOTIFICATIONS",
          content:
              "When it's your time to act, your screen will pulse and vibrate. Tap the screen to bring up your action menu and select your target.",
        ),
        _HandbookSection(
          title: "VOTING INTERFACE",
          content:
              "During the Vote phase, a scrollable list of players appears. Tap a player to select them, then confirm your vote with a long press.",
        ),
      ],
    ),
  ];
}

class _HandbookCategory {
  final String title;
  final String anchor;
  final IconData icon;
  final List<_HandbookSection> sections;

  _HandbookCategory({
    required this.title,
    required this.anchor,
    required this.icon,
    required this.sections,
  });
}

class _HandbookSection {
  final String title;
  final String content;

  _HandbookSection({
    required this.title,
    required this.content,
  });
}
