class ObjectNotFoundException implements Exception {
  String cause;
  ObjectNotFoundException(this.cause);
}