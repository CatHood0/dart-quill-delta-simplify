import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:dart_quill_delta_simplify/src/extensions/operation_ext.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Provides an extension on [Delta] to convert it into a [QueryDelta].
extension DeltaToQuery on Delta {
  /// Converts the current [Delta] instance into a [QueryDelta].
  ///
  /// This is useful for querying and manipulating the delta in a structured way.
  QueryDelta get toQuery => QueryDelta(delta: this);
}

/// Provides an extension on [Delta] to compare differences with another [Delta].
extension DeltaDiff on Delta {
  /// Compares the current [Delta] instance with another [Delta] to find differences.
  ///
  /// * [otherDelta]: The [Delta] instance to compare against.
  DeltaCompareDiffResult compareDiff(Delta otherDelta) {
    otherDelta.check();
    check();
    return (QueryDelta(delta: this)..params.originalDelta = otherDelta).compareDiff();
  }
}

/// Provides an extension on [Delta] to convert it to plain text.
extension DeltaToPlainText on Delta {
  /// Converts the [Delta] into a plain text string.
  ///
  /// * [embedBuilder]: Optional function to handle embedded objects during conversion.
  String toPlain([String Function(Object)? embedBuilder]) => operations
      .map(
        (e) => e.toPlain(
          embedBuilder: embedBuilder,
        ),
      )
      .join('');

  /// Converts the [Delta] into plain text using a custom operation builder.
  ///
  /// Throws an [UnimplementedError] as this method is not yet implemented.
  String toPlainBuilder(String Function(Operation op) opToPlainBuilder) {
    StringBuffer buffer = StringBuffer();
    for (Operation op in operations) {
      if (!op.isInsert) throw IllegalOperationPassedException(illegal: op, expected: op.clone(''));
      buffer.write(opToPlainBuilder(op));
    }
    return buffer.toString();
  }
}

/// Provides an extension on [Delta] for easy formatting, insertion, replacement, and deletion.
extension EasyDelta on Delta {
  /// Matches operations in a [Delta] based on specific [Attributes].
  ///
  /// * [inlineAttrs]: A map of inline attributes to match against the operations.
  /// * [blockAttrs]: A map of block attributes to match against the operations.
  /// * [blockAttrKeys]: A list of block attribute keys to match against the operations.
  /// * [inlineAttrKeys]: A list of inline attribute keys to match against the operations.
  /// * [strictKeysCheck]: If `true`, only matches operations where all specified keys are present.
  /// * [onlyOnce]: If `true`, stops searching after the first match.
  ///
  List<DeltaRangeResult> matchAttributes({
    required Attributes? inlineAttrs,
    required Attributes? blockAttrs,
    required List<String>? blockAttrKeys,
    required List<String>? inlineAttrKeys,
    bool strictKeysCheck = true,
    bool onlyOnce = false,
  }) =>
      toQuery.matchAttributes(
        inlineAttrs: inlineAttrs,
        blockAttrs: blockAttrs,
        blockAttrKeys: blockAttrKeys,
        inlineAttrKeys: inlineAttrKeys,
        strictKeysCheck: strictKeysCheck,
        onlyOnce: onlyOnce,
      );

  /// Finds the first match of the given [pattern] or [rawObject] in the [Delta] operations list.
  ///
  /// * [pattern]: The string pattern to search for.
  /// * [rawObject]: The object to search for within the operations.
  /// * [operationIndex]: The index of the operation.
  DeltaRangeResult? firstMatch(
    RegExp? pattern,
    Object? rawObject, {
    int? operationIndex,
  }) =>
      toQuery.firstMatch(
        pattern,
        rawObject,
        operationIndex: operationIndex,
      );

  /// Finds all matches of the given [pattern] or [rawObject] in the [Delta] operations list.
  ///
  /// * [pattern]: The string pattern to search for.
  /// * [rawObject]: The object to search for within the operations.
  /// * [operationIndex]: The index of the operation.
  /// * [caseSensitivePatterns]: Whether the pattern matching should be case-sensitive. Defaults to `false`.
  List<DeltaRangeResult> allMatches(
    RegExp? pattern,
    Object? rawObject, {
    int? operationIndex,
  }) =>
      toQuery.allMatches(
        pattern,
        rawObject,
        operationIndex: operationIndex,
      );

  void check() {
    assert(isNotEmpty, 'operations cannot be empty');
    assert(last.isNewLineOrBlockInsertion || last.containsNewLine(), 'last operation must be a new line');
  }

  int get getTextLength => operations.getEffectiveLength;

  /// Applies a simple format to the [Delta] with the specified parameters.
  ///
  /// * [offset]: The starting offset for the format.
  /// * [len]: The length of the text to format.
  /// * [target]: The target object for the format.
  /// * [attribute]: The attribute to apply.
  /// * [onlyOnce]: Whether to format only once.
  void simpleFormat({
    required int? offset,
    // we can't specify the generic type by default
    // because this Attribute can be a custom one created by the dev
    // ignore: strict_raw_type
    required Attribute attribute,
    int? len,
    Object? target,
    bool onlyOnce = false,
    bool caseSensitive = false,
  }) {
    final Delta delta = QueryDelta(delta: this)
        .format(
          offset: offset,
          len: len,
          attribute: attribute,
          target: target,
          caseSensitive: caseSensitive,
          onlyOnce: onlyOnce,
        )
        .build()
        .delta;
    _clear();
    operations.addAll(delta.operations);
  }

  /// Inserts text into the [Delta] with the specified parameters.
  ///
  /// * [insert]: The text or object to insert.
  /// * [target]: The target object for the insertion.
  /// * [startPoint]: The starting point for the insertion.
  /// * [left]: Whether to insert to the left of the target.
  /// * [onlyOnce]: Whether to insert only once.
  /// * [asDifferentOp]: Whether to treat the insertion as a different operation.
  /// * [insertAtLastOperation]: Whether to insert at the last operation.
  void simpleInsert({
    required Object insert,
    required Object? target,
    required int? startPoint,
    bool left = false,
    bool onlyOnce = true,
    bool asDifferentOp = false,
    bool insertAtLastOperation = false,
    bool caseSensitive = false,
  }) {
    final Delta delta = QueryDelta(delta: this)
        .insert(
          insert: insert,
          startPoint: startPoint,
          caseSensitive: caseSensitive,
          target: target,
          left: left,
          onlyOnce: startPoint != null ? true : onlyOnce,
          asDifferentOp: asDifferentOp,
          insertAtLastOperation: insertAtLastOperation,
        )
        .build()
        .delta;
    _clear();
    operations.addAll(delta.operations);
  }

  /// Replaces a range of text in the [Delta] with the specified insertion.
  ///
  /// * [replace]: The text or object to insert as a replacement.
  /// * [range]: The range to replace.
  /// * [target]: The target object for the replacement.
  /// * [onlyOnce]: Whether to replace only once.
  void simpleReplace({
    @Deprecated('insertion has no sense with the target of the method. Use "replace" instead') Object? insertion,
    required Object replace,
    required DeltaRange? range,
    required Object? target,
    bool onlyOnce = true,
  }) {
    final delta = QueryDelta(delta: this)
        .replace(
          replace: replace,
          target: target,
          range: range,
          onlyOnce: onlyOnce,
        )
        .build()
        .delta;
    _clear();
    operations.addAll(delta.operations);
  }

  /// Deletes a range of text in the [Delta] with the specified length and starting offset.
  ///
  /// * [target]: The target object for the deletion.
  /// * [len]: The length of text to delete.
  /// * [startPointOffset]: The starting offset for the deletion.
  void simpleDelete({
    required Object? target,
    required int? len,
    required int? startPointOffset,
    bool onlyOnce = true,
    bool caseSensitive = false,
  }) {
    final Delta delta = QueryDelta(delta: this)
        .delete(
          target: target,
          lengthOfDeletion: len,
          onlyOnce: onlyOnce,
          caseSensitive: caseSensitive,
          startPoint: startPointOffset,
        )
        .build()
        .delta;
    _clear();
    operations.addAll(delta.operations);
  }

  void _clear() {
    operations.clear();
  }
}
