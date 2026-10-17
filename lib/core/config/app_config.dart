import 'package:flutter/foundation.dart';

/// Centralized Environment Configuration loaded via --dart-define or --dart-define-from-file.
///
/// Defaults to production settings to guarantee backwards compatibility with zero-config builds.
class AppConfig {
  AppConfig._();

  /// API Base URL (Must end with trailing slash)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://technestpartners.com/api/',
  );

  /// Production API URL
  static const String liveProductionUrl = String.fromEnvironment(
    'LIVE_PRODUCTION_URL',
    defaultValue: 'https://technestpartners.com/api/',
  );

  /// Local Development API URL (Enforced Production Only)
  static const String localDevUrl = String.fromEnvironment(
    'LOCAL_DEV_URL',
    defaultValue: 'https://technestpartners.com/api/',
  );

  /// Flag indicating whether the app should connect to live production server (Production Only)
  static const bool useLiveApi = true;

  /// Stripe Publishable Key
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51UM5UtGzTs49HgxK3LffMmD1PThSWUTnF6ewF8G0iLdnHCqIpElBmdbRI5bF65lXaIszIndsUYbWpLwYwhB5bfIT00SCbR8BEy',
  );

  /// Default Currency
  static const String defaultCurrency = String.fromEnvironment(
    'DEFAULT_CURRENCY',
    defaultValue: 'aed',
  );

  /// Merchant Name for invoices and payment popups
  static const String merchantName = String.fromEnvironment(
    'MERCHANT_NAME',
    defaultValue: 'Artist Dubai Cultural Services LLC',
  );

  /// Network Connection Timeout in Seconds
  static const int connectionTimeoutSeconds = int.fromEnvironment(
    'CONNECTION_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// Network Receive Timeout in Seconds
  static const int receiveTimeoutSeconds = int.fromEnvironment(
    'RECEIVE_TIMEOUT_SECONDS',
    defaultValue: 45,
  );

  /// Whether running in development / debug mode
  static bool get isDebug => kDebugMode;
}
