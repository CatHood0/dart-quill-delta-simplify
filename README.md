# ✂️ Dart Quill Delta Simplify

This is a package designed to facilitate the manipulation of documents in the **Quill Delta** format within the `Flutter/Dart` ecosystem. The **Quill Delta** format is a data structure used by the **Quill text editor** and **Fluter Quill** to represent rich content, including text, attributes (such as **bold** or _italic_), and multimedia insertions.

## ❓ Why use it?

Manipulating content in a `Delta` format can be complex, especially when dealing with advanced operations such as searching, modifying, or filtering text based on specific attributes or patterns. `**Dart Quill Delta Simplify**` addresses this complexity by providing a user-friendly and powerful API that allows developers to perform these operations with ease and precision.

## 📚 Documentation

For detailed usage and API references, refer to the official [Dart Quill Delta](https://github.com/FlutterQuill/dart-quill-delta?tab=readme-ov-file#-dart-quill-delta) documentation.

### Resources

For detailed usage of the `QueryDelta` API, you can see:

[Insert.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/insert.md)
[Replace.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/replace.md)
[Format.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/format.md)
[Delete.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/delete.md)
[Diff.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/diff.md)
[Matching.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/matching.md)

## 📖 Some basic examples

### 1. Inserting Text at a Specific Position

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello!');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Insert ' World' after 'Hello'
  final BuildResult newDelta = queryDelta.insert(
    insert: ' World',
    target: 'Hello',
    startPoint: 5,
  ).build();

  print(newDelta.delta); // Should print 'Hello World'
}
```

### 2. Replacing Text Based on a Condition

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Replace 'World' with 'Dart'
  final BuildResult newDelta = queryDelta.replace(
    replace: 'Dart',
    target: 'World',
    range: null,
  ).build();

  print(newDelta.delta); // Should print 'Hello Dart!'
}
```

### 3. Formatting a Text Segment

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Delete 'World' from the text
  final BuildResult newDelta = queryDelta.delete(
    target: 'World',
    startPoint: 6,
    lengthOfDeletion: 5,
  );

  print(newDelta.delta); // Should print 'Hello!'
}
```

### 4. Deleting a Specific Text Segment

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Delete 'World' from the text
  final BuildResult newDelta = queryDelta.delete(
    target: 'World',
    startPoint: 6,
    lengthOfDeletion: 5,
  );

  print(newDelta.delta); // Should print 'Hello!'
}
```

### 5. Ignoring a Part of the Delta

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!\n');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Ignore the first 5 characters ('Hello')
  final BuildResult newDelta = queryDelta
      .ignorePart(0, len: 5)
      .delete(
        target: null,
        startPoint: 0,
        lengthOfDeletion: 5,
      )
      .build();

  print(newDelta.delta); // Should print 'World!'
}
```

### 6. Search for Specific Text in a Delta

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Search for the first occurrence of the word 'World'
  final DeltaRangeResult? match = queryDelta.firstMatch(RegExp('World'), null, operationIndex: 0);

  if (match != null) {
    print('Found "${match.delta}" at index ${match.startOffset}');
  } else {
    print('No match found');
  }
}
```

### 7. Filter Segments of Text with a Specific Attribute

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()
    ..insert('Hello', {'bold': true})
    ..insert(' World')
    ..insert('!', {'italic': true});

  final QueryDelta queryDelta = QueryDelta(delta: delta);

  // Retrieve all segments with the 'bold' attribute
  final List<DeltaRangeResult> boldMatches = queryDelta.matchAttributes(
    inlineAttrs: {'bold': true},
    blockAttrs: null,
    blockAttrKeys: null,
    inlineAttrKeys: null,
  );
  print(boldMatches.toString());
}
```

