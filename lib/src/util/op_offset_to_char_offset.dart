import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:meta/meta.dart';

@internal
int globalOpIndexToGlobalCharIndex(int operationOffset, List<Operation> delta) {
  int globalOffset = 0;
  for (int index = 0; index < delta.length; index++) {
    if (index == operationOffset) return globalOffset;
    final op = delta.elementAt(index);
    globalOffset += op.getEffectiveLength;
  }
  return globalOffset;
}

@internal
int getOperationIndexFromCharOffset(int charOffset, List<Operation> delta) {
  if (charOffset <= 0) return 0;
  int globalOffset = 0;
  for (int index = 0; index < delta.length; index++) {
    final opLength = delta.elementAt(index).getEffectiveLength;
    globalOffset += opLength;
    if (globalOffset >= charOffset) {
      return index;
    }
  }
  return 0;
}
