import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import '../../delta_ranges.dart';
import 'pointer.dart';

class IgnoreCondition extends PointerCondition<int, void> {
  final int? len;
  IgnoreCondition({
    required super.offset,
    this.len,
  })  : assert(offset >= 0, 'offset cannot be less than zero'),
        assert(
            len == null || len > 0, 'len cannot be equals or less than zero'),
        super(target: null, caseSensitive: false);

  @override
  void build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    OnCatchCallback? onCatch,
  ]) {
    throw Exception(
        'IgnoreCondition has no build because is treated by a different way');
  }

  @override
  bool operator ==(covariant IgnoreCondition other) {
    if (identical(other, this)) return true;
    return other.key == key &&
        other.target == target &&
        other.caseSensitive == caseSensitive &&
        len == other.len &&
        offset == other.offset;
  }

  @override
  int get hashCode =>
      target.hashCode ^
      key.hashCode ^
      caseSensitive.hashCode ^
      len.hashCode ^
      offset.hashCode;
}
