import 'dart:convert';

import 'package:flutter/services.dart';

class AppBuildUpdate {
  const AppBuildUpdate({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.highlights,
  });

  final String version;
  final String buildNumber;
  final DateTime releaseDate;
  final List<String> highlights;

  factory AppBuildUpdate.fromJson(Map<String, dynamic> json) {
    return AppBuildUpdate(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      highlights: (json['highlights'] as List<dynamic>).cast<String>(),
    );
  }
}

class AppReleaseNotes {
  static Future<List<AppBuildUpdate>> loadRecentBuildUpdates({
    int maxEntries = 3,
  }) async {
    final raw = await rootBundle.loadString(
      'packages/cb_models/lib/src/data/app_recent_builds.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    final updates = decoded
        .map((entry) => AppBuildUpdate.fromJson(entry as Map<String, dynamic>))
        .toList();
    return prepareRecentBuildUpdates(updates, maxEntries: maxEntries);
  }

  static List<AppBuildUpdate> prepareRecentBuildUpdates(
    List<AppBuildUpdate> updates, {
    int maxEntries = 3,
  }) {
    final sorted = [...updates]
      ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

    if (maxEntries < 1) {
      return const [];
    }

    return List<AppBuildUpdate>.unmodifiable(sorted.take(maxEntries));
  }
}
