// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:cb_models/cb_models.dart';

void main() {
  test('Benchmark role lookup performance', () {
    // Use the exported map from the package
    expect(roleCatalogMap, isNotNull);
    expect(roleCatalogMap.length, roleCatalog.length);

    final stopwatch = Stopwatch();
    const iterations = 100000;

    // Test data: mixture of valid and invalid IDs
    final testIds = [
      'dealer', // First item
      'party_animal', // Middle item
      'creep', // Last item
      'non_existent_role', // Not found (worst case for linear search)
      null, // Null check
    ];

    // ignore: avoid_print
    print('Benchmarking $iterations iterations per lookup type...');

    // 1. Measure Linear Search (Current implementation)
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      for (final id in testIds) {
        final _ = roleCatalog.firstWhere(
          (r) => r.id == id,
          orElse: () => roleCatalog.first,
        );
      }
    }
    stopwatch.stop();
    final linearTime = stopwatch.elapsedMicroseconds;
    // ignore: avoid_print
    print('Linear Search Time: ${linearTime / 1000} ms');

    // 2. Measure Map Lookup (Proposed optimization)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      for (final id in testIds) {
        final _ = roleCatalogMap[id] ?? roleCatalog.first;
      }
    }
    stopwatch.stop();
    final mapTime = stopwatch.elapsedMicroseconds;
    // ignore: avoid_print
    print('Map Lookup Time:    ${mapTime / 1000} ms');

    // Calculate improvement
    final improvement = (linearTime - mapTime) / linearTime * 100;
    // ignore: avoid_print
    print('Improvement: ${improvement.toStringAsFixed(2)}%');

    // Assert that the optimization is actually faster
    // Note: On very fast machines or small datasets, overhead might skew results,
    // but for 100k iterations it should be measurable.
    expect(mapTime, lessThan(linearTime), reason: "Map lookup should be faster than linear search");
  });
}
