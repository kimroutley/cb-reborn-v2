import 'dart:math' as math;

/// Utility for matching player names across games and detecting duplicates.
class PlayerMatcher {
  PlayerMatcher._();

  /// Canonicalize a name for fuzzy matching (lowercase, trimmed, no special chars).
  static String canonicalizeName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Calculate Levenshtein distance between two strings with a threshold.
  /// Returns [threshold] + 1 if the distance is greater than or equal to [threshold].
  static int _levenshteinDistance(String s1, String s2, {int threshold = 3}) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // Optimization: if length difference is too big, distance is at least that diff
    if ((len1 - len2).abs() >= threshold) return threshold + 1;

    // We only need two rows
    var prev = List<int>.filled(len2 + 1, 0);
    var curr = List<int>.filled(len2 + 1, 0);

    for (var j = 0; j <= len2; j++) {
      prev[j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      curr[0] = i;
      var minDistance = i;

      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        final d1 = curr[j - 1] + 1; // insertion
        final d2 = prev[j] + 1; // deletion
        final d3 = prev[j - 1] + cost; // substitution

        final val = math.min(d1, math.min(d2, d3));
        curr[j] = val;
        minDistance = math.min(minDistance, val);
      }

      // Early exit if the minimum distance in this row exceeds threshold
      if (minDistance >= threshold) return threshold + 1;

      // Swap arrays
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[len2];
  }

  static bool _isLikelyMatchCanonical(String canon1, String canon2) {
    if (canon1 == canon2) return true;

    // Quick length check
    if ((canon1.length - canon2.length).abs() >= 3) return false;

    // Fuzzy match with Levenshtein distance < 3
    final distance = _levenshteinDistance(canon1, canon2, threshold: 3);
    return distance < 3;
  }

  /// Check if two names are likely the same person.
  /// Returns true if canonicalized names match or Levenshtein distance < 3.
  static bool isLikelyMatch(String name1, String name2) {
    final canon1 = canonicalizeName(name1);
    final canon2 = canonicalizeName(name2);
    return _isLikelyMatchCanonical(canon1, canon2);
  }

  /// Find duplicate groups in a list of names.
  /// Returns a map of canonical name -> list of variant names.
  static Map<String, List<String>> findDuplicates(List<String> names) {
    if (names.isEmpty) return {};

    final entries = List<_PlayerEntry>.generate(names.length,
        (i) => _PlayerEntry(i, names[i], canonicalizeName(names[i])));

    // Sort by length to optimize comparisons
    entries.sort((a, b) {
      final lenCompare = a.canon.length.compareTo(b.canon.length);
      if (lenCompare != 0) return lenCompare;
      return a.index.compareTo(b.index); // Stable sort by original index
    });

    final parent = List.generate(names.length, (i) => i);

    int find(int i) {
      if (parent[i] == i) return i;
      parent[i] = find(parent[i]);
      return parent[i];
    }

    void union(int i, int j) {
      final rootI = find(i);
      final rootJ = find(j);
      if (rootI != rootJ) {
        // Always attach larger index to smaller index to ensure
        // the "first" occurrence (smallest index) becomes the canonical key.
        if (rootI < rootJ) {
          parent[rootJ] = rootI;
        } else {
          parent[rootI] = rootJ;
        }
      }
    }

    for (var i = 0; i < entries.length; i++) {
      final entry1 = entries[i];

      for (var j = i + 1; j < entries.length; j++) {
        final entry2 = entries[j];

        // Optimization: if length diff >= 3, no need to check further
        // because the list is sorted by length.
        if (entry2.canon.length - entry1.canon.length >= 3) {
          break;
        }

        if (_isLikelyMatchCanonical(entry1.canon, entry2.canon)) {
          union(entry1.index, entry2.index);
        }
      }
    }

    // Group by root
    final groups = <int, List<String>>{};
    for (var i = 0; i < names.length; i++) {
      final root = find(i);
      groups.putIfAbsent(root, () => []).add(names[i]);
    }

    // Convert to result map (only groups > 1)
    final duplicates = <String, List<String>>{};
    for (final entry in groups.entries) {
      if (entry.value.length > 1) {
        // The key is the name at the root index (which is the smallest index in the group)
        final canonicalKey = names[entry.key];
        duplicates[canonicalKey] = entry.value;
      }
    }

    return duplicates;
  }

  /// Merge duplicate names in a map, choosing the canonical name.
  /// Returns a new map with merged counts.
  static Map<String, int> mergeCounts(
    Map<String, int> originalCounts,
    Map<String, String> mergeMapping, // variant -> canonical
  ) {
    final merged = <String, int>{};

    for (final entry in originalCounts.entries) {
      final name = entry.key;
      final count = entry.value;
      final canonical = mergeMapping[name] ?? name;

      merged[canonical] = (merged[canonical] ?? 0) + count;
    }

    return merged;
  }
}

class _PlayerEntry {
  final int index;
  final String original;
  final String canon;

  _PlayerEntry(this.index, this.original, this.canon);
}
