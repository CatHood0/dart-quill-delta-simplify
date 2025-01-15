import 'package:dart_quill_delta/dart_quill_delta.dart';

const _exceptionName = 'IllegalOperationPassedException';

/// A custom exception class that represents an illegal operation passed to a process.
///
/// The `IllegalOperationPassedException` is thrown when an invalid operation is passed, 
/// particularly when the operation is expected to be an "insert" but is instead a "retain" or "delete".
/// This exception helps identify and debug issues related to incorrect operations in a sequence.
class IllegalOperationPassedException implements Exception {
  /// The operation that caused the exception.
  ///
  /// This operation is considered illegal because it does not meet the expected criteria
  /// for processing, typically because it is a "retain" or "delete" operation.
  final Operation illegal;

  /// The operation that was expected.
  ///
  /// This represents what the correct operation should have been. It helps in debugging by
  /// showing the expected state or type of operation.
  final Operation expected;

  IllegalOperationPassedException({
    required this.illegal,
    required this.expected,
  });

  @override
  String toString() {
    if (illegal.isRetain || illegal.isDelete) {
      return '$_exceptionName(cannot be processed because key is ${illegal.key}) and is only accepted "insert" key';
    }
    return '$_exceptionName(A value into a part of the Operation is unprocessable. '
        'Illegal value caught: $illegal. '
        'Expected: $expected)';
  }
}
