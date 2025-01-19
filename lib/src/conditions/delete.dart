import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/internals/delete_condition_method.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import '../../dart_quill_delta_simplify.dart';
import 'pointer.dart';

/// A condition that deletes a specified number of characters from a [Delta].
///
/// The `DeleteCondition` class extends `PointerCondition` and implements a deletion operation
/// within a `Delta` object. It supports both single and multiple deletions based on the provided
/// parameters. This condition is useful for manipulating the content of a `Delta` by removing
/// specific segments of text or embedded objects.
class DeleteCondition extends PointerCondition<int, List<Operation>> {
  /// The number of characters to delete.
  ///
  /// This property defines how many characters should be removed from the `Delta`. A value
  /// of `-1` indicates that the deletion is disabled, while a positive value specifies
  /// the exact number of characters to delete.
  final int lengthOfDeletion;

  /// Specifies whether the deletion should occur only once or multiple times.
  ///
  /// If `true`, the deletion is performed a single time at the specified target and offset.
  /// If `false`, the deletion can be executed multiple times depending on the `Delta` content.
  final bool onlyOnce;

  DeleteCondition({
    required this.lengthOfDeletion,
    required super.target,
    required super.offset,
    required this.onlyOnce,
    super.caseSensitive = false,
    super.key,
  })  : assert(target != '\n' && target != '\\n', 'target cannot be "\\n"'),
        assert(offset == -1 || offset >= 0, 'offset must be equal to or greater than zero (only -1 disables it)'),
        assert(lengthOfDeletion == -1 || lengthOfDeletion > 0,
            'lengthOfDeletion must be greater than zero (only -1 disables it)');

  @override
  List<Operation> build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    OnCatchCallback? onCatch,
  ]) {
    return deleteCondition(
      delta.toList(),
      this,
      partsToIgnore,
      onCatch,
    );
  }

  @override
  bool operator ==(covariant DeleteCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        onlyOnce == other.onlyOnce &&
        offset == other.offset &&
        lengthOfDeletion == other.lengthOfDeletion;
  }

  @override
  int get hashCode =>
      target.hashCode ^
      key.hashCode ^
      caseSensitive.hashCode ^
      onlyOnce.hashCode ^
      offset.hashCode ^
      lengthOfDeletion.hashCode;

  @override
  String toString() {
    return 'DeleteCondition('
        'target: $target, '
        'offset: $offset, '
        'caseSensitive: $caseSensitive, '
        'len: $lengthOfDeletion, '
        'onlyOnce: $onlyOnce)';
  }
}
