import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/string_ext.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:meta/meta.dart';
import 'string_tokenizer.dart';

final List<String> _inlineAttrs = List.unmodifiable(
  [...Attribute.inlineKeys],
);

/// Extension on `Iterable<Iterable<T>>` to flatten nested iterables into a single iterable.
@internal
extension FlattenedNestedIterable<T> on Iterable<Iterable<T>> {
  /// Flattens the nested iterables into a single iterable of type `T`.
  ///
  /// Iterates through each iterable in this iterable (`Iterable<Iterable<T>>`),
  /// yielding all elements sequentially from each inner iterable in order.
  Iterable<T> get flattened sync* {
    for (var elements in this) {
      yield* elements;
    }
  }
}

@internal
extension DeltaDenormalizer on Delta {
  Delta denormalize() {
    if (isEmpty) return this;

    List<Operation> denormalizedOps = [];
    for (int i = 0; i < length; i++) {
      Operation currentOp = elementAt(i);
      denormalizedOps.addAll(_denormalizeOperation(currentOp, i));
    }
    return Delta.fromOperations(denormalizedOps);
  }

  List<Operation> _denormalizeOperation(Operation op, int index) {
    dynamic insertValue = op.data;
    Map<String, dynamic>? attributes = op.attributes;

    if (insertValue is Map) {
      return [op];
    }

    if (op.isBlockLevelInsertion) {
      return [op];
    }

    List<String> lines = tokenizeWithNewLines(insertValue.toString());

    if (lines.length == 1) {
      return [op];
    }

    List<Operation> resultOps = [];
    for (String line in lines) {
      if (line.hasOnlyNewLines) {
        var cleanAttributes = attributes != null ? {...attributes} : null;
        if (cleanAttributes != null) {
          cleanAttributes.removeWhere(removeInlineAttrs);
        }
        resultOps.add(Operation.insert(line,
            cleanAttributes?.isNotEmpty == true ? cleanAttributes : null));
      } else {
        resultOps.add(Operation.insert(line, attributes));
      }
    }
    return resultOps;
  }

  bool removeInlineAttrs(key, _) => _inlineAttrs.contains(key);
}
