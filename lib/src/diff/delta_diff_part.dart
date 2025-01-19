import 'package:flutter/foundation.dart';

/// A class that represents a part of the difference between two Deltas.
///
/// Example usage:
/// ```dart
/// final diffPart = DeltaDiffPart(
///   before: 'old text',
///   after: 'new text',
///   start: 0,
///   end: 10,
/// );
/// ```
class DeltaDiffPart {
  /// The text before the change.
  final Object? before;

  /// The text after the change, or `null` if no change was made.
  final Object? after;

  /// The starting position of the change in the Delta.
  final int start;

  /// The ending position of the change in the Delta.
  final int end;

  /// Additional arguments that describe the type of change. The allowed keys are:
  /// * [isRemovedPart]: `true` if this part was removed.
  /// * [isUpdatedPart]: `true` if this part was updated.
  /// * [isAddedPart]: `true` if this part was added.
  /// * [isEquals]: `true` if this part was exactly equals than the before.
  final Map<String, dynamic>? args;

  DeltaDiffPart({
    required this.before,
    required this.start,
    required this.end,
    this.after,
    this.args,
  });

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
    return 'DeltaDiffPart(before: "${before == null ? "" : before.toString().replaceAll('\n', '\\n')}", '
        'after: "${after == null ? "" : after.toString().replaceAll('\n', '\\n')}", '
        'start: $start, end: $end, '
        'args: $args)';
  }
}
