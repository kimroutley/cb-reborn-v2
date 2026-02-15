import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Role Model Tests', () {
    const fullRole = Role(
      id: 'medic',
      name: 'Medic',
      alliance: Team.partyAnimals,
      type: 'protective',
      description: 'Can save one person each night.',
      nightPriority: 10,
      complexity: 2,
      tacticalTip: 'Try to be random.',
      hasBinaryChoiceAtStart: true,
      choices: ['p1', 'p2'],
      ability: 'Heal',
      startAlliance: Team.partyAnimals,
      deathAlliance: Team.partyAnimals,
      assetPath: 'assets/medic.png',
      colorHex: '#FFFFFF',
      canRepeat: true,
      isRequired: true,
    );

    const minimalRole = Role(
      id: 'villager',
      name: 'Villager',
      type: 'plain',
      description: 'Just a villager.',
      nightPriority: 0,
      assetPath: 'assets/villager.png',
      colorHex: '#000000',
    );

    test('Serialization (toJson/fromJson) works correctly for full object', () {
      final json = fullRole.toJson();
      final decodedRole = Role.fromJson(json);

      expect(decodedRole, equals(fullRole));
      expect(decodedRole.id, 'medic');
      expect(decodedRole.name, 'Medic');
      expect(decodedRole.alliance, Team.partyAnimals);
      expect(decodedRole.type, 'protective');
      expect(decodedRole.description, 'Can save one person each night.');
      expect(decodedRole.nightPriority, 10);
      expect(decodedRole.complexity, 2);
      expect(decodedRole.tacticalTip, 'Try to be random.');
      expect(decodedRole.hasBinaryChoiceAtStart, true);
      expect(decodedRole.choices, ['p1', 'p2']);
      expect(decodedRole.ability, 'Heal');
      expect(decodedRole.startAlliance, Team.partyAnimals);
      expect(decodedRole.deathAlliance, Team.partyAnimals);
      expect(decodedRole.assetPath, 'assets/medic.png');
      expect(decodedRole.colorHex, '#FFFFFF');
      expect(decodedRole.canRepeat, true);
      expect(decodedRole.isRequired, true);
    });

    test('Serialization (toJson/fromJson) works correctly for minimal object (defaults)', () {
      final json = minimalRole.toJson();
      final decodedRole = Role.fromJson(json);

      expect(decodedRole, equals(minimalRole));
      expect(decodedRole.alliance, Team.unknown); // Default
      expect(decodedRole.complexity, 3); // Default
      expect(decodedRole.tacticalTip, ""); // Default
      expect(decodedRole.hasBinaryChoiceAtStart, false); // Default
      expect(decodedRole.choices, isEmpty); // Default
      expect(decodedRole.ability, isNull); // Default
      expect(decodedRole.startAlliance, isNull); // Default
      expect(decodedRole.deathAlliance, isNull); // Default
      expect(decodedRole.canRepeat, false); // Default
      expect(decodedRole.isRequired, false); // Default
    });

    test('copyWith creates a new instance with updated fields', () {
      final updatedRole = minimalRole.copyWith(
        name: 'Super Villager',
        complexity: 5,
      );

      expect(updatedRole.name, 'Super Villager');
      expect(updatedRole.complexity, 5);
      expect(updatedRole.id, minimalRole.id); // Should be unchanged
    });

    test('Equality and HashCode work correctly', () {
      final role1 = Role(
        id: 'medic',
        name: 'Medic',
        type: 'protective',
        description: 'Desc',
        nightPriority: 10,
        assetPath: 'path',
        colorHex: '#FFF',
      );

      final role2 = Role(
        id: 'medic',
        name: 'Medic',
        type: 'protective',
        description: 'Desc',
        nightPriority: 10,
        assetPath: 'path',
        colorHex: '#FFF',
      );

      final role3 = Role(
        id: 'medic',
        name: 'Other Medic', // Different name
        type: 'protective',
        description: 'Desc',
        nightPriority: 10,
        assetPath: 'path',
        colorHex: '#FFF',
      );

      expect(role1, equals(role2));
      expect(role1.hashCode, equals(role2.hashCode));
      expect(role1, isNot(equals(role3)));
    });
  });
}
