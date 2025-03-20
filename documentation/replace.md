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
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert("Hello world!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
        target: "world", 
        replace: "Dart", 
        range: null,
    )
    .build();
debugPrint(result.delta.toString()); // [{"insert": "Hello Dart!⏎"}]
```

### Case-Insensitive Replacement

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

Delta delta = Delta()..insert("Hello World!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
      target: "world",
      replace: "Dart",
      range: null,
      caseSensitive: false,
    )
    .build();
debugPrint(result.delta.toString()); // [{"insert": "Hello Dart!⏎"}] 
```

### Replace in a Specific Range

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

final Delta delta = Delta()..insert("Hello beautiful world!\n");
final BuildResult result = QueryDelta(delta: delta)
    .replace(
      target: null,
      replace: "Dart",
      range: const DeltaRange(startOffset: 6, endOffset: 20),
    )
    .build();
debugPrint(result.delta.toString()); // [{"insert": "Hello Dart!⏎"}] 
```

### Replace Only Once

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';

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

## Dynamic replace method

```dart 
/// It's very similar to [replaceAllMapped] from String class
QueryDelta replaceAllMapped({
  required OperationBuilder replace, 
  required String target, 
  bool caseSensitive = false,
})
```

## Usage Example for `replaceAllMapped`

```dart
final Delta delta = Delta()
  ..insert('Experimental version Delta\n')
  ..insert('![](https:'
    '//encrypted-tbn0.gstatic.com'
    '/images?q=tbn:'
    'ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s)'
    '\n');
// basic markdown image pattern (just created for example purposes)
final RegExp pattern = RegExp(r'!\[\]\((.+?)\)');
final BuildResult result = QueryDelta(delta: delta)
 .replaceAllMapped(
   replaceBuilder: (
     String data,
     Map<String, dynamic>? currentOperationAttributes,
     DeltaRange currentRange,
     DeltaRange matchRange,
   ) {
     if (pattern.hasMatch(data)) {
       final rMatch = pattern.firstMatch(data)!;
       final String image = rMatch.group(1)!;
       return <Operation>[Operation.insert(<String, dynamic>{'image': image})];
     }
     return <Operation>[];
   },
   target: pattern.pattern,
   caseSensitive: false,
 )
 .build();
debugPrint(result.delta.toString());
/*
[
 {'insert': 'Experimental version Delta\n'},
 {'insert': {'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s'}},
 {'insert': '\n'},
]
*/
```
