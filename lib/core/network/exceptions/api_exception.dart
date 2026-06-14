/// Custom exception hierarchy for API errors.
/// Maps Dio errors to typed, descriptive exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 401 Unauthorized — token expired or invalid
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.']);
}

/// 403 Forbidden
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have permission to perform this action.']);
}

/// 404 Not Found
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested resource was not found.']);
}

/// 422 Validation error — Laravel returns errors map
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    required this.errors,
  }) : super(message);

  final Map<String, List<String>> errors;

  String get firstError {
    if (errors.isEmpty) return message;
    return errors.values.first.first;
  }
}

/// 5xx Server errors
class ServerException extends AppException {
  const ServerException([super.message = 'An unexpected server error occurred.']);
  ServerException.withCode(int code) : super('Server error ($code). Please try again.');
}

/// No internet connection
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Please check your network.']);
}

/// Request timed out
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. Please try again.']);
}

/// Generic / unknown error
class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
