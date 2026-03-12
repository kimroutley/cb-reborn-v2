import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulletin_entry.freezed.dart';
part 'bulletin_entry.g.dart';

/// Delivery status for WhatsApp-style ticks on messages.
enum MessageDeliveryStatus {
  /// Message sent by the player (pending delivery to host).
  sent,

  /// Message delivered to the host / server.
  delivered,

  /// Message seen / acknowledged by the host.
  seen,
}

@freezed
abstract class BulletinEntry with _$BulletinEntry {
  const factory BulletinEntry({
    required String id,
    required String title,
    required String content,
    @Default('info') String type, // 'info', 'action', 'result', 'urgent', 'chat', 'action_confirmation'
    required DateTime timestamp,
    String? roleId,
    String? targetRoleId,

    /// When set, this message is only visible to the player with this ID.
    String? targetPlayerId,
    @Default(false) bool isHostOnly,

    /// Delivery status for player-sent messages (WhatsApp-style ticks).
    @Default(MessageDeliveryStatus.sent) MessageDeliveryStatus deliveryStatus,
  }) = _BulletinEntry;

  factory BulletinEntry.fromJson(Map<String, dynamic> json) =>
      _$BulletinEntryFromJson(json);
}
