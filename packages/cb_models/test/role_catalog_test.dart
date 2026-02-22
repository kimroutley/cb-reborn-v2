import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Role Catalog Data Integrity', () {
    test('All role IDs should be unique', () {
      final ids = roleCatalog.map((r) => r.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, equals(ids.length), reason: 'Duplicate Role IDs found');
    });

    test('All roles should have valid hex color codes', () {
      final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (final role in roleCatalog) {
        expect(
          hexColorRegex.hasMatch(role.colorHex),
          isTrue,
          reason: 'Role ${role.id} has invalid color hex: ${role.colorHex}',
        );
      }
    });

    test('All roles should have non-empty mandatory fields', () {
      for (final role in roleCatalog) {
        expect(role.id, isNotEmpty, reason: 'Role has empty ID');
        expect(role.name, isNotEmpty, reason: 'Role ${role.id} has empty name');
        expect(role.description, isNotEmpty, reason: 'Role ${role.id} has empty description');
        expect(role.type, isNotEmpty, reason: 'Role ${role.id} has empty type');
        expect(role.assetPath, isNotEmpty, reason: 'Role ${role.id} has empty assetPath');
        expect(role.colorHex, isNotEmpty, reason: 'Role ${role.id} has empty colorHex');

        // checking ability is present for all catalog roles as per pattern
        expect(role.ability, isNotNull, reason: 'Role ${role.id} has null ability');
        expect(role.ability, isNotEmpty, reason: 'Role ${role.id} has empty ability');
      }
    });

    test('All roles should have valid night priority', () {
        for (final role in roleCatalog) {
             expect(role.nightPriority, greaterThanOrEqualTo(0), reason: 'Role ${role.id} has negative night priority');
        }
    });
  });
}
