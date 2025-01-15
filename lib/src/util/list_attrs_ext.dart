import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:meta/meta.dart';

@internal
extension ListAttrsExt on List<Attribute> {
  (List<Attribute>, List<Attribute>) get separateByAttrsType {
    final List<Attribute> inlineTypes = <Attribute>[];
    final List<Attribute> blockTypes = <Attribute>[];
    for (var attr in this) {
      if (attr.scope == AttributeScope.inline) inlineTypes.add(attr);
      if (attr.scope == AttributeScope.block) blockTypes.add(attr);
    }
    return (inlineTypes, blockTypes);
  }
}

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
