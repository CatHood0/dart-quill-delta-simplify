class NoConditionsCreatedWhileBuildExecutionException implements Exception {
  const NoConditionsCreatedWhileBuildExecutionException();

  @override
  String toString() {
    return 'During build run was detected that is not registered any type of condition to be applied to the Delta input';
  }
}
