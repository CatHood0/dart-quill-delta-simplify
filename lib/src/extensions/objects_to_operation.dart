import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/no_accepted_object_type_exception.dart';

typedef Attributes = Map<String, dynamic>;

/// Extension on `Object` that provides functionality to convert objects
/// into `Operation` instances for insertion.
extension ObjectToOperation on Object {
  /// Converts the current object into an [Operation] or a list of [Operation] instances.
  ///
  /// * `inlineAttributes`: Optional map of attributes that are applied inline to the object.
  /// * `blockAttributes`: Optional map of attributes that are applied when the object is inserted as a block.
  ///
  /// ### Example Usage:
  ///
  /// ```dart
  /// final operation = 'Hello, world'.toOperation();
  /// final operationWithAttributes = 'Hello'.toOperation(
  ///   {'color': 'red'}, // inline attributes
  ///   {'align': 'center'} // block attributes
  /// );
  /// print(operationWithAttributes); // {"insert": "Hello"}
  /// print(operationWithAttributes); // [{"insert": "Hello", "attributes": {"color": "red"}, {"insert": "⏎", "attributes": {"align": "center"}}}]
  /// ```
  Object toOperation([Attributes? inlineAttributes, Attributes? blockAttributes]) {
    if (this is Operation || this is Iterable<Operation>) return this;
    if (this is! String && this is! Map) {
      throw NoAcceptedObjectType(
        object: this,
        acceptedTypes: [String, Map, Operation, Iterable<Operation>],
      );
    }
    if (blockAttributes == null || blockAttributes.isEmpty) {
      return Operation.insert(
        this,
        inlineAttributes != null && inlineAttributes.isNotEmpty ? {...inlineAttributes} : null,
      );
    }
    if (this is Map && (this as Map).containsKey('insert')) return (this as Map).toOperation();
    return [
      Operation.insert(
        this,
        inlineAttributes != null && inlineAttributes.isNotEmpty ? {...inlineAttributes} : null,
      ),
      if (this is String && blockAttributes.isNotEmpty)
        Operation.insert(
          '\n',
          {...blockAttributes},
        ),
    ];
  }
}

/// Extension on `Map` that provides functionality to convert a map into an
/// [Operation] for insertion.
extension MapToOperation on Map {
  /// Converts the current map into an [Operation.insert].
  ///
  /// * `inlineAttributes`: Optional inline attributes that are applied to the operation.
  ///
  /// ### Example Usage:
  ///
  /// ```dart
  /// final map = {'image': 'path/to/image/file.jpg'};
  /// final operation = map.toOperation({'style': 'width:200px;height:px;'});
  /// ```
  /// or
  /// ```dart
  /// final insertJson = {'insert': 'This is an example'};
  /// final operation = insertJson.toOperation();
  /// ```
  Operation toOperation([
    Attributes? inlineAttributes,
  ]) {
    if (containsKey('insert')) {
      final attrs = this['attributes'] as Map<String, dynamic>?;
      return Operation.insert(this['insert'], attrs);
    }
    return Operation.insert(
      this,
      inlineAttributes != null && inlineAttributes.isNotEmpty ? {...inlineAttributes} : null,
    );
  }
}
