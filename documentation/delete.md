# Delete Operations Simplification

The `delete` method in `QueryDelta` is used to remove a specified segment of content from a `Delta` object. This method applies a deletion condition based on the provided parameters. By using this method, you can easily delete characters or text from a `Delta` at a specific position or offset.

## Method Signature

```dart
QueryDelta delete({
   required Object? target,
   required int? startPoint,
   required int? lengthOfDeletion,
   bool onlyOnce = true,
   bool caseSensitive = false,
})
```

## Usage Examples

### Deleting a specific portion of text

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('This is a sample text to be used for QueryDelta\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: 'sample text ',
    startPoint: 5,
    lengthOfDeletion: 10,
  )
  .build();
debugPrint(result.delta.toString()); 
// [{"insert": "This is a to be used for QueryDelta⏎"}]
```

### Deleting a portions of text that are in different Operations 

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()
    ..insert('This is a ')
    ..insert('sample text', {'underline': true})
    ..insert(' to be used for QueryDelta\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: null,
    startPoint: 8, // will start deletion at char "a"
    lengthOfDeletion: 9, // will removed "a sample text"
  )
  .build();
debugPrint(result.delta.toString()); 
// [
//   {"insert": "This is "}, 
//   {"insert": "text", "attributes": {"underline": true}, 
//   {"insert": " to be used for QueryDelta⏎"}}
// ]
```

### Deleting content with a case-sensitive match

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('This is a sample text to be used for QueryDelta\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: 'Sample Text',
    startPoint: null,
    lengthOfDeletion: null,
    caseSensitive: true, // if true, "sample text" part wont match
  )
  .build();
debugPrint(result.delta.toString()); 
// [{"insert": "This is a sample text to be used for QueryDelta⏎"}] -- no changes
```

### Deleting multiple occurrences of a target (with onlyOnce: false)

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('The Delta text should be treated as a rich text\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: ' text',
    startPoint: null,
    lengthOfDeletion: null,
    onlyOnce: false,
  )
  .build();
debugPrint(result.delta.toString()); 
// [{"insert": "The Delta should be treated as a rich⏎"}] -- no changes
```
