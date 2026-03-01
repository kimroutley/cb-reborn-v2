import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulletin_entry.freezed.dart';
part 'bulletin_entry.g.dart';

@freezed
abstract class BulletinEntry with _$BulletinEntry {
  const factory BulletinEntry({
    required String id,
    required String title,
    required String content,
    @Default('info') String type, // 'info', 'action', 'result', 'urgent', 'hostIntel'
    required DateTime timestamp,
    String? roleId,
    @Default(false) bool isHostOnly,
    /// When set, only players with this role see the message (e.g. host message to Dealers only).
    String? targetRoleId,
  }) = _BulletinEntry;

  factory BulletinEntry.fromJson(Map<String, dynamic> json) =>
      _$BulletinEntryFromJson(json);
}
