class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AppException({required this.message, this.statusCode, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    super.message = 'Network error occurred',
    super.statusCode,
    super.originalError,
  });
}

class ServerException extends AppException {
  ServerException({
    super.message = 'Server error occurred',
    super.statusCode,
    super.originalError,
  });
}

class AuthException extends AppException {
  AuthException({
    super.message = 'Authentication failed',
    super.statusCode,
    super.originalError,
  });
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    super.message = 'Validation failed',
    this.fieldErrors,
    super.statusCode,
    super.originalError,
  });
}

class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
    super.originalError,
  });
}

class CacheException extends AppException {
  CacheException({super.message = 'Cache error occurred', super.originalError});
}
