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
  late int _activeCategoryIndex;

  @override
  void initState() {
    super.initState();
    _activeCategoryIndex = widget.activeCategoryIndex;
  }

  @override
  void didUpdateWidget(CBIndexedHandbook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeCategoryIndex != oldWidget.activeCategoryIndex) {
      if (_activeCategoryIndex != widget.activeCategoryIndex) {
        _scrollToCategory(widget.activeCategoryIndex);
      }
    }
  }

  final List<_HandbookCategory> _categories = [
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
              "The Dealres know each other's identities. They aim to kill one player every night while blending into the crowd during the day.",
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

  void _scrollToCategory(int index) {
    if (!mounted) return;
    setState(() => _activeCategoryIndex = index);

    // Notify parent
    widget.onCategoryChanged?.call(index);

    // Approximate height-based scrolling
    double offset = 0;
    for (int i = 0; i < index; i++) {
      // Calculate approx height of preceding category
      offset += 60; // Category Header
      offset += _categories[i].sections.length * 140; // Approx section height
      offset += 32; // Spacing
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        // ── Navigation Rail ──
        Container(
          width: 72,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = _activeCategoryIndex == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: IconButton(
                        icon: Icon(
                          cat.icon,
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        onPressed: () => _scrollToCategory(index),
                        tooltip: cat.title,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Content ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  CBSectionHeader(
                    title: cat.title,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // ── INJECT LIVE DATA FOR OVERVIEW ──
                  if (index == 0 && widget.gameState != null) ...[
                    const SizedBox(height: 16),
                    CBAllianceGraph(
                      roles: widget.gameState!.players.map((p) => p.role).toList(),
                    ),
                    const SizedBox(height: 24),
                    CBPhaseTimeline(currentPhase: widget.gameState!.phase),
                    const SizedBox(height: 32),
                  ],

                  ...cat.sections.map((sec) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: CBPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.title,
                                style: theme.textTheme.titleMedium!.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                sec.content,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.8),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
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
