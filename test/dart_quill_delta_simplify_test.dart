import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:test/test.dart';

void main() {
  late Delta delta;
  setUp(() {
    delta = Delta()..insert('Experimental version Delta\n');
  });

  test('should fail when build method is used without create some conditions',
      () {
    expect(
      () => QueryDelta(delta: delta).build(),
      throwsA(const NoConditionsCreatedWhileBuildExecutionException()),
    );
  });

  group('contains', () {
    test('should contains simple characters part', () {
      final QueryDelta query = QueryDelta(delta: delta);
      expect(query.contains(target: 'Delta'), isTrue);
    });

    test('should contains pattern part', () {
      final QueryDelta query = QueryDelta(delta: delta);
      expect(
        query.contains(target: RegExp(r'^Experimental', caseSensitive: true)),
        isTrue,
      );
    });

    test('should contains pattern part that is divided by operations', () {
      delta = Delta()
        ..insert('Exper', {'bold': true})
        ..insert('imental\n');
      final QueryDelta query = QueryDelta(delta: delta);
      expect(
        query.contains(
            target: RegExp(r'^Experimental', caseSensitive: true),
            usePlainText: true),
        isTrue,
      );
    });

    test('should not match by pattern part when found divided operations', () {
      delta = Delta()
        ..insert('Exper', {'bold': true})
        ..insert('imental\n');
      final QueryDelta query = QueryDelta(delta: delta);
      expect(
        query.contains(
            target: RegExp(r'^Experimental', caseSensitive: true),
            usePlainText: false),
        isFalse,
      );
    });

    test('should not contain part by wrong index', () {
      final QueryDelta query = QueryDelta(delta: delta);
      // will start the verificion here ("|" is the index position):
      //
      // "Experimental version Del|ta"
      expect(query.contains(target: 'Delta', startIndex: 24), isFalse);
    });

    test('should throw RangeError by bad index', () {
      expect(
        () =>
            QueryDelta(delta: delta).contains(target: 'Delta', startIndex: 700),
        throwsA(
          isA<RangeError>(),
        ),
      );
    });
  });

  // insert
  group('insert', () {
    test('should insert into defined range', () {
      final Delta expected = Delta()
        ..insert('Experimental version Delta New data\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..insert(
          insert: ' New data',
          target: null,
          startPoint: 26,
          left: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should insert into matched part', () {
      final Delta expected = Delta()
        ..insert('Experimental version Delta New data\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..insert(
          insert: ' New data',
          target: 'Delta',
          startPoint: null,
          left: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should insert into at left', () {
      final Delta expected = Delta()
        ..insert('Experimental version New data Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..insert(
          insert: 'New data ',
          target: 'Delta',
          startPoint: null,
          left: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
  });
  // delete
  group('delete', () {
    test('should delete into defined range', () {
      final Delta expected = Delta()..insert('Expe version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..delete(
          startPoint: 4,
          lengthOfDeletion: 8,
          target: null,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should delete into matched part', () {
      final Delta expected = Delta()..insert('Expe version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..delete(
          startPoint: null,
          lengthOfDeletion: null,
          target: 'rimental',
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
  });
  // replace
  group('replace', () {
    // replace with text
    test('should replace with normal string into defined range', () {
      final Delta expected = Delta()..insert('Non experimental Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: 'Non experimental',
          target: null,
          range: const DeltaRange(startOffset: 0, endOffset: 20),
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should replace with normal string into matched part', () {
      final Delta expected = Delta()
        ..insert('Non experimental version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: 'Non experimental ',
          target: 'experimental ',
          range: null,
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    // replace with a new operation
    test('should replace with a operation into defined range', () {
      final Operation op = Operation.insert('Experimental ', {'bold': true});
      delta.insert('of this part of the code\n');
      final Delta expected = Delta()
        ..push(op)
        ..insert('is part of the code\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: op,
          target: null,
          range: const DeltaRange(startOffset: 0, endOffset: 32),
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should replace with a operation into matched part', () {
      final Operation op = Operation.insert('Experimental ', {'bold': true});
      delta.insert('of this part of the code\n');
      final Delta expected = Delta()
        ..push(op)
        ..insert('\nof this part of the code\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: op,
          target: 'experimental version delta',
          range: null,
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    // embed image
    test('should replace with image into defined range', () {
      final image = {
        'image':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s',
      };
      final Delta expected = Delta()
        ..insert(image)
        ..insert('version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: image,
          target: null,
          range: const DeltaRange(startOffset: 0, endOffset: 13),
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should replace with image into matched part', () {
      final image = {
        'image':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s',
      };
      final Delta expected = Delta()
        ..insert(image)
        ..insert('version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replace(
          replace: image,
          target: 'experimental ',
          range: null,
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
    });

    test('should replace markdown image with a valid embed operation', () {
      final image = {
        'image': 'https:'
            '//encrypted-tbn0.gstatic.com'
            '/images?q=tbn:'
            'ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s',
      };
      delta.insert('![](https:'
          '//encrypted-tbn0.gstatic.com'
          '/images?q=tbn:'
          'ANd9GcT_G1EXGbaNjBcx_u14jkW7NCQmJibMOr-EwQ&s)'
          '\n');
      final RegExp pattern = RegExp(r'!\[\]\((.+?)\)');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert(image)
        ..insert('\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..replaceAllMapped(
          replaceBuilder: (
            String data,
            Map<String, dynamic>? currentOperationAttributes,
            DeltaRange currentRange,
            DeltaRange matchRange,
          ) {
            if (pattern.hasMatch(data)) {
              final rMatch = pattern.firstMatch(data)!;
              final String image = rMatch.group(1)!;
              return <Operation>[
                Operation.insert(<String, dynamic>{'image': image})
              ];
            }
            return <Operation>[];
          },
          target: pattern.pattern,
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
  });
  // format
  group('format', () {
    test('should format with inline attribute into defined range', () {
      final Delta expected = Delta()
        ..insert('Experimental ', {'italic': true})
        ..insert('version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..format(
          target: null,
          offset: 0,
          len: 13,
          attribute: Attribute.italic,
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should format with inline into matched part', () {
      final Delta expected = Delta()
        ..insert('Experimental ', {'italic': true})
        ..insert('version Delta\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..format(
          target: 'experimental ',
          len: null,
          offset: null,
          attribute: Attribute.italic,
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    // variants
    test('should format operation with block attr', () {
      final Delta expected = Delta()
        ..insert('Experimental version Delta')
        ..insert('\n', {'header': 1});
      final QueryDelta query = QueryDelta(delta: delta)
        ..format(
          target: null,
          offset: 0,
          len: 13,
          attribute: Attribute.h1,
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
    test('should format operation with block attr and long range', () {
      delta
        ..insert('Where we can test our different type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental ', {'underline': true})
        ..insert('version', {'bold': true})
        ..insert(' Delta')
        ..insert('\n', {'header': 1})
        ..insert('Where we can test our different type changes')
        ..insert('\n', {'header': 1})
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..format(
          target: 'experimental ',
          offset: null,
          len: null,
          attribute: Attribute.underline,
          caseSensitive: false,
        )
        ..format(
          target: null,
          offset: 13,
          len: 7,
          attribute: Attribute.bold,
          caseSensitive: false,
        )
        ..format(
          target: null,
          offset: 0,
          len: 50,
          attribute: Attribute.h1,
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
  });
  // catch
  // ignore
  group('ignore', () {
    // range
    test('should ignore replace into defined range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert(
            'Where we can test our different Non experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..replace(
          replace: 'Non experimental ',
          target: null,
          range: const DeltaRange(startOffset: 59, endOffset: 72),
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "type"
      // and now the replace shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(76, len: 4)
        ..replace(
          replace: 'source',
          target: null,
          range: const DeltaRange(startOffset: 76, endOffset: 80),
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore delete into defined range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert('Where we can test our different type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..delete(
          target: null,
          startPoint: 58,
          lengthOfDeletion: 13,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "type"
      // and now the delete shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(60, len: 20)
        ..delete(
          target: null,
          startPoint: 63,
          lengthOfDeletion: 4,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore insert into defined range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert(
            'Where we can test our different Non experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..insert(
          insert: 'Non ',
          target: null,
          startPoint: 59,
          left: true,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "type"
      // and now the insert shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(60, len: 20)
        ..insert(
          insert: 's',
          target: null,
          startPoint: 74,
          left: true,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore format into defined range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert('Where we can test our different ')
        ..insert('experimental', {'color': 'red'})
        ..insert(' type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..format(
          target: null,
          attribute: const ColorAttribute('red'),
          offset: 59,
          len: 12,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "type"
      // and now the format shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(60, len: 20)
        ..format(
          target: null,
          attribute: const ColorAttribute('blue'),
          offset: 77,
          len: 3,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    // match
    test('should ignore replace into matched range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert(
            'Where we can test our different Non experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..replace(
          replace: 'Non experimental ',
          target: 'experimental ',
          range: null,
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "Non"
      // and now the replace shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(55, len: 20)
        ..replace(
          replace: 'source',
          target: 'Non',
          range: null,
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore delete into matched range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert('Where we can test our different type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..delete(
          target: 'experimental ',
          startPoint: null,
          lengthOfDeletion: null,
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "Non"
      // and now the replace shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(55, len: 20)
        ..delete(
          target: 'type ',
          startPoint: null,
          lengthOfDeletion: null,
          caseSensitive: false,
          onlyOnce: false,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore insert into matched range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert(
            'Where we can test our different Non experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..insert(
          insert: 'Non ',
          target: 'experimental',
          left: true,
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the part "Non"
      // and now the replace shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(55, len: 30)
        ..insert(
          insert: 'condition ',
          target: 'type',
          left: true,
          caseSensitive: false,
          onlyOnce: true,
        )
        ..build(preventReuseConditions: true);
      expect(query.toDelta(), expected);
    });
    test('should ignore format into matched range', () {
      delta
        ..insert('Where we can test our different experimental type changes\n')
        ..insert('And we can also match some parts\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta\n')
        ..insert('Where we can test our different ')
        ..insert('experimental', {'script': 'sub'})
        ..insert(' type changes\n')
        ..insert('And we can also match some parts\n');
      final QueryDelta query = QueryDelta(delta: delta)
        ..ignorePart(0, len: 50)
        ..format(
          offset: null,
          len: null,
          attribute: Attribute.subscript,
          target: 'experimental',
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
      // add a new ignore that wrap the last "experimental" part
      // and now the replace shouldn't be do it since that part now
      // need to be ignored
      query
        ..ignorePart(55, len: 20)
        ..format(
          offset: null,
          len: null,
          attribute: Attribute.script,
          target: 'experimental',
          caseSensitive: false,
        )
        ..build();
      expect(query.toDelta(), expected);
    });
  });

  // match parts
  group('matches', () {
    test('should get portion of the Delta with match pattern', () {
      final DeltaRangeResult? result = delta.toQuery.firstMatch(
        RegExp('Experimental', caseSensitive: false),
        null,
        operationIndex: 0,
      );
      expect(
        result,
        DeltaRangeResult(
            delta: Delta()..insert('Experimental'),
            startOffset: 0,
            endOffset: 12),
      );
    });
    test('should get portion of the Delta with a raw object matching', () {
      final List<DeltaRangeResult> result = delta.toQuery.allMatches(
        null,
        'version',
        operationIndex: 0,
      );
      expect(
        result,
        [
          DeltaRangeResult(
              delta: Delta()..insert('version'),
              startOffset: 13,
              endOffset: 20),
        ],
      );
    });
    // matching attrs
    test('should get all header parts', () {
      delta.simpleInsert(insert: [
        Operation.insert('Header 1'),
        Operation.insert('\n', {'header': 1}),
        Operation.insert('Header 2'),
        Operation.insert('\n', {'header': 2}),
      ], target: null, startPoint: null, insertAtLastOperation: true);
      final List<DeltaRangeResult> result = delta.toQuery.matchAttributes(
        inlineAttrs: null,
        blockAttrs: null,
        blockAttrKeys: ['header'],
        inlineAttrKeys: null,
      );
      expect(
        result,
        [
          DeltaRangeResult(
            delta: Delta()
              ..insert('Header 1')
              ..insert('\n', {'header': 1}),
            startOffset: 27,
            endOffset: 36,
          ),
          DeltaRangeResult(
            delta: Delta()
              ..insert('Header 2')
              ..insert('\n', {'header': 2}),
            startOffset: 36,
            endOffset: 45,
          ),
        ],
      );
    });
    test('should get all operations with bold parts', () {
      delta.simpleInsert(insert: [
        Operation.insert('He'),
        Operation.insert('ader 1', {'bold': true}),
        Operation.insert('\n', {'header': 1}),
        Operation.insert('Header '),
        Operation.insert('2', {'bold': true}),
        Operation.insert('\n', {'header': 2}),
      ], target: null, startPoint: null, insertAtLastOperation: true);
      final List<DeltaRangeResult> result = delta.toQuery.matchAttributes(
        inlineAttrs: null,
        blockAttrs: null,
        blockAttrKeys: null,
        inlineAttrKeys: ['bold'],
      );
      expect(
        result,
        [
          DeltaRangeResult(
            delta: Delta()..insert('ader 1', {'bold': true}),
            startOffset: 29,
            endOffset: 35,
          ),
          DeltaRangeResult(
            delta: Delta()..insert('2', {'bold': true}),
            startOffset: 43,
            endOffset: 44,
          ),
        ],
      );
    });
  });

  group('ranges', () {
    test('basic range in same operation', () {
      final DeltaRangeResult resultExpected = DeltaRangeResult(
        delta: Delta()..insert('Experimental ve'),
        startOffset: 0,
        endOffset: 15,
      );
      expect(
        delta.toQuery.getRange(
          range: DeltaRange(
            startOffset: 0,
            endOffset: 15,
          ),
        ),
        resultExpected,
      );
    });
    test('range in different operations', () {
      delta
        ..insert('With this test', {'bold': true})
        ..insert(' we can make possible get parts of a Delta without limits',
            {'underline': true})
        ..insert('\n');
      final DeltaRangeResult resultExpected = DeltaRangeResult(
        delta: Delta()
          ..insert('version Delta\n')
          ..insert('With this test', {'bold': true})
          ..insert(
            ' we can make possible get parts of',
            {'underline': true},
          ),
        startOffset: 13,
        endOffset: 75,
      );
      expect(
        QueryDelta(delta: delta).getRange(
          range: DeltaRange(
            startOffset: 13,
            endOffset: 75,
          ),
        ),
        resultExpected,
      );
    });
    test('range in different operations', () {
      delta
        ..insert('With this test', {'bold': true})
        ..insert(' we can make possible get parts of a Delta without limits',
            {'underline': true})
        ..insert('\n');
      final DeltaRangeResult resultExpected = DeltaRangeResult(
        delta: Delta()
          ..insert('version Delta\n')
          ..insert('With this test', {'bold': true})
          ..insert(
            ' we can make possible get parts of',
            {'underline': true},
          ),
        startOffset: 13,
        endOffset: 75,
      );
      expect(
        delta.getRange(
          range: DeltaRange(
            startOffset: 13,
            endOffset: 75,
          ),
        ),
        resultExpected,
      );
    });
  });

  // using delta only
  group('delta_ext', () {
    test('insert', () {
      delta
        ..insert('But, using this experimental test.\n')
        ..insert('We can test if the experimental changes works as expected\n');
      final Delta expected = Delta()
        ..insert('Experimental Delta version Delta\n')
        ..insert('But, using this experimental Delta test.\n')
        ..insert(
            'We can test if the experimental Delta changes works as expected\n');
      delta.simpleInsert(
        insert: ' Delta',
        target: 'Experimental',
        startPoint: null,
        left: false,
        onlyOnce: false,
      );
      expect(delta, expected);
    });

    test('complex insert', () {
      delta
        ..insert('But, using this experimental Delta test.\n')
        ..insert(
            'We can test if the experimental Delta changes works as expected\n');
      final Delta expected = Delta()
        ..insert('Experimental version Delta')
        ..insert({'img': 'my/image/path/to/file.png'})
        ..insert('\nBut, using this experimental Delta')
        ..insert({'img': 'my/image/path/to/file.png'})
        ..insert(' test.\n')
        ..insert('We can test if the experimental Delta')
        ..insert({'img': 'my/image/path/to/file.png'})
        ..insert(' changes works as expected\n');
      delta.simpleInsert(
        insert: {'img': 'my/image/path/to/file.png'},
        target: 'Delta',
        startPoint: null,
        left: false,
        onlyOnce: false,
      );
      expect(delta, expected);
    });

    test('delete', () {
      final Delta expected = Delta()..insert('Experimental version \n');
      delta.simpleDelete(
          target: 'Delta',
          caseSensitive: true,
          len: null,
          startPointOffset: null);
      expect(delta, expected);
    });
    test('replace', () {
      final Delta expected = Delta()
        ..insert('Experimental version of the Delta\n');
      delta.simpleReplace(
          replace: 'version of the', range: null, target: 'version');
      expect(delta, expected);
    });
    test('format', () {
      final Delta expected = Delta()
        ..insert('Experimental', {'bold': true})
        ..insert(' version Delta\n');
      delta.simpleFormat(offset: 0, len: 12, attribute: Attribute.bold);
      expect(delta, expected);
    });
  });
}
