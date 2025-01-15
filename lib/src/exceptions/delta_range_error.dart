/// Error thrown due to an argument value being outside an accepted range.
class DeltaRangeError implements Exception {
  /// The minimum value that [value] is allowed to assume.
  final num? start;

  /// The maximum value that [value] is allowed to assume.
  final num? end;

  /// Whether value was provided.
  final bool _hasValue;

  /// The invalid value.
  final dynamic invalidValue;

  /// Name of the invalid argument, if available.
  final String? name;

  /// Message describing the problem.
  final dynamic message;

  DeltaRangeError(this.invalidValue, this.name, this.message, this.start, this.end, this._hasValue);

  /// Create a new [DeltaRangeError] with a message for the given [value].
  /// An optional [name] can specify the argument name that has the
  ///
  /// invalid value, and the [message] can override the default error
  /// description.
  factory DeltaRangeError.value(num value, [String? name, String? message]) => DeltaRangeError(
        value,
        name,
        message ?? "Value not in range",
        null,
        null,
        true,
      );

  /// Create a new [DeltaRangeError] for a value being outside the valid range.
  ///
  /// The allowed range is from [minValue] to [maxValue], inclusive.
  /// If `minValue` or `maxValue` are `null`, the range is infinite in
  /// that direction.
  ///
  /// For a range from 0 to the length of something, end exclusive, use
  /// [DeltaRangeError.index].
  ///
  /// An optional [name] can specify the argument name that has the
  /// invalid value, and the [message] can override the default error
  /// description.
  factory DeltaRangeError.range(num invalidValue, int? minValue, int? maxValue, [String? name, String? message]) =>
      DeltaRangeError(
        invalidValue,
        name,
        message ?? "Invalid value",
        minValue,
        maxValue,
        true,
      );

  /// Check that an integer [value] lies in a specific interval.
  ///
  /// Throws if [value] is not in the interval.
  /// The interval is from [minValue] to [maxValue], both inclusive.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error.
  ///
  /// Returns [value] if it is in the interval.
  static int checkValueInInterval(int value, int minValue, int maxValue, [String? name, String? message]) {
    if (value < minValue || value > maxValue) {
      throw DeltaRangeError.range(value, minValue, maxValue, name, message);
    }
    return value;
  }

  /// Check that [index] is a valid index into an indexable object.
  ///
  /// Throws if [index] is not a valid index into [indexable].
  ///
  /// An indexable object is one that has a `length` and an index-operator
  /// `[]` that accepts an index if `0 <= index < length`.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error. If [name] is omitted, it
  /// defaults to `"index"`.
  ///
  /// If [length] is provided, it is used as the length of the indexable object,
  /// otherwise the length is found as `indexable.length`.
  ///
  /// Returns [index] if it is a valid index.
  static int checkValidIndex(int index, dynamic indexable, [String? name, int? length, String? message]) {
    length ??= (indexable.length as int);
    return IndexError.check(index, length, indexable: indexable, name: name, message: message);
  }

  /// Check that a range represents a slice of an indexable object.
  ///
  /// Throws if the range is not valid for an indexable object with
  /// the given [length].
  /// A range is valid for an indexable object with a given [length]
  ///
  /// if `0 <= [start] <= [end] <= [length]`.
  /// An `end` of `null` is considered equivalent to `length`.
  ///
  /// The [startName] and [endName] defaults to `"start"` and `"end"`,
  /// respectively.
  ///
  /// Returns the actual `end` value, which is `length` if `end` is `null`,
  /// and `end` otherwise.
  static int checkValidRange(int start, int? end, int length,
      [String? startName, String? endName, String? message]) {
    // Comparing with `0` as receiver produces better dart2js type inference.
    // Ditto `start > end` below.
    if (0 > start || start > length) {
      startName ??= "start";
      throw DeltaRangeError.range(start, 0, length, startName, message);
    }
    if (end != null) {
      if (start > end || end > length) {
        endName ??= "end";
        throw DeltaRangeError.range(end, start, length, endName, message);
      }
      return end;
    }
    return length;
  }

  /// Check that an integer value is non-negative.
  ///
  /// Throws if the value is negative.
  ///
  /// If [name] or [message] are provided, they are used as the parameter
  /// name and message text of the thrown error. If [name] is omitted, it
  /// defaults to `index`.
  ///
  /// Returns [value] if it is not negative.
  static int checkNotNegative(int value, [String? name, String? message]) {
    if (value < 0) {
      throw DeltaRangeError.range(value, 0, null, name ?? "index", message);
    }
    return value;
  }

  String get _errorName => "DeltaRangeError";
  String get _errorExplanation {
    String explanation = "";
    num? start = this.start;
    num? end = this.end;
    if (start == null) {
      if (end != null) {
        explanation = ": Not less than or equal to $end";
      }
      // If both are null, we don't add a description of the limits.
    } else if (end == null) {
      explanation = ": Not greater than or equal to $start";
    } else if (end > start) {
      explanation = ": Not in inclusive range $start..$end";
    } else if (end < start) {
      explanation = ": Valid value range is empty";
    } else {
      // end == start.
      explanation = ": Only valid value is $start";
    }
    return explanation;
  }

  @override
  String toString() {
    String? name = this.name;
    String nameString = (name == null) ? "" : " ($name)";
    Object? message = this.message;
    var messageString = message ?? '';
    String prefix = "$_errorName$nameString $messageString";
    if (!_hasValue) return prefix;
    // If we know the invalid value, we can try to describe the problem.
    String explanation = _errorExplanation;
    String errorValue = Error.safeToString(invalidValue);
    return "$prefix$explanation: $errorValue";
  }
}
