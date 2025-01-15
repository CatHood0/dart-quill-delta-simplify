import 'package:dart_quill_delta_simplify/src/conditions/condition.dart';

/// An exception that is thrown when a condition's build result does not match the expected type.
///
/// The `IllegalConditionBuildResult` class is used to represent an error that occurs when a condition's
/// `build` method returns a result that is not of the expected type. This exception helps identify and
/// debug issues related to invalid build results in conditions.
///
class IllegalConditionBuildResult implements Exception {
  /// The condition that caused the exception.
  ///
  /// This property holds a reference to the `Condition` instance that resulted in an illegal build result.
  final Condition condition;

  /// The actual result returned by the condition's build method.
  ///
  /// This property contains the value that was returned by the `build` method, which did not match the expected type.
  final Object? illegal;

  /// The expected type or value that the build method should have returned.
  ///
  /// This property holds the type or value that was expected from the `build` method. It is used to
  /// provide more context in the exception message.
  final Object expected;

  IllegalConditionBuildResult({
    required this.condition,
    required this.illegal,
    required this.expected,
  });

  @override
  String toString() {
    return 'IllegalConditionBuildResult(The condition ${condition.runtimeType} contains a '
        'build method that does not return the expected type. '
        'Build result: $illegal. '
        'Expected result: $expected)';
  }
}
