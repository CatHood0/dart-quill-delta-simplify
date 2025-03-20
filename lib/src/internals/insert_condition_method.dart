import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:meta/meta.dart';
import '../util/collections.dart';

@internal
List<Operation> insertCondition(
  List<Operation> operations,
  InsertCondition condition, [
  List<DeltaRange> partsToIgnore = const <DeltaRange>[],
  OnCatchCallback? onCatch,
]) {
  final DeltaRange? range = condition.range;
  final List<Operation> modifiedOps = <Operation>[];
  final Object insertion = condition.insertion;
  final Object? target = condition.target;
  final bool shouldAddRangeToIgnorePart =
      range != null && target != null && range.point > 0;
  final bool isEmbed = insertion is Map;
  final bool isOperation = insertion is Operation && insertion.isInsert;
  final bool isListOperation = insertion is List<Operation>;
  if (shouldAddRangeToIgnorePart) {
    partsToIgnore.add(DeltaRange(startOffset: 0, endOffset: range.point));
  }
  if (insertion is Operation && !insertion.isInsert) return operations;
  final RegExp? pattern = target == null ||
          (target is String && target.isEmpty) ||
          target is! String
      ? null
      : RegExp(
          target,
          caseSensitive: condition.caseSensitive,
        );
  int globalOffset = 0;
  bool onlyAddRest = false;
  if (condition.insertAtLastOperation) {
    _insertAtLast(
      condition: condition,
      operations: operations,
      modifiedOps: modifiedOps,
      globalOffset: globalOffset,
      isEmbed: isEmbed,
      isOperation: isOperation,
      isListOperation: isListOperation,
    );
    if (shouldAddRangeToIgnorePart) {
      partsToIgnore.removeLast();
    }
    return modifiedOps.isEmpty ? operations : modifiedOps;
  }
  // main loop
  for (int index = 0; index < operations.length; index++) {
    final Operation op = operations.elementAt(index);
    final int opLength = op.getEffectiveLength;
    Object? ofData = op.data;
    // ignore last
    if (onlyAddRest) {
      modifiedOps.add(op);
      globalOffset += opLength;
      continue;
    }
    if (target is Map<String, dynamic> && ofData is Map<String, dynamic>) {
      if (mapEquals(target, ofData)) {
        _insertAtMap(
          condition: condition,
          operations: operations,
          modifiedOps: modifiedOps,
          globalOffset: globalOffset,
          isEmbed: isEmbed,
          isOperation: isOperation,
          isListOperation: isListOperation,
          op: op,
          opLength: opLength,
        );
      }
      if (range == null) {
        modifiedOps.add(op);
        globalOffset += opLength;
        continue;
      }
    }
    // the range works as expected only when target is null
    if (range != null && target == null) {
      final int nextGlocalOffset = globalOffset + (opLength);
      final int startOffset = range.startOffset - globalOffset;
      if (nextGlocalOffset > range.startOffset && !onlyAddRest) {
        if (partsToIgnore.ignoreOverlap(
            DeltaRange.onlyStartPoint(startOffset: range.startOffset))) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        onlyAddRest = true;
        if (isEmbed || isOperation) {
          final Operation leftOp = op.clone(
              ofData is! String ? null : ofData.substring(0, startOffset));
          final Operation mainOp = isEmbed
              ? Operation.insert(condition.insertion)
              : condition.insertion as Operation;
          final Operation righOp = op
              .clone(ofData is! String ? null : ofData.substring(startOffset));
          modifiedOps.addAll(<Operation>[
            leftOp,
            mainOp,
            righOp,
          ]);
        } else if (isListOperation) {
          final Operation leftOp = op.clone(
              ofData is! String ? null : ofData.substring(0, startOffset));
          final List<Operation> mainOp = condition.insertion as List<Operation>;
          final Operation righOp = op
              .clone(ofData is! String ? null : ofData.substring(startOffset));
          modifiedOps.addAll(<Operation>[
            leftOp,
            ...mainOp,
            righOp,
          ]);
        } else {
          final String leftPart =
              ofData is! String ? '' : ofData.substring(0, startOffset);
          final String rightPart =
              ofData is! String ? '' : ofData.substring(startOffset);
          final Operation mainOp = Operation.insert(
              '$leftPart${condition.insertion}$rightPart', op.attributes);
          modifiedOps.add(mainOp);
        }
        globalOffset += opLength;
        continue;
      }
    }
    // pattern
    if (ofData is String &&
        pattern != null &&
        pattern.hasMatch(ofData.toString())) {
      final Iterable<RegExpMatch> matches = pattern.allMatches(ofData);
      if (matches.length == 1) {
        final RegExpMatch match = matches.single;
        final int startGlobalOffset = match.start + globalOffset;
        final int endGlobalOffset = match.end + globalOffset;
        final int startOffset = match.start;
        final int endOffset = match.end;
        if (partsToIgnore.ignoreOverlap(DeltaRange(
            startOffset: startGlobalOffset, endOffset: endGlobalOffset))) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        if (isEmbed || isOperation) {
          final Operation leftOp = Operation.insert(
            ofData.substring(0, condition.left ? startOffset : endOffset),
            op.attributes,
          );
          final Operation mainOp = !isOperation
              ? Operation.insert(condition.insertion, null)
              : condition.insertion as Operation;
          final Operation righOp = Operation.insert(
            ofData.substring(condition.left ? startOffset : endOffset),
            op.attributes,
          );
          modifiedOps.addAll(<Operation>[
            leftOp,
            mainOp,
            righOp,
          ]);
        } else if (isListOperation) {
          final Operation leftOp = Operation.insert(
            ofData.substring(0, condition.left ? startOffset : endOffset),
            op.attributes,
          );
          final List<Operation> mainOp = condition.insertion as List<Operation>;
          final Operation righOp = Operation.insert(
            ofData.substring(condition.left ? startOffset : endOffset),
            op.attributes,
          );
          modifiedOps.addAll(<Operation>[
            leftOp,
            ...mainOp,
            righOp,
          ]);
        } else {
          if (condition.asDifferentOp) {
            final Operation leftOp = op.clone(
                ofData.substring(0, condition.left ? startOffset : endOffset));
            final Operation mainOp = op.clone(condition.insertion);
            final Operation righOp = op.clone(
                ofData.substring(condition.left ? startOffset : endOffset));
            modifiedOps.addAll(<Operation>[
              leftOp,
              mainOp,
              righOp,
            ]);
          } else {
            final String leftPart =
                ofData.substring(0, condition.left ? startOffset : endOffset);
            final String rightPart =
                ofData.substring(condition.left ? startOffset : endOffset);
            final Operation mainOp =
                op.clone('$leftPart${condition.insertion}$rightPart');
            modifiedOps.add(mainOp);
          }
        }
        globalOffset += opLength;
        continue;
      } else {
        // this is for different matches in a same line
        final List<DeltaRange> deltaPartsToMerge = <DeltaRange>[];
        for (RegExpMatch match in matches) {
          final int startOffset = match.start;
          final int endOffset = match.end;
          // ensure to take a correct start offset for insertions when the insertion will be
          // do it at the right of the word
          deltaPartsToMerge.add(
            DeltaRange(
              startOffset: startOffset,
              endOffset: endOffset,
            ),
          );
        }
        if (deltaPartsToMerge.isEmpty) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        final StringBuffer buffer = StringBuffer();
        final List<Operation> dividedOps = <Operation>[];
        final bool isRight = !condition.left;

        for (int i = 0; i < deltaPartsToMerge.length; i++) {
          final DeltaRange partToMerge = deltaPartsToMerge.elementAt(i);
          final DeltaRange? nextPartToMerge =
              deltaPartsToMerge.elementAtOrNull(i + 1);
          final bool shouldIgnorePart = partsToIgnore.ignoreOverlap(
            DeltaRange(
                startOffset: partToMerge.startOffset + globalOffset,
                endOffset: partToMerge.point + globalOffset),
          );
          if (insertion is String) {
            if (shouldIgnorePart) {
              buffer
                ..write(
                    ofData.substring(0, partToMerge.pointByDirection(!isRight)))
                ..write(insertion)
                ..write(
                  ofData.substring(
                    partToMerge.pointByDirection(!isRight),
                    nextPartToMerge?.startOffset ?? partToMerge.endOffset,
                  ),
                );
              continue;
            }
            _mergeInsertsStringsAtSameOperation(
              buffer: buffer,
              insertion: insertion,
              ofData: ofData,
              partToMerge: partToMerge,
              nextPartToMerge: nextPartToMerge,
              condition: condition,
              index: index,
            );
            continue;
          }
          if (shouldIgnorePart) {
            dividedOps.add(
              op.clone(
                ofData.substring(
                  0,
                  nextPartToMerge?.startOffset ?? partToMerge.endOffset,
                ),
              ),
            );
            continue;
          }
          _complexMergeInsertsInSameOperation(
            dividedOps: dividedOps,
            op: op,
            ofData: ofData,
            condition: condition,
            partToMerge: partToMerge,
            nextPartToMerge: nextPartToMerge,
            insertion: insertion,
            isStart: i == 0,
          );
        }
        if (buffer.isNotEmpty) modifiedOps.add(op.clone('$buffer'));
        modifiedOps.addAll(dividedOps);
      }
      if (condition.onlyOnce) onlyAddRest = true;
      globalOffset += opLength;
      continue;
    }
    globalOffset += opLength;
    modifiedOps.add(op);
    continue;
  }
  if (shouldAddRangeToIgnorePart) {
    partsToIgnore.removeLast();
  }
  if (modifiedOps.isEmpty) return operations;
  return modifiedOps;
}

void _complexMergeInsertsInSameOperation({
  required List<Operation> dividedOps,
  required Operation op,
  required String ofData,
  required InsertCondition condition,
  required DeltaRange partToMerge,
  required DeltaRange? nextPartToMerge,
  required Object insertion,
  required bool isStart,
}) {
  final bool isEmbed = insertion is Map;
  final bool isOperation = insertion is Operation && insertion.isInsert;
  final bool isListOperation = insertion is List<Operation>;
  final bool isRight = !condition.left;
  if (isStart) {
    dividedOps.add(
      op.clone(
        ofData.substring(
          0,
          partToMerge.pointByDirection(!isRight),
        ),
      ),
    );
  }

  // adds the match part at the left if the insertion
  // need to be do it at the right part
  if (isRight) {
    dividedOps.add(
      op.clone(ofData.substring(
        partToMerge.startOffset,
        partToMerge.endOffset,
      )),
    );
  }
  if (isEmbed) {
    dividedOps.add(Operation.insert(insertion));
  } else if (isListOperation) {
    dividedOps.addAll(insertion);
  } else if (isOperation) {
    dividedOps.add(insertion);
  }
  if (!isRight) {
    dividedOps.add(
      op.clone(ofData.substring(
        partToMerge.startOffset,
        partToMerge.endOffset,
      )),
    );
  }
  dividedOps.add(
    op.clone(
      ofData.substring(
        partToMerge.endOffset,
        nextPartToMerge?.startOffset,
      ),
    ),
  );
}

void _mergeInsertsStringsAtSameOperation({
  required StringBuffer buffer,
  required Object insertion,
  required String ofData,
  required DeltaRange partToMerge,
  required DeltaRange? nextPartToMerge,
  required InsertCondition condition,
  required int index,
}) {
  if (index == 0) {
    buffer
      ..write(ofData.substring(0, partToMerge.pointByDirection(condition.left)))
      ..write(insertion)
      ..write(
        ofData.substring(
          partToMerge.pointByDirection(condition.left),
          nextPartToMerge?.endOffset,
        ),
      );
  } else {
    buffer
      ..write(insertion)
      ..write(
        ofData.substring(
          partToMerge.endOffset,
          nextPartToMerge?.endOffset,
        ),
      );
  }
}

void _insertAtLast({
  required InsertCondition condition,
  required List<Operation> operations,
  required List<Operation> modifiedOps,
  required int globalOffset,
  required bool isEmbed,
  required bool isOperation,
  required bool isListOperation,
}) {
  modifiedOps.addAll(<Operation>[...operations]);
  if (operations.isNotEmpty) globalOffset += operations.getEffectiveLength;
  final Operation lastOp = modifiedOps.lastOrNull ?? Operation.insert('');
  bool removed = false;
  if (isEmbed) {
    final Operation mainOp = Operation.insert(condition.insertion, null);
    if (lastOp.isNewLine && !lastOp.isBlockLevelInsertion) {
      modifiedOps.removeLast();
      removed = true;
    }
    modifiedOps.add(mainOp);
    if (removed) {
      modifiedOps.add(Operation.insert('\n'));
    }
  } else if (isOperation) {
    final Operation mainOp = condition.insertion as Operation;
    if (lastOp.isNewLine && !lastOp.isBlockLevelInsertion && mainOp.isEmbed) {
      modifiedOps.removeLast();
      removed = true;
    }
    modifiedOps.add(mainOp);
    if (mainOp.isEmbed || !mainOp.data.toString().contains('\n') && removed) {
      modifiedOps.add(Operation.insert('\n'));
    }
  } else if (isListOperation) {
    final List<Operation> mainOp = condition.insertion as List<Operation>;
    modifiedOps.addAll(<Operation>[...mainOp]);
    if (!mainOp.last.isNewLineOrBlockInsertion) {
      modifiedOps.add(Operation.insert('\n'));
    }
  } else {
    final Operation mainOp = Operation.insert(condition.insertion);
    if (lastOp.isNewLine && !lastOp.isBlockLevelInsertion) {
      modifiedOps.removeLast();
      removed = true;
    }
    modifiedOps.add(mainOp);
    if (!condition.insertion.toString().contains('\n') && removed) {
      modifiedOps.add(Operation.insert('\n'));
    }
  }
}

void _insertAtMap({
  required InsertCondition condition,
  required List<Operation> operations,
  required List<Operation> modifiedOps,
  required int globalOffset,
  required bool isEmbed,
  required bool isOperation,
  required bool isListOperation,
  required Operation op,
  required int opLength,
}) {
  // here the change starts
  if (!condition.left) {
    modifiedOps.add(op);
  }
  if (isEmbed) {
    final Operation mainOp = Operation.insert(condition.insertion, null);
    modifiedOps.add(mainOp);
  } else if (isOperation) {
    final Operation mainOp = condition.insertion as Operation;
    modifiedOps.add(mainOp);
  } else if (isListOperation) {
    final List<Operation> mainOp = condition.insertion as List<Operation>;
    modifiedOps.addAll(<Operation>[...mainOp]);
  } else {
    final Operation mainOp = Operation.insert(condition.insertion);
    modifiedOps.add(mainOp);
  }
  if (condition.left) {
    modifiedOps.add(op);
  }
  globalOffset += opLength;
}
