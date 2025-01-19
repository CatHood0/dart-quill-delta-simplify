import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/string_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/delta/denormalizer_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/list_attrs_ext.dart';
import 'package:diff_match_patch/diff_match_patch.dart' as dmp;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../util/op_offset_to_char_offset.dart';

extension EssentialsQueryExt on QueryDelta {
  /// Matches operations in a [Delta] based on specific [Attributes].
  ///
  /// * [inlineAttrs]: A map of inline attributes to match against the operations.
  /// * [blockAttrs]: A map of block attributes to match against the operations.
  /// * [blockAttrKeys]: A list of block attribute keys to match against the operations.
  /// * [inlineAttrKeys]: A list of inline attribute keys to match against the operations.
  /// * [strictKeysCheck]: If `true`, only matches operations where all specified keys are present.
  /// * [onlyOnce]: If `true`, stops searching after the first match.
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/matching.md#matching-attributes)
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
  /// * [pattern]: The string pattern to search for.
  /// * [rawObject]: The object to search for within the operations.
  /// * [operationIndex]: The index of the operation.
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/matching.md#first-match)
  DeltaRangeResult? firstMatch(
    RegExp? pattern,
    Object? rawObject, {
    int? operationIndex,
  }) {
    // check if the index of the operation passed, is illegal
    if (operationIndex != null && (operationIndex < 0 || operationIndex >= getDelta().length)) {
      throw IllegalParamsValuesException(
        illegal: operationIndex,
        expected: {'start': 0, 'end': getDelta().length},
      );
    }
    return _matches(
      pattern: pattern,
      rawObject: rawObject,
      operationOffset: operationIndex,
      onlyOnce: true,
    ).firstOrNull;
  }

  /// Finds all matches of the given [pattern] or [rawObject] in the [Delta] operations list.
  ///
  /// * [pattern]: The string pattern to search for.
  /// * [rawObject]: The object to search for within the operations.
  /// * [operationIndex]: The index of the operation.
  /// * [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive. Defaults to `false`.
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/matching.md#multiple-occurrence-matches)
  List<DeltaRangeResult> allMatches(
    RegExp? pattern,
    Object? rawObject, {
    int? operationIndex,
  }) {
    return _matches(
      pattern: pattern,
      rawObject: rawObject,
      operationOffset: operationIndex,
      onlyOnce: false,
    );
  }

  /// Matches operations in the [Delta] based on specified attributes.
  ///
  /// * [inlineAttrs]: The inline attributes to match.
  /// * [blockAttrs]: The block attributes to match.
  /// * [blockAttrKeys]: The keys of block attributes to match.
  /// * [inlineAttrKeys]: The keys of inline attributes to match.
  /// * [strictKeysCheck]: Whether to strictly check for the presence of all keys. Defaults to `true`.
  /// * [onlyOnce]: Whether to stop after the first match is found. Defaults to `false`.
  List<DeltaRangeResult> _attrMatches({
    Attributes? inlineAttrs,
    Attributes? blockAttrs,
    List<String>? blockAttrKeys,
    List<String>? inlineAttrKeys,
    bool strictKeysCheck = true,
    bool onlyOnce = false,
  }) {
    final Delta inputClone = getDelta().denormalize();
    List<DeltaRangeResult> parts = [];
    int globalOffset = 0;
    for (int index = 0; index < inputClone.length; index++) {
      final Operation op = inputClone.elementAt(index);
      final Object? opData = op.data;
      final int opLength = op.getEffectiveLength;
      if (inlineAttrKeys != null) {
        if (op.containsAttrs(inlineAttrKeys, strictKeysCheck)) {
          parts.add(
            DeltaRangeResult(
              delta: Delta.fromOperations(
                <Operation>[op],
              ),
              startOffset: globalOffset,
              endOffset: globalOffset + opLength,
            ),
          );
          if (parts.isNotEmpty && onlyOnce) {
            return <DeltaRangeResult>[...parts];
          }
          globalOffset += opLength;
          continue;
        }
      }
      if (blockAttrKeys != null) {
        if (op.isBlockLevelInsertion) {
          if (op.containsAttrs(blockAttrKeys, strictKeysCheck)) {
            int startOffset = globalOffset;
            int endOffset = globalOffset + opLength;
            List<Operation> operationsWithAttrsApplied = <Operation>[];
            for (int index2 = index - 1; index2 >= 0; index2--) {
              final Operation beforeOp = inputClone.elementAt(index2);
              final Object? opData = beforeOp.data;
              if (op.isEmbed) break;
              if (opData is String) {
                if (opData.contains('\n')) break;
                operationsWithAttrsApplied.insert(0, beforeOp);
              }
              startOffset -= beforeOp.getEffectiveLength;
            }
            operationsWithAttrsApplied = <Operation>[...operationsWithAttrsApplied, op];
            parts.add(
              DeltaRangeResult(
                delta: Delta.fromOperations(operationsWithAttrsApplied),
                startOffset: startOffset.nonNegativeInt,
                endOffset: endOffset.nonNegativeInt,
              ),
            );
            if (parts.isNotEmpty && onlyOnce) {
              return <DeltaRangeResult>[...parts];
            }
            globalOffset += opLength;
            continue;
          }
        }
      }
      if (inlineAttrs != null) {
        if (mapEquals(inlineAttrs, op.attributes)) {
          parts.add(
            DeltaRangeResult(
              delta: Delta.fromOperations(
                <Operation>[op],
              ),
              startOffset: globalOffset,
              endOffset: globalOffset + opLength,
            ),
          );
          if (parts.isNotEmpty && onlyOnce) {
            return <DeltaRangeResult>[...parts];
          }
          globalOffset += opLength;
          continue;
        }
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
            operationsWithAttrsApplied = <Operation>[...operationsWithAttrsApplied, op];
            parts.add(
              DeltaRangeResult(
                delta: Delta.fromOperations(operationsWithAttrsApplied),
                startOffset: startOffset.nonNegativeInt,
                endOffset: endOffset.nonNegativeInt,
              ),
            );
            if (parts.isNotEmpty && onlyOnce) {
              return <DeltaRangeResult>[...parts];
            }
            globalOffset += opLength;
            continue;
          }
        }
      }
      globalOffset += opLength;
    }
    return <DeltaRangeResult>[...parts];
  }

  /// Internal method to find matches based on a [pattern] or [rawObject] in the [Delta] operations.
  ///
  /// * [pattern]: The string pattern to search for.
  /// * [rawObject]: The object to search for within the operations.
  /// * [operationOffset]: The starting offset in the operations to begin the search.
  /// * [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive.
  /// * [onlyOnce]: Whether to stop after the first match is found.
  List<DeltaRangeResult> _matches({
    RegExp? pattern,
    Object? rawObject,
    int? operationOffset,
    bool onlyOnce = false,
  }) {
    final Delta inputClone = getDelta().denormalize();
    if (operationOffset != null && (operationOffset < 0 || operationOffset >= inputClone.length)) {
      throw StateError('Invalid offset operation passed [$operationOffset] | available [${inputClone.length}]');
    }
    List<DeltaRangeResult> parts = <DeltaRangeResult>[];
    int globalOffset = globalOpIndexToGlobalCharIndex(operationOffset ?? 0, inputClone.operations);
    for (int offset = operationOffset ?? 0; offset < inputClone.length; offset++) {
      final op = inputClone.elementAt(offset);
      if (parts.isNotEmpty && onlyOnce) {
        return [...parts];
      }
      if (pattern != null && op.data is String) {
        assert(
          pattern.pattern.trim().isNotEmpty && !pattern.pattern.contains('\n'),
          'the pattern passed cannot be empty or contain new lines',
        );
        final RegExp expression = pattern;
        if (expression.hasMatch(op.data.toString())) {
          final Iterable<RegExpMatch> matches = expression.allMatches(op.data.toString());
          for (RegExpMatch match in matches) {
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
      }
      if (rawObject != null) {
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
          assert(
            rawObject.toString().trim().isNotEmpty && !rawObject.toString().contains('\n'),
            'rawObject passed cannot be empty or contain new lines',
          );
          final RegExp expression = RegExp(rawObject.toString());
          if (expression.hasMatch(op.data.toString())) {
            final Iterable<RegExpMatch> matches = expression.allMatches(op.data.toString());
            for (RegExpMatch match in matches) {
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
                return <DeltaRangeResult>[...parts];
              }
            }
          }
        }
      }
      globalOffset += op.getEffectiveLength;
    }
    return <DeltaRangeResult>[...parts];
  }

  /// Apply any type of Attribute in any part of you text
  ///
  /// * [offset] is used as the point where the changes will start
  /// * [len] is used to know what the len in characters of how many characters will apply the new Attribute
  /// * [attribute] the Attribute that will be applied to the matched text or embed, or the selected text into the range of the [offset] and [len]
  /// * [target] is an alternative to match a portion of the Delta where we need to make the change (can be String or a Map)
  /// * [onlyOnce] decides if the format should be applied once more time
  ///
  /// # Notes
  /// 1. If the offset and the len match into a same Operation and the Attribute is block scope, the len will be ignored and only apply the Attribute to the entire Operation
  /// 2. The target by now can only match with text or an Map into a same Operation. This means that you put all document text as a the target, this will never make a match as we expect, since is limited to the object into the Operation
  /// 3. If the Attribute is inline and the len is not passed will throw an assert error
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/format.md#usage-examples)
  QueryDelta format({
    required Attribute attribute,
    required int? offset,
    required int? len,
    Object? target,
    bool caseSensitive = false,
    bool onlyOnce = false,
  }) {
    return push(
      FormatCondition(
        target: target,
        attribute: attribute,
        offset: offset,
        len: len,
        caseSensitive: caseSensitive,
        onlyOnce: onlyOnce,
      ),
    );
  }

  /// Creates a condition where will be inserted the object at the place that we expect or specify
  ///
  /// * [insert] is the object that gonna be inserted into the [Delta]
  /// * [target] is an object that could be a [String] or a [Map<String, dynamic>] that is used to match a part of the data of a [Operation] or directly match with all [Operation]
  /// * [startPoint] decides where starts the execution of the insert method
  /// * [asDifferentOp] decides if the object to be inserted will be part of its own Operation or will be joined with the matched target
  /// * [left] decides if the insertion will be do it at the left or the right of the [possibleTarget] match
  /// * [onlyOnce] decides if the insert will be do it one or more times (only apply when [startPoint] is null)
  ///
  /// # Types for insert
  ///
  /// [InsertCondition] only accepts these types of values:
  ///
  ///   * [Map]
  ///   * [String]
  ///   * [Operation] or [List<Operation>]
  ///
  /// # Types for possibleTarget
  ///
  /// [InsertCondition] only accepts these types of values:
  ///
  ///   * [Map<String, dynamic>]
  ///   * [String]
  ///
  /// # Note
  /// if [startPoint] is not null, then the object will be inserted at that point
  /// and [possibleTarget], [left], and [onlyOnce] params will be ignored
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/insert.md#usage-examples)
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

  /// Deletes a portion of text based on specified conditions.
  ///
  /// * [target]: The object representing the target to delete. It cannot be `'\n'` or `'\\n'`.
  /// * [startPoint]: The starting position of the deletion in the text. It must be a non-negative integer.
  /// * [lengthOfDeletion]: The length of text to delete, which must be greater than 0.
  /// * [onlyOnce]: A boolean indicating whether the deletion should happen only once. Default is `true`.
  /// * [caseSensitive]: A boolean indicating whether the deletion should be case-sensitive. Default is `false`.
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/delete.md#usage-examples)
  QueryDelta delete({
    required Object? target,
    required int? startPoint,
    required int? lengthOfDeletion,
    bool onlyOnce = true,
    bool caseSensitive = false,
  }) {
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

  /// Replaces a portion of text with a new value based on the provided conditions.
  ///
  /// * [replace]: The object representing the value to replace the target with.
  /// * [target]: The object representing the target to be replaced. It cannot be `null` if `range` is also `null`.
  /// * [range]: The range specifying the portion of text to replace. It cannot be `null` if `target` is `null`.
  /// * [onlyOnce]: A boolean indicating whether the replacement should occur only once. Default is `false`.
  /// * [caseSensitive]: A boolean indicating whether the replacement should be case-sensitive. Default is `false`.
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/replace.md#usage-examples)
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
  /// Get the diff between the changes applied to the Delta
  /// and the original version passed before run the build method
  ///
  /// You can see examples [here](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/diff.md#usage-examples)
  ///
  /// _This method is inspired on the original diff method from Delta class [Here](https://github.com/FlutterQuill/dart-quill-delta/blob/141f86aff1a65c14a25a6b59d76a4a23781c5d91/lib/src/delta/delta.dart#L310-L323)_
  DeltaCompareDiffResult compareDiff({bool cleanupSemantic = true}) {
    final Delta originalDelta = params.originalDelta;
    final Delta newDelta = getDelta();
    originalDelta.check();
    newDelta.check();
    if (listEquals(newDelta.operations, originalDelta.operations)) return DeltaCompareDiffResult(diffParts: []);

    final String stringThis = newDelta.toPlainBuilder(
      (op) => op.toPlain(
        embedBuilder: (Object e) => String.fromCharCode(0),
      ),
    );
    final String stringOther = originalDelta.toPlainBuilder(
      (op) => op.toPlain(
        embedBuilder: (Object e) => String.fromCharCode(0),
      ),
    );

    // we need to know the diff between the original and the modified Deltas
    final List<dmp.Diff> diffResult = dmp.diff(stringOther, stringThis);
    // removes duplicated ops
    if (cleanupSemantic) dmp.DiffMatchPatch().diffCleanupSemantic(diffResult);

    final DeltaIterator thisIter = DeltaIterator(newDelta);
    final DeltaIterator otherIter = DeltaIterator(originalDelta);

    final List<DeltaDiffPart> diffParts = [];
    int globalOffset = 0;

    for (final dmp.Diff component in diffResult) {
      int compTextLength = component.text.length;
      while (compTextLength > 0) {
        int opLength = 0;
        Object? before = null;
        Object? after = null;
        Map<String, dynamic> args = {};

        switch (component.operation) {
          case dmp.DIFF_INSERT:
            opLength = math.min(thisIter.peekLength(), compTextLength);
            after = thisIter.next(opLength).data;
            args = {'isAddedPart': true};
            break;
          case dmp.DIFF_DELETE:
            opLength = math.min(compTextLength, otherIter.peekLength());
            before = otherIter.next(opLength).data;
            args = {'isRemovedPart': true};
            break;
          case dmp.DIFF_EQUAL:
            opLength = math.min(math.min(otherIter.peekLength(), thisIter.peekLength()), compTextLength);
            final Operation thisOp = thisIter.next(opLength);
            final Operation otherOp = otherIter.next(opLength);
            if (!thisOp.hasSameAttributes(otherOp)) {
              args['diff_attributes'] = {
                'new': thisOp.attributes,
                'old': otherOp.attributes,
              };
              args['isUpdatedPart'] = true;
            }
            if (thisOp.data != otherOp.data) {
              before = thisOp.data;
              after = otherOp.data;
              args['isUpdatedPart'] = true;
            } else {
              if (!args.containsKey('diff_attributes')) args['isEquals'] = true;
              diffParts.add(DeltaDiffPart(
                before: thisOp.data,
                after: otherOp.data,
                start: globalOffset,
                end: globalOffset + opLength,
                args: args.isEmpty ? null : args,
              ));
            }
            break;
        }
        if (before != null || after != null) {
          diffParts.add(DeltaDiffPart(
            before: before,
            after: after,
            start: globalOffset,
            end: globalOffset + opLength,
            args: args..removeWhere((k, v) => k == 'diff_attributes'),
          ));
        }
        globalOffset += opLength;
        compTextLength -= opLength;
      }
    }
    return DeltaCompareDiffResult(diffParts: diffParts);
  }
}
