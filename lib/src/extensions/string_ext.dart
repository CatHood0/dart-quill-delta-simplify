final RegExp _newLinesRegexp = RegExp(r'^\n+$');

extension StringExt on String {
  String? substringOrNull(int start, int end, [bool returnEmptyString = false]) {
    return start > 0 && start < length && (end >= start && end > 0) && end < length
        ? substring(start, end)
        : returnEmptyString
            ? ''
            : null;
  }

  bool startsAndEndsWith(String pattern) {
    return startsWith(pattern) && endsWith(pattern) || length == 1 && endsWith(pattern) || endsWith(pattern);
  }

  bool get hasOnlyNewLines {
    return _newLinesRegexp.hasMatch(this);
  }
}
