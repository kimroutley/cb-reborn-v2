import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'role.freezed.dart';
part 'role.g.dart';

@freezed
abstract class Role with _$Role {
  const factory Role({
    required String id,
    required String name,
    @Default(Team.unknown) Team alliance,
    required String type,
    required String description,
    required int nightPriority,
    @Default(3) int complexity, // 1-5 rating
    @Default("") String tacticalTip, // Pro strategy
    @Default(false) bool hasBinaryChoiceAtStart,
    @Default([]) List<String> choices,
    String? ability,
    Team? startAlliance,
    Team? deathAlliance,
    required String assetPath,
    required String colorHex,
    @Default(false) bool canRepeat,
    @Default(false) bool isRequired,
  }) = _Role;

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
}
