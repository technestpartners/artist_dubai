class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'No internet connection available.'});

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  final int? statusCode;

  const UnauthorizedException({this.message = 'Unauthorized access', this.statusCode = 401});

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final int? statusCode;

  const ValidationException({required this.message, this.statusCode = 422});

  @override
  String toString() => message;
}
