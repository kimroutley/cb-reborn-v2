import 'dart:async';
import 'dart:ui';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/custom_drawer.dart';

/// A high-impact, Spotify Wrapped style recap for the Games Night.
/// Features animated story slides, dynamic neon glows, and player awards.
class GamesNightRecapScreen extends StatefulWidget {
  final GamesNightRecord session;
  final List<GameRecord> games;

  const GamesNightRecapScreen({
    super.key,
    required this.session,
    required this.games,
  });

  @override
  State<GamesNightRecapScreen> createState() => _GamesNightRecapScreenState();
}

class _GamesNightRecapScreenState extends State<GamesNightRecapScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late SessionRecap _recap;
  int _currentPage = 0;
  Timer? _progressTimer;
  double _progress = 0;

  // Slide duration in seconds
  static const int _slideDuration = 8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    try {
      _recap = RecapGenerator.generateRecap(widget.session, widget.games);
    } catch (_) {
      // Fallback: never crash the recap UI due to partial/corrupt data.
      final totalDuration = widget.session.endedAt != null
          ? widget.session.endedAt!.difference(widget.session.startedAt)
          : DateTime.now().difference(widget.session.startedAt);

      _recap = SessionRecap(
        sessionName: widget.session.sessionName,
        startedAt: widget.session.startedAt,
        endedAt: widget.session.endedAt,
        totalGames: widget.games.length,
        totalDuration: totalDuration,
        uniquePlayers: widget.session.playerNames.length,
        gameSummaries: const [],
        clubStaffWins:
            widget.games.where((g) => g.winner == Team.clubStaff).length,
        partyAnimalsWins:
            widget.games.where((g) => g.winner == Team.partyAnimals).length,
      );
    }
    _startTimer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _progressTimer?.cancel();
    _progress = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextProgress = _progress + (0.05 / _slideDuration);
      if (nextProgress < 1.0) {
        setState(() => _progress = nextProgress);
        return;
      }

      // Clamp and advance exactly once.
      setState(() => _progress = 1.0);
      timer.cancel();
      _nextPage();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      if (!_pageController.hasClients) {
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _progressTimer?.cancel();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  int get _totalSlides {
    int count = 3; // Intro, Roster, Summary
    if (_recap.mvp != null) count++;
    if (_recap.mainCharacter != null) count++;
    if (_recap.ghost != null) count++;
    if (_recap.dealerOfDeath != null) count++;
    count += _recap.specialAwards.length;
    if (_recap.spiciestMoment != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CBPrismScaffold(
      title: 'SESSION RECAP',
      showAppBar: false,
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
            // ── ANIMATED BACKGROUND ──
            _buildDynamicBackground(scheme),

            // ── STORY CONTENT ──
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _startTimer();
                });
              },
              children: _buildSlides(scheme),
            ),

            // ── NAVIGATION OVERLAY ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _previousPage,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextPage,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),

            // ── TOP INDICATORS ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProgressBar(scheme),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const CBConnectionDot(
                            isConnected: true, label: "SESSION RECAP"),
                        const SizedBox(width: 8),
                        const SimulationModeBadgeAction(),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: scheme.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground(ColorScheme scheme) {
    final colors = [
      scheme.tertiary, // Previously CBColors.matrixGreen
      scheme.primary, // Previously CBColors.neonBlue
      scheme.secondary, // Previously CBColors.neonPurple
      scheme.secondary, // Previously CBColors.hotPink
      scheme.error, // Previously CBColors.bloodOrange
    ];
    final color = colors[_currentPage % colors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: ColoredBox(color: scheme.surface.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme scheme) {
    return Row(
      children: List.generate(_totalSlides, (index) {
        double value = 0;
        if (index < _currentPage) {
          value = 1.0;
        }
        if (index == _currentPage) {
          value = _progress;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Stack(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildSlides(ColorScheme scheme) {
    final slides = <Widget>[
      _buildIntroSlide(scheme),
      _buildRosterSlide(scheme),
    ];

    if (_recap.mvp != null) {
      slides.add(
        _buildAwardSlide("MVP", _recap.mvp!, Icons.emoji_events,
            scheme.tertiary), // Previously CBColors.yellow
      );
    }
    if (_recap.mainCharacter != null) {
      slides.add(
        _buildAwardSlide(
          "MAIN CHARACTER",
          _recap.mainCharacter!,
          Icons.my_location,
          scheme.secondary, // Previously CBColors.hotPink
        ),
      );
    }
    if (_recap.ghost != null) {
      slides.add(
        _buildAwardSlide(
          "THE GHOST",
          _recap.ghost!,
          Icons.visibility_off,
          scheme.secondary, // Previously CBColors.neonPurple
        ),
      );
    }
    if (_recap.dealerOfDeath != null) {
      slides.add(
        _buildAwardSlide(
          "DEALER OF DEATH",
          _recap.dealerOfDeath!,
          Icons.local_bar,
          scheme.error, // Previously CBColors.bloodOrange
        ),
      );
    }
    for (final special in _recap.specialAwards) {
      slides.add(_buildSpecialAwardSlide(special, scheme));
    }

    if (_recap.spiciestMoment != null) {
      slides.add(_buildSpicySlide(scheme));
    }

    slides.add(_buildSummarySlide(scheme));
    return slides;
  }

  static IconData _specialAwardIcon(String id) => switch (id) {
        'cannon_fodder' => Icons.crisis_alert,
        'the_npc' => Icons.person_off,
        'friendly_fire_champion' => Icons.group_remove,
        'professional_victim' => Icons.healing,
        'the_cockroach' => Icons.pest_control,
        'absolutely_clueless' => Icons.psychology_alt,
        'the_tourist' => Icons.luggage,
        'designated_scapegoat' => Icons.front_hand,
        'the_judas' => Icons.masks,
        'participation_trophy' => Icons.workspace_premium,
        _ => Icons.emoji_events,
      };

  static Color _specialAwardColor(String id, ColorScheme scheme) => switch (id) {
        'cannon_fodder' => scheme.error,
        'the_npc' => scheme.onSurface.withValues(alpha: 0.4),
        'friendly_fire_champion' => scheme.error,
        'professional_victim' => scheme.secondary,
        'the_cockroach' => scheme.tertiary,
        'absolutely_clueless' => scheme.secondary,
        'the_tourist' => scheme.primary,
        'designated_scapegoat' => scheme.error,
        'the_judas' => scheme.secondary,
        'participation_trophy' => scheme.tertiary,
        _ => scheme.primary,
      };

  Widget _buildSpecialAwardSlide(SpecialAward award, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _specialAwardIcon(award.id);
    final color = _specialAwardColor(award.id, scheme);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            award.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.displayLarge!
                .copyWith(color: scheme.onSurface, fontSize: 32)
                .copyWith(shadows: CBColors.textGlow(color)),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: CBColors.circleGlow(color, intensity: 0.8),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            award.playerName.toUpperCase(),
            style: textTheme.displayMedium!
                .copyWith(color: scheme.onSurface, fontSize: 34),
          ),
          const SizedBox(height: 12),
          Text(
            award.stat.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelSmall!.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          CBGlassTile(
            borderColor: color.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              '"${award.roastLine}"',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium!.copyWith(
                fontStyle: FontStyle.italic,
                color: scheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome,
              color: scheme.tertiary,
              size: 80),
          const SizedBox(height: 32),
          Text(
            widget.session.sessionName.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.displayLarge!
                .copyWith(
                  color: scheme.onSurface,
                  letterSpacing: 4,
                )
                .copyWith(
                    shadows: CBColors.textGlow(scheme.tertiary)),
          ),
          const SizedBox(height: 24),
          Text(
            "WHAT A NIGHT.",
            style: textTheme.labelSmall!.copyWith(
                letterSpacing: 4,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 64),
          _buildStatRow(
              Icons.videogame_asset, "${_recap.totalGames} GAMES PLAYED"),
          const SizedBox(height: 16),
          _buildStatRow(Icons.timer,
              "${_recap.totalDuration.inHours}H ${_recap.totalDuration.inMinutes % 60}M DURATION"),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CBGlassTile(
      isPrismatic: true,
      borderColor: scheme.onSurface.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.onSurface.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 16),
          Text(label,
              style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRosterSlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("THE GUEST LIST",
              style: textTheme.headlineMedium!
                  .copyWith(
                      color: scheme.primary) // Previously CBColors.neonBlue
                  .copyWith(
                      shadows: CBColors.textGlow(
                          scheme.primary))),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: widget.session.playerNames.map((name) {
              return CBBadge(
                  text: name,
                  color: scheme.primary); // Previously CBColors.neonBlue
            }).toList(),
          ),
          const SizedBox(height: 48),
          Text("${_recap.uniquePlayers} LEGENDS ENTERED.\nSOME NEVER LEFT.",
              textAlign: TextAlign.center,
              style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAwardSlide(
      String title, PlayerAward award, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: textTheme.displayLarge!
                  .copyWith(color: scheme.onSurface)
                  .copyWith(shadows: CBColors.textGlow(color))),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: CBColors.circleGlow(color, intensity: 1.0),
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 48),
          Text(award.playerName.toUpperCase(),
              style: textTheme.displayMedium!
                  .copyWith(color: scheme.onSurface, fontSize: 36)),
          const SizedBox(height: 16),
          Text(award.description.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall!.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpicySlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("SPICIEST MOMENT",
              style: textTheme.headlineMedium!.copyWith(
                  color: scheme.error)), // Previously CBColors.bloodOrange
          const SizedBox(height: 48),
          CBPanel(
            borderColor: scheme.error,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: scheme.error),
                    const SizedBox(width: CBSpace.x3),
                    Expanded(
                      child: Text(
                        "RECORDED DATA",
                        style: textTheme.headlineSmall!.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CBSpace.x3),
                Text(
                  _recap.spiciestMoment ?? "NONE RECORDED",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium!
                      .copyWith(height: 1.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("NIGHT SUMMARY",
              style: textTheme.headlineMedium!
                  .copyWith(
                      color: scheme.tertiary) // Previously CBColors.matrixGreen
                  .copyWith(
                      shadows: CBColors.textGlow(scheme.tertiary))),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLargeStat("STAFF WINS", _recap.clubStaffWins,
                  scheme.secondary), // Previously CBColors.hotPink
              _buildLargeStat("ANIMAL WINS", _recap.partyAnimalsWins,
                  scheme.primary), // Previously CBColors.neonBlue
            ],
          ),
          const SizedBox(height: 64),
          CBPrimaryButton(
            label: "CLOSE RECAP",
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, int value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text("$value",
            style:
                textTheme.displayLarge!.copyWith(color: color, fontSize: 64)),
        const SizedBox(height: 8),
        Text(label,
            style: textTheme.labelSmall!
                .copyWith(color: color.withValues(alpha: 0.5))),
      ],
    );
  }
}
