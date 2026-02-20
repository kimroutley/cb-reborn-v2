import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prepareRecentBuildUpdates sorts newest first and limits to three', () {
    final updates = [
      AppBuildUpdate(
        version: '1.0.0',
        buildNumber: '10',
        releaseDate: DateTime(2026, 2, 10),
        highlights: const ['A'],
      ),
      AppBuildUpdate(
        version: '1.0.3',
        buildNumber: '13',
        releaseDate: DateTime(2026, 2, 18),
        highlights: const ['B'],
      ),
      AppBuildUpdate(
        version: '1.0.1',
        buildNumber: '11',
        releaseDate: DateTime(2026, 2, 12),
        highlights: const ['C'],
      ),
      AppBuildUpdate(
        version: '1.0.2',
        buildNumber: '12',
        releaseDate: DateTime(2026, 2, 16),
        highlights: const ['D'],
      ),
    ];

    final recent = AppReleaseNotes.prepareRecentBuildUpdates(updates);

    expect(recent, hasLength(3));
    expect(recent[0].buildNumber, '13');
    expect(recent[1].buildNumber, '12');
    expect(recent[2].buildNumber, '11');
  });
}
