import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/delta_range_error.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import '../../conditions.dart';
import '../util/enums.dart';
import '../change/delta_change.dart';
import '../range/delta_range.dart';

@internal
List<Operation> replaceCondition(
  List<Operation> operations,
  ReplaceCondition condition, [
  List<DeltaRange> partsToIgnore = const <DeltaRange>[],
  void Function(DeltaChange)? registerChange,
  OnCatchCallback? onCatch,
]) {
  final List<Operation> modifiedOps = <Operation>[];
  final Object? target = condition.target;
  final RegExp? pattern = !condition.checkIfTargetIsValidToBePattern
      ? null
      : RegExp(
          '$target',
          caseSensitive: condition.caseSensitive,
        );
  final DeltaRange? range = condition.range;
  final Object replace = condition.replace;
  if (target is! Map && pattern == null && range == null) return operations;
  int globalOffset = 0;
  bool addRestOfOps = false;
  List<int> indexToIgnore = <int>[];
  int indexToInsertSpecialReplace = -1;
  Operation? specialReplacedOperation;
  final bool isListOperation = replace is List<Operation>;
  final bool isEmbed = replace is Map;
  final bool isOperation = replace is Operation;
  for (int index = 0; index < operations.length; index++) {
    final Operation op = operations.elementAt(index);
    final Object? data = op.data;
    final int opLength = op.getEffectiveLength;
    if (indexToIgnore.contains(index)) {
      globalOffset += opLength;
      continue;
    }
    if (indexToInsertSpecialReplace == index) {
      modifiedOps.add(specialReplacedOperation!);
      continue;
    }
    if (addRestOfOps) {
      modifiedOps.add(op);
      continue;
    }
    if (range != null) {
      final int currentGlobalOffset = globalOffset + (opLength);
      final int startOffset = (range.startOffset - globalOffset).nonNegativeInt;
      final int endOffset = (range.endOffset - globalOffset).nonNegativeInt;
      final bool replaceIsOutOfRangeOfThisOperation = range.startOffset >= currentGlobalOffset;
      // check if we only need to add this operation
      // since we are out of the range of the
      // replace operation
      if (replaceIsOutOfRangeOfThisOperation) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      // check if we only need to add these operations since the
      // offsets could be less that we expect
      if (partsToIgnore.ignoreOverlap(
        DeltaRange(startOffset: startOffset, endOffset: endOffset),
      )) {
        addRestOfOps = true;
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      if (currentGlobalOffset > range.startOffset && !addRestOfOps) {
        // some embeds can be replaced easily only passing the same offset in DeltaRange
        if (op.isEmbed && startOffset == endOffset) {
          globalOffset += opLength;
          continue;
        }
        // we need to check first if is we really need to search for other operations to replace
        // because if the cursor selection if into the operation range, then we don't need to
        // make unnecessary traversal operations
        bool isIntoRange = range.startOffset < currentGlobalOffset && range.endOffset <= currentGlobalOffset;
        final (Operation? specialOp, int specialIndex, bool useOpLength, bool addRest, bool ignoreCondition) =
            _mergeIfNeeded(
          range: range,
          isIntoRange: isIntoRange,
          globalOffset: globalOffset,
          opLength: opLength,
          data: data,
          startOffset: startOffset,
          endOffset: endOffset,
          index: index,
          operations: operations,
          indexToIgnore: indexToIgnore,
          registerChange: registerChange,
          onCatch: onCatch,
        );
        if (ignoreCondition) return operations;
        addRestOfOps = addRest;
        specialReplacedOperation = specialOp;
        indexToInsertSpecialReplace = specialIndex;
        if (isEmbed || isOperation) {
          final Operation leftOp = op.clone(data is! String ? null : data.substring(0, startOffset));
          final Operation mainOp = isEmbed ? Operation.insert(replace) : replace as Operation;
          final Operation righOp = op.clone(data is! String ? null : data.substring(endOffset));
          modifiedOps.addAll(<Operation>[
            leftOp,
            mainOp,
            righOp,
          ]);
          registerChange?.call(
            DeltaChange(
              change: <String, Object>{
                'original_op': op,
                'new_ops': <Operation>[
                  leftOp,
                  mainOp,
                  righOp,
                ],
              },
              startOffset: range.startOffset,
              endOffset: range.startOffset + opLength,
              type: ChangeType.replace,
            ),
          );
        } else if (isListOperation) {
          final Operation leftOp = op.clone(data is! String ? null : data.substring(0, startOffset));
          final List<Operation> mainOps = <Operation>[...replace];
          final Operation righOp = op.clone(data is! String ? null : data.substring(endOffset));
          modifiedOps.addAll(<Operation>[
            leftOp,
            ...mainOps,
            righOp,
          ]);
          registerChange?.call(
            DeltaChange(
              change: mainOps,
              startOffset: range.startOffset,
              endOffset: range.startOffset + mainOps.getEffectiveLength,
              type: ChangeType.replace,
            ),
          );
        } else {
          final String leftPart = data is! String ? '' : data.substring(0, startOffset);
          final String rightPart = data is! String ? '' : data.substring(useOpLength ? opLength : endOffset);
          final Operation mainOp = Operation.insert(
            '$leftPart${condition.replace}$rightPart',
            data is Map ? null : op.attributes,
          );
          if (mainOp.ignoreIfEmpty) {
            registerChange?.call(
              DeltaChange(
                change: <String, Object>{
                  'is_selected_op': true,
                  'len_op': opLength,
                  'original_op': op,
                  'replace_by_empty_data': true,
                },
                startOffset: startOffset,
                endOffset: useOpLength ? opLength : endOffset,
                type: ChangeType.delete,
              ),
            );
            globalOffset += opLength;
            continue;
          }
          modifiedOps.add(mainOp);
          registerChange?.call(
            DeltaChange(
              change: mainOp,
              startOffset: startOffset,
              endOffset: endOffset,
              type: ChangeType.replace,
            ),
          );
        }
      }
      addRestOfOps = true;
      globalOffset += opLength;
      continue;
    }
    if (target is Map && data is Map) {
      if (mapEquals(target, data)) {
        int startAndEndOffset = globalOffset;
        if (partsToIgnore
            .ignoreOverlap(DeltaRange(startOffset: startAndEndOffset, endOffset: startAndEndOffset))) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        final Operation mainOp = Operation.insert(
          condition.replace,
          condition.replace is Map ? op.attributes : null,
        );
        modifiedOps.add(mainOp);
        registerChange?.call(
          DeltaChange(
            change: <String, Operation>{
              'original_op': op,
              'change': mainOp,
            },
            startOffset: startAndEndOffset,
            endOffset: startAndEndOffset,
            type: ChangeType.replace,
          ),
        );
        if (condition.onlyOnce) addRestOfOps = true;
        globalOffset += opLength;
        continue;
      }
      modifiedOps.add(op);
      globalOffset += opLength;
      continue;
    }
    if (pattern != null && pattern.hasMatch('$data')) {
      if (data is! String) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      // this is for different matches in a same line
      final List<DeltaRange> deltaPartsToMerge = <DeltaRange>[];
      final Iterable<RegExpMatch> matches = pattern.allMatches(data);
      for (RegExpMatch match in matches) {
        final startOffset = match.start;
        final endOffset = match.end;
        if (partsToIgnore.ignoreOverlap(
            DeltaRange(startOffset: startOffset + globalOffset, endOffset: endOffset + globalOffset))) {
          continue;
        }
        deltaPartsToMerge.add(DeltaRange(startOffset: startOffset, endOffset: endOffset));
      }
      if (deltaPartsToMerge.isEmpty) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      StringBuffer buffer = StringBuffer();
      List<Operation> dividedOps = <Operation>[];

      ///TODO: use the parts to merge to create DeltaChanges
      for (int i = 0; i < deltaPartsToMerge.length; i++) {
        final DeltaRange partToMerge = deltaPartsToMerge.elementAt(i);
        final DeltaRange? nextPartToMerge = deltaPartsToMerge.elementAtOrNull(i + 1);
        if (replace is String) {
          if (i == 0) {
            buffer
              ..write(data.substring(0, partToMerge.startOffset))
              ..write(replace)
              ..write(
                data.substring(
                  partToMerge.endOffset,
                  nextPartToMerge?.startOffset,
                ),
              );
          } else {
            buffer
              ..write(replace)
              ..write(
                data.substring(
                  partToMerge.endOffset,
                  nextPartToMerge?.startOffset,
                ),
              );
          }
        } else if (i == 0) {
          dividedOps.add(Operation.insert(data.substring(0, partToMerge.startOffset), op.attributes));
          if (isEmbed) {
            dividedOps.add(Operation.insert(replace));
          } else if (isListOperation) {
            dividedOps.addAll(replace);
          } else {
            dividedOps.add(replace as Operation);
          }
          dividedOps.add(
            Operation.insert(
              data.substring(
                partToMerge.endOffset,
                nextPartToMerge?.startOffset,
              ),
              op.attributes,
            ),
          );
        } else {
          if (isEmbed) {
            dividedOps.add(Operation.insert(replace));
          } else if (isListOperation) {
            dividedOps.addAll(replace);
          } else {
            dividedOps.add(replace as Operation);
          }
          dividedOps.add(
            Operation.insert(
              data.substring(partToMerge.endOffset, nextPartToMerge?.startOffset),
              op.attributes,
            ),
          );
        }
        //end of match loop
      }
      if (buffer.isNotEmpty) {
        final Operation mainOp = Operation.insert(buffer.toString(), op.attributes);
        modifiedOps.add(mainOp);
      }
      modifiedOps.addAll(dividedOps);
      if (condition.onlyOnce) addRestOfOps = true;
      globalOffset += opLength;
      continue;
    }
    globalOffset += opLength;
    modifiedOps.add(op);
  }
  if (modifiedOps.isEmpty) return operations;
  return modifiedOps;
}

(Operation?, int, bool, bool, bool) _mergeIfNeeded({
  required DeltaRange range,
  required bool isIntoRange,
  required int globalOffset,
  required int opLength,
  required Object? data,
  required int startOffset,
  required int endOffset,
  required int index,
  required List<Operation> operations,
  required List<int> indexToIgnore,
  void Function(DeltaChange)? registerChange,
  OnCatchCallback? onCatch,
}) {
  int indexToInsertSpecialReplace = -1;
  Operation? specialReplacedOperation;
  bool useOpLength = false;
  bool addRestOfOps = false;
  if (range.endOffset > opLength && !isIntoRange) {
    int cloneGlobal = globalOffset;
    int localPerRemoveOffset = range.startOffset != 0 ? 0 : range.endOffset - opLength;
    if (localPerRemoveOffset == 0) {
      int effectiveOffsetPerRemove = data.toString().substring(startOffset).length;
      localPerRemoveOffset = (range.endOffset - range.startOffset) - effectiveOffsetPerRemove;
    }
    // in some cases, we are selecting an entire operation
    // and does not need to be replaced a special part of the ops
    bool nonNeedSpecialInsert = false;
    // buscamos hacia delante una op que satisfaga
    for (int j = index + 1; j < operations.length; j++) {
      if (localPerRemoveOffset <= 0) break;
      // ignore last
      if (j + 1 >= operations.length) break;
      final Operation? nextOp = operations.elementAtOrNull(j);
      // check if the current element is the last operation
      // in [Delta]
      if (nextOp == null && index + 1 == j || nextOp == null) break;
      final Object? nextData = nextOp.data;
      final int nextOpLength = nextOp.getEffectiveLength;
      if (localPerRemoveOffset > nextOpLength || localPerRemoveOffset == nextOpLength) {
        localPerRemoveOffset -= nextOpLength;
        indexToIgnore.add(j);
        if (localPerRemoveOffset <= 0) {
          registerChange?.call(
            DeltaChange(
              change: nextOp,
              startOffset: cloneGlobal,
              endOffset: cloneGlobal + nextOpLength,
              type: ChangeType.delete,
            ),
          );
          nonNeedSpecialInsert = true;
          break;
        }
        registerChange?.call(
          DeltaChange(
            change: nextOp,
            startOffset: cloneGlobal,
            endOffset: cloneGlobal + nextOpLength,
            type: ChangeType.ignore,
          ),
        );
      } else if (localPerRemoveOffset < nextOpLength) {
        if (localPerRemoveOffset == 0) break;
        specialReplacedOperation =
            Operation.insert(nextData.toString().substring(localPerRemoveOffset), nextOp.attributes);
        registerChange?.call(
          DeltaChange(
            change: <String, Operation>{
              'original_op': nextOp,
              'change': specialReplacedOperation,
            },
            startOffset: cloneGlobal,
            endOffset: cloneGlobal + localPerRemoveOffset,
            type: ChangeType.replace,
          ),
        );
        localPerRemoveOffset = 0;
        indexToInsertSpecialReplace = j;
        break;
      }
      cloneGlobal += nextOpLength;
      indexToIgnore.add(j);
    }
    // check if the indexToIgnore is not empty
    // if it is, then the endOffset is out of range and
    // cannot be accepted as a valid argument
    if (indexToInsertSpecialReplace == -1 && !nonNeedSpecialInsert) {
      final int maxLength = operations.getEffectiveLength;
      final DeltaRangeError err = DeltaRangeError.range(
        range.endOffset,
        0,
        maxLength,
        'out',
        'Invalid values',
      );
      if (onCatch != null) {
        onCatch.call(err);
        return (specialReplacedOperation, indexToInsertSpecialReplace, useOpLength, addRestOfOps, true);
      }
      throw err;
    }
    useOpLength = true;
    addRestOfOps = true;
  }
  return (specialReplacedOperation, indexToInsertSpecialReplace, useOpLength, addRestOfOps, false);
}
