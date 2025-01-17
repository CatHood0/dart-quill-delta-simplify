import 'package:dart_quill_delta/dart_quill_delta.dart';
import '../change/delta_change.dart';
import '../range/delta_range.dart';
import 'condition.dart';

abstract class PointerCondition<T extends num, R extends Object?> extends Condition<R> {
  final T offset;
  PointerCondition({
    required this.offset,
    required super.target,
    required super.caseSensitive,
    super.key,
  });

  @override
  R build(
    Delta delta, [
    List<DeltaRange> partsToIgnore = const [],
    void Function(DeltaChange)? registerChange,
    void Function(Exception err)? onCatch,
  ]);
}
