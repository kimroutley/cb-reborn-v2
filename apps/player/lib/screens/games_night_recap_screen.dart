import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';

class GamesNightRecapScreen extends StatelessWidget {
  final GamesNightRecord session;
  final List<GameRecord> games;

  const GamesNightRecapScreen({
    super.key,
    required this.session,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sortedGames = List<GameRecord>.from(games)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return CBPrismScaffold(
      title: 'SESSION RECAP',
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CBFadeSlide(
              child: CBGlassTile(
                borderColor: scheme.primary.withValues(alpha: 0.4),
                isPrismatic: session.isActive,
                padding: const EdgeInsets.all(CBSpace.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(CBSpace.x2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(Icons.calendar_today_rounded,
                              color: scheme.primary, size: 20),
                        ),
                        const SizedBox(width: CBSpace.x3),
                        Expanded(
                          child: Text(
                            session.sessionName.toUpperCase(),
                            style: textTheme.titleMedium!.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x3),
                    Text(
                      DateFormat('MMM dd, yyyy').format(session.startedAt).toUpperCase(),
                      style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: CBSpace.x4),
                    _buildStatsSummary(context, scheme, textTheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x8),

            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: CBSectionHeader(
                title: 'MISSIONS LOGGED',
                icon: Icons.track_changes_rounded,
                count: sortedGames.length,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: CBSpace.x4),

            if (sortedGames.isEmpty)
              CBFadeSlide(
                delay: const Duration(milliseconds: 150),
                child: CBPanel(
                  padding: const EdgeInsets.all(CBSpace.x6),
                  borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined,
                          size: CBSpace.x12, color: scheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        "NO MISSIONS LOGGED FOR THIS SESSION.".toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        'COMPLETE GAMES TO SEE THEIR RECAPS HERE.'.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sortedGames.asMap().entries.map((entry) {
                final index = entry.key;
                final game = entry.value;
                final gameNumber = games.length - index; // Correct for descending sort
                return CBFadeSlide(
                  delay: Duration(milliseconds: 50 * index.clamp(0, 10) + 150), // Staggered delay
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: CBSpace.x3),
                    child: _buildGameTile(context, gameNumber, game, scheme, textTheme),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, ColorScheme scheme, TextTheme textTheme) {
    final partyWins = games.where((g) => g.winner == Team.partyAnimals).length;
    final staffWins = games.where((g) => g.winner == Team.clubStaff).length;
    final totalGames = games.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            "PARTY ANIMALS",
            partyWins,
            scheme.primary, // Turquoise/Blue
            scheme,
            textTheme,
          ),
        ),
        const SizedBox(width: CBSpace.x4),
        Expanded(
          child: _buildStatCard(
            context,
            "CLUB STAFF",
            staffWins,
            scheme.secondary, // Pink/Magenta
            scheme,
            textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    Color color,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(CBSpace.x4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: CBColors.boxGlow(color, intensity: 0.2),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: textTheme.headlineSmall!.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontFamily: 'RobotoMono',
            shadows: CBColors.textGlow(color, intensity: 0.3),
          )),
          const SizedBox(height: CBSpace.x2),
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(
      BuildContext context, int number, GameRecord game, ColorScheme scheme, TextTheme textTheme) {
    final isPartyWin = game.winner == Team.partyAnimals;
    final winColor = game.winner == Team.partyAnimals ? scheme.primary : (game.winner == Team.clubStaff ? scheme.secondary : CBColors.alertOrange);
    final winnerLabel = game.winner == Team.partyAnimals ? "PARTY ANIMALS" : (game.winner == Team.clubStaff ? "CLUB STAFF" : "NEUTRAL");
    final duration = game.endedAt.difference(game.startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = "${minutes}M ${seconds}S";

    return CBGlassTile(
      borderColor: winColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CBSpace.x2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: winColor.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.videogame_asset_rounded,
                    color: winColor, size: 20),
              ),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Text(
                  'MISSION ${number} // ${game.dayCount} CYCLES'.toUpperCase(),
                  style: textTheme.titleSmall!.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            'OUTCOME: $winnerLabel • DURATION: $durationStr'.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
                color: winColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: CBSpace.x4),
          Text("OPERATIVES (${game.playerCount})".toUpperCase(),
              style: textTheme.labelSmall!.
                  copyWith(color: scheme.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: CBSpace.x2),
          Wrap(
            spacing: CBSpace.x2,
            runSpacing: CBSpace.x2,
            children: game.roster
                .map<Widget>((p) => CBMiniTag(
                    text: p.name.toUpperCase(),
                    color: p.alive
                        ? scheme.tertiary
                        : scheme.error.withValues(alpha: 0.7),
                    tooltip: p.alive ? null : 'Eliminated',
                  ))
                .toList(),
          )
        ],
      ),
    );
  }
}
