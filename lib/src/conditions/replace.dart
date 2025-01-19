import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/delta_ranges.dart';
import 'package:dart_quill_delta_simplify/src/internals/replace_part_condition_method.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'condition.dart';

/// A concrete implementation of the `Condition` class that defines a replace condition for a `Delta` object.
///
/// The `ReplaceCondition` class is used to specify a condition where certain parts of a `Delta` object are replaced
/// with new content. This class accepts a `target` to match and a `replace` value to substitute the matched content.
/// Additionally, it supports an optional `range` to limit the replacement to a specific part of the `Delta`, and
/// an `onlyOnce` flag to control whether the replacement should happen only once.
class ReplaceCondition extends Condition<List<Operation>> {
  /// The value to replace the matched content with.
  ///
  /// The `replace` value can be of type `Operation`, `List<Operation>`, `String`, or `Map`. This value
  /// specifies what should replace the matched content in the `Delta`.
  final Object replace;

  /// An optional range that limits the replacement to a specific part of the `Delta`.
  ///
  /// If provided, the `range` specifies the start and end indices within the `Delta` where the replacement
  /// should occur. If `null`, the replacement is applied throughout the entire `Delta`.
  final DeltaRange? range;

  /// A flag indicating whether the replacement should occur only once.
  ///
  /// If set to `true`, the replacement is applied only to the first occurrence of the `target` in the `Delta`.
  /// If `false`, the replacement is applied to all occurrences.
  final bool onlyOnce;

  ReplaceCondition({
    required super.target,
    required this.replace,
    required this.range,
    super.caseSensitive = false,
    this.onlyOnce = false,
  }) : assert(replace is Operation || replace is Iterable<Operation> || replace is String || replace is Map,
            'replace of type ${replace.runtimeType}, only can be String or Map');

  @override
  List<Operation> build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    OnCatchCallback? onCatch,
  ]) {
    return replaceCondition(
      delta.toList(),
      this,
      partsToIgnore,
      onCatch,
    );
  }

  @override
  bool operator ==(covariant ReplaceCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        range == other.range &&
        replace == other.replace &&
        onlyOnce == other.onlyOnce;
  }

  @override
  int get hashCode =>
      target.hashCode ^
      key.hashCode ^
      caseSensitive.hashCode ^
      onlyOnce.hashCode ^
      range.hashCode ^
      replace.hashCode;

  @override
  String toString() {
    return 'ReplaceCondition('
        'target: $target, '
        'caseSensitive: $caseSensitive, '
        'DeltaRange: $range, '
        'replace: $replace, '
        'onlyOnce: $onlyOnce)';
  }
}
