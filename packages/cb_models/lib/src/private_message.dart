import 'package:freezed_annotation/freezed_annotation.dart';

part 'private_message.freezed.dart';
part 'private_message.g.dart';

@freezed
abstract class PrivateMessage with _$PrivateMessage {
  const factory PrivateMessage({
    required String id,
    required String message,
    required DateTime timestamp,
    @Default(false) bool isRead,
    String? title,
    String? icon,
  }) = _PrivateMessage;

  factory PrivateMessage.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageFromJson(json);
}
