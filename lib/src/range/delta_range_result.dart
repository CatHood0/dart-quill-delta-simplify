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

  DeltaRangeResult({
    required this.delta,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  bool operator ==(covariant DeltaRangeResult other) {
    if (identical(other, this)) return true;
    return other.delta == delta &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  @override
  int get hashCode =>
      delta.hashCode ^ startOffset.hashCode ^ endOffset.hashCode;

  @override
  String toString() =>
      'DeltaRangeResult(delta: [$delta], Offset: [$startOffset, $endOffset])';
}
