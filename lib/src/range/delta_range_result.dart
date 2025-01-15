import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Represents the result of a range operation on a [Delta].
///
/// This class holds a [Delta] and the range within it, defined by [startOffset] and [endOffset].
class DeltaRangeResult {
  /// The [Delta] object that this range is associated with.
  final Delta delta;

  /// The starting position of the range within the [Delta].
  final int startOffset;

  /// The ending position of the range within the [Delta].
  final int endOffset;

  /// Creates an instance of `DeltaRangeResult` with the given [delta], [startOffset], and [endOffset].
  ///
  /// - [delta]: The [Delta] object representing the changes.
  /// - [startOffset]: The starting global offset of the range.
  /// - [endOffset]: The ending global offset of the range.
  DeltaRangeResult({
    required this.delta,
    required this.startOffset,
    required this.endOffset,
  });

  /// Provides a string representation of the `DeltaRangeResult`.
  ///
  /// This method returns a string in the format:
  /// `DeltaRangeResult(delta: [delta], Offset: [startOffset, endOffset])`.
  @override
  String toString() => 'DeltaRangeResult(delta: [$delta], Offset: [$startOffset, $endOffset])';

  /// Compares two `DeltaRangeResult` instances for equality.
  ///
  /// Returns `true` if [delta], [startOffset], and [endOffset] are the same in both instances.
  @override
  bool operator ==(covariant DeltaRangeResult other) {
    if (identical(other, this)) return true;
    return other.delta == delta &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  /// Returns a hash code for the `DeltaRangeResult`.
  ///
  /// The hash code is calculated based on the [delta], [startOffset], and [endOffset] properties.
  @override
  int get hashCode => delta.hashCode ^ startOffset.hashCode ^ endOffset.hashCode;
}
