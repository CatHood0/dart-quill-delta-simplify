import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/build_result.dart';
import 'package:dart_quill_delta_simplify/src/conditions/condition.dart';

import 'util/typedef.dart';

/// Represents the parameters used in the [QueryDelta] class.
/// This class encapsulates various properties and states involved in building
/// and processing a [Delta] object through the [QueryDelta] class.
class QueryDeltaParams {
  /// The original [Delta] object that is being processed by [QueryDelta].
  /// This represents the initial state of the document before any operations
  /// are applied.
  late Delta originalDelta;

  /// The result produced by the [build] method in [QueryDelta].
  /// It may contain the modified [Delta] after applying certain conditions or
  /// transformations, or be null if no result has been built yet.
  late BuildResult? result;

  /// A list of conditions used by the [build] method in [QueryDelta].
  /// These conditions determine how the [Delta] is processed and transformed.
  late List<Condition> conditions;

  /// A list of condition identifiers that have already been used in a
  /// backward build process.
  /// This helps to keep track of which conditions have been applied to avoid
  /// reapplying them unnecessarily.
  late List<String> usedConditions;

  /// If a exception is catched, this will be called.
  late OnCatchCallback? onCatch;

  /// Initializes a new instance of the [QueryDeltaParams] class.
  /// This sets up default values for the `conditions` and `usedConditions`
  /// lists, and initializes `originalDelta` with an empty [Delta] object.
  QueryDeltaParams({
    Delta? originalDelta,
    List<Condition>? conditions,
    List<String>? usedConditions,
    this.result,
    this.onCatch,
  }) {
    if (originalDelta != null) this.originalDelta = originalDelta;
    this.conditions = conditions ?? <Condition>[];
    this.usedConditions = usedConditions ?? <String>[];
    this.originalDelta = Delta();
  }

  factory QueryDeltaParams.fromAnother(QueryDeltaParams params) {
    return QueryDeltaParams(
      originalDelta: params.originalDelta,
      conditions: params.conditions,
      usedConditions: params.usedConditions,
      onCatch: params.onCatch,
    );
  }
}
