class BusinessException implements Exception {
  final String message;
  final String? code;

  BusinessException(this.message, {this.code});

  @override
  String toString() => 'BusinessException: $message';
}
