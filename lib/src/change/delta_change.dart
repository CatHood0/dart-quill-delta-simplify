import '../util/enums.dart';

/// Represents a change within a `Delta`, including information about the
/// change content, type, and the range it affects.
class DeltaChange {
  /// The content of the change. This can be any object that represents the
  /// change, such as a string, list, or another custom object.
  final Object? change;

  /// The starting offset (position) of the change within the `Delta`.
  /// This is the point where the change begins.
  final int startOffset;

  /// The ending offset (position) of the change within the `Delta`.
  /// This is the point where the change ends.
  final int endOffset;

  /// The type of the change, which can represent different kinds of operations,
  /// such as insertions, deletions, or formatting changes.
  final ChangeType type;

  /// Creates a [DeltaChange] instance with the given parameters.
  ///
  /// - `change`: The content of the change, which can be of any type.
  /// - `startOffset`: The position where the change starts.
  /// - `endOffset`: The position where the change ends.
  /// - `type`: The type of the change (e.g., insert, delete, format).
  ///
  /// Example usage:
  /// ```dart
  /// final deltaChange = DeltaChange(
  ///   change: 'Hello, world!',
  ///   startOffset: 0,
  ///   endOffset: 13,
  ///   type: ChangeType.insert,
  /// );
  /// ```
  DeltaChange({
    required this.change,
    required this.startOffset,
    required this.endOffset,
    required this.type,
  });

  @override
  String toString() {
    return 'DeltaChange(change: $change, type: ${type.name}, start: $startOffset, end: $endOffset)';
  }
}
