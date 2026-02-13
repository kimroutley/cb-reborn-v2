import 'dart:convert';
import 'package:flutter/services.dart';

/// Strategy data loaded from JSON files
class StrategyData {
  /// Load base strategy content for all roles
  static Future<Map<String, RoleStrategy>> loadStrategyCatalog() async {
    final jsonString = await rootBundle.loadString(
      'packages/cb_models/lib/src/data/strategy_catalog.json',
    );
    final Map<String, dynamic> data = jsonDecode(jsonString);

    return data.map(
      (key, value) =>
          MapEntry(key, RoleStrategy.fromJson(value as Map<String, dynamic>)),
    );
  }

  /// Load conditional alerts
  static Future<List<StrategyAlert>> loadStrategyAlerts() async {
    final jsonString = await rootBundle.loadString(
      'packages/cb_models/lib/src/data/strategy_alerts.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);

    return data
        .map((alert) => StrategyAlert.fromJson(alert as Map<String, dynamic>))
        .toList();
  }
}

/// Strategy content for a single role
class RoleStrategy {
  final String roleId;
  final String overview;
  final String earlyGame;
  final String lateGame;
  final List<String> counters;
  final List<String> synergies;

  const RoleStrategy({
    required this.roleId,
    required this.overview,
    required this.earlyGame,
    required this.lateGame,
    required this.counters,
    required this.synergies,
  });

  factory RoleStrategy.fromJson(Map<String, dynamic> json) {
    return RoleStrategy(
      roleId: json['roleId'] as String,
      overview: json['overview'] as String,
      earlyGame: json['earlyGame'] as String,
      lateGame: json['lateGame'] as String,
      counters: (json['counters'] as List<dynamic>).cast<String>(),
      synergies: (json['synergies'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Conditional strategy alert
class StrategyAlert {
  final String id;
  final String condition;
  final int priority;
  final String type;
  final String text;

  const StrategyAlert({
    required this.id,
    required this.condition,
    required this.priority,
    required this.type,
    required this.text,
  });

  factory StrategyAlert.fromJson(Map<String, dynamic> json) {
    return StrategyAlert(
      id: json['id'] as String,
      condition: json['condition'] as String,
      priority: json['priority'] as int,
      type: json['type'] as String,
      text: json['text'] as String,
    );
  }
}

/// Player status information visible in strategy guide
class PlayerStatusSummary {
  final bool isAlive;
  final int? lives;
  final bool isSilenced;
  final bool hasRumour;
  final List<String> tabooNames;
  final String? clingerPartnerId;
  final bool pendingConversion;

  // Host-only fields
  final bool? isMuted;
  final bool? hasHostShield;
  final bool? isShadowBanned;
  final bool? isSinBinned;
  final bool? idCheckedByBouncer;
  final String? medicProtectedPlayerId;

  const PlayerStatusSummary({
    required this.isAlive,
    this.lives,
    required this.isSilenced,
    required this.hasRumour,
    required this.tabooNames,
    this.clingerPartnerId,
    required this.pendingConversion,
    this.isMuted,
    this.hasHostShield,
    this.isShadowBanned,
    this.isSinBinned,
    this.idCheckedByBouncer,
    this.medicProtectedPlayerId,
  });
}
