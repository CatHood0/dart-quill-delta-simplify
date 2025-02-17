import 'dart:math' as math;

import 'package:dart_quill_delta_simplify/delta_diff.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/string_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/join_strings.dart';
import 'package:meta/meta.dart';

/// Compares two text strings and detects the differences between them.
///
/// This method uses the **Longest Common Subsequence (LCS)** algorithm to identify
/// the changes between `oldText` (original text) and `newText` (new text).
/// It can detect the following types of changes:
///
/// * [insert]: Text present in `newText` but not in `oldText`.
/// * [delete]: Text that was in `oldText` but is not in `newText`.
/// * [equals]: Common parts present in both strings (these are not reported
///   but help to delimit the differences).
@internal
List<DeltaDiffPart> diff(String oldText, String newText) {
  final lcsMatrix = _buildLCSMatrix(oldText, newText);
  return _findChanges(oldText, newText, lcsMatrix);
}

/// Builds a Longest Common Subsequence (LCS) matrix for two input strings.
/// The LCS matrix is used to find the longest subsequence common to both strings.
/// This matrix is the foundation for detecting differences between two texts.
///
/// ### How it works:
/// 1. An **LCS matrix** is generated to find the longest common subsequences
///    between `oldText` and `newText`. This helps identify parts that remain the same
///    and delimit the areas where changes occurred.
/// 2. Based on the matrix, the indices in both strings are traced to determine:
///    - Which characters were deleted.
///    - Which characters were inserted.
/// 3. Changes are grouped into consecutive blocks (e.g., multiple added characters
///    together are reported as a single change).
///
/// Time Complexity: O(m * n), where `m` and `n` are the lengths of the two strings.
List<List<int>> _buildLCSMatrix(String oldText, String newText) {
  // 1. Determine the lengths of the two input strings.
  int m = oldText.length; // Length of the original string.
  int n = newText.length; // Length of the new string.

  // 2. Initialize a 2D list `lcsMatrix` with dimensions (m + 1) x (n + 1).
  // Each cell is initialized to 0. The extra row and column handle the base case
  // when comparing with an empty string.
  List<List<int>> lcsMatrix = List.generate(
    m + 1,
    (_) => List<int>.filled(n + 1, 0,
        growable: false), // Fill each row with zeros.
    growable: false, // The matrix itself is not growable.
  );

  // 3. Populate the LCS matrix using dynamic programming.
  // Iterate through each character of `oldText` (rows) and `newText` (columns).
  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      // 3.1. Check if the characters at the current indices match.
      if (oldText[i - 1] == newText[j - 1]) {
        // If they match, the LCS length increases by 1.
        // Update the current cell based on the diagonal value (top-left neighbor).
        lcsMatrix[i][j] = lcsMatrix[i - 1][j - 1] + 1;
      } else {
        // 3.2. If the characters don't match, take the maximum LCS length
        // from either the cell above or the cell to the left.
        lcsMatrix[i][j] = math.max(lcsMatrix[i - 1][j], lcsMatrix[i][j - 1]);
      }
    }
  }

  return lcsMatrix;
}

/// Identifies the changes (insertions or deletions) between two strings using the LCS matrix.
/// This method traces back through the LCS matrix to find differences between `oldText` and `newText`,
/// categorizing them as "insert" (characters added in `newText`) or "delete" (characters removed from `oldText`).
///
/// The process is based on analyzing how the LCS was built, comparing the `oldText` and `newText`
/// character by character while moving backward through the LCS matrix.
List<DeltaDiffPart> _findChanges(
    String oldText, String newText, List<List<int>> lcsMatrix) {
  // 1. Start from the bottom-right corner of the LCS matrix.
  int i = oldText.length; // Pointer for `oldText` (row index).
  int j = newText.length; // Pointer for `newText` (column index).

  // 2. Initialize a list to store the detected changes.
  List<DeltaDiffPart> changes = [];

  // 3. Traverse the LCS matrix in reverse (bottom to top, right to left).
  while (i > 0 || j > 0) {
    // 3.1. Check if the characters match (part of the LCS).
    if (i > 0 && j > 0 && oldText[i - 1] == newText[j - 1]) {
      // Characters match, part of the LCS (unchanged segment).
      int startI = i - 1;
      int startJ = j - 1;

      // Track consecutive matches (move diagonally up-left).
      while (i > 0 && j > 0 && oldText[i - 1] == newText[j - 1]) {
        i--;
        j--;
      }

      changes.add(DeltaDiffPart.equals(
        newText.substring(i, startI + 1),
        j,
        startJ,
      ));
    }
    // 3.2. Check if a character was added in `newText`.
    else if (j > 0 && (i == 0 || lcsMatrix[i][j - 1] >= lcsMatrix[i - 1][j])) {
      // Start tracking the added characters.
      int start = j - 1;
      // Continue moving left while there are additions.
      while (j > 0 && (i == 0 || lcsMatrix[i][j - 1] >= lcsMatrix[i - 1][j])) {
        j--;
      }
      changes.add(DeltaDiffPart.insert(
        oldText.substringOrNull(
            j, start + 1), // Substring from oldText (may be empty).
        newText.substring(
            j, start + 1), // Substring from newText (inserted text).
        j,
        start,
      ));
    }
    // 3.3. Check if a character was removed in `oldText`.
    else if (i > 0 && (j == 0 || lcsMatrix[i - 1][j] > lcsMatrix[i][j - 1])) {
      // Start tracking the removed characters.
      int start = i;
      // Track the word to be deleted by moving backwards until a space is found
      int wordStart = j;
      int wordEnd = start + 1;

      while (wordStart > 0 && oldText[wordStart - 1] != ' ') {
        wordStart--;
      }

      // Check first is we really need to search the end of the word
      if ((wordEnd) < oldText.length) {
        while (wordEnd < oldText.length && oldText[wordEnd] != ' ') {
          if (wordEnd + 1 < oldText.length) {
            if (oldText[wordEnd + 1] == '') {
              break;
            }
          }
          wordEnd++;
        }
      }

      // Continue moving up while there are deletions.
      while (i > 0 && (j == 0 || lcsMatrix[i - 1][j] > lcsMatrix[i][j - 1])) {
        i--;
      }

      final newEnd = (start - j).nonNegativeInt;

      changes.add(DeltaDiffPart.delete(
        oldText.substringOrNull(
            wordStart, wordEnd), // Substring from oldText (removed text).
        joinStrings(
          newText.substringOrNull(
            wordStart,
            start,
            true,
          ),
          newText.substringOrNull(
            start,
            (wordEnd - newEnd).nonNegativeInt,
            true,
          ),
        ),
        j, // removes from this
        start, // to this
      ));
    }
  }

  // 4. Reverse the changes list to ensure the changes are in logical order
  // (from the beginning of the strings to the end).
  return changes.reversed.toList();
}
