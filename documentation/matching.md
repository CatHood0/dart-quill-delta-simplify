# Matching attributes, text or embeds Simplification

The `matching` methods in the `QueryDelta` class allow searching for and extracting specific operations from a `Delta` object based on defined attributes or patterns. These methods are essential for filtering and manipulating content in a document represented by `Delta`.

## What do matching methods do?

Matching methods provide a way to identify specific parts of a Delta according to set criteria. They can search for operations that match certain attributes, text patterns, or object values, enabling more precise modifications or analysis of the content.

## First match

```dart
DeltaRangeResult firstMatch(
   RegExp? pattern, // The string pattern to search for
   Object? rawObject, { // The object to search for within the operations 
   int? operationIndex, // The index of the operation
})
```

### Example

```dart
final Delta delta = Delta()
    ..insert('This is a bold text.\n', {'bold': true})
    ..insert('Header 1')
    ..insert('\n', {'header': 1})
    ..insert('This is a normal paragraph.\n')
    ..insert('Header 2')
    ..insert('\n', {'header': 2})
    ..insert('Another common paragraph.\n');
final DeltaRangeResult result = QueryDelta(delta: delta).firstMatch(
    RegExp('paragraph', caseSensitive: false),
    null, // raw pattern
    operationIndex: 0, // where will start
);
print(result); // DeltaRangeResult(delta: [{"insert": "paragraph"}], Offset: [47, 56]) 
```
## Multiple occurrence matches 

```dart
List<DeltaRangeResult> allMatches(
   RegExp? pattern, // The string pattern to search for
   Object? rawObject, { // The object to search for within the operations 
   int? operationIndex, // The index of the operation
})
```

### Example
```dart
final Delta delta = Delta()
    ..insert('This is a bold text.\n', {'bold': true})
    ..insert('Header 1')
    ..insert('\n', {'header': 1})
    ..insert('This is a normal paragraph.\n')
    ..insert('Header 2')
    ..insert('\n', {'header': 2})
    ..insert('Another common paragraph.\n');
final List<DeltaRangeResult> result = QueryDelta(delta: delta).allMatches(
    RegExp('paragraph', caseSensitive: false),
    null, // raw pattern
    operationIndex: 0, // where will start
);
print(result); 
// [
//   DeltaRangeResult(delta: [{"insert": "paragraph"}], Offset: [47, 56]),
//   DeltaRangeResult(delta: [{"insert": "paragraph"}], Offset: [82, 91]),
// ] 
//
```

## Matching attributes 

```dart
List<DeltaRangeResult> matchAttributes({
   required Attributes? inlineAttrs, // A map of inline attributes to match against the operations 
   required Attributes? blockAttrs, // A map of block attributes to match against the operations
   required List<String>? blockAttrKeys, // A list of block attribute keys to match against the operations
   required List<String>? inlineAttrKeys, // A list of inline attribute keys to match against the operations
   bool strictKeysCheck = true, // If `true`, only matches operations where all specified keys are present
   bool onlyOnce = false, // If `true`, stops searching after the first match
})
```

### Example

```dart
final Delta delta = Delta()
    ..insert('This is a bold text.\n', {'bold': true})
    ..insert('Header 1')
    ..insert('\n', {'header': 1})
    ..insert('This is a normal paragraph.\n')
    ..insert('Header 2')
    ..insert('\n', {'header': 2})
    ..insert('Another common paragraph.\n');
final List<DeltaRangeResult> result = QueryDelta(delta: delta).matchAttributes(
  inlineAttrs: {'bold': true},
  blockAttrKeys: ['header'],
  blockAttrs: null,
  inlineAttrKeys: null,
);
print(result); 
// [
//  DeltaRangeResult(delta: [{"insert": "This is a bold text.", "attributes": {"bold": true}}], Offset: [0, 20]),
//  DeltaRangeResult(delta: [{"insert": "Header 1"}, {"insert": "⏎", "attributes": {"header": 1}}], Offset: [21, 30]),
//  DeltaRangeResult(delta: [{"insert": "Header 2"}, {"insert": "⏎", "attributes": {"header": 2}}], Offset: [58, 67]),
// ] 
```
