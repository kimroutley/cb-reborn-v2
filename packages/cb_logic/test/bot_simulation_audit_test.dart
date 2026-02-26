import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late ProviderContainer container;
  late Game game;

  setUp(() {
    container = ProviderContainer();
    game = container.read(gameProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('bot audit: generated interactive role steps are simulatable', () {
    final botRoles = roleCatalog
        .where((r) => r.id != 'unassigned' && r.isBotFriendly)
        .toList();

    final bots = botRoles
        .map(
          (role) => Player(
            id: 'bot_${role.id}',
            name: 'Bot ${role.id}',
            role: role,
            alliance: role.alliance,
            isBot: true,
          ),
        )
        .toList();

    final fillers = [
      Player(
        id: 'filler_a',
        name: 'Filler A',
        role: roleCatalogMap[RoleIds.partyAnimal]!,
        alliance: Team.partyAnimals,
      ),
      Player(
        id: 'filler_b',
        name: 'Filler B',
        role: roleCatalogMap[RoleIds.partyAnimal]!,
        alliance: Team.partyAnimals,
      ),
      Player(
        id: 'filler_c',
        name: 'Filler C',
        role: roleCatalogMap[RoleIds.partyAnimal]!,
        alliance: Team.partyAnimals,
      ),
    ];

    final roster = [...bots, ...fillers];

    final setupSteps = ScriptBuilder.buildSetupScript(roster, dayCount: 0)
        .where(
          (s) =>
              s.roleId != null &&
              s.roleId != 'unassigned' &&
              (s.actionType == ScriptActionType.selectPlayer ||
                  s.actionType == ScriptActionType.selectTwoPlayers ||
                  (s.actionType == ScriptActionType.binaryChoice &&
                      s.options.isNotEmpty)),
        )
        .toList();

    final nightSteps = ScriptBuilder.buildNightScript(roster, 1)
        .where(
          (s) =>
              s.roleId != null &&
              s.roleId != 'unassigned' &&
              (s.actionType == ScriptActionType.selectPlayer ||
                  s.actionType == ScriptActionType.selectTwoPlayers ||
                  (s.actionType == ScriptActionType.binaryChoice &&
                      s.options.isNotEmpty)),
        )
        .toList();

    final dayRoster = roster
        .map(
          (p) => p.role.id == RoleIds.secondWind
              ? p.copyWith(secondWindPendingConversion: true)
              : p,
        )
        .toList();

    final daySteps = ScriptBuilder.buildDayScript(1, dayRoster)
        .where(
          (s) =>
              s.roleId != null &&
              s.roleId != 'unassigned' &&
              (s.actionType == ScriptActionType.selectPlayer ||
                  s.actionType == ScriptActionType.selectTwoPlayers ||
                  (s.actionType == ScriptActionType.binaryChoice &&
                      s.options.isNotEmpty)),
        )
        .toList();

    final reactiveSteps = <ScriptStep>[];
    if (botRoles.any((r) => r.id == RoleIds.teaSpiller)) {
      reactiveSteps.add(
        const ScriptStep(
          id: 'tea_spiller_reveal_bot_tea_spiller_1',
          title: 'TEA SPILLER REVEAL',
          readAloudText: '',
          instructionText: '',
          actionType: ScriptActionType.selectPlayer,
          roleId: RoleIds.teaSpiller,
        ),
      );
    }
    if (botRoles.any((r) => r.id == RoleIds.predator)) {
      reactiveSteps.add(
        const ScriptStep(
          id: 'predator_retaliation_bot_predator_1',
          title: 'PREDATOR RETALIATION',
          readAloudText: '',
          instructionText: '',
          actionType: ScriptActionType.selectPlayer,
          roleId: RoleIds.predator,
        ),
      );
    }
    if (botRoles.any((r) => r.id == RoleIds.dramaQueen)) {
      reactiveSteps.add(
        const ScriptStep(
          id: 'drama_queen_vendetta_bot_drama_queen_1',
          title: 'DRAMA QUEEN VENDETTA',
          readAloudText: '',
          instructionText: '',
          actionType: ScriptActionType.selectTwoPlayers,
          roleId: RoleIds.dramaQueen,
        ),
      );
    }

    final auditSteps = <ScriptStep>[
      ...setupSteps,
      ...nightSteps,
      ...daySteps,
      ...reactiveSteps,
    ];

    expect(
      auditSteps,
      isNotEmpty,
      reason: 'No interactive bot-role steps discovered for audit.',
    );

    for (final step in auditSteps) {
      var players = dayRoster;

      if (step.id.startsWith('tea_spiller_reveal_')) {
        players = players
            .map(
              (p) => p.id == 'bot_tea_spiller'
                  ? p.copyWith(isAlive: false, deathReason: 'exile')
                  : p,
            )
            .toList();
      }
      if (step.id.startsWith('predator_retaliation_')) {
        players = players
            .map(
              (p) => p.id == 'bot_predator'
                  ? p.copyWith(isAlive: false, deathReason: 'exile')
                  : p,
            )
            .toList();
      }
      if (step.id.startsWith('drama_queen_vendetta_')) {
        players = players
            .map(
              (p) => p.id == 'bot_drama_queen'
                  ? p.copyWith(isAlive: false, deathReason: 'exile')
                  : p,
            )
            .toList();
      }

      final phase =
          step.id.contains('_setup_') || step.id.startsWith('medic_choice_')
          ? GamePhase.setup
          : (step.id.startsWith('day_') ||
                step.id.startsWith('second_wind_convert_') ||
                step.id.startsWith('tea_spiller_reveal_') ||
                step.id.startsWith('predator_retaliation_') ||
                step.id.startsWith('drama_queen_vendetta_'))
          ? GamePhase.day
          : GamePhase.night;

      final dayCount = step.id.endsWith('_0') ? 0 : 1;

      game.state = GameState(
        players: players,
        phase: phase,
        dayCount: dayCount,
        scriptQueue: [step],
        scriptIndex: 0,
        actionLog: const {},
      );

      final acted = game.simulateBotTurns();
      expect(
        acted,
        1,
        reason:
            'Bot simulation failed for interactive step `${step.id}` (${step.actionType.name}).',
      );

      final updated = container.read(gameProvider);
      if (step.id.startsWith('second_wind_convert_')) {
        final sw = updated.players.firstWhere((p) => p.id == 'bot_second_wind');
        expect(
          sw.secondWindConverted || !sw.isAlive,
          isTrue,
          reason:
              'Second Wind conversion/execute did not resolve for `${step.id}`.',
        );
      } else {
        expect(
          updated.actionLog.containsKey(step.id),
          isTrue,
          reason: 'Expected action log entry for `${step.id}`.',
        );
      }
    }
  });
}
