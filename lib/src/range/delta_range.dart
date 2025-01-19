/// Represents a range of character positions within a [Delta] operation.
///
/// This class defines a range using global offsets and provides
/// utility methods for creating and validating ranges, as well as
/// checking for overlaps between different ranges.
class DeltaRange {
  /// The starting position of the range in global offset terms.
  final int startOffset;

  /// The ending position of the range in global offset terms.
  /// A value of `-1` indicates an undefined end.
  final int endOffset;

  const DeltaRange({
    required this.startOffset,
    required this.endOffset,
  }) : assert(
          endOffset == -1 || endOffset >= startOffset,
          'endOffset must be equal to or greater than startOffset',
        );

  /// Creates a `DeltaRange` with only a starting offset, setting the end offset to `-1`.
  ///
  /// This is useful when the end of the range is not yet defined.
  factory DeltaRange.onlyStartPoint({
    required int startOffset,
  }) {
    return DeltaRange(startOffset: startOffset, endOffset: -1);
  }

  /// Creates a `DeltaRange` from given start and end offsets, or returns `null`
  /// if the inputs are invalid.
  ///
  /// Returns `null` if either [start] or [end] are negative.
  static DeltaRange? deltaRangeOrNull(int start, int end) {
    if (start < 0 || end < 0) return null;
    return DeltaRange(startOffset: start, endOffset: end);
  }

  /// Checks if the range has the same start and end offsets.
  ///
  /// Returns `true` if [startOffset] equals [endOffset], indicating an empty range.
  bool get hasSameOffset => startOffset == endOffset;

  /// Checks if there is any overlap with another [DeltaRange].
  ///
  /// - [strictPartial]: Determines if partial overlaps should be considered.
  ///   If `true`, touching edges are treated as overlaps.
  ///
  /// Returns `true` if the ranges overlap or touch (depending on [strictPartial]).
  ///
  /// ## Examples
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 0, endOffset: 50);
  /// final selectedRange = DeltaRange(startOffset: 20, endOffset: 30);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // true > is overlapped;
  /// ```
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 0, endOffset: 50);
  /// final selectedRange = DeltaRange(startOffset: 50, endOffset: 55);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // true > is overlapped partially;
  /// ignorePart.checkOverlapOfRanges(selectedRange, false) // false > is not overlapped;
  /// ```
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 30, endOffset: 50);
  /// final selectedRange = DeltaRange(startOffset: 30, endOffset: 40);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // true > is overlapped;
  /// ```
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 30, endOffset: 50);
  /// final selectedRange = DeltaRange(startOffset: 10, endOffset: 29);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // false > is not overlapped;
  /// ```
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 10, endOffset: 15);
  /// final selectedRange = DeltaRange(startOffset: 15, endOffset: 20);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // true > is overlapped partially;
  /// ignorePart.checkOverlapOfRanges(selectedRange, false) // false > is not overlapped;
  /// ```
  ///
  /// ```dart
  /// final ignorePart = DeltaRange(startOffset: 50, endOffset: 55);
  /// final selectedRange = DeltaRange(startOffset: 30, endOffset: 50);
  /// ignorePart.checkOverlapOfRanges(selectedRange) // true > is overlapped partially;
  /// ignorePart.checkOverlapOfRanges(selectedRange, false) // false > is not overlapped;
  /// ```
  bool checkOverlapOfRanges(DeltaRange otherPart, [bool strictPartial = true]) {
    // Check if the two ranges are the same instance
    if (this == otherPart || identical(this, otherPart)) return true;

    // Check for exact match with same offset but different end
    if (otherPart.hasSameOffset && otherPart.endOffset > endOffset)
      return false;

    // Get limits of the current range
    final localStartOffset = startOffset;
    final localEndOffset = endOffset == -1 ? double.infinity : endOffset;

    // Get limits of the other range
    final otherStartOffset = otherPart.startOffset;
    final otherEndOffset =
        otherPart.endOffset == -1 ? double.infinity : otherPart.endOffset;

    // Check for overlap or touching edges
    return (otherStartOffset >= localStartOffset &&
            otherEndOffset <= localEndOffset) || // Fully contained
        (strictPartial
            ? (otherStartOffset <= localEndOffset &&
                otherEndOffset >= localStartOffset)
            : (otherStartOffset < localEndOffset &&
                otherEndOffset >
                    localStartOffset)); // Partial or touching overlap
  }

  @override
  String toString() {
    return 'DeltaRange(start: $startOffset, end: $endOffset)';
  }

  @override
  bool operator ==(covariant DeltaRange other) {
    if (identical(other, this)) return true;
    return other.startOffset == startOffset && other.endOffset == endOffset;
  }

  @override
  int get hashCode => startOffset.hashCode ^ endOffset.hashCode;
}
