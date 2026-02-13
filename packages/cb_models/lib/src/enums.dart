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
enum SyncMode {
  local, // WebSocket based
  cloud, // Firebase Firestore based
}

@JsonEnum()
enum GameStyle {
  offensive, // "Blood Bath" - high kill/aggression
  defensive, // "Last One Standing" - high protection/tank
  reactive, // "Whodunit" - high investigation/information
  chaos, // "Free For All" - all 22 roles possible
}

extension GameStyleExtension on GameStyle {
  String get label {
    switch (this) {
      case GameStyle.offensive:
        return 'BLOOD BATH';
      case GameStyle.defensive:
        return 'LAST STAND';
      case GameStyle.reactive:
        return 'WHODUNIT';
      case GameStyle.chaos:
        return 'CHAOS';
    }
  }

  String get description {
    switch (this) {
      case GameStyle.offensive:
        return 'High aggression. More kills, less protection.';
      case GameStyle.defensive:
        return 'Endurance match. High defense and survival.';
      case GameStyle.reactive:
        return 'Information is key. Heavy on investigation.';
      case GameStyle.chaos:
        return 'Anything goes. The full 22-role catalog.';
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
      case GameStyle.chaos:
        return []; // Empty means all roles
    }
  }
}
