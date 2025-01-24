import 'package:meta/meta.dart';

/// Join the assigned strings by a delimiter
@internal
String joinStrings(
  String? join1,
  String? join2, [
  String join3 = '',
  String join4 = '',
  String join5 = '',
  String join6 = '',
  String join7 = '',
  String separator = '',
]) {
  return [
    join1 ?? '',
    join2 ?? '',
    join3,
    join4,
    join5,
    join6,
    join7,
  ].join(separator);
}
