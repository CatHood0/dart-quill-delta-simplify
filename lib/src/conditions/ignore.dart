import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/conditions/condition.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import '../../delta_changes.dart';
import '../../delta_ranges.dart';
import 'pointer.dart';

class IgnoreCondition extends PointerCondition<int, void> {
  final int? len;
  IgnoreCondition({
    required super.offset,
    this.len,
  }) : super(target: null, caseSensitive: false);

  @override
  void build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    void Function(DeltaChange)? registerChange,
    OnCatchCallback? onCatch,
  ]) {
    throw Exception('IgnoreCondition has no build because is treated by a different way');
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
  int get hashCode => target.hashCode ^ key.hashCode ^ caseSensitive.hashCode ^ len.hashCode ^ offset.hashCode;
}
