import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Dynamic Base URL Resolution (Connects to Laragon Apache/PHP)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/artist_dubai/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/artist_dubai/api/v1';
    }
    return 'http://localhost/artist_dubai/api/v1';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth
  static const String login = '/login.php';
  static const String register = '/login.php';
  static const String userProfile = '/login.php';

  // Artists
  static const String artists = '/artists.php';
  static const String artistDetails = '/artists.php';
  static const String artistRegister = '/artists.php';

  // Categories
  static const String categories = '/categories.php';

  // Events
  static const String events = '/events.php';
  static const String eventDetails = '/events.php';
  static const String eventCreate = '/events.php';

  // Government & Cultural Hubs
  static const String government = '/government.php';

  // Galleries & Art Centers
  static const String galleries = '/galleries.php';
  static const String galleryRegister = '/galleries.php';

  // Bookings & RSVPs
  static const String bookings = '/bookings.php';
  static const String bookingCreate = '/bookings.php';

  // Competitions & Open Calls
  static const String competitions = '/events.php';

  // About Platform
  static const String aboutUs = '/index.php';
}
