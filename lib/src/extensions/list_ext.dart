import 'package:meta/meta.dart';
import '../../delta_ranges.dart';

/// Extension on `List<DeltaRange>` that provides additional functionality
/// for managing and checking overlapping ranges.
@internal
extension OverlapDeltaRangeListExtension on List<DeltaRange> {
  /// Checks if the provided [range] overlaps with any `DeltaRange` in the list.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final ignoreTheseRanges = [
  ///   DeltaRange(startOffset: 0, endOffset: 50),
  ///   DeltaRange(startOffset: 70, endOffset: 100)
  /// ];
  ///
  /// final newRange = DeltaRange(startOffset: 101, endOffset: 120);
  /// final newRange2 = DeltaRange(startOffset: 60, endOffset: 65);
  ///
  /// // Check if newRange overlaps with any existing range
  /// final result = ignoreTheseRanges.ignoreOverlap(newRange); // false
  /// final result2 = ignoreTheseRanges.ignoreOverlap(newRange); // false
  /// ```
  @internal
  bool ignoreOverlap(DeltaRange? range, [bool strictPartial = true]) {
    if (isEmpty || range == null) return false;
    int index = 0;
    while (index < length) {
      if (elementAt(index).checkOverlapOfRanges(range, strictPartial)) {
        return true;
      }
      index++;
    }
    return false;
  }
}
