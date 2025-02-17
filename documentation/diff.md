# A more exact Delta Diff 

The following **Dart** code demonstrates how to perform a more precise `Delta` comparison using the `QueryDelta` class and `DeltaCompareDiffResult`. 

## Usage Examples

```dart
final Delta delta = Delta()..insert('Experimental version Delta\n');
final QueryDelta query = QueryDelta(delta: delta)
    ..insert(
        insert: ' New data',
        target: 'Delta',
        startPoint: null,
        left: false,
    )
    ..delete(
        target: null,
        startPoint: 14,
        lengthOfDeletion: 2,
    )
    ..format(
        offset: 0, 
        len: 12, 
        attribute: Attribute.bold,
    )
    ..build();
final DeltaCompareDiffResult result = query.compareDiff();
debugPrint(result);
```

## Output in console

```console
DeltaCompareDiffResult(
  parts: [
    DeltaDiffPart(before: 'Experimental', after: 'Experimental', start: 0, end: 12, type: format, attributes: {bold: true}),
    DeltaDiffPart(before: ' v', after: ' v', start: 12, end: 14, type: equals),
    DeltaDiffPart(before: 'er', after: '', start: 14, end: 16, type: delete),
    DeltaDiffPart(before: 'sion Delta', after: 'sion Delta', start: 16, end: 26, type: equals),
    DeltaDiffPart(before: '', after: ' New data', start: 26, end: 35, type: insert),
  ]
```
