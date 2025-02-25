# Format Operations Simplification

The `format` method in the `QueryDelta` class allows you to apply an `Attribute` to a specific part of a `Delta` object. It is useful for text editing scenarios where precise formatting needs to be applied to certain text segments based on offset and length.

## Method Signature

```dart
QueryDelta format({
  // The starting position where the formatting will begin in the Delta
  required int? offset, 
  // The formatting Attribute to be applied
  required Attribute attribute,
  // The number of characters over which the formatting will be applied
  int? len,
  // Specifies a specific target within the Delta for applying the format. 
  // The target can be a String or a Map
  Object? target,
  // A flag indicating whether the search for the target should be case-sensitive
  bool caseSensitive = false,
})
```

## Notes

* If the attribute is inline (e.g., text styles like **bold** or _italic_), and `len` is not provided, an `assertion error` will be thrown. The method expects `len` to specify how many characters should receive the formatting.

* If Attribute is block-level (e.g., **header** style), the `len` parameter may be ignored if it is not major than the `Operation` matched, and the formatting is applied to the entire operation that matches the `offset`.

* The `target` allows matching a specific part of the `Delta` to apply the format. This is helpful for selectively formatting only parts of the text that meet certain criteria.

## Usage Examples

### Applying **Bold** to a Specific Range

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('Hello, world!\n');
final BuildResult result = QueryDelta(delta: delta)
   .format(
     attribute: Attribute.bold,
     offset: 0,
     len: 5,
   ).build();
debugPrint(result.delta.toString());
// [
//  {'insert': 'Hello', 'attributes': {'bold': true}}, 
//  {'insert': ', world!⏎'}
// ]
```

### Formatting a **Targeted** Text Segment

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('The quick brown fox jumps over the lazy dog.\n');
final BuildResult result = QueryDelta(delta: delta)
    .format(
       attribute: Attribute.italic,
       target: 'brown fox',
       offset: null,
       len: null,
    )
    .build();
debugPrint(result.delta.toString()); 
// [
//   {'insert': 'The quick '}, 
//   {'insert': 'brown fox', 'attributes': {'italic': true}}, 
//   {'insert': ' jumps over the lazy dog.⏎'}
// ]
```

### Applying a Block Attribute

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
final Delta delta = Delta()..insert('A paragraph\n');
final BuildResult result = QueryDelta(delta: delta)
    .format(
       attribute: Attribute.blockQuote,
       offset: 0,
       len: null,
    )
    .build();
debugPrint(result.delta.toString()); 
// [
//   {'insert': 'A paragraph'}, 
//   {'insert': '⏎', 'attributes': {'blockquote': true}}
// ]
```

### Case-Sensitive Formatting

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert('Example text with Example repeated.\n');
final BuildResult result = QueryDelta(delta: delta)
    .format(
       attribute: Attribute.bold,
       target: 'Example',
       offset: null,
       len: null,
       caseSensitive: true,
    )
    .build();
debugPrint(result.delta.toString()); 
// [
//   {'insert': 'Example', 'attributes': {'bold': true}}, 
//   {'insert': ' text with '}, 
//   {'insert': 'Example', 'attributes': {'bold': true}}, 
//   {'insert': ' repeated.⏎'}
// ]
```
