import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/extensions/string_ext.dart';
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
  })  : assert(target == null || (target is String && target.isNotEmpty) || (target is Map && target.isNotEmpty),
            'target can be only String or Map'),
        assert((target == null || target is Map) || target is String && !target.hasOnlyNewLines,
            'target cannot contain newlines'),
        assert(
          (!attribute.isInline || attribute.isInline && target != null) ||
              attribute.isInline && (len != null && len > 0),
          'len cannot be null or less than zero, or the target '
          'cannot be undefined if the Attribute(${attribute.runtimeType}) is inline',
        );

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

  @override
  String toString() {
    return 'FormatCondition(Attribute: $attribute, target: $target, caseSensitive: $caseSensitive, offset: $offset, len: $len)';
  }
}
