# Format Operations Simplification

The `format` method in the `QueryDelta` class allows you to apply an `Attribute` to a specific part of a `Delta` object. It is useful for text editing scenarios where precise formatting needs to be applied to certain text segments based on offset and length.

## Method Signature

```dart
QueryDelta format({
  required int? offset, // The starting position where the formatting will begin in the Delta. 
  required Attribute attribute, // The formatting Attribute to be applied
  int? len, // The number of characters over which the formatting will be applied
  Object? target, // Specifies a specific target within the Delta for applying the format. The target can be a String or a Map
  bool caseSensitive = false, // A flag indicating whether the search for the target should be case-sensitive
})
```

## Notes

* If the attribute is inline (e.g., text styles like **bold** or _italic_), and `len` is not provided, an `assertion error` will be thrown. The method expects `len` to specify how many characters should receive the formatting.

* If Attribute is block-level (e.g., **header** style), the `len` parameter may be ignored if it is not major than the `Operation` matched, and the formatting is applied to the entire operation that matches the `offset`.

* The `target` allows matching a specific part of the `Delta` to apply the format. This is helpful for selectively formatting only parts of the text that meet certain criteria.

### Applying **Bold** to a Specific Range

```dart
final Delta delta = Delta()..insert('Hello, world!\n');
final BuildResult result = QueryDelta(delta: delta)
   .format(
     attribute: Attribute.bold,
     offset: 0,
     len: 5,
   ).build();
print(result.delta)// [{'insert': 'Hello', 'attributes': {'bold': true}}, {'insert': ', world!⏎'}]
```

### Formatting a **Targeted** Text Segment

```dart
final Delta delta = Delta()..insert('The quick brown fox jumps over the lazy dog.\n');
final BuildResult result = QueryDelta(delta: delta)
    .format(
       attribute: Attribute.italic,
       target: 'brown fox',
       offset: null,
       len: null,
    )
    .build();
print(result.delta); // [{'insert': 'The quick '}, {'insert': 'brown fox', 'attributes': {'italic': true}}, {'insert': ' jumps over the lazy dog.⏎'}]
```

### Applying a Block Attribute

```dart
final Delta delta = Delta()..insert('A paragraph\n');
final BuildResult result = QueryDelta(delta: delta)
    .format(
       attribute: Attribute.blockQuote,
       offset: 0,
       len: null,
    )
    .build();
print(result.delta); // [{'insert': 'A paragraph'}, {'insert': '⏎', 'attributes': {'blockquote': true}}]
```

### Case-Sensitive Formatting

```dart
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
print(result.delta); 
// [
//   {'insert': 'Example', 'attributes': {'bold': true}}, 
//   {'insert': ' text with '}, 
//   {'insert': 'Example', 'attributes': {'bold': true}}, 
//   {'insert': ' repeated.⏎'}
// ]
```
