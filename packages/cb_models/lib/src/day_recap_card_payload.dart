import 'dart:convert';

class DayRecapCardPayload {
  final int v;
  final int day;
  final String playerTitle;
  final List<String> playerBullets;
  final String hostTitle;
  final List<String> hostBullets;

  const DayRecapCardPayload({
    required this.v,
    required this.day,
    required this.playerTitle,
    required this.playerBullets,
    required this.hostTitle,
    required this.hostBullets,
  });

  Map<String, dynamic> toJson() => {
        'v': v,
        'day': day,
        'playerTitle': playerTitle,
        'playerBullets': playerBullets,
        'hostTitle': hostTitle,
        'hostBullets': hostBullets,
      };

  factory DayRecapCardPayload.fromJson(Map<String, dynamic> json) {
    return DayRecapCardPayload(
      v: json['v'] as int? ?? 1,
      day: json['day'] as int? ?? 0,
      playerTitle: json['playerTitle'] as String? ?? '',
      playerBullets: (json['playerBullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hostTitle: json['hostTitle'] as String? ?? '',
      hostBullets: (json['hostBullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static DayRecapCardPayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = DayRecapCardPayload.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (payload.v != 1) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }
}
