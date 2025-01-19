import 'package:dart_quill_delta/dart_quill_delta.dart';

extension CheckingOperationAttributes on Operation {
  bool containsAttrs(List<String> keys, bool strict) {
    final attrs = attributes;
    if (attrs == null || attrs.isEmpty) return false;
    if (strict) {
      for (var key in keys) {
        if (!attrs.containsKey(key)) return false;
      }
      return true;
    }
    for (var key in keys) {
      if (attrs.containsKey(key)) return true;
    }
    return false;
  }
}
