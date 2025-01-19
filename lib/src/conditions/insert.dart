import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/internals/insert_condition_method.dart';

import 'package:dart_quill_delta_simplify/delta_changes.dart';
import 'package:dart_quill_delta_simplify/delta_ranges.dart';
import '../util/typedef.dart';
import 'condition.dart';

/// A condition that inserts content into a [Delta] at a specified position or range.
///
/// The [InsertCondition] class extends [Condition] and is used to insert various types of content,
/// such as strings, maps, or operations, into a [Delta] object based on a specified target or within a defined range.
///
/// The [InsertCondition] provides flexibility in how and where the content is inserted, with options
/// to control the behavior of the insertion, such as inserting content only once, on the left or right
/// side of the target, or as a distinct operation.
class InsertCondition extends Condition<List<Operation>> {
  /// The range within the [Delta] where the content will be inserted.
  ///
  /// If `range` is specified, the insertion will occur within this range. The range must have a
  /// `startOffset` that is zero or greater.
  final DeltaRange? range;

  /// The content to be inserted into the [Delta].
  ///
  /// This can be a `String`, `Map`, `Operation`, or a `List` of `Operations`. The content defines
  /// what will be added to the `Delta` at the target or range.
  final Object insertion;

  /// Determines whether the insertion should be made to the left of the target.
  ///
  /// If `true`, the content will be inserted to the left of the target; otherwise, it will be inserted
  /// to the right.
  final bool left;

  /// Specifies whether the insertion should occur only once.
  ///
  /// If `true`, the content will be inserted only once at the specified position or range, even if
  /// multiple matches are found.
  final bool onlyOnce;

  /// Indicates whether the insertion should be treated as a different operation.
  ///
  /// If `true`, the insertion will be handled as a distinct operation separate from existing ones.
  final bool asDifferentOp;

  /// Determines if the insertion should be made at the last operation of the `Delta`.
  ///
  /// If `true`, the content will be inserted at the end of the `Delta`, regardless of the specified
  /// target or range.
  final bool insertAtLastOperation;

  InsertCondition({
    required this.insertion,
    this.range,
    this.left = true,
    this.onlyOnce = false,
    this.asDifferentOp = false,
    this.insertAtLastOperation = false,
    required super.target,
    super.caseSensitive = false,
    super.key,
  })  : assert(range == null || range.startOffset >= 0, 'startOffset cannot be less than zero'),
        assert(
          insertion is String || insertion is Map || insertion is Operation || insertion is List<Operation>,
          'Cannot be inserted ${insertion.runtimeType} that is unknown. '
          'The unique types accepted by this insertions is: "String", "Map", "Operation" and "List<Operation>"',
        );

  @override
  List<Operation> build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    OnCatchCallback? onCatch,
  ]) {
    return insertCondition(
      delta.toList(),
      this,
      partsToIgnore,
      onCatch,
    );
  }

  @override
  bool operator ==(covariant InsertCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        insertion == other.insertion &&
        onlyOnce == other.onlyOnce &&
        range == other.range &&
        left == other.left &&
        asDifferentOp == other.asDifferentOp &&
        insertAtLastOperation == other.insertAtLastOperation;
  }

  @override
  int get hashCode =>
      target.hashCode ^
      key.hashCode ^
      caseSensitive.hashCode ^
      onlyOnce.hashCode ^
      insertion.hashCode ^
      onlyOnce.hashCode ^
      range.hashCode ^
      left.hashCode ^
      asDifferentOp.hashCode ^
      insertAtLastOperation.hashCode;

  @override
  String toString() {
    return 'InsertCondition('
        'target: $target, '
        'DeltaRange: $range, '
        'insertion: $insertion, '
        'onlyOnce: $onlyOnce, '
        'left: $left, '
        'asDifferentOp: $asDifferentOp, '
        'insertAtLastOperation: $insertAtLastOperation)';
  }
}
