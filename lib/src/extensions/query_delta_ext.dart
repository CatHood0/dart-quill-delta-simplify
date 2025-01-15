import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/string_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/delta/normalizer_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/list_attrs_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../util/op_offset_to_char_offset.dart';

extension EssentialsQueryExt on QueryDelta {
  /// Matches operations in a [Delta] based on specific [Attributes].
  ///
  /// This extension method allows for matching operations that have specific inline or block attributes, or that contain specific attribute keys.
  ///
  /// ## Parameters:
  ///
  /// - [inlineAttrs]: A map of inline attributes to match against the operations.
  /// - [blockAttrs]: A map of block attributes to match against the operations.
  /// - [blockAttrKeys]: A list of block attribute keys to match against the operations.
  /// - [inlineAttrKeys]: A list of inline attribute keys to match against the operations.
  /// - [strictKeysCheck]: If `true`, only matches operations where all specified keys are present.
  /// - [onlyOnce]: If `true`, stops searching after the first match.
  ///
  /// ## Usage:
  ///
  /// ### Matching Attributes
  ///
  /// This method can be used to match operations that have specific attributes. For instance, you might want to find all headers within the Delta that have a specific attribute:
  ///
  /// ```dart
  /// final results = QueryDelta(delta: <your-delta>).matchAttributes(
  ///   inlineAttrs: {'bold': true},
  ///   blockAttrs: {'header': 1},
  /// );
  /// ```
  ///
  /// ### Matching Attribute Keys
  ///
  /// Alternatively, you can match operations based on the presence of specific attribute keys, without considering their values:
  ///
  /// ```dart
  /// final results = QueryDelta(delta: <your-delta>).matchAttributes(
  ///   blockAttrKeys: ['header'],
  ///   inlineAttrKeys: ['bold', 'italic'],
  ///   strictKeysCheck: false,
  /// );
  /// ```
  ///
  /// ## Assertions:
  ///
  /// - Ensures that if attributes or keys are provided, they are not empty.
  /// - Throws an [IllegalParamsValuesException] if no matching criteria are provided.
  ///
  /// ## Returns:
  ///
  /// A list of [DeltaRangeResult] objects, each representing a range in the Delta that matches the specified criteria.
  List<DeltaRangeResult> matchAttributes({
    required Attributes? inlineAttrs,
    required Attributes? blockAttrs,
    required List<String>? blockAttrKeys,
    required List<String>? inlineAttrKeys,
    bool strictKeysCheck = true,
    bool onlyOnce = false,
  }) {
    assert(blockAttrs == null || blockAttrs.isNotEmpty, 'No empty block attributes');
    assert(inlineAttrs == null || inlineAttrs.isNotEmpty, 'No empty inline attributes');
    assert(blockAttrKeys == null || blockAttrKeys.isNotEmpty, 'No empty block attribute keys');
    assert(inlineAttrKeys == null || inlineAttrKeys.isNotEmpty, 'No empty inline attribute keys');
    if (inlineAttrs == null && blockAttrs == null && blockAttrKeys == null && inlineAttrKeys == null) {
      throw IllegalParamsValuesException(illegal: null, expected: [Attributes, List<String>]);
    }
    return _attrMatches(
      inlineAttrs: inlineAttrs,
      blockAttrs: blockAttrs,
      onlyOnce: onlyOnce,
      blockAttrKeys: blockAttrKeys,
      inlineAttrKeys: inlineAttrKeys,
      strictKeysCheck: strictKeysCheck,
    );
  }

  /// Finds the first match of the given [pattern] or [rawObject] in the [Delta] operations list.
  ///
  /// This method searches the operations for a pattern or object match and returns the first occurrence wrapped in a [DeltaRangeResult].
  ///
  /// - [pattern]: The string pattern to search for.
  /// - [rawObject]: The object to search for within the operations.
  /// - [operationOffset]: The starting offset in the operations to begin the search.
  /// - [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive. Defaults to `false`.
  ///
  /// Throws [IllegalParamsValuesException] if the provided [operationOffset] is out of bounds.
  ///
  /// Returns a list containing the first matching [DeltaRangeResult].
  List<DeltaRangeResult> firstMatch(
    RegExp? pattern,
    Object? rawObject, {
    int? operationOffset,
  }) {
    // check if the index of the operation passed, is illegal
    if (operationOffset != null && (operationOffset < 0 || operationOffset >= getDelta().length)) {
      throw IllegalParamsValuesException(
        illegal: operationOffset,
        expected: {'start': 0, 'end': getDelta().length},
      );
    }
    return _matches(
      pattern: pattern,
      rawObject: rawObject,
      operationOffset: operationOffset,
      onlyOnce: true,
    );
  }

  /// Finds all matches of the given [pattern] or [rawObject] in the [Delta] operations list.
  ///
  /// This method searches the operations for all occurrences of the pattern or object match and returns each occurrence wrapped in a [DeltaRangeResult].
  ///
  /// - [pattern]: The string pattern to search for.
  /// - [rawObject]: The object to search for within the operations.
  /// - [operationOffset]: The starting offset in the operations to begin the search.
  /// - [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive. Defaults to `false`.
  ///
  /// Returns a list of all matching [DeltaRangeResult]s.
  List<DeltaRangeResult> allMatch(
    RegExp? pattern,
    Object? rawObject, {
    int? operationOffset,
  }) {
    return _matches(
      pattern: pattern,
      rawObject: rawObject,
      operationOffset: operationOffset,
      onlyOnce: false,
    );
  }

  /// Matches operations in the [Delta] based on specified attributes.
  ///
  /// This method checks for operations that match either inline or block attributes and returns them wrapped in [DeltaRangeResult].
  ///
  /// - [inlineAttrs]: The inline attributes to match.
  /// - [blockAttrs]: The block attributes to match.
  /// - [blockAttrKeys]: The keys of block attributes to match.
  /// - [inlineAttrKeys]: The keys of inline attributes to match.
  /// - [strictKeysCheck]: Whether to strictly check for the presence of all keys. Defaults to `true`.
  /// - [onlyOnce]: Whether to stop after the first match is found. Defaults to `false`.
  ///
  /// Returns a list of matching [DeltaRangeResult]s.
  List<DeltaRangeResult> _attrMatches({
    Attributes? inlineAttrs,
    Attributes? blockAttrs,
    List<String>? blockAttrKeys,
    List<String>? inlineAttrKeys,
    bool strictKeysCheck = true,
    bool onlyOnce = false,
  }) {
    final inputClone = getDelta().normalize();
    List<DeltaRangeResult> parts = [];
    int globalOffset = 0;
    for (int index = 0; index < inputClone.length; index++) {
      final op = inputClone.elementAt(index);
      final opData = op.data;
      final opLength = op.getEffectiveLength;
      if (inlineAttrKeys != null) {
        if (op.containsAttrs(inlineAttrKeys, strictKeysCheck)) {
          parts.add(
            DeltaRangeResult(
              delta: Delta.fromOperations(
                [
                  op,
                ],
              ),
              startOffset: globalOffset,
              endOffset: globalOffset + opLength,
            ),
          );
        }
        if (parts.isNotEmpty && onlyOnce) {
          return [...parts];
        }
        globalOffset += opLength;
        continue;
      }
      if (blockAttrKeys != null) {
        if (opData is String && opData.hasOnlyNewLines && op.attributes != null) {
          if (op.containsAttrs(blockAttrKeys, strictKeysCheck)) {
            int startOffset = globalOffset;
            int endOffset = globalOffset + opLength;
            List<Operation> operationsWithAttrsApplied = [];
            for (int index2 = index - 1; index2 > 0; index2--) {
              final beforeOp = inputClone.elementAt(index2);
              final opData = beforeOp.data;
              if (opData is Map) break;
              if (opData is String) {
                if (opData.contains('\n')) break;
                operationsWithAttrsApplied.insert(0, beforeOp);
              }
              startOffset -= beforeOp.getEffectiveLength;
            }
            operationsWithAttrsApplied = [...operationsWithAttrsApplied, op];
            parts.add(
              DeltaRangeResult(
                delta: Delta.fromOperations(operationsWithAttrsApplied),
                startOffset: startOffset.nonNegativeInt,
                endOffset: endOffset.nonNegativeInt,
              ),
            );
          }
        }
        if (parts.isNotEmpty && onlyOnce) {
          return [...parts];
        }
        globalOffset += opLength;
        continue;
      }
      if (inlineAttrs != null) {
        if (mapEquals(inlineAttrs, op.attributes)) {
          parts.add(
            DeltaRangeResult(
              delta: Delta.fromOperations(
                [
                  op,
                ],
              ),
              startOffset: globalOffset,
              endOffset: globalOffset + opLength,
            ),
          );
        }
        if (parts.isNotEmpty && onlyOnce) {
          return [...parts];
        }
        globalOffset += opLength;
        continue;
      }
      if (blockAttrs != null) {
        if (opData is String && opData.hasOnlyNewLines && op.attributes != null) {
          if (mapEquals(blockAttrs, op.attributes)) {
            int startOffset = globalOffset;
            int endOffset = globalOffset + opLength;
            List<Operation> operationsWithAttrsApplied = [];
            for (int index2 = index - 1; index2 > 0; index2--) {
              final beforeOp = inputClone.elementAt(index2);
              final opData = beforeOp.data;
              if (opData is Map) break;
              if (opData is String) {
                if (opData.contains('\n')) break;
                operationsWithAttrsApplied.insert(0, beforeOp);
              }
              startOffset -= beforeOp.getEffectiveLength;
            }
            operationsWithAttrsApplied = [...operationsWithAttrsApplied, op];
            parts.add(
              DeltaRangeResult(
                delta: Delta.fromOperations(operationsWithAttrsApplied),
                startOffset: startOffset.nonNegativeInt,
                endOffset: endOffset.nonNegativeInt,
              ),
            );
          }
        }
        if (parts.isNotEmpty && onlyOnce) {
          return [...parts];
        }
        globalOffset += opLength;
        continue;
      }
      globalOffset += opLength;
    }
    return [...parts];
  }

  /// Internal method to find matches based on a [pattern] or [rawObject] in the [Delta] operations.
  ///
  /// This method performs the core logic for matching operations based on the specified criteria.
  ///
  /// - [pattern]: The string pattern to search for.
  /// - [rawObject]: The object to search for within the operations.
  /// - [operationOffset]: The starting offset in the operations to begin the search.
  /// - [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive.
  /// - [onlyOnce]: Whether to stop after the first match is found.
  ///
  /// Returns a list of matching [DeltaRangeResult]s.
  List<DeltaRangeResult> _matches({
    RegExp? pattern,
    Object? rawObject,
    int? operationOffset,
    bool onlyOnce = false,
  }) {
    final inputClone = getDelta().normalize();
    if (operationOffset != null && (operationOffset < 0 || operationOffset >= inputClone.length)) {
      throw StateError('Invalid offset operation passed [$operationOffset] | available [${inputClone.length}]');
    }
    List<DeltaRangeResult> parts = [];
    int globalOffset = globalOpIndexToGlobalCharIndex(operationOffset ?? 0, inputClone.operations);
    for (int offset = operationOffset ?? 0; offset < inputClone.length; offset++) {
      final op = inputClone.elementAt(offset);
      if (parts.isNotEmpty && onlyOnce) {
        return [...parts];
      }
      if (pattern != null) {
        final RegExp expression = pattern;
        if (expression.hasMatch(op.data.toString())) {
          final matches = expression.allMatches(op.data.toString());
          for (var match in matches) {
            final Delta delta = Delta();
            parts.add(DeltaRangeResult(
              delta: delta
                ..insert(
                  op.data.toString().substring(match.start, match.end),
                  op.attributes,
                ),
              startOffset: globalOffset + match.start,
              endOffset: globalOffset + match.end,
            ));
            if (parts.isNotEmpty && onlyOnce) {
              return [...parts];
            }
          }
          globalOffset += op.data is String ? op.data!.toString().length : 1;
          continue;
        }
      } else if (rawObject != null) {
        if (op.data is Map && rawObject is Map) {
          if (mapEquals(op.data! as Map, rawObject)) {
            final Delta delta = Delta();
            final startOffset = globalOffset;
            final endOffset = op.data is String ? globalOffset + op.data.toString().length : globalOffset + 1;
            parts.add(DeltaRangeResult(
              delta: delta
                ..insert(
                  op.data,
                  op.attributes,
                ),
              startOffset: startOffset,
              endOffset: endOffset,
            ));
            if (parts.isNotEmpty && onlyOnce) {
              return [...parts];
            }
            globalOffset += op.data is String ? op.data!.toString().length : 1;
            continue;
          }
        } else {
          final RegExp expression = RegExp(rawObject.toString());
          if (expression.hasMatch(op.data.toString())) {
            final matches = expression.allMatches(op.data.toString());
            for (var match in matches) {
              final Delta delta = Delta();
              parts.add(DeltaRangeResult(
                delta: delta
                  ..insert(
                    op.data.toString().substring(match.start, match.end),
                    op.attributes,
                  ),
                startOffset: globalOffset + match.start,
                endOffset: globalOffset + match.end,
              ));
              if (parts.isNotEmpty && onlyOnce) {
                return [...parts];
              }
            }
          }
        }
      }
      globalOffset += op.data is String ? op.data!.toString().length : 1;
    }
    return [...parts];
  }

  /// Apply any type of Attribute in any part of you text
  ///
  /// * [offset] is used as the point where the changes will start
  /// * [len] is used to know what the len in characters of how many characters will apply the new Attribute
  /// * [attribute] the Attribute that will be applied to the matched text or embed, or the selected text into the range of the [offset] and [len]
  /// * [target] is an alternative to match a portion of the Delta where we need to make the change (can be String or a Map)
  ///
  /// # Notes
  /// 1. If the offset and the len match into a same Operation and the Attribute is block scope, the len will be ignored and only apply the Attribute to the entire Operation
  /// 2. The target by now can only match with text or an Map into a same Operation. This means that you put all document text as a the target, this will never make a match as we expect, since is limited to the object into the Operation
  /// 3. If the Attribute is inline and the len is not passed will throw an assert error
  QueryDelta format({
    required int? offset,
    int? len,
    required Attribute attribute,
    Object? target,
    bool caseSensitive = false,
  }) {
    assert(target == null || (target is String && target.isNotEmpty) || (target is Map && target.isNotEmpty),
        'target can be only String or Map');
    assert((target == null || target is Map) || target is String && !target.hasOnlyNewLines,
        'target cannot contain newlines');
    assert(
      (!attribute.isInline || attribute.isInline && target != null) ||
          attribute.isInline && (len != null && len > 0),
      'len cannot be null or less than zero, or the target '
      'cannot be undefined if the Attribute(${attribute.runtimeType}) is inline',
    );
    return push(
      FormatCondition(
        target: target,
        attribute: attribute,
        offset: offset,
        len: len,
        caseSensitive: caseSensitive,
      ),
    );
  }

  // will remove the block attributes, and, if the len is major than zero
  // it removes too the inline attrs in range
  QueryDelta removeFormat({
    required int offset,
    required int len,
  }) {
    return push(
      RemoveFormattingCondition(
        range: DeltaRange(
          startOffset: offset,
          endOffset: len <= 0 ? offset : len + offset,
        ),
      ),
    );
  }

  /// Creates a condition where will be inserted the object
  /// at the place that we expect or specify
  ///
  /// - [insert] is the object that gonna be inserted into the [Delta]
  /// - [possibleTarget] is an object that could be a [String] or a [Map<String, dynamic>] that is used to match a part of the data of a [Operation] or directly match with all [Operation]
  /// - [startPoint] decides where starts the execution of the insert method
  /// - [asDifferentOp] decides if the object to be inserted will be part of its own Operation or will be joined with the matched target
  /// - [left] decides if the insertion will be do it at the left or the right of the [possibleTarget] match
  /// - [onlyOnce] decides if the insert will be do it one or more times (only apply when [startPoint] is null)
  ///
  /// # Types for insert
  ///
  /// [InsertCondition] only accepts these types of values:
  ///
  ///   - [Map]
  ///   - [String]
  ///   - [Operation] or [List<Operation>]
  ///
  /// # Types for possibleTarget
  ///
  /// [InsertCondition] only accepts these types of values:
  ///
  ///   - [Map<String, dynamic>]
  ///   - [String]
  ///
  /// # Note
  /// if [startPoint] is not null, then the object will be inserted at that point
  /// and [possibleTarget], [left], and [onlyOnce] params will be ignored
  QueryDelta insert({
    required Object insert,
    required Object? target,
    int? startPoint,
    bool left = false,
    bool onlyOnce = false,
    bool asDifferentOp = false,
    bool insertAtLastOperation = false,
    bool caseSensitive = false,
  }) {
    int? offset = startPoint;
    if (target == null && startPoint == null) offset = 0;
    return push(
      InsertCondition(
        target: offset != null ? null : target,
        insertion: asDifferentOp || insert is Map ? insert.toOperation() : insert,
        range: insertAtLastOperation || offset == null ? null : DeltaRange.onlyStartPoint(startOffset: offset),
        left: startPoint != null ? true : left,
        onlyOnce: startPoint != null ? true : onlyOnce,
        insertAtLastOperation: startPoint != null || target != null ? false : insertAtLastOperation,
        caseSensitive: caseSensitive,
      ),
    );
  }

  /// Creates a [Condition] where the part selected
  /// cannot be modified or removed.
  ///
  /// * [offset] works at two different ways. If len is null, then [offset] will be considered as the length of the ignored part.
  ///   Example 1: if you pass only the [offset] and not the [len], then all chars before the [offset] will be ignore (similar to retain() method from Operation).
  ///   Example 2: if you pass the [offset] and the [len], then all chars into the range of the [offset] and [len] will be ignored and any condition cannot be applied there
  /// * [len] the char length of the ignored part
  /// * [ignoreLength] only use this when you want to ignore a [Operation] with a [Embed] as its data
  QueryDelta ignorePart(int offset, {int? len, bool ignoreLen = false}) {
    assert(offset >= 0, 'offset cannot be less than zero');
    assert(len == null || len > 0, 'len cannot be equals or less than zero');
    return push(
      IgnoreCondition(
        offset: ignoreLen
            ? offset
            : len == null
                ? 0
                : offset,
        len: ignoreLen ? 0 : (len ?? offset),
      ),
    );
  }

  QueryDelta delete({
    required Object? possibleTarget,
    required int? startPoint,
    required int? lengthOfDeletion,
    bool onlyOnce = true,
    bool caseSensitive = false,
  }) {
    final target = possibleTarget ?? '';
    assert(startPoint == null || startPoint >= 0, 'startPoint cannot be less of zero');
    assert(lengthOfDeletion == null || lengthOfDeletion > 0, 'lengthOfDeletion cannot be less of zero');
    assert(target != '\n' && target != '\\n', 'target cannot be "\\n"');
    return push(
      DeleteCondition(
        target: target,
        offset: startPoint ?? -1,
        lengthOfDeletion: lengthOfDeletion ?? -1,
        onlyOnce: onlyOnce,
        caseSensitive: caseSensitive,
      ),
    );
  }

  QueryDelta replace({
    required Object replace,
    required Object? target,
    required DeltaRange? range,
    bool onlyOnce = false,
    bool caseSensitive = false,
  }) {
    if (target == null && range == null) {
      throw Exception('target and range are null or invalid to use. Them cannot be null');
    }
    return push(
      ReplaceCondition(
        target: target,
        replace: replace,
        range: range,
        onlyOnce: range != null ? true : onlyOnce,
        caseSensitive: caseSensitive,
      ),
    );
  }
}

extension DiffDelta on QueryDelta {
  // Get the diff between the changes applied to the Delta
  // and the original version passed before run the build method
  DeltaCompareDiffResult compareDiff() {
    final diffParts = <DeltaDiffPart>[];
    final original = params['original_version'] as Delta;
    final modified = getDelta();

    int originalIndex = 0;
    int modifiedIndex = 0;
    int currentPosition = 0;

    while (originalIndex < original.length || modifiedIndex < modified.length) {
      final originalOp = originalIndex < original.length ? original.elementAt(originalIndex) : null;
      final modifiedOp = modifiedIndex < modified.length ? modified.elementAt(modifiedIndex) : null;

      if (originalOp == null) {
        // Add remaining parts from modified (added parts)
        final int addedLength = modifiedOp!.getEffectiveLength;
        diffParts.add(DeltaDiffPart(
          before: 'no-before-state',
          after: modifiedOp.data,
          start: currentPosition,
          end: currentPosition + addedLength,
          args: {
            'isAddedPart': true,
            'originalOp': 'no-original-op',
            'modifiedOp': modifiedOp,
          },
        ));
        currentPosition += addedLength;
        modifiedIndex++;
      } else if (modifiedOp == null) {
        // Add remaining parts from original (removed parts)
        final int removedLength = originalOp.getEffectiveLength;
        diffParts.add(DeltaDiffPart(
          before: originalOp.data!,
          after: null,
          start: currentPosition,
          end: currentPosition + removedLength,
          args: {
            'isRemovedPart': true,
            'originalOp': originalOp,
            'modifiedOp': 'no-modified-op',
          },
        ));
        currentPosition += removedLength;
        originalIndex++;
      } else if (originalOp.data == modifiedOp.data) {
        // No change
        currentPosition += originalOp.getEffectiveLength;
        originalIndex++;
        modifiedIndex++;
      } else if (originalOp.data != modifiedOp.data) {
        final String originalText = originalOp.data.toString();
        final String modifiedText = modifiedOp.data.toString();
        final int commonLength =
            originalText.length < modifiedText.length ? originalText.length : modifiedText.length;

        String accumulatedBefore = '';
        String accumulatedAfter = '';

        for (int i = 0; i < commonLength; i++) {
          if (originalText[i] != modifiedText[i]) {
            accumulatedBefore += originalText[i];
            accumulatedAfter += modifiedText[i];
          } else {
            if (accumulatedBefore.isNotEmpty || accumulatedAfter.isNotEmpty) {
              diffParts.add(DeltaDiffPart(
                before: accumulatedBefore,
                after: accumulatedAfter,
                start: currentPosition,
                end: currentPosition + accumulatedBefore.length,
                args: {
                  'isUpdatedPart': true,
                  'originalOp': originalOp,
                  'modifiedOp': modifiedOp,
                },
              ));
              // Limpiar el acumulador para futuras diferencias
              accumulatedBefore = '';
              accumulatedAfter = '';
            }
          }
        }
        if (accumulatedBefore.isNotEmpty || accumulatedAfter.isNotEmpty) {
          diffParts.add(DeltaDiffPart(
            before: accumulatedBefore,
            after: accumulatedAfter,
            start: currentPosition,
            end: currentPosition + accumulatedBefore.length,
            args: {
              'isUpdatedPart': true,
              'originalOp': originalOp,
              'modifiedOp': modifiedOp,
            },
          ));
        }
        currentPosition += commonLength;
        originalIndex++;
        modifiedIndex++;
      }
    }
    return DeltaCompareDiffResult(diffParts: diffParts);
  }
}
