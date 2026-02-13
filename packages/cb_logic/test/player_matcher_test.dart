import 'package:cb_logic/cb_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerMatcher', () {
    // ═══════════════════════════════════════════════
    //  Canonicalize Name
    // ═══════════════════════════════════════════════
    group('canonicalizeName', () {
      test('trims whitespace', () {
        expect(PlayerMatcher.canonicalizeName('  Bob  '), 'bob');
      });

      test('converts to lowercase', () {
        expect(PlayerMatcher.canonicalizeName('ALICE'), 'alice');
      });

      test('removes special characters', () {
        expect(PlayerMatcher.canonicalizeName('Bob-Smith_123!'), 'bobsmith123');
      });

      test('handles empty string', () {
        expect(PlayerMatcher.canonicalizeName(''), '');
      });

      test('handles string with only special characters', () {
        expect(PlayerMatcher.canonicalizeName('!@#\$%'), '');
      });
    });

    // ═══════════════════════════════════════════════
    //  Is Likely Match (Fuzzy Logic)
    // ═══════════════════════════════════════════════
    group('isLikelyMatch', () {
      test('matches exact strings', () {
        expect(PlayerMatcher.isLikelyMatch('Alice', 'Alice'), isTrue);
      });

      test('matches case-insensitive strings', () {
        expect(PlayerMatcher.isLikelyMatch('Alice', 'alice'), isTrue);
      });

      test('matches strings with special characters differences', () {
        expect(PlayerMatcher.isLikelyMatch('Alice!', 'Alice'), isTrue);
      });

      test('matches with Levenshtein distance 1 (substitution)', () {
        // "Alice" vs "Alicee" -> distance 1 (insertion)
        // "Alice" vs "Alic" -> distance 1 (deletion)
        // "Alice" vs "Alike" -> distance 1 (substitution)
        expect(PlayerMatcher.isLikelyMatch('Alice', 'Alike'), isTrue);
      });

      test('matches with Levenshtein distance 2', () {
        // "Alice" vs "Alicyy" -> distance 2
        expect(PlayerMatcher.isLikelyMatch('Alice', 'Alicyy'), isTrue);
      });

      test('does not match with Levenshtein distance 3', () {
        // "Alice" vs "Aliczzz" -> distance 3
        expect(PlayerMatcher.isLikelyMatch('Alice', 'Aliczzz'), isFalse);
      });

      test('does not match completely different strings', () {
        expect(PlayerMatcher.isLikelyMatch('Alice', 'Bob'), isFalse);
      });

      test('handles empty strings', () {
        // Two empty strings match
        expect(PlayerMatcher.isLikelyMatch('', ''), isTrue);
        // One empty, one short (length < 3) match?
        // Levenshtein distance between "" and "a" is 1 -> True
        expect(PlayerMatcher.isLikelyMatch('', 'a'), isTrue);
        // Levenshtein distance between "" and "abc" is 3 -> False
        expect(PlayerMatcher.isLikelyMatch('', 'abc'), isFalse);
      });
    });

    // ═══════════════════════════════════════════════
    //  Find Duplicates
    // ═══════════════════════════════════════════════
    group('findDuplicates', () {
      test('returns empty map for empty list', () {
        expect(PlayerMatcher.findDuplicates([]), isEmpty);
      });

      test('returns empty map for list with unique names', () {
        final names = ['Alice', 'Bob', 'Charlie'];
        expect(PlayerMatcher.findDuplicates(names), isEmpty);
      });

      test('detects exact duplicates', () {
        final names = ['Alice', 'Bob', 'Alice'];
        final duplicates = PlayerMatcher.findDuplicates(names);

        expect(duplicates.length, 1);
        expect(duplicates.keys.first, 'Alice');
        expect(duplicates['Alice'], unorderedEquals(['Alice', 'Alice']));
      });

      test('detects fuzzy duplicates', () {
        final names = ['Alice', 'Alike', 'Bob'];
        final duplicates = PlayerMatcher.findDuplicates(names);

        expect(duplicates.length, 1);
        expect(duplicates.keys.first, 'Alice');
        expect(duplicates['Alice'], unorderedEquals(['Alice', 'Alike']));
      });

      test('detects multiple groups of duplicates', () {
        final names = ['Alice', 'Alike', 'Bob', 'Bobby'];
        final duplicates = PlayerMatcher.findDuplicates(names);

        expect(duplicates.length, 2);
        expect(duplicates['Alice'], unorderedEquals(['Alice', 'Alike']));
        expect(duplicates['Bob'], unorderedEquals(['Bob', 'Bobby']));
      });

      test('handles triplicates', () {
        final names = ['Alice', 'Alike', 'Alic'];
        final duplicates = PlayerMatcher.findDuplicates(names);

        expect(duplicates.length, 1);
        expect(duplicates['Alice'], unorderedEquals(['Alice', 'Alike', 'Alic']));
      });
    });

    // ═══════════════════════════════════════════════
    //  Merge Counts
    // ═══════════════════════════════════════════════
    group('mergeCounts', () {
      test('returns original counts if mapping is empty', () {
        final counts = {'Alice': 1, 'Bob': 2};
        final merged = PlayerMatcher.mergeCounts(counts, {});

        expect(merged, counts);
      });

      test('merges counts based on mapping', () {
        final counts = {'Alice': 1, 'Alike': 2, 'Bob': 3};
        final mapping = {'Alike': 'Alice'};
        final merged = PlayerMatcher.mergeCounts(counts, mapping);

        expect(merged.length, 2);
        expect(merged['Alice'], 3); // 1 + 2
        expect(merged['Bob'], 3);
      });

      test('handles mapping where key is not in counts', () {
        final counts = {'Alice': 1};
        final mapping = {'Bob': 'Robert'}; // Bob is not in counts
        final merged = PlayerMatcher.mergeCounts(counts, mapping);

        expect(merged, counts);
      });

      test('handles complex merging', () {
        final counts = {'Alice': 1, 'Alic': 2, 'Bob': 5, 'Bobby': 1};
        final mapping = {'Alic': 'Alice', 'Bobby': 'Bob'};
        final merged = PlayerMatcher.mergeCounts(counts, mapping);

        expect(merged.length, 2);
        expect(merged['Alice'], 3);
        expect(merged['Bob'], 6);
      });
    });
  });
}
