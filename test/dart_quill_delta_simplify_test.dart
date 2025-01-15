import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/src/extensions/delta_ext.dart';
import 'package:dart_quill_delta_simplify/src/extensions/query_delta_ext.dart';
import 'package:dart_quill_delta_simplify/src/query_delta.dart';
import 'package:flutter_test/flutter_test.dart';

//TODO: create tests for the different cases (with catch, build, nonBuild, multipleBuilds, delete, formatting, removeFormatting, inserting, replacing, ignoring, matching ops, matching attrs)
void main() {
  late Delta delta;
  setUp(() {
    delta = Delta()..insert('Experimental version Delta\n');
  });
  // insert
  group('insert', () {
    test('should insert into defined range', () {
      final expected = Delta()..insert('Experimental version Delta New data\n');
      final newDeltaV = delta.simpleInsert(
        insert: ' New data',
        target: null,
        startPoint: 26,
        left: false,
      );
      expect(newDeltaV, expected);
    });
    test('should insert into matched part', () {
      final expected = Delta()..insert('Experimental version Delta New data\n');
      final newDeltaV = delta.simpleInsert(
        insert: ' New data',
        target: 'Delta',
        startPoint: null,
        left: false,
      );
      expect(newDeltaV, expected);
    });
    test('should insert into at left', () {});
    test('should insert into at right', () {});
  });
  // delete
  group('delete', () {
    test('should delete into defined range', () {});
    test('should delete into matched part', () {});
  });
  // replace
  group('replace', () {
    test('should replace into defined range', () {});
    test('should replace into matched part', () {});
  });
  // format
  group('format', () {
    test('should format into defined range', () {});
    test('should format into matched part', () {});
    // variants
    test('should format operation with block attr', () {});
    test('should format operation with block attr and long range', () {});
  });
  // catch
  // ignore
  group('ignore', () {
    // range
    test('should ignore replace into defined range', () {});
    test('should ignore delete into defined range', () {});
    test('should ignore insert into defined range', () {});
    test('should ignore format into defined range', () {});
    // match
    test('should ignore replace into matched range', () {});
    test('should ignore delete into matched range', () {});
    test('should ignore insert into matched range', () {});
    test('should ignore format into matched range', () {});
  });
  // multiple builds
  group('multiple builds', () {
    test('should get different Delta versions after some builds', () {});
    test('should get always the same Delta with three build', () {});
  });
  // match parts
  group('matches', () {
    test('should get portion of the Delta with match pattern', () {});
    test('should get portion of the Delta with a raw object matching', () {});
    // matching attrs
    test('should get all header parts', () {});
    test('should get all operations with bold parts', () {});
    test('should get all operations with underline and align parts', () {});
  });
}
