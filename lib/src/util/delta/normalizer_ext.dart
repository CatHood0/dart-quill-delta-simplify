import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:meta/meta.dart';

@internal
extension DeltaNormalizer on Delta {
  /// Fully normalizes the operations within the Delta.
  Delta normalize() {
    Delta newDelta = Delta();
    for (var op in operations) {
      newDelta.push(op);
    }
    return newDelta;
  }
}
