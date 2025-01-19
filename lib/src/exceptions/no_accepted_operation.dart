import 'package:dart_quill_delta/dart_quill_delta.dart';

class NoAcceptedOperation implements Exception {
  final Operation operation;
  NoAcceptedOperation({
    required this.operation,
  });

  @override
  String toString() {
    return 'The data of the op can\'t be nullable';
  }
}
