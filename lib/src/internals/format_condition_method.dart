import 'package:dart_quill_delta_simplify/src/conditions/format.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/delta_range_error.dart';
import 'package:dart_quill_delta_simplify/src/extensions/delta_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/list_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/num_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:dart_quill_delta_simplify/src/util/typedef.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:meta/meta.dart';
import '../../delta_changes.dart';
import '../../delta_ranges.dart';
import '../util/enums.dart';
import '../util/search_block_attribute.dart';

@internal
List<Operation> formatCondition(
  List<Operation> operations,
  FormatCondition condition, [
  List<DeltaRange> partsToIgnore = const <DeltaRange>[],
  void Function(DeltaChange)? registerChange,
  OnCatchCallback? onCatch,
]) {
  final List<Operation> modifiedOps = <Operation>[];
  final Object? target = condition.target;
  final RegExp? pattern = target == null || target is Map<String, dynamic> || (target as String? ?? '').isEmpty
      ? null
      : RegExp(
          target as String,
          caseSensitive: condition.caseSensitive,
        );
  final int conditionOffset = condition.offset ?? -1;
  final int conditionLen = condition.len ?? 0;
  final Attribute attr = condition.attribute;
  final Set<int> indexsToIgnore = {};
  final bool isBlock = attr.scope == AttributeScope.block;
  final bool isInline = attr.scope == AttributeScope.inline;
  final bool isIgnore = attr.scope == AttributeScope.ignore;
  final int startOffset = conditionOffset;
  final int endOffset = conditionOffset + conditionLen;
  int globalOffset = 0;
  Operation? noInsertThisOperation;
  bool onlyAddRest = false;
  int indexOfSpecialInsert = -1;
  Operation? specialInsertionOp;
  for (int index = 0; index < operations.length; index++) {
    final Operation op = operations.elementAt(index);
    final Object? data = op.data;
    final int opLength = op.getEffectiveLength;
    if (indexsToIgnore.contains(index)) {
      globalOffset += opLength;
      continue;
    }
    // ignore last
    if (indexOfSpecialInsert == index) {
      modifiedOps.add(specialInsertionOp!);
      globalOffset += opLength;
      continue;
    }
    if (index + 1 >= operations.length) {
      modifiedOps.add(op);
      globalOffset += opLength;
      break;
    }
    // we don't need to check or modify at any moment the insertions
    // that apply block level attributes to other inserts
    if (op.isBlockLevelInsertion) {
      modifiedOps.add(op);
      globalOffset += opLength;
      continue;
    }
    if (attr.key == Attribute.style.key) {
      if (target is Map && data is Map) {
        if (mapEquals(target, data)) {
          int startAndEndOffset = globalOffset;
          if (partsToIgnore.ignoreOverlap(
            DeltaRange(startOffset: startAndEndOffset, endOffset: startAndEndOffset),
          )) {
            modifiedOps.add(op);
            globalOffset += opLength;
            continue;
          }
          Operation changedOp = op.clone(null, attr, true);
          modifiedOps.add(changedOp);
          registerChange?.call(
            DeltaChange(
              change: <String, Object>{
                'original_op': op,
                'change': changedOp,
                'attr_applied': attr,
              },
              startOffset: startAndEndOffset,
              endOffset: startAndEndOffset,
              type: ChangeType.format,
            ),
          );
          globalOffset += opLength;
          continue;
        }
      } else {
        modifiedOps.add(op);
      }
      globalOffset += opLength;
      continue;
    }

    if (!conditionOffset.isNegative) {
      int currentGlobalOffset = globalOffset + opLength;
      int localStartOffset = (conditionOffset - globalOffset).nonNegativeInt;
      int localEndOffset = ((conditionOffset + conditionLen) - globalOffset).nonNegativeInt;
      if ((currentGlobalOffset >= conditionOffset || conditionOffset == 0) && !onlyAddRest) {
        onlyAddRest = true;
        if (partsToIgnore.ignoreOverlap(DeltaRange(startOffset: startOffset, endOffset: endOffset))) {
          modifiedOps.add(op);
          globalOffset += opLength;
          continue;
        }
        Object? mainPartOp;
        // we need to add traversal part
        final bool useOpLength = localEndOffset > opLength;
        final bool willNeedTraverse = localEndOffset > opLength;
        final Operation leftOp = op.clone(data.toString().substring(0, localStartOffset));
        final Operation? rightOp = willNeedTraverse || (localStartOffset == 0 && localEndOffset == 0)
            ? null
            : op.clone(data.toString().substring(localEndOffset));
        var (int indexToBlockAttributes, List<Operation> opsAfterCurrentOne, _) = searchForBlockAttributes(
          index + 1,
          operations,
          globalOffset,
          true,
        );
        if (data is String) {
          final String textPart = localStartOffset == 0 && localEndOffset == 0
              ? data
              : data.substring(localStartOffset, useOpLength ? opLength : localEndOffset);
          // when is block, we don't need to calculate the other part that need to be removed
          // because we with block attrs, only need to be applied to the new lines into the range (offset + len)
          int charactersPerChange = endOffset > opLength
              ? isBlock
                  ? endOffset
                  : (endOffset - textPart.length).nonNegativeInt
              : 0;
          mainPartOp = <Operation>[
            // left
            if (leftOp.data.toString().isNotEmpty) leftOp,
            op.clone(textPart, isInline ? attr : null),
            // right
            if (rightOp != null && rightOp.data.toString().isNotEmpty) rightOp,
          ];
          modifiedOps.addAll(mainPartOp as List<Operation>);
          if (willNeedTraverse && charactersPerChange > 0) {
            var (
              Operation? specialInsert,
              int specialIndex,
              bool nonNeedSpecialInsert,
              bool blockMode,
              bool ignoreCondition
            ) = _formatRestIfNeeded(
              globalOffset: globalOffset,
              charactersPerChange: charactersPerChange,
              rangeAccepted: DeltaRange(
                startOffset: startOffset,
                endOffset: endOffset,
              ),
              endOffset: endOffset,
              attr: attr,
              op: op,
              index: index,
              indexOfSpecialInsert: indexOfSpecialInsert,
              indexsToIgnore: indexsToIgnore,
              modifiedOps: modifiedOps,
              operations: <Operation>[...operations],
              registerChange: registerChange,
              onCatch: onCatch,
            );
            if (ignoreCondition) return operations;
            if (!nonNeedSpecialInsert) {
              indexOfSpecialInsert = specialIndex;
              specialInsertionOp = specialInsert;
            }
            if (blockMode) {
              onlyAddRest = true;
              globalOffset += opLength;
              continue;
            }
            // here ends the traverse
          }
          if (isBlock) {
            if (indexToBlockAttributes != -1) {
              _applyBlockLevelAttributesMergingWithExistOp(
                globalOffset: globalOffset,
                data: data,
                indexsToIgnore: indexsToIgnore,
                condition: condition,
                attr: attr,
                op: op,
                index: index,
                indexToBlockAttributes: indexToBlockAttributes,
                opsAfterCurrentOne: opsAfterCurrentOne,
                modifiedOps: modifiedOps,
                operations: operations,
                registerChange: registerChange,
                noInsertThisOperation: noInsertThisOperation,
                startOffset: startOffset,
                endOffset: endOffset,
                mainPartOp: mainPartOp,
              );
              onlyAddRest = true;
            } else if (indexToBlockAttributes == -1) {
              _applyInsertingNewOpBlockLevelAttributes(
                globalOffset: globalOffset,
                data: data,
                condition: condition,
                attr: attr,
                op: op,
                index: index,
                modifiedOps: modifiedOps,
                operations: operations,
                registerChange: registerChange,
                noInsertThisOperation: noInsertThisOperation,
                startOffset: startOffset,
                endOffset: endOffset,
                mainPartOp: mainPartOp,
              );
              onlyAddRest = true;
            }
          }
          globalOffset += opLength;
          continue;
        } else if (data is Map && isIgnore) {
          // means that this is a embed part and we don't need to insert block attrs
          mainPartOp = op.clone(null, attr, true);
          onlyAddRest = true;
          modifiedOps.add(mainPartOp as Operation);
          globalOffset += opLength;
          continue;
        }
      }
      globalOffset += opLength;
      if (op != noInsertThisOperation) modifiedOps.add(op);
      continue;
    }
    // here start pattern matching
    if (pattern != null && pattern.hasMatch('$data')) {
      Iterable<RegExpMatch> matches = pattern.allMatches('$data');
      // ignores any exact part match and apply to the entire op
      if (isBlock) {
        int startOffset = globalOffset;
        int endOffset = globalOffset + opLength;
        var (int indexToBlockAttributes, List<Operation> opsAfterCurrentOne, _) = searchForBlockAttributes(
          index + 1,
          operations,
          globalOffset,
          true,
        );
        modifiedOps.add(op);
        if (indexToBlockAttributes != -1) {
          if (opsAfterCurrentOne.isNotEmpty) {
            modifiedOps.addAll(opsAfterCurrentOne);
            int lastPartIndex = indexToBlockAttributes;
            while (true) {
              lastPartIndex -= 1;
              if (lastPartIndex == index) break;
              indexsToIgnore.add(lastPartIndex);
            }
          }
          Operation blockAttrsOp = operations.elementAt(indexToBlockAttributes);
          Operation blockChangedOp = blockAttrsOp.clone(null, attr);
          modifiedOps.add(blockChangedOp);
          indexsToIgnore.add(indexToBlockAttributes);
          registerChange?.call(
            DeltaChange(
              change: <String, Object>{
                'attribute': attr,
                'applied_to': op,
                'block_level': <String, Object?>{
                  'op': blockChangedOp,
                  'removed': attr.value == null,
                  'index_of_op_before_change': indexToBlockAttributes,
                },
              },
              startOffset: startOffset,
              endOffset: endOffset + 1,
              type: ChangeType.format,
            ),
          );
          globalOffset += opLength;
          continue;
        } else if (indexToBlockAttributes == -1 && attr.value != null) {
          Operation blockAddedOp = Operation.insert(
            '\n',
            attr.toJson(),
          );
          modifiedOps.add(blockAddedOp);
          registerChange?.call(
            DeltaChange(
              change: <String, Object>{
                'attribute': attr,
                'applied_to': op,
                'block_level': <String, Object>{
                  'op': blockAddedOp,
                  'index_of_op_before_change': index + 1,
                },
              },
              startOffset: startOffset,
              endOffset: endOffset + 1,
              type: ChangeType.format,
            ),
          );
        } else if (attr.value == null) {
          noInsertThisOperation = op;
          globalOffset += opLength;
          continue;
        }
      } else {
        for (RegExpMatch match in matches) {
          int startGlobalOffset = match.start + globalOffset;
          int endGlobalOffset = match.end + globalOffset;
          if (partsToIgnore
              .ignoreOverlap(DeltaRange(startOffset: startGlobalOffset, endOffset: endGlobalOffset))) {
            modifiedOps.add(op);
            break;
          }
          bool wasMatchedAllOperation = match.start == 0 && match.end == data.toString().length || isBlock;
          int startOffset = match.start + globalOffset;
          int endOffset = match.end + globalOffset;
          if (wasMatchedAllOperation) {
            _isEntireSelectionChangePattern(
              match: match,
              globalOffset: globalOffset,
              attr: attr,
              indexsToIgnore: indexsToIgnore,
              data: data,
              condition: condition,
              op: op,
              index: index,
              modifiedOps: modifiedOps,
              operations: operations,
              registerChange: registerChange,
              noInsertThisOperation: noInsertThisOperation,
              startOffset: startOffset,
              endOffset: endOffset,
            );
            break;
          } else {
            _isNotEntireSelectionChangePattern(
              match: match,
              globalOffset: globalOffset,
              attr: attr,
              data: data,
              condition: condition,
              op: op,
              index: index,
              modifiedOps: modifiedOps,
              operations: operations,
              registerChange: registerChange,
              noInsertThisOperation: noInsertThisOperation,
            );
            break;
          }
          //heres end match for loop
        }
      }
      globalOffset += opLength;
      continue;
      //heres end match
    }
    globalOffset += opLength;
    if (op != noInsertThisOperation) {
      modifiedOps.add(op);
    }
  }
  if (modifiedOps.isEmpty) return operations;
  return modifiedOps;
}

(Operation?, int, bool, bool, bool) _formatRestIfNeeded({
  required int globalOffset,
  required int charactersPerChange,
  required DeltaRange rangeAccepted,
  required Attribute attr,
  required Operation op,
  required int index,
  required int indexOfSpecialInsert,
  required Set<int> indexsToIgnore,
  required List<Operation> modifiedOps,
  required int endOffset,
  required List<Operation> operations,
  required void Function(DeltaChange)? registerChange,
  required OnCatchCallback? onCatch,
}) {
  final bool isBlock = attr.scope == AttributeScope.block;
  // block mode is a different way that we use to add
  final bool blockMode = isBlock;
  Operation? specialInsertionOp;
  // we need to check first if is we really need to search for other operations to replace
  // because if the cursor selection if into the operation range, then we don't need to
  // make unnecessary traversal operations
  int cloneGlobal = globalOffset + op.getEffectiveLength;
  // and does not need to be replaced a special part of the ops
  bool nonNeedSpecialInsert = false;
  // we use this to avoid make a mutation when the index is already processed
  for (int nextIndex = index + 1; nextIndex < operations.length; nextIndex++) {
    // avoid make a mutation to the last op
    Operation? nextOp = operations.elementAtOrNull(nextIndex);
    // check if the current element is the last operation
    // in [Delta]
    if (nextOp == null) break;
    Object? nextData = nextOp.data;
    int nextOpLength = nextOp.getEffectiveLength;
    if (blockMode) {
      if (nextOp.isEmbed) {
        modifiedOps.add(nextOp);
        indexsToIgnore.add(nextIndex);
        cloneGlobal += nextOpLength;
        continue;
      } else if (nextOp.isNewLineOrBlockInsertion && (cloneGlobal + nextOpLength) < charactersPerChange) {
        modifiedOps.add(nextOp.clone(null, attr));
        indexsToIgnore.add(nextIndex);
        cloneGlobal += nextOpLength;
        continue;
      } else if ((cloneGlobal + nextOpLength) >= charactersPerChange) {
        indexsToIgnore.add(nextIndex);
        if (nextOp.isNewLineOrBlockInsertion) {
          modifiedOps.add(nextOp.clone(null, attr));
          cloneGlobal += nextOpLength;
          charactersPerChange = 0;
          nonNeedSpecialInsert = true;
          break;
        }
        modifiedOps.add(nextOp);
        // check if next is last op (it is always ignored)
        var (int indexToNextBlockAttributes, List<Operation> ops, _) = searchForBlockAttributes(
          nextIndex + 1,
          operations,
          cloneGlobal,
          true,
        );
        if (indexToNextBlockAttributes != -1) {
          // ignores the original new line version
          indexsToIgnore.add(indexToNextBlockAttributes);
          if (ops.isNotEmpty) {
            // add ops before the new line founded (can be empty if the new line if after the current operation)
            modifiedOps.addAll(ops);
            int lastPartIndex = indexToNextBlockAttributes;
            // add all indexs to be ignored
            while (true) {
              lastPartIndex--;
              if (lastPartIndex == index) break;
              indexsToIgnore.add(lastPartIndex);
            }
          }
          // adds the new version of the new line with the attr
          modifiedOps.add(operations.elementAt(indexToNextBlockAttributes).clone(null, attr));
        } else {
          if (attr.value != null) modifiedOps.add(Operation.insert('\n', attr.toJson()));
        }
        nonNeedSpecialInsert = true;
        break;
      } else {
        modifiedOps.add(nextOp);
        indexsToIgnore.add(nextIndex);
        cloneGlobal += nextOpLength;
        continue;
      }
      // inline part
    } else {
      if (nextOp.isNewLineOrBlockInsertion) {
        modifiedOps.add(nextOp);
        indexsToIgnore.add(nextIndex);
        cloneGlobal += nextOpLength;
        charactersPerChange -= nextOpLength;
        continue;
      }
      if (charactersPerChange > nextOpLength || charactersPerChange == nextOpLength) {
        modifiedOps.add(
          nextData is! String
              ? nextOp
              : nextOp.clone(
                  nextData
                      .toString()
                      .substring(0, charactersPerChange > nextOpLength ? nextOpLength : charactersPerChange),
                  attr,
                ),
        );
        charactersPerChange -= nextOpLength;
        if (charactersPerChange <= 0) {
          indexsToIgnore.add(nextIndex);
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
        cloneGlobal += nextOpLength;
        indexsToIgnore.add(nextIndex);
        continue;
      } else if (charactersPerChange < nextOpLength) {
        if (charactersPerChange == 0) break;
        if (nextData is String) {
          modifiedOps.add(
            nextOp.clone(
              nextData.substring(0, charactersPerChange),
              attr,
            ),
          );
          specialInsertionOp = Operation.insert(
            nextData.substring(charactersPerChange),
            nextOp.attributes,
          );
          indexOfSpecialInsert = nextIndex;
          nonNeedSpecialInsert = false;
        } else {
          modifiedOps.add(nextOp);
        }
        indexsToIgnore.add(nextIndex);
        registerChange?.call(
          DeltaChange(
            change: <String, dynamic>{
              'original_op': nextOp,
              'change': specialInsertionOp,
            },
            startOffset: cloneGlobal,
            endOffset: cloneGlobal + charactersPerChange,
            type: ChangeType.replace,
          ),
        );
        charactersPerChange = 0;
        break;
      }
    }
    cloneGlobal += nextOpLength;
    charactersPerChange -= nextOpLength;
    indexsToIgnore.add(nextIndex);
  }
  if (indexOfSpecialInsert == -1 && !nonNeedSpecialInsert && !blockMode) {
    final int maxLength = Delta.fromOperations([...operations]..removeLast()).toPlain().length;
    final err = DeltaRangeError.range(
      endOffset,
      0,
      maxLength,
      'out',
      'Invalid values',
    );
    if (onCatch != null) {
      onCatch.call(err);
      return (specialInsertionOp, indexOfSpecialInsert, nonNeedSpecialInsert, blockMode, true);
    }
    throw err;
  }
  return (specialInsertionOp, indexOfSpecialInsert, nonNeedSpecialInsert, blockMode, false);
}

void _applyBlockLevelAttributesMergingWithExistOp({
  required int globalOffset,
  required Object? data,
  required FormatCondition condition,
  required Attribute attr,
  required Operation op,
  required int index,
  required int indexToBlockAttributes,
  required List<Operation> opsAfterCurrentOne,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required Set<int> indexsToIgnore,
  required void Function(DeltaChange)? registerChange,
  required Operation? noInsertThisOperation,
  required int startOffset,
  required int endOffset,
  required Object? mainPartOp,
}) {
  if (opsAfterCurrentOne.isNotEmpty) {
    modifiedOps.addAll(opsAfterCurrentOne);
    int lastPartIndex = indexToBlockAttributes;
    while (true) {
      lastPartIndex -= 1;
      if (lastPartIndex == index) break;
      indexsToIgnore.add(lastPartIndex);
    }
  }
  Operation blockAttrsOp = operations.elementAt(indexToBlockAttributes);
  Operation blockChangedOp = blockAttrsOp.clone(null, attr);
  indexsToIgnore.add(indexToBlockAttributes);
  modifiedOps.add(blockChangedOp);
  registerChange?.call(
    DeltaChange(
      change: <String, Object>{
        'attribute': attr,
        'changed_op': op,
        'block_level': <String, Object>{
          'op': blockChangedOp,
          'removed_attribute': attr.value == null,
          'index_of_op_before_change': indexToBlockAttributes,
        },
      },
      startOffset: startOffset,
      endOffset: endOffset,
      type: ChangeType.format,
    ),
  );
  noInsertThisOperation = blockAttrsOp;
}

void _applyInsertingNewOpBlockLevelAttributes({
  required int globalOffset,
  required Object? data,
  required FormatCondition condition,
  required Attribute attr,
  required Operation op,
  required int index,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required void Function(DeltaChange)? registerChange,
  required Operation? noInsertThisOperation,
  required int startOffset,
  required int endOffset,
  required Object? mainPartOp,
}) {
  Operation blockAddedOp = Operation.insert(
    '\n',
    attr.toJson(),
  );
  modifiedOps.add(blockAddedOp);
  registerChange?.call(
    DeltaChange(
      change: <String, Object?>{
        'attribute': attr,
        'changed_op': mainPartOp,
        'block_level_added': <String, Object>{
          'op': blockAddedOp,
          'index_of_op_before_change': index + 1,
        },
      },
      startOffset: startOffset,
      endOffset: endOffset,
      type: ChangeType.format,
    ),
  );
}

void _isEntireSelectionChangePattern({
  required RegExpMatch match,
  required int globalOffset,
  required Object? data,
  required FormatCondition condition,
  required Attribute attr,
  required Operation op,
  required int index,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required Set<int> indexsToIgnore,
  required void Function(DeltaChange)? registerChange,
  required Operation? noInsertThisOperation,
  required int startOffset,
  required int endOffset,
}) {
  // apply the inline attrs
  Operation mainPartOp = attr.scope == AttributeScope.block ? op : op.clone(null, attr);
  modifiedOps.add(mainPartOp);
  // apply block attrs
  if (attr.scope == AttributeScope.block) {
    var (int indexToBlockAttributes, List<Operation> ops, _) = searchForBlockAttributes(index + 1, operations);
    if (indexToBlockAttributes != -1) {
      Operation nextOp = operations.elementAt(indexToBlockAttributes);
      Operation blockChangedOp = nextOp.clone(null, attr);
      if (ops.isNotEmpty) {
        modifiedOps.addAll(ops);
        int lastPartIndex = indexToBlockAttributes;
        while (true) {
          lastPartIndex -= 1;
          if (lastPartIndex == index) break;
          indexsToIgnore.add(lastPartIndex);
        }
      }
      modifiedOps.add(blockChangedOp);
      registerChange?.call(
        DeltaChange(
          change: <String, Object>{
            'attribute': attr,
            'changed_op': mainPartOp,
            'block_level': <String, Object>{
              'op': blockChangedOp,
              'removed_attribute': attr.value == null,
              'index_of_op_before_change': index + 1,
            },
          },
          startOffset: startOffset,
          endOffset: endOffset + 1,
          type: ChangeType.format,
        ),
      );
    } else {
      Operation blockAddedOp = Operation.insert(
        '\n',
        attr.toJson(),
      );
      modifiedOps.add(blockAddedOp);
      registerChange?.call(
        DeltaChange(
          change: <String, Object>{
            'attribute': attr,
            'changed_op': mainPartOp,
            'block_level': <String, Object>{
              'op': blockAddedOp,
              'index_of_op_before_change': index + 1,
            },
          },
          startOffset: startOffset,
          endOffset: endOffset + 1,
          type: ChangeType.format,
        ),
      );
    }
  }
}

void _isNotEntireSelectionChangePattern({
  required RegExpMatch match,
  required int globalOffset,
  required Object? data,
  required FormatCondition condition,
  required Attribute attr,
  required Operation op,
  required int index,
  required List<Operation> modifiedOps,
  required List<Operation> operations,
  required void Function(DeltaChange)? registerChange,
  required Operation? noInsertThisOperation,
}) {
  bool isBlockAttr = attr.scope == AttributeScope.block;
  bool isInlineAttr = attr.scope == AttributeScope.inline;
  int startOffset = match.start + globalOffset;
  int endOffset = match.end + globalOffset;
  String mainPart = data.toString().substring(match.start, match.end);
  Operation leftPartOp = Operation.insert(data.toString().substring(0, match.start), op.attributes);
  var (int indexToBlockAttributes, List<Operation> opsAfterCurrentOne, _) = isInlineAttr
      ? (-1, <Operation>[], -1)
      : searchForBlockAttributes(
          index + 1,
          operations,
        );
  List<Operation> mainPartOp = <Operation>[
    Operation.insert(mainPart, <String, dynamic>{
      ...?op.attributes,
      if (isInlineAttr) attr.key: attr.value,
    }),
  ];
  Operation rightPartOp = Operation.insert(data.toString().substring(match.end), op.attributes);
  // add divided parts
  modifiedOps.addAll(<Operation>[
    leftPartOp,
    ...mainPartOp,
    rightPartOp,
    if (isBlockAttr && indexToBlockAttributes == -1)
      Operation.insert('\n', <String, dynamic>{attr.key: attr.value}),
  ]);
  if (indexToBlockAttributes != -1) {
    modifiedOps.addAll(opsAfterCurrentOne);
    Operation blockAttrsOp = operations.elementAt(indexToBlockAttributes);
    Operation blockChangedOp = blockAttrsOp.clone(null, attr);
    modifiedOps.add(blockChangedOp);
    registerChange?.call(
      DeltaChange(
        change: <String, Object>{
          'attribute': attr,
          'changed_op': mainPartOp,
          'block_level': <String, Object>{
            'op': blockChangedOp,
            'removed_attribute': attr.value == null,
            'index_of_op_before_change': indexToBlockAttributes,
          },
        },
        startOffset: startOffset,
        endOffset: endOffset + 1,
        type: ChangeType.format,
      ),
    );
    noInsertThisOperation = blockAttrsOp;
  }
}
