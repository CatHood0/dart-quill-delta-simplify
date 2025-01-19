import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:meta/meta.dart';

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
  final bool isEmbed = insertion is Map;
  final bool isOperation = insertion is Operation && insertion.isInsert;
  final bool isListOperation = insertion is List<Operation>;
  if (insertion is Operation && !insertion.isInsert) return operations;
  final RegExp? pattern = range != null ||
          target == null ||
          (target is String && target.isEmpty) ||
          target is Map<String, dynamic>
      ? null
      : RegExp(
          target as String,
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
    // range
    if (range != null) {
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
          // avoid make a change in a part that need to be ignored
          if (partsToIgnore.ignoreOverlap(DeltaRange(
              startOffset: startOffset + globalOffset,
              endOffset: endOffset + globalOffset))) {
            continue;
          }
          // ensure to take a correct start offset for insertions when the insertion will be
          // do it at the right of the word
          final int effectiveOffsetToWord =
              condition.left ? startOffset : endOffset;
          deltaPartsToMerge.add(DeltaRange(
              startOffset: effectiveOffsetToWord, endOffset: endOffset));
        }
        if (deltaPartsToMerge.isEmpty) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        StringBuffer buffer = StringBuffer();
        List<Operation> dividedOps = <Operation>[];

        for (int i = 0; i < deltaPartsToMerge.length; i++) {
          final DeltaRange partToMerge = deltaPartsToMerge.elementAt(i);
          final DeltaRange? nextPartToMerge =
              deltaPartsToMerge.elementAtOrNull(i + 1);
          if (insertion is String) {
            if (i == 0) {
              buffer
                ..write(ofData.substring(0, partToMerge.startOffset))
                ..write(insertion)
                ..write(
                  ofData.substring(
                    partToMerge.endOffset,
                    nextPartToMerge?.startOffset,
                  ),
                );
            } else {
              buffer
                ..write(insertion)
                ..write(
                  ofData.substring(
                    partToMerge.endOffset,
                    nextPartToMerge?.startOffset,
                  ),
                );
            }
          } else if (i == 0) {
            dividedOps
                .add(op.clone(ofData.substring(0, partToMerge.startOffset)));
            if (isEmbed) {
              dividedOps.add(Operation.insert(insertion));
            } else if (isListOperation) {
              dividedOps.addAll(insertion);
            } else {
              dividedOps.add(insertion as Operation);
            }
            dividedOps.add(
              op.clone(ofData.substring(
                partToMerge.endOffset,
                nextPartToMerge?.startOffset,
              )),
            );
          } else {
            if (isEmbed) {
              dividedOps.add(Operation.insert(insertion));
            } else if (isListOperation) {
              dividedOps.addAll(insertion);
            } else {
              dividedOps.add(insertion as Operation);
            }
            dividedOps.add(
              op.clone(
                ofData.substring(
                    partToMerge.endOffset, nextPartToMerge?.startOffset),
              ),
            );
          }
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
  if (modifiedOps.isEmpty) return operations;
  return modifiedOps;
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
  if (isEmbed) {
    final Operation mainOp = Operation.insert(condition.insertion, null);
    final Operation lastOp = modifiedOps.last;
    if (lastOp.isNewLine && !lastOp.isBlockLevelInsertion) {
      modifiedOps.removeLast();
    }
    modifiedOps
      ..add(mainOp)
      ..add(Operation.insert('\n'));
  } else if (isOperation) {
    final Operation mainOp = condition.insertion as Operation;
    final Operation lastOp = modifiedOps.last;
    if (lastOp.isNewLine && !lastOp.isBlockLevelInsertion && mainOp.isEmbed) {
      modifiedOps.removeLast();
    }
    modifiedOps.add(mainOp);
    if (mainOp.isEmbed || !mainOp.data.toString().contains('\n')) {
      modifiedOps.add(Operation.insert('\n'));
    }
  } else if (isListOperation) {
    final List<Operation> mainOp = condition.insertion as List<Operation>;
    final Operation lastOp = mainOp.last;
    modifiedOps.addAll(<Operation>[...mainOp]);
    if (!lastOp.isNewLineOrBlockInsertion) {
      modifiedOps.add(Operation.insert('\n'));
    }
  } else {
    final Operation mainOp = Operation.insert(condition.insertion);
    modifiedOps.add(mainOp);
    if (!condition.insertion.toString().contains('\n')) {
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
