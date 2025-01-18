import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/internals/format_condition_method.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:flutter_quill/flutter_quill.dart' show Attribute;

import '../../conditions.dart';
import '../change/delta_change.dart';
import '../range/delta_range.dart';

/// A condition that applies formatting attributes to a [Delta].
///
/// The [FormatCondition] class extends the [Condition] class and is designed to format specific parts
/// of a [Delta] object by applying an [Attribute]. It allows targeting a substring or a range defined
/// by an offset and length within the [Delta].
///
/// This class is useful for scenarios where text formatting needs to be conditionally applied based
/// on the content or structure of a [Delta] object, such as bolding text, changing text color, or
/// applying other style attributes.
class FormatCondition extends Condition<List<Operation>> {
  /// The attribute to be applied to the [Delta].
  ///
  /// This attribute specifies the formatting style, such as bold, italic, or color,
  /// that will be applied to the targeted text or range in the [Delta].
  final Attribute attribute;

  /// The offset within the [Delta] where the formatting should begin.
  ///
  /// This value defines the starting point from which the formatting will be applied.
  /// If `null`, the formatting is applied based on the target without a specific starting offset.
  final int? offset;

  /// The length of the text range to which the formatting should be applied.
  ///
  /// This value defines how many characters from the offset should be formatted.
  /// If `null`, the formatting will be applied to the entire target or until the end
  /// of the [Delta] if an offset is specified.
  final int? len;

  /// Specifies whether the format should occur only once.
  ///
  /// If `true`, the content will be formatted only once at the specified position or range, even if
  /// multiple matches are found.
  final bool onlyOnce;

  FormatCondition({
    required super.target,
    required this.attribute,
    super.caseSensitive = false,
    super.key,
    this.onlyOnce = false,
    this.offset,
    this.len,
  });

  @override
  List<Operation> build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    void Function(DeltaChange)? registerChange,
    OnCatchCallback? onCatch,
  ]) {
    return formatCondition(
      delta.toList(),
      this,
      partsToIgnore,
      registerChange,
      onCatch,
    );
  }

  @override
  String toString() {
    return 'FormatCondition(Attribute: $attribute, target: $target, caseSensitive: $caseSensitive, offset: $offset, len: $len)';
  }

  @override
  bool operator ==(covariant FormatCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        attribute == other.attribute &&
        len == other.len &&
        offset == other.offset;
  }

  @override
  int get hashCode =>
      target.hashCode ^
      key.hashCode ^
      caseSensitive.hashCode ^
      len.hashCode ^
      attribute.hashCode ^
      offset.hashCode;
}

/// A condition that removes formatting from a specified range within a [Delta].
///
/// The [RemoveFormattingCondition] class extends [Condition] and is used to remove all
/// formatting attributes within a specified [DeltaRange].
///
/// - [range]: The [DeltaRange] specifying the start and end positions for removing formatting.
class RemoveFormattingCondition extends Condition<List<Operation>> {
  final DeltaRange range;

  RemoveFormattingCondition({
    required this.range,
    super.key,
  }) : super(target: null, caseSensitive: false);

  @override
  List<Operation> build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    void Function(DeltaChange)? registerChange,
    OnCatchCallback? onCatch,
  ]) {
    return delta.toList();
  }

  @override
  String toString() {
    return 'RemoveFormattingCondition()';
  }

  @override
  bool operator ==(covariant RemoveFormattingCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        range == other.range;
  }

  @override
  int get hashCode => target.hashCode ^ key.hashCode ^ caseSensitive.hashCode ^ range.hashCode;
}
