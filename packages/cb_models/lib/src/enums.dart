import 'package:json_annotation/json_annotation.dart';

import 'role_ids.dart';

@JsonEnum()
enum GamePhase {
  lobby,
  setup,
  night,
  day,
  resolution,
  endGame,
}

@JsonEnum()
enum SyncMode {
  local,
  cloud,
}

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
          RoleIds.partyAnimal
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
          RoleIds.partyAnimal
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
          RoleIds.partyAnimal
        ];
      case GameStyle.manual:
        return []; // Host chooses roles directly.
      case GameStyle.chaos:
        return []; // Empty means all roles
    }
  }
}
