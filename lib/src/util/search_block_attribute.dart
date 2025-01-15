import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:meta/meta.dart';

@internal
(int, List<Operation>, int) searchForBlockAttributes(
  int opIndex,
  List<Operation> delta, [
  int globalOffset = 0,
  bool returnANonBlockLevelInsertionIndexIfNeeded = false,
]) {
  if (opIndex >= delta.length) return (-1, <Operation>[], -1);
  // check if current endsWith a newline
  final List<Operation> opsBeforeBlock = <Operation>[];
  final List<int> opIndexsBeforeBlock = <int>[];
  int cloneOffset = globalOffset;
  // check if current has a newline at the end
  for (int index = opIndex; index < delta.length; index++) {
    final Operation nextOp = delta.elementAt(index);
    // ignore last
    if (nextOp.isBlockLevelInsertion ||
        (returnANonBlockLevelInsertionIndexIfNeeded && nextOp.isNewLineOrBlockInsertion)) {
      return (index, opsBeforeBlock, cloneOffset);
    }
    // check if there are some newlines into the data, and if it is, then ignore because
    // directly we cannot apply the block attributes there
    if (nextOp.containsNewLine() || nextOp.isEmbed) {
      return (-1, <Operation>[], -1);
    }
    opsBeforeBlock.add(nextOp);
    opIndexsBeforeBlock.add(index);
    cloneOffset += nextOp.getEffectiveLength;
  }
  return (-1, <Operation>[], -1);
}
