import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/conditions.dart';
import 'package:dart_quill_delta_simplify/extensions.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/illegal_condition_build_result.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/no_conditions_created_while_build_execution_exception.dart';
import 'package:dart_quill_delta_simplify/src/util/delta/denormalizer_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/delta/normalizer_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:meta/meta.dart';

import '../delta_changes.dart';
import '../delta_ranges.dart';
import 'build_result.dart';
import 'util/enums.dart';

/// Represents a query builder for a [Delta] object, allowing modifications and
/// conditions to be applied to it. The `QueryDelta` class facilitates the creation
/// of a `Delta` through various conditions and tracks changes made during the process.
class QueryDelta {
  /// The input [Delta] used to create modifications.
  Delta _input = Delta();

  /// A map holding various parameters such as the original version of the [Delta],
  /// errors encountered, conditions to apply, and cached changes.
  Map<String, dynamic> params = {};

  QueryDelta({
    required Delta delta,
  })  : assert(delta.isNotEmpty, 'cannot be passed an empty Delta'),
        assert(delta.last.isNewLineOrBlockInsertion || delta.last.containsNewLine(),
            'last operation must contain a new line') {
    _input = Delta.fromOperations(delta.operations);
    params['original_version'] = Delta.fromOperations(delta.operations);
    params['errors'] = <String>[];
    params['conditions'] = <Condition>[];
    params['used-conditions'] = <String>[];
  }

  factory QueryDelta.fromJson(String json, [List<Condition>? conditions]) {
    return QueryDelta(delta: Delta.fromJson(jsonDecode(json) as List<dynamic>))
      ..params['conditions'].addAll(conditions);
  }

  factory QueryDelta.fromOperations(List<Operation> ops, [List<Condition>? conditions]) {
    return QueryDelta(delta: Delta.fromOperations(ops))..params['conditions'].addAll(conditions);
  }

  factory QueryDelta.withConditions(Delta delta, List<Condition> conditions) {
    return QueryDelta(delta: delta)..params['conditions'].addAll(conditions);
  }

  /// Adds a single [Condition] to the list of conditions to be applied to the [Delta].
  ///
  /// - [`condition`]: The condition to apply.
  ///
  /// Returns a new [QueryDelta] instance with the added condition.
  QueryDelta push(Condition condition) => this..params['conditions'].add(condition);

  /// Adds a list of [Condition] objects to the conditions to be applied to the [Delta].
  ///
  /// - [`condition`]: A list of conditions to apply.
  ///
  /// Returns a new [QueryDelta] instance with the added conditions.
  QueryDelta pushAll(List<Condition> condition) => this..params['conditions'].addAll(condition);

  /// If a exception is catched, this will be called.
  ///
  /// - [`onCatchError`]: A function called when an exception is catched. If return `true`, ignores the error and the condition, if return `false`, throw the exception
  ///
  /// Returns a new [QueryDelta] instance with the added catch.
  QueryDelta catchErr(OnCatchCallback onCatchError) => this..params['catch'] = onCatchError;

  /// Retrieves the cached changes made during the build process, grouped by
  /// timestamp.
  Map<String, List<DeltaChange>> get changes => {...?params['cached_changes']};

  /// Converts the built [QueryDelta] into a [Delta]. If the build has not been
  /// executed, an exception will be thrown.
  ///
  /// Returns the final [Delta] after all conditions have been applied.
  ///
  /// Throws [Exception] if [build()] has not been called before.
  Delta toDelta() => params['result'] == null
      ? throw Exception('first run build() before use toDelta() method')
      : params['result'].delta;

  /// Attempts to convert the built [QueryDelta] into a [Delta]. If the build has
  /// not been executed or has failed, `null` is returned.
  ///
  /// Returns the resulting [Delta], or `null` if the build is incomplete.
  Delta? tryToDelta() => params['result']?.delta;

  /// Builds a final [Delta] based on the conditions applied so far.
  ///
  /// This method applies a series of conditions to the current [Delta] object and returns a final [BuildResult] containing the modified [Delta]. If no conditions are provided, an exception is thrown. During the build process, the original [Delta] may be modified and changes may be tracked.
  ///
  /// The method checks if the final [Delta] has been modified since the last build. If no changes are detected (because, we can make a build, then after that, we can also add more conditions a do again a build), the previously stored result is returned to avoid redundant processing.
  ///
  /// Example usage:
  /// ```dart
  ///final QueryDelta queryDelta = QueryDelta(delta: delta)
  ///    ..delete(
  ///      lengthOfDeletion: 5,
  ///      startPoint: 5,
  ///      possibleTarget: '',
  ///    )
  ///    ..push(<your_custom_condition>)
  ///    ..build(unknownObjectTypeBuilder: (Object result) {
  ///     return [Operation.insert(result)];
  ///   },
  ///);
  /// ```
  BuildResult build({
    List<Operation> Function(Object)? unknownObjectTypeBuilder,
    bool preventReuseConditions = true,
    bool maintainIgnoresConditions = true,
  }) {
    if (params['conditions'] == null || params['conditions'].isEmpty) {
      throw const NoConditionsCreatedWhileBuildExecutionException();
    }
    // clone the current input version since something can fail and we do not need
    // partial modifications
    Delta inputClone = _input.denormalize();
    final List<Condition> conditions = params['conditions'] as List<Condition>;
    final List<DeltaRange> partsToIgnore = <DeltaRange>[];
    final Map<String, List<DeltaChange>> changes = Map.of(params['cached_changes'] ?? {});
    final String executedBuildDate = DateTime.now().toIso8601String();
    final OnCatchCallback? onCatch = params['catch'] as OnCatchCallback?;
    if (changes.isEmpty) {
      changes[executedBuildDate] = [];
    }
    for (Condition condition in conditions) {
      final bool wasUsedAlready = params['used-conditions'].contains(condition.key);
      if (preventReuseConditions && wasUsedAlready) continue;
      if (condition is IgnoreCondition) {
        if (!wasUsedAlready && !maintainIgnoresConditions) params['used-conditions'].add(condition.key);
        final len = condition.len ?? -1;
        partsToIgnore.add(
          DeltaRange(
            startOffset: condition.offset,
            endOffset: len == -1 ? len : condition.offset + len,
          ),
        );
        final DeltaChange change = DeltaChange(
          change: null,
          startOffset: condition.offset,
          endOffset: condition.offset + (condition.len ?? 0),
          type: ChangeType.ignore,
        );
        if (changes.containsKey(executedBuildDate)) {
          changes[executedBuildDate]?.add(change);
        } else {
          changes.addAll({
            executedBuildDate: [change]
          });
        }
        continue;
      }
      if (condition is ReplaceCondition && partsToIgnore.ignoreOverlap(condition.range)) continue;
      final Object? result = condition.build(
        inputClone,
        partsToIgnore,
        (DeltaChange change) {
          if (changes.containsKey(executedBuildDate)) {
            changes[executedBuildDate]?.add(change);
          } else {
            changes.addAll({
              executedBuildDate: [change]
            });
          }
        },
        onCatch,
      );
      if (!wasUsedAlready) params['used-conditions'].add(condition.key);
      if (result is Iterable<Operation>) {
        inputClone = Delta.fromOperations([...result]);
      } else if (result is Operation) {
        inputClone = Delta.fromOperations([result]);
      } else if (result is String) {
        if (result.trim().isEmpty) {
          final IllegalConditionBuildResult err = IllegalConditionBuildResult(
            condition: condition,
            illegal: '"$result" < result is empty',
            expected: 'Non empty string',
          );
          if (onCatch != null) {
            onCatch.call(err);
            continue;
          }
          throw err;
        }
        inputClone.insert(result);
      } else if (result is Map) {
        if (result.containsKey('insert')) {
          inputClone.insert(result['insert'], result['attributes']);
          continue;
        }
        final IllegalConditionBuildResult err = IllegalConditionBuildResult(
          condition: condition,
          illegal: result,
          expected: {'insert': ''},
        );
        if (onCatch != null) {
          onCatch.call(err);
          continue;
        }
        throw err;
      } else if (unknownObjectTypeBuilder != null && result != null) {
        final ops = unknownObjectTypeBuilder.call(result);
        if (ops.isEmpty) {
          final IllegalConditionBuildResult err = IllegalConditionBuildResult(
            condition: condition,
            illegal: 'List of operations is empty',
            expected: 'A non empty List of operations',
          );
          if (onCatch != null) {
            onCatch.call(err);
            continue;
          }
          throw err;
        }
        inputClone = Delta.fromOperations(ops);
      } else {
        final err = IllegalConditionBuildResult(
          condition: condition,
          illegal: result,
          expected: [
            Iterable<Operation>,
            Operation,
            String,
            Map,
          ],
        );
        if (onCatch != null) {
          onCatch.call(err);
          continue;
        }
        throw err;
      }
    }
    // the delta needs to be normalized to avoid an exception from the Document class of Flutter Quill
    _input = inputClone.normalize();
    final BuildResult result = BuildResult(delta: _input);
    params['result'] = result;
    params['cached_changes'] = {...changes};
    return result;
  }

  /// Clones the current [QueryDelta] instance, allowing for an alternative [Delta]
  /// to be passed as the input. The clone retains all conditions, errors, and cached changes.
  ///
  /// - [`alternativeDelta`]: An optional [Delta] to use as the input for the clone.
  ///
  /// Returns a new [QueryDelta] instance that is a copy of the current one.
  QueryDelta clone([Delta? alternativeDelta]) {
    return QueryDelta(delta: alternativeDelta ?? _input)
      ..params['original_version'] = params['original_version']
      ..params['errors'] = params['errors']
      ..params['conditions'] = params['conditions']
      ..params['result'] = params['result']
      ..params['cached_changes'] = params['cached_changes'];
  }

  // used only by internal resources
  @internal
  Delta getDelta() {
    return _input;
  }
}
