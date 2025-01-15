class NoAcceptedObjectType implements Exception {
  final Object object;
  final List<Object> acceptedTypes;
  NoAcceptedObjectType({
    required this.object,
    required this.acceptedTypes,
  });

  @override
  String toString() {
    return 'The object of type ${object.runtimeType} is not acceptedTypes. Only can use these types: $acceptedTypes';
  }
}
