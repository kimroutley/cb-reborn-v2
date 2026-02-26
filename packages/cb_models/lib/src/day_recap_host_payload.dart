import 'dart:convert';

/// Host-only day recap payload (never synced to players).
///
/// Contains unredacted names, roles, votes, and spicy commentary.
class DayRecapHostPayload {
  /// Schema version — start at 1.
  final int v;

  /// Stable dedup key, e.g. `day-2-recap-host-v1`.
  final String recapId;

  /// The day number that was resolved.
  final int day;

  /// Headline (e.g. "DAY 2 RECAP (HOST)").
  final String title;

  /// Unredacted host-spicy bullets (may include names, roles, votes).
  final List<String> bullets;

  /// Epoch millis when generated.
  final int generatedAtMs;

  const DayRecapHostPayload({
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

  factory DayRecapHostPayload.fromJson(Map<String, dynamic> json) {
    return DayRecapHostPayload(
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
  static DayRecapHostPayload? tryParse(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final payload = DayRecapHostPayload.fromJson(map);
      if (payload.v < 1 || payload.v > 1) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }
}
