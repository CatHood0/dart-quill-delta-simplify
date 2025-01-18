# Replace Operations Simplification

The `replace` method in `QueryDelta` is designed to "replace" a existing content with a new object into the `Delta` at a specified location or based on certain matching criteria. This method provides flexibility in manipulating the content of a Delta by replacing `strings` or `maps` either at a specific position or relative to existing content.

## Method Signature

```dart 
QueryDelta replace({
  required Object replace, // The content to replace the target with. This can be a String, Operation, List<Operation>, or Map
  required Object? target, // The content to be replaced. This can be a String or Map. If null, the range parameter must be provided
  required DeltaRange? range, // Specifies the start and end indices within the Delta where the replacement should occur. If null, the replacement applies to all occurrences of the target
  bool onlyOnce = false, // If true, the replacement is applied only to the first occurrence of the target. Defaults to false
  bool caseSensitive = false, // If true, the search for the target is case-sensitive. Defaults to false
})
```

## Usage Examples

### Simple Text Replacement

```dart
final Delta delta = Delta()..insert("Hello world!\n");
final BuildResult result = QueryDelta(delta: delta).replace(target: "world", replace: "Dart", range: null).build();
print(result.delta); // [{"insert": "Hello Dart!⏎"}]
```

### Case-Insensitive Replacement

```dart
Delta delta = Delta()..insert("Hello World!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
      target: "world",
      replace: "Dart",
      range: null,
      caseSensitive: false,
    )
    .build();
print(result.delta); // [{"insert": "Hello Dart!⏎"}] 
```

### Replace in a Specific Range

```dart
final Delta delta = Delta()..insert("Hello beautiful world!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
      target: null,
      replace: "Dart",
      range: const DeltaRange(startOffset: 6, endOffset: 20),
    )
    .build();
print(result.delta); // [{"insert": "Hello beautiful world!⏎"}] 
```

### Replace Only Once

```dart
final Delta delta = Delta()..insert("Hello world! and Hello world 2!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
      target: "world",
      replace: "Dart",
      range: null,
      onlyOnce: true,
    )
    .build();
print(result.delta); // [{"insert": "Hello Dart! and Hello world 2⏎"}] 
```
