import '../../delta_diff.dart';
import '../util/collections.dart';

/// This class represents the result of comparing two Deltas, specifically
/// the list of differences between them. It stores the differences as a
/// list of `DeltaDiffPart` objects, which represent the individual parts
/// of the diff between the two Deltas.
class DeltaCompareDiffResult {
  /// A list of `DeltaDiffPart` objects representing the differences between two Deltas.
  final List<DeltaDiffPart> diffParts;

  DeltaCompareDiffResult({
    required this.diffParts,
  });

  @override
  bool operator ==(covariant DeltaCompareDiffResult other) {
    if (identical(this, other)) return true;
    return listEquals(diffParts, other.diffParts);
  }

  @override
  int get hashCode => diffParts.hashCode;

  @override
  String toString() {
    return 'DeltaCompareDiffResult(parts: [${diffParts.join(',\n')}])';
  }
}
