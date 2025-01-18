import 'package:dart_quill_delta_simplify/delta_ranges.dart';

/// Represents the match result of a range operation on a [Delta].
///
/// This class holds a [Delta] and the range within it, defined by [startOffset] and [endOffset].
class DeltaMatch extends DeltaRangeResult {
  final Object? input;
  DeltaMatch({
    required super.delta,
    required super.startOffset,
    required super.endOffset,
    this.input,
  });

  @override
  String toString() => 'DeltaMatch(delta: [$delta], Offset: [$startOffset, $endOffset], input: $input)';
}
