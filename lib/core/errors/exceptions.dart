class ServerException implements Exception {
  ServerException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  CacheException({required this.message});

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  NetworkException({required this.message});

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  ValidationException({required this.message});

  final String message;

  @override
  String toString() => 'ValidationException: $message';
}
