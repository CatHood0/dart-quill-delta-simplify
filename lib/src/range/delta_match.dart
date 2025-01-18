import 'package:dart_quill_delta_simplify/delta_ranges.dart';

/// Represents the match result of a range operation on a [Delta].
///
/// This class holds a [Delta] and the range within it, defined by [startOffset] and [endOffset].
class DeltaMatch extends DeltaRangeResult {
  DeltaMatch({
    required super.delta,
    required super.startOffset,
    required super.endOffset,
  });

  @override
  String toString() => 'DeltaMatch(delta: [$delta], Offset: [$startOffset, $endOffset])';
}
