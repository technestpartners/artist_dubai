import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Dynamic Base URL Resolution (Supports Web, Desktop, and Android Emulator)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth
  static const String login = '/login.php';
  static const String register = '/login.php';
  static const String logout = '/login.php';
  static const String userProfile = '/login.php';

  // Artists & Bookings
  static const String artists = '/artists.php';
  static const String artistDetails = '/artists.php';
  static const String categories = '/categories.php';
  static const String artworks = '/artworks.php';
  static const String bookings = '/bookings.php';
  static const String events = '/events.php';
  static const String government = '/government.php';
}
