import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import 'package:flutter/foundation.dart';
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
      persistentConnection: !kIsWeb ? false : true,
      headers: {
        'Accept': 'application/json',
        if (!kIsWeb) 'Connection': 'close',
      },
    );

    if (dio.httpClientAdapter is IOHttpClientAdapter) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 2);
        client.connectionTimeout = const Duration(seconds: 10);
        return client;
      };
    }

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
      if (_isTransientNetworkError(e)) {
        // Retry up to 2 times on transient network/timeout/connection abort error
        for (int attempt = 1; attempt <= 2; attempt++) {
          try {
            await Future.delayed(Duration(milliseconds: 250 * attempt));
            final retryResponse = await request();
            return retryResponse.data;
          } on DioException catch (retryError) {
            if (attempt == 2 || !_isTransientNetworkError(retryError)) {
              _handleDioError(retryError);
            }
          }
        }
      }
      _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  bool _isTransientNetworkError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    if (error.type == DioExceptionType.unknown) {
      final message = '${error.error} ${error.message}'.toLowerCase();
      if (message.contains('software caused connection abort') ||
          message.contains('connection abort') ||
          message.contains('httpexception') ||
          message.contains('socketexception') ||
          message.contains('connection closed') ||
          message.contains('connection reset') ||
          message.contains('broken pipe') ||
          message.contains('clientexception')) {
        return true;
      }
    }

    return false;
  }

  void _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw const NetworkException(
        message: 'Connection timed out. Please check your internet connection and try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        _isTransientNetworkError(error)) {
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
