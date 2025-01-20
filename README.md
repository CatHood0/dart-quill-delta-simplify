# ✂️ Dart Quill Delta Simplify

This is a package designed to facilitate the manipulation of documents in the **Quill Delta** format within the Flutter ecosystem. The **Quill Delta** format is a data structure used by the **Quill text editor** and **Fluter Quill** to represent rich content, including text, attributes (such as **bold** or _italic_), and multimedia insertions.

## ❓ Why use it?

Manipulating content in a `Delta` format can be complex, especially when dealing with advanced operations such as searching, modifying, or filtering text based on specific attributes or patterns. **Dart Quill Delta Simplify** addresses this complexity by providing a user-friendly and powerful API that allows developers to perform these operations with ease and precision.

## 📚 Documentation

For detailed usage and API references, refer to the official [Dart Quill Delta](https://github.com/FlutterQuill/dart-quill-delta?tab=readme-ov-file#-dart-quill-delta) documentation.

### 📎 Resources

For detailed usage of the `QueryDelta` API, you can see:

[Insert.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/insert.md)
[Replace.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/replace.md)
[Format.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/format.md)
[Delete.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/delete.md)
[Diff.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/diff.md)
[Matching.md](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/documentation/matching.md)

## 🔎 Introduction to QueryDelta

The `QueryDelta` class is a query builder designed to create and modify `Delta` objects by applying various conditions. It allows for conditional operations and tracks changes made to the delta during the modification process. The purpose of `QueryDelta` is to provide a structured way to manipulate a `Delta` object, while keeping track of applied changes through conditions and ensuring the integrity of the final result.

```dart
QueryDelta({
  required Delta delta,
})
```

### 🔨 Pushing conditions 

The `push` method is used to add a single `Condition` to the `QueryDelta`. Each condition added to the `QueryDelta` defines a rule or requirement for modifying the `Delta`. These conditions are applied in order, so the order in which you add them is important for the final result.

```dart
QueryDelta push(Condition condition);
```

### 🛠️ Building the final Delta

This is the key to finalizing the changes made to the `QueryDelta`. It applies all the conditions that were added to the query and generates the final `Delta`. This method is essential, as no modifications will be applied to the `Delta` until `build()` is run.

```dart
BuildResult build({
  // A function that converts an unknown object type to a list of `Operation` objects
  // use it in case of you use a custom condition and it returns a type that is not supported
  // by default. Supported: [Iterable<Operation>, Operation, String, Map<String,dynamic>]
  List<Operation> Function(Object)? unknownObjectTypeBuilder,
  // Determines whether conditions should be reused. If set to `true`, previously used conditions will be ignored
  bool preventReuseConditions = true,
  // Controls whether ignore conditions should persist when building the final `Delta`
  bool maintainIgnoresConditions = true,
});
```

## 📖 Some examples (using regular operations)

### 1. Inserting Text at a Specific Position

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello!');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Insert ' World' after 'Hello'
  final BuildResult newDelta = queryDelta
    .insert(
      insert: ' World',
      target: 'Hello',
      startPoint: 5,
    )
    .build();

  /* 
  * You can use too:
  * delta.simpleInsert(
  *   insert: ' World',
  *   target: 'Hello',
  *   startPoint: 5,
  * );
  */

  print(newDelta.delta); // Should print [{"insert": "Hello World!"}]
}
```

### 2. Replacing Text Based on a Condition

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Replace 'World' with 'Dart'
  final BuildResult newDelta = queryDelta
    .replace(
      replace: 'Dart',
      target: 'World',
      range: null,
    )
    .build();
  
  /* 
  * You can use too:
  * delta.simpleReplace(
  *  replace: 'Dart',
  *  target: 'World',
  *  range: null,
  * );
  */

  print(newDelta.delta); // Should print [{"insert": "Hello Dart!"}]
}
```

### 3. Formatting a Text Segment

```dart
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Format the second part 'World' to be italic
  final BuildResult updatedDelta = queryDelta
    .format(
      attribute: Attribute.italic,
      offset: 6,
      len: 5,
    )
    .build();

  /*
  * You can use too:
  * delta.simpleFormat(
  *  attribute: Attribute.italic,
  *  offset: 6,
  *  len: 5,
  * );
  */

  // Should print [{"insert": "Hello"}, {"insert": " World", "attributes": {"italic": true}}] 
  print(updatedDelta.delta); 
}
```

### 4. Deleting a Specific Text Segment

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // to delta.toQuery

  // Delete 'World' from the text
  final BuildResult newDelta = queryDelta
      .delete(
        target: null,
        startPoint: 6,
        lengthOfDeletion: 5,
      )
      .build();
  /*
  * You can use too:
  * delta.simpleDelete(
  *  target: 'World',
  *  startPointOffset: 6,
  *  len: 5,
  *);
  */

  print(newDelta.delta); // Should print '[{"insert": "Hello!"}]'
}
```

### 5. Ignoring a Part of the Delta

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!\n');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Ignore the first 5 characters ('Hello')
  final BuildResult newDelta = queryDelta
      .ignorePart(0, len: 5)
      .delete(
        target: null,
        startPoint: 0,
        lengthOfDeletion: 5,
      )
      .build(); // no changes ocurrs since the deletion is into the Range of the Ignore Part

  print(newDelta.delta); // Should print [{"insert": "Hello World!\n"}]
}
```

### 6. Search for Specific Text in a Delta

```dart
import 'package:quill_delta/quill_delta.dart';
import 'package:dart_quill_delta_simplify/query_delta.dart';

void main() {
  final Delta delta = Delta()..insert('Hello World!');
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Search for the first occurrence of the word 'World'
  final DeltaRangeResult? match = queryDelta
    .firstMatch(
     RegExp('World'),
     null,
    );

  /* 
  * Or you can use allMatches to multiple occurrences
  * final List<DeltaRangeResult> match = queryDelta
  *   .allMatches(
  *    RegExp('World'),
  *    null,
  *  );
  *
  * You can use too:
  * final DeltaRangeResult? match2 = delta.firstMatch(
  *   RegExp('World'),
  *   null,
  * );
  * or
  * final List<DeltaRangeResult> match = delta.allMatches(
  *   RegExp('World'),
  *   null,
  * );
  */

  if (match != null) {
    print(match); // DeltaRangeResult(delta: [{"insert": "World"}], Offset: [6, 10])
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
  final QueryDelta queryDelta = QueryDelta(delta: delta); // or delta.toQuery

  // Retrieve all segments with the 'bold' attribute
  final List<DeltaRangeResult> boldMatches = queryDelta.matchAttributes(
    inlineAttrs: {'bold': true},
    blockAttrs: null,
    blockAttrKeys: null,
    inlineAttrKeys: null,
  );

  /*
  * You can use too:
  * final List<DeltaRangeResult> matches = delta.matchAttributes(
  *   inlineAttrs: {'bold': true},
  *   blockAttrs: null,
  *   blockAttrKeys: null,
  *   inlineAttrKeys: null,
  * );
    */

  print(boldMatches.toString());
}
```

## 🌳 Contributing

We greatly appreciate your time and effort.

To keep the project consistent and maintainable, we have a few guidelines that we ask all contributors to follow. These guidelines help ensure that everyone can understand and work with the code easier.

See [Contributing](https://github.com/FlutterQuill/dart-quill-delta-simplify/blob/master/CONTRIBUTING.md) for more details.
