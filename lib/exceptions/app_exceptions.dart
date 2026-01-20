/// Excepciones personalizadas de la aplicación
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => message;
}

/// Excepciones de autenticación
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
  }) : super(message: message, code: code);

  factory AuthException.fromSupabase(dynamic error) {
    if (error is Exception) {
      return AuthException(
        message: error.toString(),
        code: 'AUTH_ERROR',
      );
    }
    return AuthException(
      message: 'Error de autenticación desconocido',
      code: 'UNKNOWN_AUTH_ERROR',
    );
  }
}

/// Excepciones de base de datos
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
  }) : super(message: message, code: code);

  factory DatabaseException.fromSupabase(dynamic error) {
    if (error is Exception) {
      return DatabaseException(
        message: error.toString(),
        code: 'DATABASE_ERROR',
      );
    }
    return DatabaseException(
      message: 'Error de base de datos desconocido',
      code: 'UNKNOWN_DATABASE_ERROR',
    );
  }
}

/// Excepciones de red
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
  }) : super(message: message, code: code);

  factory NetworkException.fromError(dynamic error) {
    if (error is Exception) {
      return NetworkException(
        message: error.toString(),
        code: 'NETWORK_ERROR',
      );
    }
    return NetworkException(
      message: 'Error de conexión desconocido',
      code: 'UNKNOWN_NETWORK_ERROR',
    );
  }
}

/// Excepciones de validación
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Excepciones de IA
class AIException extends AppException {
  AIException({
    required String message,
    String? code,
  }) : super(message: message, code: code);

  factory AIException.fromResponse(int statusCode) {
    return AIException(
      message: 'Error del servicio de IA: $statusCode',
      code: 'AI_SERVICE_ERROR',
    );
  }
}

/// Excepciones de almacenamiento
class StorageException extends AppException {
  StorageException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
