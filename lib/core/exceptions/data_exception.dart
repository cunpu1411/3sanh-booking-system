class DataException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  DataException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'DataException: $message';
}
