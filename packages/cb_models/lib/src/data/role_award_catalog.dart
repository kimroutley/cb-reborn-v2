import '../persistence/role_awards.dart';
import '../role.dart';
import '../role_ids.dart';
import 'role_catalog.dart';

/// Canonical role-award definitions (Phase 1).
///
/// Source-of-truth naming/icon metadata is authored in
/// `docs/features/awards/name-icon-catalog.md`.
final Map<String, List<RoleAwardDefinition>> roleAwardCatalogByRoleId = {
  for (final role in roleCatalog) role.id: _awardDefinitionsForRole(role),
};

List<RoleAwardDefinition> roleAwardsForRoleId(String roleId) {
  return roleAwardCatalogByRoleId[roleId] ?? const <RoleAwardDefinition>[];
}

List<RoleAwardDefinition> allRoleAwardDefinitions() {
  return roleAwardCatalogByRoleId.values
      .expand((definitions) => definitions)
      .toList(growable: false);
}

bool isKnownRoleAwardIconSource(String source) {
  return _iconSourceUrls.containsKey(source.trim());
}

List<String> roleAwardDefinitionsWithUnknownIconSource() {
  return allRoleAwardDefinitions()
      .where(
        (definition) =>
            !isKnownRoleAwardIconSource(definition.iconSource ?? ''),
      )
      .map((definition) => definition.awardId)
      .toList(growable: false);
}

RoleAwardDefinition? roleAwardDefinitionById(String awardId) {
  for (final definition in allRoleAwardDefinitions()) {
    if (definition.awardId == awardId) {
      return definition;
    }
  }
  return null;
}

bool hasFinalizedRoleAwards(String roleId) {
  return roleAwardsForRoleId(roleId).isNotEmpty;
}

List<String> rolesMissingAwardDefinitions([List<Role>? roles]) {
  final roleList = roles ?? roleCatalog;
  final missing = <String>[];
  for (final role in roleList) {
    if (!hasFinalizedRoleAwards(role.id)) {
      missing.add(role.id);
    }
  }
  return missing;
}

String _sanitizeAwardSlug(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

List<RoleAwardDefinition> _awardDefinitionsForRole(Role role) {
  final seeds = _awardSeedsByRoleId[role.id] ?? const <_RoleAwardSeed>[];
  if (seeds.isEmpty) {
    return _defaultRoleAwardLadder(role);
  }

  return List<RoleAwardDefinition>.generate(seeds.length, (index) {
    final seed = seeds[index];
    final unlockRule = _unlockRuleForRoleAward(role.id, index, seed.tier);
    final iconMetadata = _iconMetadataForSeed(seed);
    return RoleAwardDefinition(
      awardId: '${role.id}_${seed.tier.name}_${_sanitizeAwardSlug(seed.title)}',
      roleId: role.id,
      tier: seed.tier,
      title: seed.title,
      description: _descriptionForRule(role, unlockRule),
      unlockRule: unlockRule,
      iconKey: seed.iconKey,
      iconSource: seed.iconSource,
      iconLicense: seed.iconLicense,
      iconAuthor: iconMetadata.iconAuthor,
      attributionText: iconMetadata.attributionText,
      iconUrl: iconMetadata.iconUrl,
    );
  }, growable: false);
}

_ResolvedIconMetadata _iconMetadataForSeed(_RoleAwardSeed seed) {
  final normalizedSource = seed.iconSource.trim();
  final normalizedLicense = seed.iconLicense.trim();
  final sourceUrl = isKnownRoleAwardIconSource(normalizedSource)
      ? _iconSourceUrls[normalizedSource]
      : null;

  final requiresAttribution = normalizedLicense.toLowerCase().contains('cc by');
  final iconAuthor = requiresAttribution ? 'Unknown' : null;
  final attributionText = requiresAttribution
      ? 'Icon by ${iconAuthor!} via $normalizedSource ($normalizedLicense)'
      : null;

  return _ResolvedIconMetadata(
    iconAuthor: iconAuthor,
    attributionText: attributionText,
    iconUrl: sourceUrl,
  );
}

Map<String, dynamic> _unlockRuleForRoleAward(
  String roleId,
  int index,
  RoleAwardTier tier,
) {
  final profile = _unlockProfilesByRoleId[roleId];
  if (profile != null && index >= 0 && index < profile.length) {
    final rule = profile[index];
    return <String, dynamic>{'metric': rule.metric, 'minimum': rule.minimum};
  }
  return _defaultUnlockRule(tier, index);
}

String _descriptionForRule(Role role, Map<String, dynamic> unlockRule) {
  final minimumRaw = unlockRule['minimum'];
  final minimum = minimumRaw is num ? minimumRaw.toInt() : 1;
  final metric = (unlockRule['metric'] as String? ?? 'gamesPlayed').trim();

  switch (metric) {
    case 'wins':
    case 'gamesWon':
      return 'Win $minimum games as ${role.name}.';
    case 'survivals':
    case 'gamesSurvived':
      return 'Survive $minimum games as ${role.name}.';
    case 'gamesPlayed':
    default:
      return 'Play $minimum games as ${role.name}.';
  }
}

Map<String, dynamic> _defaultUnlockRule(RoleAwardTier tier, int index) {
  switch (tier) {
    case RoleAwardTier.rookie:
      return const <String, dynamic>{'metric': 'gamesPlayed', 'minimum': 1};
    case RoleAwardTier.pro:
      return const <String, dynamic>{'metric': 'gamesPlayed', 'minimum': 3};
    case RoleAwardTier.legend:
      return const <String, dynamic>{'metric': 'wins', 'minimum': 1};
    case RoleAwardTier.bonus:
      if (index == 3) {
        return const <String, dynamic>{'metric': 'gamesPlayed', 'minimum': 5};
      }
      return const <String, dynamic>{'metric': 'survivals', 'minimum': 3};
  }
}

List<RoleAwardDefinition> _defaultRoleAwardLadder(Role role) {
  final rookieRule = _unlockRuleForRoleAward(role.id, 0, RoleAwardTier.rookie);
  final proRule = _unlockRuleForRoleAward(role.id, 1, RoleAwardTier.pro);
  final legendRule = _unlockRuleForRoleAward(role.id, 2, RoleAwardTier.legend);
  final bonusOneRule = _unlockRuleForRoleAward(role.id, 3, RoleAwardTier.bonus);
  final bonusTwoRule = _unlockRuleForRoleAward(role.id, 4, RoleAwardTier.bonus);

  return <RoleAwardDefinition>[
    RoleAwardDefinition(
      awardId: '${role.id}_rookie_first_shift',
      roleId: role.id,
      tier: RoleAwardTier.rookie,
      title: '${role.name}: First Shift',
      description: _descriptionForRule(role, rookieRule),
      unlockRule: rookieRule,
    ),
    RoleAwardDefinition(
      awardId: '${role.id}_pro_clocked_in',
      roleId: role.id,
      tier: RoleAwardTier.pro,
      title: '${role.name}: Clocked In',
      description: _descriptionForRule(role, proRule),
      unlockRule: proRule,
    ),
    RoleAwardDefinition(
      awardId: '${role.id}_legend_house_legend',
      roleId: role.id,
      tier: RoleAwardTier.legend,
      title: '${role.name}: House Legend',
      description: _descriptionForRule(role, legendRule),
      unlockRule: legendRule,
    ),
    RoleAwardDefinition(
      awardId: '${role.id}_bonus_overtime',
      roleId: role.id,
      tier: RoleAwardTier.bonus,
      title: '${role.name}: Overtime',
      description: _descriptionForRule(role, bonusOneRule),
      unlockRule: bonusOneRule,
    ),
    RoleAwardDefinition(
      awardId: '${role.id}_bonus_after_hours',
      roleId: role.id,
      tier: RoleAwardTier.bonus,
      title: '${role.name}: After Hours',
      description: _descriptionForRule(role, bonusTwoRule),
      unlockRule: bonusTwoRule,
    ),
  ];
}

class _UnlockRuleSeed {
  const _UnlockRuleSeed({required this.metric, required this.minimum});

  final String metric;
  final int minimum;
}

const Map<String, List<_UnlockRuleSeed>> _unlockProfilesByRoleId = {
  RoleIds.dealer: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 6),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
  ],
  RoleIds.whore: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
  ],
  RoleIds.silverFox: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.partyAnimal: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 4),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 9),
  ],
  RoleIds.medic: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.bouncer: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
  ],
  RoleIds.roofi: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
  ],
  RoleIds.sober: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.wallflower: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.allyCat: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 6),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
  ],
  RoleIds.minor: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.seasonedDrinker: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 9),
    _UnlockRuleSeed(metric: 'survivals', minimum: 6),
  ],
  RoleIds.lightweight: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 4),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
  ],
  RoleIds.teaSpiller: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
  ],
  RoleIds.predator: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
  ],
  RoleIds.dramaQueen: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
  ],
  RoleIds.bartender: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'wins', minimum: 5),
  ],
  RoleIds.messyBitch: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 4),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 9),
  ],
  RoleIds.clubManager: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.clinger: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'survivals', minimum: 4),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
  ],
  RoleIds.secondWind: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'wins', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 7),
    _UnlockRuleSeed(metric: 'survivals', minimum: 5),
  ],
  RoleIds.creep: <_UnlockRuleSeed>[
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 1),
    _UnlockRuleSeed(metric: 'wins', minimum: 2),
    _UnlockRuleSeed(metric: 'wins', minimum: 4),
    _UnlockRuleSeed(metric: 'survivals', minimum: 3),
    _UnlockRuleSeed(metric: 'gamesPlayed', minimum: 8),
  ],
};

class _RoleAwardSeed {
  const _RoleAwardSeed({
    required this.tier,
    required this.title,
    required this.iconKey,
    required this.iconSource,
    required this.iconLicense,
  });

  final RoleAwardTier tier;
  final String title;
  final String iconKey;
  final String iconSource;
  final String iconLicense;
}

class _ResolvedIconMetadata {
  const _ResolvedIconMetadata({
    this.iconAuthor,
    this.attributionText,
    this.iconUrl,
  });

  final String? iconAuthor;
  final String? attributionText;
  final String? iconUrl;
}

const Map<String, String> _iconSourceUrls = {
  'Phosphor': 'https://phosphoricons.com/',
  'Tabler': 'https://tabler.io/icons',
  'Heroicons': 'https://heroicons.com/',
  'Material Symbols': 'https://fonts.google.com/icons',
  'Game-Icons': 'https://game-icons.net/',
};

const Map<String, List<_RoleAwardSeed>> _awardSeedsByRoleId = {
  RoleIds.dealer: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'First Pour',
      iconKey: 'knife',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Last Call Hitman',
      iconKey: 'target',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Velvet Guillotine',
      iconKey: 'swords',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Clean Exit',
      iconKey: 'door-open',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: "Dealer's Choice",
      iconKey: 'cards',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.whore: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Scapegoat Starter',
      iconKey: 'users-three',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Deflection Specialist',
      iconKey: 'arrow-bend-up-left',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Vote Houdini',
      iconKey: 'sparkles',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'One-Time Miracle',
      iconKey: 'hourglass-high',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Puppet Strings',
      iconKey: 'gesture-click',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.silverFox: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Paper Alibi',
      iconKey: 'badge-check',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Untouchable Noon',
      iconKey: 'shield-check',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Golden Cover Story',
      iconKey: 'star',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Foxfire',
      iconKey: 'flame',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Daylight Immunity',
      iconKey: 'wb-sunny',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.partyAnimal: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Still Standing',
      iconKey: 'person-simple-run',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Crowd Favorite',
      iconKey: 'users',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Neon Survivor',
      iconKey: 'bolt',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'No Ability, No Problem',
      iconKey: 'smiley',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Dance Floor General',
      iconKey: 'music-note',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.medic: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Pulse Check',
      iconKey: 'heartbeat',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Night Shift Nurse',
      iconKey: 'medical-cross',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Defibrillator Deity',
      iconKey: 'heart-plus',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Surgical Save',
      iconKey: 'bandage',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Miracle Worker',
      iconKey: 'ecg-heart',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.bouncer: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'ID Please',
      iconKey: 'identification',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Door Policy',
      iconKey: 'shield',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Human Lie Detector',
      iconKey: 'scan-eye',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Wristband Authority',
      iconKey: 'ticket',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Backroom Intel',
      iconKey: 'binoculars',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.roofi: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Silent Sip',
      iconKey: 'glass-water',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Mute Button',
      iconKey: 'microphone-slash',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Paralysis Protocol',
      iconKey: 'hand-stop',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Kill Switch',
      iconKey: 'toggle-left',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Quiet Riot',
      iconKey: 'bell-slash',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.sober: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Cut Off',
      iconKey: 'wine',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Safe Ride Home',
      iconKey: 'car',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Designated Savior',
      iconKey: 'shield-half',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Dry Night',
      iconKey: 'moon-stars',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Hard Stop',
      iconKey: 'do-not-disturb-on',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.wallflower: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Nosy Neighbor',
      iconKey: 'eye',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Professional Snitch',
      iconKey: 'binoculars',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Night Shift Manager',
      iconKey: 'visibility',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Wrong Place, Right Time',
      iconKey: 'shield-check',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Receipts',
      iconKey: 'clipboard-list',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.allyCat: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Nine Lives, One Braincell',
      iconKey: 'cat',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Meow Intelligence',
      iconKey: 'chat-bubble-left-right',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Feline Informant',
      iconKey: 'paw-print',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Landed on Feet',
      iconKey: 'arrow-down-circle',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Purrfect Read',
      iconKey: 'eye-check',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.minor: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Fake ID Energy',
      iconKey: 'id-card',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Protected by Policy',
      iconKey: 'shield-lock',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Untouchable Until Checked',
      iconKey: 'verified-user',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Too Young to Die',
      iconKey: 'baby',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Plot Armor',
      iconKey: 'shield-star',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.seasonedDrinker: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'First Hangover',
      iconKey: 'beer-bottle',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Built Different',
      iconKey: 'biceps-flexed',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Bottomless Constitution',
      iconKey: 'battery-full',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Last One Upright',
      iconKey: 'person-standing',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Iron Liver',
      iconKey: 'shield-plus',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.lightweight: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Taboo Trouble',
      iconKey: 'warning',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Name Minefield',
      iconKey: 'bomb',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Verbal Tightrope',
      iconKey: 'wave-sine',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Lips Sealed',
      iconKey: 'mouth',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'One Wrong Name',
      iconKey: 'x-circle',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.teaSpiller: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Hot Gossip',
      iconKey: 'teapot',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Final Sip Reveal',
      iconKey: 'eye-search',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Scalding Truth',
      iconKey: 'fire',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Spill on Exit',
      iconKey: 'door-exit',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Receipt Queen',
      iconKey: 'receipt',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.predator: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Cornered Bite',
      iconKey: 'teeth',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Retaliation Ready',
      iconKey: 'crosshair',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Deadly Last Word',
      iconKey: 'skull',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'If I Go, You Go',
      iconKey: 'arrows-exchange',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Apex on Exile',
      iconKey: 'mountain',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.dramaQueen: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Scene Starter',
      iconKey: 'masks-theater',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Role Swap Scandal',
      iconKey: 'switch-horizontal',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Curtain Call Chaos',
      iconKey: 'theaters',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Vendetta Vogue',
      iconKey: 'sparkles',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Encore Betrayal',
      iconKey: 'repeat',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.bartender: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'First Mix',
      iconKey: 'martini',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Alignment on the Rocks',
      iconKey: 'balance-scale',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Master of Pairings',
      iconKey: 'glass-cocktail',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Shaken, Not Fooled',
      iconKey: 'shake',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'House Special Intel',
      iconKey: 'flask-conical',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.messyBitch: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Rumour Starter Pack',
      iconKey: 'megaphone',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Whisper Network',
      iconKey: 'messages',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Chaos Curator',
      iconKey: 'storm',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Everybody Heard',
      iconKey: 'volume-2',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Rumour Mill Maxed',
      iconKey: 'hub',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.clubManager: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Floor Check',
      iconKey: 'clipboard-check',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Eyes Everywhere',
      iconKey: 'eye',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: "Owner's Ledger",
      iconKey: 'book-open',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Self-Preservation',
      iconKey: 'life-buoy',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'After-Hours Audit',
      iconKey: 'schedule',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
  RoleIds.clinger: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Velcro Soul',
      iconKey: 'link',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Ride or Die',
      iconKey: 'heart-handshake',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Attack Dog Unleashed',
      iconKey: 'dog',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Bonded Fate',
      iconKey: 'infinity',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Breakup Violence',
      iconKey: 'heart-break',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.secondWind: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Not Dead Yet',
      iconKey: 'heartbeat',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Conversion Pending',
      iconKey: 'refresh',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Twice-Born Menace',
      iconKey: 'autorenew',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Refused the Offer',
      iconKey: 'hand-raised',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Back from Blackout',
      iconKey: 'sunrise',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
  ],
  RoleIds.creep: <_RoleAwardSeed>[
    _RoleAwardSeed(
      tier: RoleAwardTier.rookie,
      title: 'Shadow Copy',
      iconKey: 'copy',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.pro,
      title: 'Mimic Mode',
      iconKey: 'user-circle',
      iconSource: 'Phosphor',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.legend,
      title: 'Inheritance Predator',
      iconKey: 'dna',
      iconSource: 'Tabler',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Night Zero Stalker',
      iconKey: 'moon',
      iconSource: 'Heroicons',
      iconLicense: 'MIT',
    ),
    _RoleAwardSeed(
      tier: RoleAwardTier.bonus,
      title: 'Identity Thief',
      iconKey: 'person-swap',
      iconSource: 'Material Symbols',
      iconLicense: 'Apache-2.0',
    ),
  ],
};
