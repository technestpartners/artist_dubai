import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import 'dio_interceptor.dart';
import 'network_info.dart';

abstract class ApiClient {
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });
}

class ApiClientImpl implements ApiClient {
  final Dio dio;
  final NetworkInfo networkInfo;

  ApiClientImpl({
    required this.dio,
    required this.networkInfo,
    DioInterceptor? interceptor,
    String? baseUrl,
  }) {
    dio.options = BaseOptions(
      baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
      connectTimeout: ApiEndpoints.connectionTimeout,
      receiveTimeout: ApiEndpoints.receiveTimeout,
      responseType: ResponseType.json,
    );

    if (interceptor != null) {
      dio.interceptors.add(interceptor);
    }
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _sendRequest(
      () => dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _sendRequest(
      () => dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _sendRequest(
      () => dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _sendRequest(
      () => dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _sendRequest(
      () => dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<dynamic> _sendRequest(Future<Response> Function() request) async {
    if (!await networkInfo.isConnected) {
      throw const NetworkException();
    }

    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        // Retry once on transient network/timeout error
        try {
          await Future.delayed(const Duration(milliseconds: 600));
          final retryResponse = await request();
          return retryResponse.data;
        } on DioException catch (retryError) {
          _handleDioError(retryError);
        }
      }
      _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  void _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw const NetworkException(
        message: 'Connection timed out. Please check your internet connection and try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw const NetworkException(
        message: 'Unable to reach server. Please check your internet connection and try again.',
      );
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String errorMessage = 'Something went wrong';
    if (data is Map<String, dynamic>) {
      errorMessage = data['message'] ?? data['error'] ?? errorMessage;
    } else if (error.message != null && error.message!.isNotEmpty) {
      errorMessage = error.message!;
    }

    switch (statusCode) {
      case 401:
      case 403:
        throw UnauthorizedException(
          message: errorMessage,
          statusCode: statusCode,
        );
      case 422:
        throw ValidationException(
          message: errorMessage,
          statusCode: statusCode,
        );
      default:
        throw ServerException(message: errorMessage, statusCode: statusCode);
    }
  }
}
