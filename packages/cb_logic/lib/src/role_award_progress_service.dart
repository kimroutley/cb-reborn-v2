import 'package:cb_models/cb_models.dart';

class RoleAwardCoverageSummary {
  const RoleAwardCoverageSummary({
    required this.totalRoles,
    required this.rolesWithDefinitions,
    required this.rolesWithPlaceholders,
  });

  final int totalRoles;
  final int rolesWithDefinitions;
  final int rolesWithPlaceholders;

  int get rolesMissingAnyCoverage {
    final covered = rolesWithDefinitions + rolesWithPlaceholders;
    final missing = totalRoles - covered;
    return missing < 0 ? 0 : missing;
  }
}

class RoleAwardProgressService {
  const RoleAwardProgressService();

  RoleAwardCoverageSummary buildCoverageSummary() {
    final totalRoles = roleCatalog.length;
    var rolesWithDefinitions = 0;
    var rolesWithPlaceholders = 0;

    for (final role in roleCatalog) {
      if (hasFinalizedRoleAwards(role.id)) {
        rolesWithDefinitions++;
        continue;
      }
      if (roleAwardPlaceholderRegistry.containsKey(role.id)) {
        rolesWithPlaceholders++;
      }
    }

    return RoleAwardCoverageSummary(
      totalRoles: totalRoles,
      rolesWithDefinitions: rolesWithDefinitions,
      rolesWithPlaceholders: rolesWithPlaceholders,
    );
  }

  bool roleUsesPlaceholder(String roleId) {
    return !hasFinalizedRoleAwards(roleId) &&
        roleAwardPlaceholderRegistry.containsKey(roleId);
  }

  List<RoleAwardDefinition> roleDefinitionsOrEmpty(String roleId) {
    return roleAwardsForRoleId(roleId);
  }
}
