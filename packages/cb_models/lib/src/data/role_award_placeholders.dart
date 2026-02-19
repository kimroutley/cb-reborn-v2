import '../role_ids.dart';
import 'role_catalog.dart';

/// Canonical fallback copy used when a role ladder is not yet finalized.
const String awardsComingSoonLabel = 'Awards Coming Soon';

/// Phase 0 placeholder registry for role-specific awards.
///
/// Keep this list aligned with [roleCatalog].
const Map<String, String> roleAwardPlaceholderRegistry = {
  RoleIds.dealer: awardsComingSoonLabel,
  RoleIds.whore: awardsComingSoonLabel,
  RoleIds.silverFox: awardsComingSoonLabel,
  RoleIds.partyAnimal: awardsComingSoonLabel,
  RoleIds.medic: awardsComingSoonLabel,
  RoleIds.bouncer: awardsComingSoonLabel,
  RoleIds.roofi: awardsComingSoonLabel,
  RoleIds.sober: awardsComingSoonLabel,
  RoleIds.wallflower: awardsComingSoonLabel,
  RoleIds.allyCat: awardsComingSoonLabel,
  RoleIds.minor: awardsComingSoonLabel,
  RoleIds.seasonedDrinker: awardsComingSoonLabel,
  RoleIds.lightweight: awardsComingSoonLabel,
  RoleIds.teaSpiller: awardsComingSoonLabel,
  RoleIds.predator: awardsComingSoonLabel,
  RoleIds.dramaQueen: awardsComingSoonLabel,
  RoleIds.bartender: awardsComingSoonLabel,
  RoleIds.secondWind: awardsComingSoonLabel,
  RoleIds.messyBitch: awardsComingSoonLabel,
  RoleIds.clubManager: awardsComingSoonLabel,
  RoleIds.clinger: awardsComingSoonLabel,
  RoleIds.creep: awardsComingSoonLabel,
};

/// Role IDs in the canonical catalog with no placeholder/fallback entry.
List<String> missingRoleAwardPlaceholders() {
  final canonicalRoleIds = roleCatalog.map((role) => role.id).toSet();
  final placeholderRoleIds = roleAwardPlaceholderRegistry.keys.toSet();
  final missing = canonicalRoleIds.difference(placeholderRoleIds).toList()
    ..sort();
  return missing;
}

/// Whether the placeholder registry fully covers all canonical role IDs.
bool hasCompleteRoleAwardPlaceholderCoverage() {
  return missingRoleAwardPlaceholders().isEmpty;
}
