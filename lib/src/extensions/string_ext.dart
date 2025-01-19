final RegExp _newLinesRegexp = RegExp(r'^\n+$');

extension StringExt on String {
  bool startsAndEndsWith(String pattern) {
    return startsWith(pattern) && endsWith(pattern) ||
        length == 1 && endsWith(pattern) ||
        endsWith(pattern);
  }

  bool get hasOnlyNewLines {
    return _newLinesRegexp.hasMatch(this);
  }
}
