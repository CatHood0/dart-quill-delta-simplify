import 'package:dart_quill_delta/dart_quill_delta.dart';
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
}
