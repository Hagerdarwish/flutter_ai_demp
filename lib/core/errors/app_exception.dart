/// Base class for all application exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code, super.originalError});
}

class AIException extends AppException {
  const AIException({required super.message, super.code, super.originalError});
}

class StorageException extends AppException {
  const StorageException({required super.message, super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code, super.originalError});
}

class FileException extends AppException {
  const FileException({required super.message, super.code, super.originalError});
}
