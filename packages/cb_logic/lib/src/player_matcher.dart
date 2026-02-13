/// Utility for matching player names across games and detecting duplicates.
class PlayerMatcher {
  PlayerMatcher._();

  /// Canonicalize a name for fuzzy matching (lowercase, trimmed, no special chars).
  static String canonicalizeName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Calculate Levenshtein distance between two strings.
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final prev = List<int>.filled(len2 + 1, 0);
    final curr = List<int>.filled(len2 + 1, 0);

    for (var j = 0; j <= len2; j++) {
      prev[j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      curr[0] = i;
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1, // insertion
          prev[j] + 1, // deletion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j <= len2; j++) {
        prev[j] = curr[j];
      }
    }

    return curr[len2];
  }

  /// Check if two names are likely the same person.
  /// Returns true if canonicalized names match or Levenshtein distance < 3.
  static bool isLikelyMatch(String name1, String name2) {
    final canon1 = canonicalizeName(name1);
    final canon2 = canonicalizeName(name2);

    // Exact match after canonicalization
    if (canon1 == canon2) return true;

    // Fuzzy match with Levenshtein distance
    final distance = _levenshteinDistance(canon1, canon2);
    return distance < 3;
  }

  /// Find duplicate groups in a list of names.
  /// Returns a map of canonical name -> list of variant names.
  static Map<String, List<String>> findDuplicates(List<String> names) {
    final duplicates = <String, List<String>>{};
    final processedIndices = <int>{};

    for (var i = 0; i < names.length; i++) {
      if (processedIndices.contains(i)) continue;

      final name1 = names[i];
      final matches = <String>[name1];
      processedIndices.add(i);

      for (var j = i + 1; j < names.length; j++) {
        if (processedIndices.contains(j)) continue;

        final name2 = names[j];
        if (isLikelyMatch(name1, name2)) {
          matches.add(name2);
          processedIndices.add(j);
        }
      }

      // Only include groups with more than one name
      if (matches.length > 1) {
        // Use the first name as the canonical key
        duplicates[name1] = matches;
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
