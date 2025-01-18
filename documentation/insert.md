# Insert Operations Simplification

The `insert` method in `QueryDelta` is designed to add a new object into the existing `Delta` at a specified location or based on certain matching criteria. This method provides flexibility in manipulating the content of a Delta by inserting `strings`, `maps`, or `operation(s)` either at a specific position or relative to existing content.

## Method Signature

```dart
QueryDelta insert({
  required Object insert, // The object to insert into the Delta. It can be a String, Map, Operation, or a list of Operations
  required Object? target, // An optional object used to match a part of the Operation. This can be a String or a Map<String, dynamic>
  int? startPoint, //An optional parameter indicating the exact offset where the insertion should start. If provided, it overrides target and related parameters 
  bool left = false, // A boolean indicating whether to insert to the left or right of the target. Ignored if startPoint is provided
  bool onlyOnce = false, // A boolean specifying if the insertion should happen only once. Ignored if startPoint is provided
  bool asDifferentOp = false, // A boolean indicating whether the inserted object should be part of its own Operation or merged with the matched target
  bool insertAtLastOperation = false, // A boolean indicating whether the insertion should happen at the end of the last Operation if no target or startPoint is provided
  bool caseSensitive = false, // A boolean determining if the matching of the target should be case-sensitive
}) 
```

## Notes

* Providing both `startPoint` and `target` will prioritize `startPoint`, ignoring `target`, `left`, and `onlyOnce`.

* `insert` accepts various types of objects, and each type's behavior is governed by the logic defined in the method and conditions applied during the `build()` phase.

## Usage Examples

### `Inserting` a `String` at a Specific Offset

```dart
final Delta delta = Delta()..insert('Hello\n');
final BuildResult result = QueryDelta(delta: delta).insert(insert: ', world!', startPoint: 5, target: null).build();
// you can use too: delta.simpleInsert(insert: ', world!', startPoint: 5, target: null);
print(result.delta); // should print: [{"insert": "Hello, world!⏎"}]
```

### `Inserting` a `Map` Relative to a `Target`

```dart
final Delta delta = Delta()..insert('Hello, world!\n');
final BuildResult result = QueryDelta(delta: delta).insert(insert: {'insert': ' and hello again'}, target: 'world!', left: false, target: null).build();
// you can use too: delta.simpleInsert(insert: {'insert': ' and hello again'}, target: 'world!', left: false, target: null, startPoint: null);
print(result.delta); // should print: [{"insert": "Hello, world! and hello again⏎"}]
```

### `Inserting` an `Operation` at the End
```dart
final Delta delta = Delta()..insert('Hello, world! \n');
final Operation operation = Operation.insert('New content', {'bold': true});
final BuildResult result = QueryDelta(delta: delta).insert(insert: operation, insertAtLastOperation: true, target: null).build();
// you can use too: delta.simpleInsert(insert: operation, insertAtLastOperation: true, target: null, startPoint: null);
print(result.delta); // should print: [{"insert": "Hello, world! "}, {"insert": "New content⏎", "attributes": {"bold": true}}]
```

### `Inserting` Multiple Times with a `Target`

```dart
final Delta delta = Delta()..insert('marker content Marker');
final BuildResult result = QueryDelta(delta: delta)
    .insert(
       insert: ' Repeated', 
       target: 'marker', 
       onlyOnce: false, 
       left: false, 
       caseSensitive: false, // if caseSensitive is true, the last "Marker" word wont be matched 
    ).build();
// you can use too: delta.simpleInsert(insert: ' Repeated', target: 'marker', startPoint: null, onlyOnce: false, left: false, caseSensitive: false);
print(result.delta); // should print: [{"insert": "marker Repeated content Marker Repeated⏎"}]
```

### Case-Sensitive `Insertion`

```dart
final Delta delta = Delta()..insert('target is here\n');
final BuildResult result = QueryDelta(delta: delta)
    .insert(
       insert: 's', 
       target: 'Target', 
       left: false, 
       caseSensitive: true, 
    ).build();
// you can use too: delta.simpleInsert(insert: 's', target: 'Target', left: false, caseSensitive: true, startPoint: null);
print(result.delta); // should print: [{"insert": "target is here⏎"}] -- no changes
```
