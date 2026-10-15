import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  /// Factory helper that maps domain and system exceptions to typed Failures.
  factory Failure.fromException(Object error) {
    if (error is Failure) return error;
    final typeName = error.runtimeType.toString();
    final errStr = error.toString();
    if (typeName == 'NetworkException' ||
        errStr.contains('NetworkException') ||
        errStr.contains('SocketException') ||
        errStr.contains('TimeoutException') ||
        errStr.contains('No internet connection')) {
      return NetworkFailure(message: errStr.replaceFirst('Exception: ', ''));
    }
    if (typeName == 'UnauthorizedException' ||
        errStr.contains('UnauthorizedException') ||
        errStr.contains('401') ||
        errStr.contains('403')) {
      return UnauthorizedFailure(
        message: errStr.replaceFirst('Exception: ', ''),
      );
    }
    if (typeName == 'ValidationException' ||
        errStr.contains('ValidationException') ||
        errStr.contains('422')) {
      return ValidationFailure(message: errStr.replaceFirst('Exception: ', ''));
    }
    if (typeName == 'CacheException' || errStr.contains('CacheException')) {
      return CacheFailure(message: errStr.replaceFirst('Exception: ', ''));
    }
    return ServerFailure(message: errStr.replaceFirst('Exception: ', ''));
  }

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection detected.',
    super.statusCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expired or unauthorized.',
    super.statusCode = 401,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode = 422});
}
