import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/dio_interceptor.dart';
import '../network/network_info.dart';
import '../services/api_service.dart';
import '../services/live_sync_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  if (sl.isRegistered<SharedPreferences>()) {
    await sl.reset();
  }

  //! 1. External & Core Services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<Dio>(() => Dio());

  //! 2. Core Infrastructure
  sl.registerLazySingleton<LoggerService>(() => LoggerServiceImpl());

  sl.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(
      prefs: sl<SharedPreferences>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<Connectivity>()),
  );

  sl.registerLazySingleton<DioInterceptor>(
    () => DioInterceptor(
      storageService: sl<StorageService>(),
      loggerService: sl<LoggerService>(),
    ),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClientImpl(
      dio: sl<Dio>(),
      networkInfo: sl<NetworkInfo>(),
      interceptor: sl<DioInterceptor>(),
    ),
  );

  sl.registerLazySingleton<ApiService>(
    () => ApiService(sl<ApiClient>()),
  );

  sl.registerLazySingleton<LiveSyncService>(
    () => LiveSyncService(sl<ApiService>()),
  );

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  //! 3. Features (Auth, Home, Artists, Bookings, Profile)
}
