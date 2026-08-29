import 'package:dio/dio.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

class DioInterceptor extends Interceptor {
  final StorageService storageService;
  final LoggerService loggerService;

  DioInterceptor({required this.storageService, required this.loggerService});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storageService.readSecure(
      StorageServiceImpl.keyAuthToken,
    );
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    loggerService.debug('🌐 [HTTP REQUEST] [${options.method}] ${options.path} --> \nHeaders: ${options.headers}\nData: ${options.data}');

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    loggerService.debug('✅ [HTTP RESPONSE] [${response.statusCode}] [${response.requestOptions.path}] <-- \nData: ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    loggerService.error(
      '❌ [HTTP ERROR] [${err.response?.statusCode}] [${err.requestOptions.path}] <-- \nMessage: ${err.message}\nResponse: ${err.response?.data}',
      err,
      err.stackTrace,
    );
    return handler.next(err);
  }
}
