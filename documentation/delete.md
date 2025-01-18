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

### Deleting a specific portion of text

```dart
final Delta delta = Delta()..insert('This is a sample text to be used for QueryDelta\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: 'sample text ',
    startPoint: 5,
    lengthOfDeletion: 10,
  )
  .build();
print(result.delta); // [{"insert": "This is a to be used for QueryDelta⏎"}]
```

### Deleting a portions of text that are in different Operations 

```dart
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
print(result.delta); // [{"insert": "This is "}, {"insert": "text", "attributes": {"underline": true}, {"insert": " to be used for QueryDelta⏎"}}]
```

### Deleting content with a case-sensitive match

```dart
final Delta delta = Delta()..insert('This is a sample text to be used for QueryDelta\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: 'Sample Text',
    startPoint: null,
    lengthOfDeletion: null,
    caseSensitive: true, // if true, "sample text" part wont match
  )
  .build();
print(result.delta); // [{"insert": "This is a sample text to be used for QueryDelta⏎"}] -- no changes
```

### Deleting multiple occurrences of a target (with onlyOnce: false)

```dart
final Delta delta = Delta()..insert('The Delta text should be treated as a rich text\n');
final BuildResult result = QueryDelta(delta: delta)
  .delete(
    target: ' text',
    startPoint: null,
    lengthOfDeletion: null,
    onlyOnce: false,
  )
  .build();
print(result.delta); // [{"insert": "The Delta should be treated as a rich⏎"}] -- no changes
```
