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
          'Dealers and associates, wake up and choose a player to eliminate.',
      instructionText: 'SELECT A TARGET TO ELIMINATE',
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
      readAloudText: 'Silver Fox, wake up and choose someone to give an alibi.',
      instructionText: 'SELECT A PLAYER TO GRANT IMMUNITY FROM VOTING',
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
      readAloudText: 'Dealers and associates, wake up and choose your target.',
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
      readAloudText: 'Sober, wake up and choose a player to investigate.',
      instructionText: 'SELECT A PLAYER TO BLOCK TONIGHT',
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
      readAloudText: 'Roofi, wake up and slip the drink.',
      instructionText: 'SELECT A PLAYER TO SILENCE TOMORROW',
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
      readAloudText: 'Bouncer, wake up and check a player\'s ID.',
      instructionText: 'SELECT A PLAYER TO CHECK ALLIANCE',
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
        ? 'Medic, wake up and choose someone to revive.'
        : 'Medic, wake up and choose someone to protect.';

    final instruction = player.medicChoice == 'REVIVE'
        ? 'SELECT A DEAD PLAYER TO REVIVE'
        : 'SELECT A PLAYER TO PROTECT FROM MURDER';

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
      readAloudText: 'Bartender, wake up and choose two players to compare.',
      instructionText: 'SELECT TWO PLAYERS TO CHECK ALIGNMENT',
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
      readAloudText: 'Lightweight, wake up. A new name is now taboo.',
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
      readAloudText: 'Messy Bitch, wake up and start a rumour.',
      instructionText: 'SELECT A PLAYER TO START A RUMOR ABOUT',
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
          'Club Manager, wake up and secretly look at a player\'s card.',
      instructionText: 'SELECT A PLAYER TO INSPECT THEIR ROLE CARD',
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
      instructionText: 'OPTIONAL: SELECT A PLAYER TO KILL, OR SKIP.',
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
