/// An exception that is thrown when an illegal or unexpected parameter value is encountered.
///
/// This exception is used to signal that a parameter value passed to a function or constructor
/// is either not accepted or is invalid for its intended use. It provides details about the
/// illegal value that was caught and what the expected value or range of values should be.
class IllegalParamsValuesException implements Exception {
  /// The illegal value that caused the exception to be thrown.
  ///
  /// This property holds the value that was deemed invalid or unacceptable in the context
  /// where it was used. It provides insight into what triggered the exception.
  final Object? illegal;

  /// The expected value or range of values that would have been acceptable.
  ///
  /// This property describes what the correct or expected value should have been. It serves
  /// as a guide for developers to understand what type of input is valid.
  final Object expected;
  IllegalParamsValuesException({
    required this.illegal,
    required this.expected,
  });

  @override
  String toString() {
    return 'IllegalParamsValuesException(Some parameter values passed are not accepted or them are invalid to its use. '
        'Illegal value catched: $illegal. '
        'Expected: $expected)';
  }
}
