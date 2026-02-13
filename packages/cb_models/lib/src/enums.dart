import 'package:json_annotation/json_annotation.dart';

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
          'dealer',
          'whore',
          'roofi',
          'predator',
          'drama_queen',
          'tea_spiller',
          'messy_bitch',
          'party_animal'
        ];
      case GameStyle.defensive:
        return [
          'dealer',
          'silver_fox',
          'medic',
          'sober',
          'minor',
          'seasoned_drinker',
          'bouncer',
          'second_wind',
          'party_animal'
        ];
      case GameStyle.reactive:
        return [
          'dealer',
          'silver_fox',
          'bouncer',
          'wallflower',
          'ally_cat',
          'bartender',
          'tea_spiller',
          'lightweight',
          'club_manager',
          'creep',
          'party_animal'
        ];
      case GameStyle.chaos:
        return []; // Empty means all roles
    }
  }
}
