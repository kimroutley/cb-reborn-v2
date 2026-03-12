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
  anythingGoes, // Completely random after base roles
  politicalMF, // Defensive/neutral roles, Party Animal-favoured
  wtf, // More Dealer allies, reactive players, Dealer-favoured
  manual, // Host assigns all roles manually
}

extension GameStyleExtension on GameStyle {
  String get label {
    switch (this) {
      case GameStyle.anythingGoes:
        return 'ANYTHING GOES';
      case GameStyle.politicalMF:
        return 'POLITICAL MIND F**K';
      case GameStyle.wtf:
        return 'WTF';
      case GameStyle.manual:
        return 'MANUAL';
    }
  }

  String get description {
    switch (this) {
      case GameStyle.anythingGoes:
        return 'Completely random roles after the base are filled. One role per player, overflow becomes Party Animals.';
      case GameStyle.politicalMF:
        return 'Defensive & neutral roles. Odds favour the Party Animals, but the right cast can swing it.';
      case GameStyle.wtf:
        return 'More Dealer allies, reactive players. Odds are stacked for the Dealers.';
      case GameStyle.manual:
        return 'Host assigns every role before setup starts.';
    }
  }

  /// The pool of role IDs available for this game style.
  ///
  /// Base roles (Dealer, Medic, Bouncer, Party Animal) are always assigned
  /// first by the algorithm regardless of this pool. The pool only controls
  /// which *extra* roles can fill remaining player slots.
  ///
  /// An empty pool means either all roles (anythingGoes) or host-selected
  /// (manual).
  List<String> get rolePool {
    switch (this) {
      case GameStyle.anythingGoes:
        return []; // Empty = all non-base roles are eligible
      case GameStyle.politicalMF:
        // Defensive, protective, tank, investigative, neutral — NO offensive,
        // NO reactive, NO extra dealer-staff allies (Whore, Silver Fox).
        return [
          RoleIds.sober,
          RoleIds.minor,
          RoleIds.seasonedDrinker,
          RoleIds.allyCat,
          RoleIds.secondWind,
          RoleIds.messyBitch,
          RoleIds.clubManager,
          RoleIds.clinger,
          RoleIds.creep,
          RoleIds.bartender,
          RoleIds.lightweight,
          RoleIds.wallflower,
        ];
      case GameStyle.wtf:
        // Staff allies + reactive roles — stacks odds for the Dealers.
        return [
          RoleIds.whore,
          RoleIds.silverFox,
          RoleIds.roofi,
          RoleIds.teaSpiller,
          RoleIds.predator,
          RoleIds.dramaQueen,
          RoleIds.secondWind,
          RoleIds.lightweight,
          RoleIds.messyBitch,
        ];
      case GameStyle.manual:
        return []; // Host chooses roles directly.
    }
  }
}

@JsonEnum()
enum TieBreakStrategy {
  @JsonValue("peaceful")
  peaceful, // No one exiled on tie
  @JsonValue("random")
  random, // Random tied player exiled
  @JsonValue("bloodbath")
  bloodbath, // Everyone tied is exiled
  @JsonValue("silent")
  silentTreatment, // No one exiled, but all tied are silenced tomorrow
}

extension TieBreakStrategyExtension on TieBreakStrategy {
  String get label {
    switch (this) {
      case TieBreakStrategy.peaceful:
        return 'PEACEFUL';
      case TieBreakStrategy.random:
        return 'CHAOTIC';
      case TieBreakStrategy.bloodbath:
        return 'BLOODBATH';
      case TieBreakStrategy.silentTreatment:
        return 'SILENT TREATMENT';
    }
  }

  String get description {
    switch (this) {
      case TieBreakStrategy.peaceful:
        return 'NO EXILE ON TIE. ROOM STAYS STABLE.';
      case TieBreakStrategy.random:
        return 'RANDOM TIED OPERATIVE IS TERMINATED.';
      case TieBreakStrategy.bloodbath:
        return 'ALL TIED OPERATIVES ARE TERMINATED.';
      case TieBreakStrategy.silentTreatment:
        return 'NO EXILE, BUT TIED OPERATIVES LOSE VOICE.';
    }
  }
}
