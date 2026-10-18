class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError, super.stackTrace});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError, super.stackTrace});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError, super.stackTrace});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError, super.stackTrace});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError, super.stackTrace});
}

class LocationException extends AppException {
  const LocationException(super.message, {super.code, super.originalError, super.stackTrace});
}

class PaymentException extends AppException {
  const PaymentException(super.message, {super.code, super.originalError, super.stackTrace});
}

class BookingException extends AppException {
  const BookingException(super.message, {super.code, super.originalError, super.stackTrace});
}

class DriverMatchingException extends AppException {
  const DriverMatchingException(super.message, {super.code, super.originalError, super.stackTrace});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.originalError, super.stackTrace});
}