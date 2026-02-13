import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulletin_entry.freezed.dart';
part 'bulletin_entry.g.dart';

@freezed
abstract class BulletinEntry with _$BulletinEntry {
  const factory BulletinEntry({
    required String id,
    required String title,
    required String content,
    @Default('info') String type, // 'info', 'action', 'result', 'urgent'
    required DateTime timestamp,
    String? roleId,
  }) = _BulletinEntry;

  factory BulletinEntry.fromJson(Map<String, dynamic> json) =>
      _$BulletinEntryFromJson(json);
}
