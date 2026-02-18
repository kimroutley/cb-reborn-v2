import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every canonical role has a full baseline award ladder', () {
    final missing = rolesMissingAwardDefinitions();
    expect(missing, isEmpty);

    for (final role in roleCatalog) {
      final definitions = roleAwardsForRoleId(role.id);
      expect(definitions.length, 5);
      expect(definitions.any((d) => d.tier == RoleAwardTier.rookie), true);
      expect(definitions.any((d) => d.tier == RoleAwardTier.pro), true);
      expect(definitions.any((d) => d.tier == RoleAwardTier.legend), true);
      expect(
        definitions.where((d) => d.tier == RoleAwardTier.bonus).length,
        2,
      );
      expect(definitions.every((d) => d.roleId == role.id), true);
    }
  });

  test('award id lookup resolves generated definitions', () {
    final sampleRole = roleCatalog.first;
    final definition = roleAwardsForRoleId(sampleRole.id).first;
    final lookedUp = roleAwardDefinitionById(definition.awardId);

    expect(lookedUp, isNotNull);
    expect(lookedUp!.awardId, definition.awardId);
    expect(lookedUp.roleId, sampleRole.id);
  });

  test('role ladders include deterministic role-specific metrics', () {
    final dealer = roleAwardsForRoleId(RoleIds.dealer);
    expect(dealer.length, 5);
    expect(dealer[1].unlockRule['metric'], 'wins');
    expect(dealer[1].unlockRule['minimum'], 2);
    expect(dealer[4].unlockRule['metric'], 'survivals');
    expect(dealer[4].unlockRule['minimum'], 3);

    final wallflower = roleAwardsForRoleId(RoleIds.wallflower);
    expect(wallflower.length, 5);
    expect(wallflower[1].unlockRule['metric'], 'survivals');
    expect(wallflower[1].unlockRule['minimum'], 3);
    expect(wallflower[2].unlockRule['metric'], 'wins');
    expect(wallflower[2].unlockRule['minimum'], 3);
  });

  test('descriptions align with metric-driven unlock rules', () {
    final roofi = roleAwardsForRoleId(RoleIds.roofi);
    expect(roofi, isNotEmpty);

    final winAward = roofi.firstWhere(
      (definition) => definition.unlockRule['metric'] == 'wins',
    );
    final survivalAward = roofi.firstWhere(
      (definition) => definition.unlockRule['metric'] == 'survivals',
    );

    expect(winAward.description, contains('Win '));
    expect(survivalAward.description, contains('Survive '));
  });

  test('icon metadata is complete for finalized role awards', () {
    final definitions = allRoleAwardDefinitions();
    expect(definitions, isNotEmpty);

    for (final definition in definitions) {
      expect(definition.iconKey, isNotNull,
          reason: '${definition.awardId} missing iconKey');
      expect(definition.iconKey, isNotEmpty,
          reason: '${definition.awardId} iconKey is empty');

      expect(definition.iconSource, isNotNull,
          reason: '${definition.awardId} missing iconSource');
      expect(definition.iconSource, isNotEmpty,
          reason: '${definition.awardId} iconSource is empty');

      expect(definition.iconLicense, isNotNull,
          reason: '${definition.awardId} missing iconLicense');
      expect(definition.iconLicense, isNotEmpty,
          reason: '${definition.awardId} iconLicense is empty');

      expect(definition.iconUrl, isNotNull,
          reason: '${definition.awardId} missing iconUrl');
      expect(definition.iconUrl, isNotEmpty,
          reason: '${definition.awardId} iconUrl is empty');
    }
  });

  test('attribution metadata is present for CC-BY licenses', () {
    for (final definition in allRoleAwardDefinitions()) {
      final license = (definition.iconLicense ?? '').toLowerCase();
      if (!license.contains('cc by')) {
        continue;
      }

      expect(definition.iconAuthor, isNotNull,
          reason: '${definition.awardId} missing iconAuthor for CC-BY icon');
      expect(definition.iconAuthor, isNotEmpty,
          reason: '${definition.awardId} has empty iconAuthor for CC-BY icon');

      expect(definition.attributionText, isNotNull,
          reason:
              '${definition.awardId} missing attributionText for CC-BY icon');
      expect(definition.attributionText, isNotEmpty,
          reason:
              '${definition.awardId} has empty attributionText for CC-BY icon');
    }
  });
}
