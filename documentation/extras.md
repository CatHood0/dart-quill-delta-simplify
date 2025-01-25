# Another features of this package

## Converting any Object to a Operation 

We can use `toOperation()` method to converts the current object into an `Operation` or a `List<Operation>` instances.

```dart
/// Only support: `String`, `Map`, `List<Operation>`, `Operation`
Object toOperation([Attributes? inlineAttributes, Attributes? blockAttributes]) {}
```

### Example:
  
```dart
final operation = 'Hello, world'.toOperation();
final operationWithAttributes = 'Hello'.toOperation(
     {'color': 'red'}, // inline attributes
     {'align': 'center'} // block attributes
   );
print(operation); // {"insert": "Hello"}
print(operationWithAttributes); 
// [
//  {"insert": "Hello", "attributes": {"color": "red"}, 
//  {"insert": "⏎", "attributes": {"align": "center"}},
// ]

final map = {'image': 'path/to/image/file.jpg'};
final insertMap = {'insert': 'This is an example', 'attributes': {'bold': true}};
// for maps works, different
// if we have a embed object, this will be converted in a common operation
final embedOp = map.toOperation({'style': 'width:200px;height:px;'});
// but, if we have a Json operation, this will be converted in a Operation again
final insertOp = insertJson.toOperation();
print(embedOp); // {"insert": {'image': 'path/to/image/file.jpg'}, "attributes": {"styles": "width:200px;height:px;"}}
// we show this as json because is more simple
print(insertOp); // {"insert": "This is an example", "attributes": "bold": true} 
```


## Getting an effective length of a Operation or List of Operations 

Getting effetive length means that we will get only the exact length that we want (the data length). Use this carefully, because, if there some `retain/delete Operations` or is a `retain/delete Operation`, will throw `IllegalOperationPassedException`

```dart
int get getEffectiveLength {}
```

### Example

```dart
final Operation errorOp = Operation.retain(23);
final Operation errorOp2 = Operation.delete(23);
print(errorOp.getEffectiveLength); // will throw IllegalOperationPassedException
print(errorOp2.getEffectiveLength); // will throw IllegalOperationPassedException

final Operation validOp = Operation.insert('This is my subscript text.\n', {'script': 'sub'});
print('len: ${validOp.getEffectiveLength}'); // len: 27

final List<Operation> listOfOps = [
   Operation.insert('This is an example'),
   Operation.insert(' of how works getting effective length example\n'),
];
print('len: ${listOfOps.getEffectiveLength}'); // len: 66 

```

## Converting Delta or Operation to plain text

Getting effetive length means that we will get only the exact length that we want (the data length). Use this carefully, because, if there some `retain/delete Operations` or is a `retain/delete Operation`, will throw `IllegalOperationPassedException`

### Operation object

```dart
String toPlain({String Function(Object embedData)? embedBuilder}) {}
```

### Delta object

```dart
String toPlain({String Function(Object embedData)? embedBuilder}) {}
String toPlainBuilder(String Function(Operation op) opToPlainBuilder) {}
```

### Example

```dart
// using Delta
final Delta delta = Delta()
  ..insert('This is my example delta\nUsing ')
  ..insert('toPlain', {'code': true})
  ..insert(' method, we can build a plain text without too much code\n');
final plainText = delta.toPlain();
final plainTextBuilded = delta.toPlainBuilder((Operation op) => op.data.toString());
// using Operation
final Operation op = Operation.insert('This is an op example\n');
// ensure that you op is insert, because toPlain can throw IllegalOperationPassedException
final opPlainText = op.toPlain();
// will have the same string result
print(plainText);
print(plainTextBuilded);
// but this will be different by a obvious reason
print(opPlainText); // "This is an op example\n"
```

## Checking the type of the Operation

```dart
/// Checks if the operation represents a block-level insertion (e.g., a newline with attributes).
bool get isBlockLevelInsertion {}
/// Checks if the operation represents a new line.
bool get isNewLine {}
/// Checks if the operation contains embedded data.
bool get isEmbed {};
/// Checks if the operation contains a new line.
bool containsNewLine() {}
/// Checks if the operation represents a new line or a block insertion.
bool get isNewLineOrBlockInsertion {} 
/// Returns the opposite of [isBlockLevelInsertion].
bool get nonIsBlockLevelInsertion {} 
```

## Converting Delta to QueryDelta (without create an instance manually)

If we don't want create a instance of `QueryDelta` manually, we can use `toQuery()` method:

```dart
QueryDelta get toQuery => QueryDelta(delta: <delta>);
```

### Example

```dart
final Delta delta = Delta()..insert('This is an example\n');
final BuildResult result = delta.toQuery
    .insert(
       insert: ' data',
       target: null,
       startPoint: 4,
       left: false,
    )
    .build();
print(result.delta); // [{"insert": "This data is an example⏎"}]
```
