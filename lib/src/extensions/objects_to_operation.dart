import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/exceptions/no_accepted_object_type_exception.dart';

typedef Attributes = Map<String, dynamic>;

/// Extension on `Object` that provides functionality to convert objects
/// into `Operation` instances for insertion.
extension ObjectToOperation on Object {
  /// Converts the current object into an [Operation] or a list of [Operation] instances.
  ///
  /// This extension method checks the type of the object and converts it accordingly:
  ///
  /// - If the object is already an [Operation] or a [Iterable<Operation>], it is returned as is.
  /// - If the object is a [String] or a [Map], it will be converted into an [Operation.insert].
  /// - If `blockAttributes` are provided, a newline character (`'\n'`) will be inserted with those attributes.
  /// - If no `blockAttributes` are provided, only the `inlineAttributes` (if any) will be included with the operation.
  ///
  /// If the object is neither a [String] nor a [Map], a [NoAcceptedObjectType] exception will be thrown.
  ///
  /// ### Parameters:
  ///
  /// - `inlineAttributes`: Optional map of attributes that are applied inline to the object.
  /// - `blockAttributes`: Optional map of attributes that are applied when the object is inserted as a block.
  ///
  /// ### Returns:
  ///
  /// A single [Operation] if no `blockAttributes` are provided, or a list of two [Operation] instances:
  /// one for the inline operation and one for the block operation (if applicable).
  ///
  /// ### Example Usage:
  ///
  /// ```dart
  /// final operation = 'Hello, world'.toOperation();
  /// // Returns an Operation.insert for the string "Hello, world"
  ///
  /// final operationWithAttributes = 'Hello'.toOperation(
  ///   {'color': 'red'}, // inline attributes
  ///   {'align': 'center'} // block attributes
  /// );
  /// // Returns a list of two Operations:
  /// // 1. Operation.insert for "Hello" with inline attributes.
  /// // 2. Operation.insert for a newline with block attributes.
  /// ```
  ///
  /// Throws a [NoAcceptedObjectType] if the object is not a [String] or [Map].
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
  /// This method creates an [Operation.insert] for the map and applies any
  /// `inlineAttributes` (if provided) to the operation.
  ///
  /// ### Parameters:
  ///
  /// - `inlineAttributes`: Optional inline attributes that are applied to the operation.
  ///
  /// ### Returns:
  ///
  /// A single [Operation.insert] containing the map and its associated attributes (if any).
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
