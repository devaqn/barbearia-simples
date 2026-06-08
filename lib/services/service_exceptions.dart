class ServiceException implements Exception {
  final String message;
  final Object? cause;

  const ServiceException(this.message, {this.cause});

  @override
  String toString() => 'ServiceException: $message';
}

class ValidationException extends ServiceException {
  const ValidationException(super.message);
}

class NotFoundException extends ServiceException {
  const NotFoundException(super.message);
}

class ConflictException extends ServiceException {
  const ConflictException(super.message);
}

class UnauthorizedException extends ServiceException {
  const UnauthorizedException(super.message);
}
