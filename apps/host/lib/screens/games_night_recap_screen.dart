import 'dart:async';
import 'dart:ui';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static const int _slideDuration = 8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    try {
      _recap = RecapGenerator.generateRecap(widget.session, widget.games);
    } catch (_) {
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
        duration: CBMotion.transition,
        curve: CBMotion.emphasizedCurve,
      );
    } else {
      _progressTimer?.cancel();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: CBMotion.transition,
        curve: CBMotion.emphasizedCurve,
      );
    }
  }

  int get _totalSlides {
    int count = 2; // Intro, Summary (Roster is in Intro now)
    if (_recap.mvp != null) count++;
    if (_recap.mainCharacter != null) count++;
    if (_recap.ghost != null) count++;
    if (_recap.dealerOfDeath != null) count++;
    count += _recap.specialAwards.length; // Each special award is a slide
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
          _buildDynamicBackground(scheme),

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

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.light();
                    _previousPage();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.light();
                    _nextPage();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(CBSpace.x4, CBSpace.x5, CBSpace.x4, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProgressBar(scheme),
                  const SizedBox(height: CBSpace.x4),
                  Row(
                    children: [
                      CBBadge(
                        text: 'ARCHIVED SESSION',
                        color: scheme.tertiary,
                        icon: Icons.archive_rounded,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'CLOSE RECAP',
                        icon: Icon(Icons.close_rounded, color: scheme.onSurface, size: 24),
                        onPressed: () {
                          HapticService.selection();
                          Navigator.pop(context);
                        },
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
      scheme.tertiary, // Starts with tertiary
      scheme.primary,
      scheme.secondary,
      scheme.error,
      CBColors.alertOrange,
    ];
    final color = colors[_currentPage % colors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.3),
            scheme.surface.withValues(alpha: 0.8),
          ],
          stops: [0.0, 1.0],
          center: Alignment(0.5 - (_progress * 0.5), 0.5 + (_progress * 0.5)),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CBRadius.xs),
              child: LinearProgressIndicator(
                value: value,
                minHeight: CBSpace.x1,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface.withValues(alpha: 0.8)),
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildSlides(ColorScheme scheme) {
    final slides = <Widget>[
      _buildIntroSlide(scheme),
    ];

    if (_recap.mvp != null) {
      slides.add(
        _buildAwardSlide("MOST VALUABLE OPERATIVE", _recap.mvp!, Icons.star_rounded,
            scheme.tertiary),
      );
    }
    if (_recap.mainCharacter != null) {
      slides.add(
        _buildAwardSlide(
          "THE KEY PLAYER",
          _recap.mainCharacter!,
          Icons.person_pin_rounded,
          scheme.secondary,
        ),
      );
    }
    if (_recap.ghost != null) {
      slides.add(
        _buildAwardSlide(
          "SPECTRAL OBSERVER",
          _recap.ghost!,
          Icons.visibility_off_rounded,
          scheme.primary,
        ),
      );
    }
    if (_recap.dealerOfDeath != null) {
      slides.add(
        _buildAwardSlide(
          "THE ELIMINATOR",
          _recap.dealerOfDeath!,
          Icons.crisis_alert_rounded,
          scheme.error,
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
        'cannon_fodder' => Icons.local_fire_department_rounded,
        'the_npc' => Icons.person_off_rounded,
        'friendly_fire_champion' => Icons.group_remove_rounded,
        'professional_victim' => Icons.healing_rounded,
        'the_cockroach' => Icons.pest_control_rounded,
        'absolutely_clueless' => Icons.psychology_alt_rounded,
        'the_tourist' => Icons.luggage_rounded,
        'designated_scapegoat' => Icons.front_hand_rounded,
        'the_judas' => Icons.masks_rounded,
        'participation_trophy' => Icons.workspace_premium_rounded,
        _ => Icons.emoji_events_rounded,
      };

  static Color _specialAwardColor(String id, ColorScheme scheme) =>
      switch (id) {
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
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Text(
              award.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.displaySmall!
                  .copyWith(color: scheme.onSurface)
                  .copyWith(shadows: CBColors.textGlow(color, intensity: 0.6)),
            ),
          ),
          const SizedBox(height: CBSpace.x10),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(CBSpace.x6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2.5),
                boxShadow: CBColors.circleGlow(color, intensity: 0.8),
              ),
              child: Icon(icon, size: CBSpace.x16, color: color),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Text(
              award.playerName.toUpperCase(),
              style: textTheme.displayMedium!
                  .copyWith(color: scheme.onSurface, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: Text(
              award.stat.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelLarge!.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBGlassTile(
              borderColor: color.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Text(
                '"${award.roastLine.toUpperCase()}"',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: 14,
                ),
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
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Icon(Icons.auto_awesome_rounded, color: scheme.tertiary, size: CBSpace.x16 + CBSpace.x4),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Text(
              widget.session.sessionName.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.displayLarge!
                  .copyWith(
                    color: scheme.onSurface,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  )
                  .copyWith(shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.8)),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Text(
              "AN OPERATIONS RECAP.".toUpperCase(),
              style: textTheme.labelLarge!.copyWith(
                  letterSpacing: 4,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x12),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: _buildStatRow(
                Icons.videogame_asset_rounded, "${_recap.totalGames} MISSIONS LOGGED", scheme.primary),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: _buildStatRow(Icons.timer_rounded,
                "${_recap.totalDuration.inHours}H ${_recap.totalDuration.inMinutes % 60}M ACTIVE", scheme.secondary),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 500),
            child: _buildStatRow(Icons.people_alt_rounded, "${_recap.uniquePlayers} UNIQUE OPERATIVES", scheme.tertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, Color accentColor) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CBGlassTile(
      isPrismatic: true,
      borderColor: accentColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5, vertical: CBSpace.x4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(CBSpace.x1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: CBSpace.x4),
          Text(label.toUpperCase(),
              style: textTheme.labelLarge!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRosterSlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Text("ACTIVE OPERATIVES",
                style: textTheme.headlineMedium!
                    .copyWith(color: scheme.primary)
                    .copyWith(shadows: CBColors.textGlow(scheme.primary, intensity: 0.6))),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Wrap(
              spacing: CBSpace.x3,
              runSpacing: CBSpace.x3,
              alignment: WrapAlignment.center,
              children: widget.session.playerNames.map((name) {
                return CBMiniTag(
                    text: name.toUpperCase(),
                    color: scheme.primary);
              }).toList(),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Text("${_recap.uniquePlayers} OPERATIVES DEPLOYED.\nSOME NEVER RETURNED.".toUpperCase(),
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    height: 1.5,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardSlide(
      String title, PlayerAward award, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Text(title.toUpperCase(),
                textAlign: TextAlign.center,
                style: textTheme.displayLarge!
                    .copyWith(color: scheme.onSurface)
                    .copyWith(shadows: CBColors.textGlow(color, intensity: 0.8))),
          ),
          const SizedBox(height: CBSpace.x10),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(CBSpace.x6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
                boxShadow: CBColors.circleGlow(color, intensity: 1.0),
              ),
              child: Icon(icon, size: CBSpace.x16 + CBSpace.x4, color: color),
            ),
          ),
          const SizedBox(height: CBSpace.x10),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: Text(award.playerName.toUpperCase(),
                style: textTheme.displayMedium!
                    .copyWith(color: scheme.onSurface, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          ),
          const SizedBox(height: CBSpace.x4),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: Text(award.description.toUpperCase(),
                textAlign: TextAlign.center,
                style: textTheme.labelLarge!.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 12,)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpicySlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Text("CRITICAL INCIDENT LOG",
                style: textTheme.headlineMedium!.
                    copyWith(color: scheme.error)
                    .copyWith(shadows: CBColors.textGlow(scheme.error, intensity: 0.6))),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBPanel(
              borderColor: scheme.error.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(CBSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: "RECORDED TELEMETRY",
                    icon: Icons.security_rounded,
                    color: scheme.error,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    (_recap.spiciestMoment ?? "NO DATA RECORDED").toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium!
                        .copyWith(height: 1.6, fontStyle: FontStyle.italic, color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySlide(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(CBSpace.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CBFadeSlide(
            child: Text("SESSION OVERVIEW",
                style: textTheme.headlineMedium!
                    .copyWith(color: scheme.tertiary)
                    .copyWith(shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.6))),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLargeStat("STAFF PROTOCOLS", _recap.clubStaffWins,
                    scheme.primary, textTheme),
                _buildLargeStat("PARTY ANIMAL ENGAGEMENTS", _recap.partyAnimalsWins,
                    scheme.secondary, textTheme),
              ],
            ),
          ),
          const SizedBox(height: CBSpace.x12),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBPrimaryButton(
              label: "CLOSE RECAP",
              icon: Icons.exit_to_app_rounded,
              onPressed: () {
                HapticService.heavy();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, int value, Color color, TextTheme textTheme) {
    return Column(
      children: [
        Text("$value",
            style:
                textTheme.displayLarge!.copyWith(color: color, fontSize: 64, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono', shadows: CBColors.textGlow(color, intensity: 0.5))),
        const SizedBox(height: CBSpace.x2),
        Text(label.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelLarge!
                .copyWith(color: color.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
