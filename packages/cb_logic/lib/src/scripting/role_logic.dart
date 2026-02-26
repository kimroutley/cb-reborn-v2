import 'package:cb_models/cb_models.dart';

abstract class RoleStrategy {
  const RoleStrategy();

  String get roleId;

  bool canAct(Player player, int dayCount);

  ScriptStep buildStep(Player player, int dayCount);
}

// ═══════════════════════════════════════════════
//  CLUB STAFF STRATEGIES
// ═══════════════════════════════════════════════

class DealerStrategy extends RoleStrategy {
  const DealerStrategy();

  @override
  String get roleId => RoleIds.dealer;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'dealer_act_${player.id}_$dayCount',
      title: 'THE DEALER',
      readAloudText:
          'Dealers, wake up. Who is leaving the club tonight?',
      instructionText: 'SELECT A TARGET FOR ELIMINATION',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class SilverFoxStrategy extends RoleStrategy {
  const SilverFoxStrategy();

  @override
  String get roleId => RoleIds.silverFox;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'silver_fox_act_${player.id}_$dayCount',
      title: 'THE SILVER FOX',
      readAloudText: 'Silver Fox, wake up. Who needs an alibi tomorrow?',
      instructionText: 'GRANT VOTING IMMUNITY TO A PLAYER',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class WhoreStrategy extends RoleStrategy {
  const WhoreStrategy();

  @override
  String get roleId => RoleIds.whore;

  @override
  bool canAct(Player player, int dayCount) {
    // One-use ability: pick scapegoat, only if not already used
    return player.isActive &&
        !player.whoreDeflectionUsed &&
        player.whoreDeflectionTargetId == null;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'whore_act_${player.id}_$dayCount',
      title: 'THE WHORE',
      readAloudText: 'Whore, wake up. Choose your scapegoat for tomorrow\'s vote.',
      instructionText: 'SELECT A SCAPEGOAT FOR VOTE DEFLECTION (ONE USE)',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

// ═══════════════════════════════════════════════
//  PARTY ANIMAL STRATEGIES
// ═══════════════════════════════════════════════

class SoberStrategy extends RoleStrategy {
  const SoberStrategy();

  @override
  String get roleId => RoleIds.sober;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'sober_act_${player.id}_$dayCount',
      title: 'SOBER',
      readAloudText: 'Sober, wake up. Who are you blocking tonight?',
      instructionText: 'BLOCK A PLAYER\'S ACTION',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class RoofiStrategy extends RoleStrategy {
  const RoofiStrategy();

  @override
  String get roleId => RoleIds.roofi;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive && !player.roofiAbilityRevoked;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'roofi_act_${player.id}_$dayCount',
      title: 'THE ROOFI',
      readAloudText: 'Roofi, wake up. Who are you silencing tomorrow?',
      instructionText: 'SELECT A PLAYER TO SILENCE',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class BouncerStrategy extends RoleStrategy {
  const BouncerStrategy();

  @override
  String get roleId => RoleIds.bouncer;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive && !player.bouncerAbilityRevoked;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'bouncer_act_${player.id}_$dayCount',
      title: 'THE BOUNCER',
      readAloudText: 'Bouncer, wake up. Who are you checking tonight?',
      instructionText: 'CHECK A PLAYER\'S ALLEGIANCE',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class MedicStrategy extends RoleStrategy {
  const MedicStrategy();

  @override
  String get roleId => RoleIds.medic;

  @override
  bool canAct(Player player, int dayCount) {
    if (!player.isActive) {
      return false;
    }

    if (player.medicChoice == 'REVIVE' && !player.hasReviveToken) {
      return false;
    }

    return true;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    final readText = player.medicChoice == 'REVIVE'
        ? 'Medic, wake up. Who do you want to bring back?'
        : 'Medic, wake up. Who are you saving tonight?';

    final instruction = player.medicChoice == 'REVIVE'
        ? 'SELECT A DEAD PLAYER TO REVIVE'
        : 'PROTECT A PLAYER FROM DEATH';

    return ScriptStep(
      id: 'medic_act_${player.id}_$dayCount',
      title: 'THE MEDIC',
      readAloudText: readText,
      instructionText: instruction,
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class BartenderStrategy extends RoleStrategy {
  const BartenderStrategy();

  @override
  String get roleId => RoleIds.bartender;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: '${player.role.id}_act_${player.id}_$dayCount',
      title: 'THE BARTENDER',
      readAloudText: 'Bartender, wake up. Which two patrons are you mixing up?',
      instructionText: 'COMPARE TWO PLAYERS\' ALLEGIANCE',
      actionType: ScriptActionType.selectTwoPlayers,
      roleId: roleId,
    );
  }
}

class LightweightStrategy extends RoleStrategy {
  const LightweightStrategy();

  @override
  String get roleId => RoleIds.lightweight;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'lightweight_act_${player.id}_$dayCount',
      title: 'THE LIGHTWEIGHT',
      readAloudText: 'Lightweight, wake up. Whose name is forbidden tomorrow?',
      instructionText: 'SELECT A PLAYER TO MAKE THEIR NAME TABOO',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

// ═══════════════════════════════════════════════
//  NEUTRAL STRATEGIES
// ═══════════════════════════════════════════════

class MessyBitchStrategy extends RoleStrategy {
  const MessyBitchStrategy();

  @override
  String get roleId => RoleIds.messyBitch;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: '${player.role.id}_act_${player.id}_$dayCount',
      title: 'THE MESSY BITCH',
      readAloudText: 'Messy Bitch, wake up. Who do you want to start a rumour about tonight?',
      instructionText: 'START A RUMOUR ABOUT A PLAYER',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class ClubManagerStrategy extends RoleStrategy {
  const ClubManagerStrategy();

  @override
  String get roleId => RoleIds.clubManager;

  @override
  bool canAct(Player player, int dayCount) {
    return player.isActive;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: 'club_manager_act_${player.id}_$dayCount',
      title: 'THE CLUB MANAGER',
      readAloudText:
          'Club Manager, wake up. Choose a patron to inspect.',
      instructionText: 'INSPECT A PLAYER\'S ID CARD',
      actionType: ScriptActionType.selectPlayer,
      roleId: roleId,
    );
  }
}

class AttackDogStrategy extends RoleStrategy {
  const AttackDogStrategy();

  @override
  String get roleId => RoleIds.attackDog;

  @override
  bool canAct(Player player, int dayCount) {
    // Clinger freed as Attack Dog after partner dies, one-shot kill
    return player.isActive &&
        player.clingerFreedAsAttackDog &&
        !player.clingerAttackDogUsed;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: '${roleId}_act_${player.id}_$dayCount',
      title: 'THE ATTACK DOG',
      readAloudText: 'Attack Dog, wake up. You are free. Choose your revenge.',
      instructionText: 'SELECT A PLAYER TO ELIMINATE (ONE USE)',
      actionType: ScriptActionType.selectPlayer,
      roleId: RoleIds.attackDog,
    );
  }
}

class MessyBitchKillStrategy extends RoleStrategy {
  const MessyBitchKillStrategy();

  @override
  String get roleId => RoleIds.messyBitchKill;

  @override
  bool canAct(Player player, int dayCount) {
    // Messy Bitch can kill once per game (optional night action)
    return player.isActive && !player.messyBitchKillUsed;
  }

  @override
  ScriptStep buildStep(Player player, int dayCount) {
    return ScriptStep(
      id: '${RoleIds.messyBitch}_kill_${player.id}_$dayCount',
      title: 'THE MESSY BITCH - KILL',
      readAloudText:
          'Messy Bitch, do you wish to use your one-time kill tonight?',
      instructionText:
          'OPTIONAL: SELECT A PLAYER TO KILL, OR SKIP.',
      actionType: ScriptActionType.selectPlayer,
      roleId: RoleIds.messyBitch,
      isOptional: true,
    );
  }
}

// ═══════════════════════════════════════════════
//  STRATEGY REGISTRY
// ═══════════════════════════════════════════════

const Map<String, RoleStrategy> roleStrategies = {
  RoleIds.dealer: DealerStrategy(),
  RoleIds.silverFox: SilverFoxStrategy(),
  RoleIds.whore: WhoreStrategy(),
  RoleIds.sober: SoberStrategy(),
  RoleIds.roofi: RoofiStrategy(),
  RoleIds.bouncer: BouncerStrategy(),
  RoleIds.medic: MedicStrategy(),
  RoleIds.bartender: BartenderStrategy(),
  RoleIds.lightweight: LightweightStrategy(),
  RoleIds.messyBitch: MessyBitchStrategy(),
  RoleIds.clubManager: ClubManagerStrategy(),
  RoleIds.clinger: AttackDogStrategy(),
  RoleIds.attackDog: AttackDogStrategy(),
  RoleIds.messyBitchKill: MessyBitchKillStrategy(),
};
