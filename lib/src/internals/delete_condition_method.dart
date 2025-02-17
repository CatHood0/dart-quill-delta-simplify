import 'package:dart_quill_delta_simplify/query_delta_exceptions.dart';
import 'package:dart_quill_delta_simplify/src/conditions/delete.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:meta/meta.dart';

import '../../delta_ranges.dart';
import '../util/collections.dart';

@internal
List<Operation> deleteCondition(
  List<Operation> operations,
  DeleteCondition condition, [
  List<DeltaRange> partsToIgnore = const <DeltaRange>[],
  OnCatchCallback? onCatch,
]) {
  final List<Operation> modifiedOps = <Operation>[];
  final Object? target = condition.target;
  final RegExp? pattern = condition.checkIfTargetIsValidToBePattern
      ? RegExp(
          '$target',
          caseSensitive: condition.caseSensitive,
        )
      : null;
  final DeltaRange? range = DeltaRange.deltaRangeOrNull(
      condition.offset, condition.offset + condition.lengthOfDeletion);
  if (range != null) {
    // if len of deletion is major than the entire Delta
    // then just return a empty list of operations
    if (range.endOffset > operations.getEffectiveLength) {
      return [...operations];
    }
  }
  // mutable len deletions
  int lengthOfDeletion = condition.lengthOfDeletion;
  // the global offset that will be updated at every iteration
  int globalOffset = 0;
  // decides if the rest of the ops will be added without modifications
  bool onlyAddRest = false;
  // we use this operation to insert into a specific index
  // because the change maded to this part is fundamental
  Operation? specialInsertion;
  int specialinsertionIndex = -1;
  // contains all indexs where the loop should ignore or non modify
  Set<int> indexToIgnore = <int>{};
  final List<Operation> ops = [...operations];
  for (int index = 0; index < ops.length; index++) {
    final Operation op = ops.elementAt(index);
    final Object? data = op.data;
    if (data == null)
      throw IllegalOperationPassedException(
          illegal: op, expected: op.clone(''));
    final int opLength = op.getEffectiveLength;
    if (indexToIgnore.contains(index)) {
      globalOffset += opLength;
      continue;
    }
    if (specialinsertionIndex == index) {
      modifiedOps.add(specialInsertion!);
      globalOffset += opLength;
      continue;
    }
    // will ignore rest of the modifications and add the rest of op
    if (onlyAddRest) {
      modifiedOps.add(op);
      continue;
    }
    if (target is Map && data is Map) {
      if (mapEquals(target, data)) {
        globalOffset += opLength;
        continue;
      }
    }
    if (range != null) {
      if (lengthOfDeletion == 0) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      final int currentGlobalOffset = globalOffset + opLength;
      // check if we are into the range of the operation that need to be modified
      final bool isOutOfRange = currentGlobalOffset <= range.startOffset;
      // check if we only need to add this operation
      // since we are out of the range of the
      // delete
      if (isOutOfRange) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
      final bool isIntoRange = isOutOfRange == false;
      if (isIntoRange) {
        final (len, specialOp, specialIndex) = _range(
          op: op,
          opLength: opLength,
          partsToIgnore: partsToIgnore,
          index: index,
          currentGlobalOffset: currentGlobalOffset,
          data: data,
          range: range,
          globalOffset: globalOffset,
          modifiedOps: modifiedOps,
          operations: ops,
          indexToIgnore: indexToIgnore,
          lengthOfDeletion: lengthOfDeletion,
        );
        if (specialIndex != -1) {
          specialinsertionIndex = specialIndex;
          specialInsertion = specialOp;
        }
        if (len != lengthOfDeletion) {
          lengthOfDeletion = len;
          onlyAddRest = true;
        }
        globalOffset += opLength;
        continue;
      }
    }
    if (data is String) {
      if (pattern != null && pattern.hasMatch(data)) {
        final Iterable<RegExpMatch> matches = pattern.allMatches(data);
        final currentGlobalOffset = globalOffset + opLength;
        _pattern(
          op: op,
          opLength: opLength,
          partsToIgnore: partsToIgnore,
          data: data,
          matches: matches,
          globalOffset: globalOffset,
          currentGlobalOffset: currentGlobalOffset,
          modifiedOps: modifiedOps,
          operations: ops,
          indexToIgnore: indexToIgnore,
          lengthOfDeletion: lengthOfDeletion,
          index: index,
        );
        if (condition.onlyOnce) onlyAddRest = true;
        globalOffset += opLength;
        continue;
      }
    }
    globalOffset += opLength;
    modifiedOps.add(op);
  }
  if (modifiedOps.isEmpty) return operations;
  return modifiedOps;
}

void _pattern({
  required Operation op,
  required int opLength,
  required Object data,
  required Iterable<RegExpMatch> matches,
  required int globalOffset,
  required int currentGlobalOffset,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required List<DeltaRange> partsToIgnore,
  required Set<int> indexToIgnore,
  required int lengthOfDeletion,
  required int index,
}) {
  final List<DeltaRange> deltaPartsToMerge = <DeltaRange>[];
  for (RegExpMatch match in matches) {
    final startOffset = match.start;
    final endOffset = match.end;
    if (partsToIgnore.ignoreOverlap(DeltaRange(
        startOffset: startOffset + globalOffset,
        endOffset: endOffset + globalOffset))) {
      continue;
    }
    deltaPartsToMerge
        .add(DeltaRange(startOffset: startOffset, endOffset: endOffset));
  }
  if (deltaPartsToMerge.isEmpty) {
    modifiedOps.add(op);
    globalOffset += opLength;
    return;
  }
  StringBuffer buffer = StringBuffer();
  for (int i = 0; i < deltaPartsToMerge.length; i++) {
    final DeltaRange partToMerge = deltaPartsToMerge.elementAt(i);
    final DeltaRange? nextPartToMerge =
        deltaPartsToMerge.elementAtOrNull(i + 1);
    if (data is String) {
      if (i == 0) {
        buffer
          ..write(data.substring(0, partToMerge.startOffset))
          ..write(
            data.substring(
              partToMerge.endOffset,
              nextPartToMerge?.startOffset,
            ),
          );
      } else {
        buffer.write(
          data.substring(
            partToMerge.endOffset,
            nextPartToMerge?.startOffset,
          ),
        );
      }
    }
  }
  if (buffer.isNotEmpty) {
    final Operation mainOp = op.clone(buffer.toString());
    modifiedOps.add(mainOp);
  } else {
    final int indexToAttrs = index + 1;
    if (indexToAttrs < operations.length) {
      final Operation blockAttrOp = operations.elementAt(indexToAttrs);
      operations[indexToAttrs] = blockAttrOp.clone(
        null,
        null,
        false,
        true,
      );
    }
  }
}

(int, Operation?, int) _range({
  required Operation op,
  required int opLength,
  required Object data,
  required DeltaRange range,
  required int globalOffset,
  required int currentGlobalOffset,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required List<DeltaRange> partsToIgnore,
  required Set<int> indexToIgnore,
  required int lengthOfDeletion,
  required int index,
}) {
  if (partsToIgnore.ignoreOverlap(range)) {
    modifiedOps.add(op);
    return (lengthOfDeletion, null, -1);
  }
  int len = lengthOfDeletion.toInt();
  final int localStartOffset =
      (range.startOffset - globalOffset).nonNegativeInt;
  final int localEndOffset = (range.endOffset - globalOffset).nonNegativeInt;
  // if the len is major than the length of the operation
  if (localEndOffset > opLength) {
    if (data is! String) {
      len--;
    } else {
      // verify if the local start offset is not zero
      // because if it is, then means that the entire Operation is selected
      // to be removed
      if (localStartOffset > 0) {
        final rawData = data.substring(0, localStartOffset);
        modifiedOps.add(op.clone(rawData));
        len -= (opLength - rawData.length).nonNegativeInt;
      } else {
        len -= opLength;
      }
    }

    final (specialOp, specialIndex, useOpLength, addRestOfOps, cachedLen) =
        _removeInRange(
      range: range,
      globalOffset: globalOffset,
      partsToIgnore: partsToIgnore,
      op: op,
      modifiedOps: modifiedOps,
      len: len,
      opLength: opLength,
      startOffset: localStartOffset,
      endOffset: localEndOffset,
      index: index,
      operations: operations,
      indexToIgnore: indexToIgnore,
    );
    len = cachedLen.nonNegativeInt;
    return (len, specialOp, specialIndex);
  } else {
    if (data is! String) {
      len = 0;
      return (len, null, -1);
    }
    if (localStartOffset > 0) {
      final leftPart = data.substring(0, localStartOffset);
      final rightPart = data.substring(localEndOffset);
      final rawData = '$leftPart$rightPart';
      modifiedOps.add(op.clone(rawData));
      len -= (opLength - rawData.length);
      return (len.nonNegativeInt, null, -1);
    } else {
      len -= opLength;
      if (!op.isNewLineOrBlockInsertion) {
        final indexToAttrs = index + 1;
        if (indexToAttrs < operations.length) {
          final blockAttrOp = operations.elementAt(indexToAttrs);
          operations[indexToAttrs] = blockAttrOp.clone(
            null,
            null,
            false,
            true,
          );
        }
      }
      return (len.nonNegativeInt, null, -1);
    }
  }
}

(Operation?, int, bool, bool, int) _removeInRange({
  required DeltaRange range,
  required int globalOffset,
  required int len,
  required int opLength,
  required int startOffset,
  required int endOffset,
  required int index,
  required Operation op,
  required List<Operation> operations,
  required List<Operation> modifiedOps,
  required List<DeltaRange> partsToIgnore,
  required Set<int> indexToIgnore,
}) {
  int indexToInsertSpecialReplace = -1;
  Operation? specialReplacedOperation;
  bool useOpLength = false;
  bool addRestOfOps = false;
  if (range.endOffset > opLength) {
    int cloneGlobal = globalOffset;
    int localPerRemoveOffset = len;
    // in some cases, we are selecting an entire operation
    // and does not need to be replaced a special part of the ops
    bool nonNeedSpecialInsert = false;
    // buscamos hacia delante una op que satisfaga
    for (int j = index + 1; j < operations.length; j++) {
      // ignore last
      if (j + 1 >= operations.length) break;
      final Operation? nextOp = operations.elementAtOrNull(j);
      // check if the current element is the last operation
      // in [Delta]
      if (nextOp == null) break;
      final Object? nextData = nextOp.data;
      final int nextOpLength = nextOp.getEffectiveLength;
      if (partsToIgnore.ignoreOverlap(DeltaRange(
          startOffset: cloneGlobal, endOffset: cloneGlobal + nextOpLength))) {
        continue;
      }
      if (localPerRemoveOffset > nextOpLength ||
          localPerRemoveOffset == nextOpLength) {
        if (nextData is String &&
            !nextOp.isNewLineOrBlockInsertion &&
            localPerRemoveOffset == nextOpLength) {
          final indexToAttrs = j + 1;
          if (indexToAttrs < operations.length) {
            final blockAttrOp = operations.elementAt(indexToAttrs);
            operations[indexToAttrs] = blockAttrOp.clone(
              null,
              null,
              false,
              true,
            );
          }
          localPerRemoveOffset = 0;
        }
        indexToIgnore.add(j);
        localPerRemoveOffset -= nextOpLength;
        if (localPerRemoveOffset <= 0) {
          nonNeedSpecialInsert = true;
          break;
        }
        cloneGlobal += nextOpLength;
        continue;
      } else if (localPerRemoveOffset < nextOpLength) {
        specialReplacedOperation =
            nextOp.clone(nextData.toString().substring(localPerRemoveOffset));
        localPerRemoveOffset = 0;
        indexToInsertSpecialReplace = j;
        break;
      }
      cloneGlobal += nextOpLength;
      localPerRemoveOffset -= nextOpLength;
      indexToIgnore.add(j);
    }
    // check if the indexToIgnore is not empty
    // if it is, then the endOffset is out of range and
    // cannot be accepted as a valid argument
    if (indexToInsertSpecialReplace == -1 && !nonNeedSpecialInsert) {
      final int maxLength = operations.getEffectiveLength;
      throw DeltaRangeError.range(
        range.endOffset,
        0,
        maxLength,
        'out',
        'Invalid value: Not in inclusive range 0..$maxLength: ${range.endOffset}',
      );
    }
    useOpLength = true;
    addRestOfOps = true;
  }
  return (
    specialReplacedOperation,
    indexToInsertSpecialReplace,
    useOpLength,
    addRestOfOps,
    len
  );
}
