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
    ..format(offset: 0, len: 12, attribute: Attribute.bold)
    ..build();
final DeltaCompareDiffResult result = query.compareDiff();
print(result);
```

## Output in console

```console
DeltaCompareDiffResult: [
    DeltaDiffPart(before: 'Experimental', after: 'Experimental', start: 0, end: 12, args: {
        'diff_attributes': {
            'new': {'bold': true},
            'old': null
        },
        'isUpdatedPart': true,
    }),
    DeltaDiffPart(
        before: ' version Delta', after: ' version Delta', start: 12, end: 26, args: {'isEquals': true}),
    DeltaDiffPart(before: null, after: ' New data', start: 26, end: 35, args: {'isAddedPart': true}),
    DeltaDiffPart(before: '\n', after: '\n', start: 35, end: 36, args: {'isEquals': true}),
]
```
