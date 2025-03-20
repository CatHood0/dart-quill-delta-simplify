import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/delta_ranges.dart';

typedef OnCatchCallback = void Function(Exception);
typedef OperationBuilder = Iterable<Operation> Function(
  String data,
  Map<String, dynamic>? currentOperationAttributes,
  DeltaRange currentRange,
  DeltaRange matchRange,
);
