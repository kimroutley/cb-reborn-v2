enum RoleAwardTier {
  rookie,
  pro,
  legend,
  bonus,
}

enum RoleAwardScope {
  role,
  scenario,
  allStar,
}

class RoleAwardDefinition {
  const RoleAwardDefinition({
    required this.awardId,
    required this.roleId,
    required this.tier,
    required this.title,
    required this.description,
    this.unlockRule = const <String, dynamic>{},
    this.iconKey,
    this.iconSource,
    this.iconLicense,
    this.iconAuthor,
    this.attributionText,
    this.iconUrl,
    this.scope = RoleAwardScope.role,
    this.toneVariant,
  });

  final String awardId;
  final String roleId;
  final RoleAwardTier tier;
  final String title;
  final String description;
  final Map<String, dynamic> unlockRule;
  final String? iconKey;
  final String? iconSource;
  final String? iconLicense;
  final String? iconAuthor;
  final String? attributionText;
  final String? iconUrl;
  final RoleAwardScope scope;
  final String? toneVariant;

  RoleAwardDefinition copyWith({
    String? awardId,
    String? roleId,
    RoleAwardTier? tier,
    String? title,
    String? description,
    Map<String, dynamic>? unlockRule,
    String? iconKey,
    String? iconSource,
    String? iconLicense,
    String? iconAuthor,
    String? attributionText,
    String? iconUrl,
    RoleAwardScope? scope,
    String? toneVariant,
  }) {
    return RoleAwardDefinition(
      awardId: awardId ?? this.awardId,
      roleId: roleId ?? this.roleId,
      tier: tier ?? this.tier,
      title: title ?? this.title,
      description: description ?? this.description,
      unlockRule: unlockRule ?? this.unlockRule,
      iconKey: iconKey ?? this.iconKey,
      iconSource: iconSource ?? this.iconSource,
      iconLicense: iconLicense ?? this.iconLicense,
      iconAuthor: iconAuthor ?? this.iconAuthor,
      attributionText: attributionText ?? this.attributionText,
      iconUrl: iconUrl ?? this.iconUrl,
      scope: scope ?? this.scope,
      toneVariant: toneVariant ?? this.toneVariant,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'awardId': awardId,
      'roleId': roleId,
      'tier': tier.name,
      'title': title,
      'description': description,
      'unlockRule': unlockRule,
      'iconKey': iconKey,
      'iconSource': iconSource,
      'iconLicense': iconLicense,
      'iconAuthor': iconAuthor,
      'attributionText': attributionText,
      'iconUrl': iconUrl,
      'scope': scope.name,
      'toneVariant': toneVariant,
    };
  }

  static RoleAwardDefinition fromJson(Map<String, dynamic> json) {
    return RoleAwardDefinition(
      awardId: json['awardId'] as String? ?? '',
      roleId: json['roleId'] as String? ?? '',
      tier: RoleAwardTier.values.firstWhere(
        (value) => value.name == json['tier'],
        orElse: () => RoleAwardTier.bonus,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      unlockRule:
          (json['unlockRule'] as Map?)?.cast<String, dynamic>() ?? const {},
      iconKey: json['iconKey'] as String?,
      iconSource: json['iconSource'] as String?,
      iconLicense: json['iconLicense'] as String?,
      iconAuthor: json['iconAuthor'] as String?,
      attributionText: json['attributionText'] as String?,
      iconUrl: json['iconUrl'] as String?,
      scope: RoleAwardScope.values.firstWhere(
        (value) => value.name == json['scope'],
        orElse: () => RoleAwardScope.role,
      ),
      toneVariant: json['toneVariant'] as String?,
    );
  }
}

class PlayerRoleAwardProgress {
  const PlayerRoleAwardProgress({
    required this.playerKey,
    required this.awardId,
    this.progressValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.sourceGameId,
    this.sourceSessionId,
  });

  final String playerKey;
  final String awardId;
  final int progressValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? sourceGameId;
  final String? sourceSessionId;

  PlayerRoleAwardProgress copyWith({
    String? playerKey,
    String? awardId,
    int? progressValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? sourceGameId,
    String? sourceSessionId,
  }) {
    return PlayerRoleAwardProgress(
      playerKey: playerKey ?? this.playerKey,
      awardId: awardId ?? this.awardId,
      progressValue: progressValue ?? this.progressValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      sourceGameId: sourceGameId ?? this.sourceGameId,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'playerKey': playerKey,
      'awardId': awardId,
      'progressValue': progressValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'sourceGameId': sourceGameId,
      'sourceSessionId': sourceSessionId,
    };
  }

  static PlayerRoleAwardProgress fromJson(Map<String, dynamic> json) {
    final unlockedRaw = json['unlockedAt'] as String?;
    return PlayerRoleAwardProgress(
      playerKey: json['playerKey'] as String? ?? '',
      awardId: json['awardId'] as String? ?? '',
      progressValue: (json['progressValue'] as num?)?.toInt() ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: unlockedRaw == null ? null : DateTime.tryParse(unlockedRaw),
      sourceGameId: json['sourceGameId'] as String?,
      sourceSessionId: json['sourceSessionId'] as String?,
    );
  }
}
