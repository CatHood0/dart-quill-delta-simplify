import 'package:flutter/foundation.dart';

/// A class that represents a part of the difference between two Deltas.
///
/// This class is used to store information about a change in the Delta, including:
/// - The text before the change (`before`).
/// - The text after the change (`after`).
/// - The start and end positions of the change in the Delta.
///
/// It implements the `Comparable` interface, allowing instances of this class to be compared based on the `start` position.
///
/// Example usage:
/// ```dart
/// final diffPart = DeltaDiffPart(
///   before: 'old text',
///   start: 0,
///   end: 10,
///   after: 'new text',
/// );
/// ```
class DeltaDiffPart implements Comparable<DeltaDiffPart> {
  /// The text before the change.
  final Object before;

  /// The text after the change, or `null` if no change was made.
  final Object? after;

  /// The starting position of the change in the Delta.
  final int start;

  /// The ending position of the change in the Delta.
  final int end;

  /// Additional arguments that describe the type of change. The allowed keys are:
  /// - `isRemovedPart`: `true` if this part was removed.
  /// - `isUpdatedPart`: `true` if this part was updated.
  /// - `isAddedPart`: `true` if this part was added.
  /// - `originalOp`: The original `Operation` before the change.
  /// - `modifiedOp`: The modified `Operation` after the change.
  final Map<String, dynamic>? args;

  DeltaDiffPart({
    required this.before,
    required this.start,
    required this.end,
    this.after,
    this.args,
  }) : assert(args == null || args.isNotEmpty, 'args can be null or non empty');

  /// Compares this `DeltaDiffPart` with another based on their `start` positions.
  ///
  /// Returns:
  /// - [`1`] if this part starts after the other.
  /// - [`0`] if both parts start at the same position.
  @override
  int compareTo(DeltaDiffPart other) {
    if (start > other.start) {
      return 1;
    }
    return 0;
  }

  @override
  bool operator ==(covariant DeltaDiffPart other) {
    if (identical(this, other)) return true;
    return before == other.before &&
        after == other.after &&
        start == other.start &&
        end == other.end &&
        mapEquals(args, other.args);
  }

  @override
  int get hashCode => before.hashCode ^ after.hashCode ^ start.hashCode ^ end.hashCode ^ args.hashCode;

  @override
  String toString() {
    return 'DeltaDiffPart(before: $before, after: $after, start: $start, end: $end, args: $args)';
  }
}
