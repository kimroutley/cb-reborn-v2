import 'package:json_annotation/json_annotation.dart';

import 'role_ids.dart';

@JsonEnum()
enum GamePhase { lobby, setup, night, day, resolution, endGame }

@JsonEnum()
enum SyncMode { local, cloud }

enum Team {
  @JsonValue("The Dealers")
  clubStaff, // Renamed display name to "The Dealers" (Killers)

  @JsonValue("The Party Animals")
  partyAnimals, // (Innocent)

  @JsonValue("Wildcards")
  neutral, // Renamed display name to "Wildcards" (Variables)

  @JsonValue("Unknown")
  unknown,
}

@JsonEnum()
enum GameStyle {
  offensive, // "Blood Bath" - high kill/aggression
  defensive, // "Last One Standing" - high protection/tank
  reactive, // "Whodunit" - high investigation/information
  manual, // Host assigns all roles manually
  chaos, // "Free For All" - all 22 roles possible
}

extension GameStyleExtension on GameStyle {
  String get label {
    switch (this) {
      case GameStyle.offensive:
        return 'BLOOD_BATH';
      case GameStyle.defensive:
        return 'POLITICAL';
      case GameStyle.reactive:
        return 'CHAOS';
      case GameStyle.manual:
        return 'MANUAL';
      case GameStyle.chaos:
        return 'FREE_FOR_ALL';
    }
  }

  String get description {
    switch (this) {
      case GameStyle.offensive:
        return 'High aggression. More kills, less protection.';
      case GameStyle.defensive:
        return 'Strategic social play with balanced pressure.';
      case GameStyle.reactive:
        return 'Guide CHAOS mode with weighted disruptive roles.';
      case GameStyle.manual:
        return 'Host assigns every role before setup starts.';
      case GameStyle.chaos:
        return 'Legacy full random from all available roles.';
    }
  }

  List<String> get rolePool {
    switch (this) {
      case GameStyle.offensive:
        return [
          RoleIds.dealer,
          RoleIds.whore,
          RoleIds.roofi,
          RoleIds.predator,
          RoleIds.dramaQueen,
          RoleIds.teaSpiller,
          RoleIds.messyBitch,
          RoleIds.partyAnimal,
        ];
      case GameStyle.defensive:
        return [
          RoleIds.dealer,
          RoleIds.silverFox,
          RoleIds.medic,
          RoleIds.sober,
          RoleIds.minor,
          RoleIds.seasonedDrinker,
          RoleIds.bouncer,
          RoleIds.secondWind,
          RoleIds.partyAnimal,
        ];
      case GameStyle.reactive:
        return [
          RoleIds.dealer,
          RoleIds.silverFox,
          RoleIds.bouncer,
          RoleIds.wallflower,
          RoleIds.allyCat,
          RoleIds.bartender,
          RoleIds.teaSpiller,
          RoleIds.lightweight,
          RoleIds.clubManager,
          RoleIds.creep,
          RoleIds.partyAnimal,
        ];
      case GameStyle.manual:
        return []; // Host chooses roles directly.
      case GameStyle.chaos:
        return []; // Empty means all roles
    }
  }
}

@JsonEnum()
enum TieBreakStrategy {
  peaceful, // No one is exiled on tie.
  random, // A random player from the tied group is exiled.
  bloodbath, // Everyone in the tie is exiled.
  dealerMercy, // Dealer's vote breaks the tie. Falls back to peaceful if no dealer vote.
  silentTreatment, // Tied players are silenced for the next day.
}

extension TieBreakStrategyExtension on TieBreakStrategy {
  String get label {
    switch (this) {
      case TieBreakStrategy.peaceful:
        return 'PEACEFUL';
      case TieBreakStrategy.random:
        return 'RANDOM';
      case TieBreakStrategy.bloodbath:
        return 'BLOODBATH';
      case TieBreakStrategy.dealerMercy:
        return 'DEALER MERCY';
      case TieBreakStrategy.silentTreatment:
        return 'SILENT TREATMENT';
    }
  }

  String get description {
    switch (this) {
      case TieBreakStrategy.peaceful:
        return 'No one is exiled on a tie.';
      case TieBreakStrategy.random:
        return 'A random player from the tied group is exiled.';
      case TieBreakStrategy.bloodbath:
        return 'Everyone involved in the tie is exiled.';
      case TieBreakStrategy.dealerMercy:
        return 'Dealer vote breaks ties. Falls back to Peaceful.';
      case TieBreakStrategy.silentTreatment:
        return 'Tied players are silenced for the next day.';
    }
  }
}
