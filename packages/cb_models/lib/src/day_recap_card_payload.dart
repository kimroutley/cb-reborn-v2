import 'dart:convert';

/// Player-safe day recap payload (public, synced to players).
///
/// Contains only redacted/anonymous content — no real player names or roles.
class DayRecapCardPayload {
  /// Schema version — start at 1.
  final int v;

  /// Stable dedup key, e.g. `day-2-recap-v1`.
  final String recapId;

  /// The day number that was resolved.
  final int day;

  /// Headline shown above bullets (e.g. "DAY 2 RECAP").
  final String title;

  /// Redacted bullet-point strings safe for players.
  final List<String> bullets;

  /// Epoch millis when generated.
  final int generatedAtMs;

  const DayRecapCardPayload({
    required this.v,
    required this.recapId,
    required this.day,
    required this.title,
    required this.bullets,
    required this.generatedAtMs,
  });

  Map<String, dynamic> toJson() => {
        'v': v,
        'recapId': recapId,
        'day': day,
        'title': title,
        'bullets': bullets,
        'generatedAtMs': generatedAtMs,
      };

  factory DayRecapCardPayload.fromJson(Map<String, dynamic> json) {
    return DayRecapCardPayload(
      v: json['v'] as int? ?? 1,
      recapId: json['recapId'] as String? ?? '',
      day: json['day'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      bullets: (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      generatedAtMs: json['generatedAtMs'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// Safe parser — returns null on any failure or unsupported version.
  static DayRecapCardPayload? tryParse(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final payload = DayRecapCardPayload.fromJson(map);
      if (payload.v < 1 || payload.v > 1) return null; // reject unknown version
      return payload;
    } catch (_) {
      return null;
    }
  }
}
