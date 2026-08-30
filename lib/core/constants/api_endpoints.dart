import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Dynamic Base URL Resolution (Connects to Live PHP MySQL Server)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/dubai/artist_dubai';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // USB device: ADB reverse tunnel (adb reverse tcp:8080 tcp:80)
      return 'http://localhost:8080/dubai/artist_dubai';
    }
    return 'http://localhost/dubai/artist_dubai';
  }

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth (MySQL Backend)
  static const String login = '/api.php?resource=login';
  static const String register = '/api.php?resource=register';
  static const String userProfile = '/api.php?resource=login&action=profile';

  // Artists (MySQL Backend)
  static const String artists = '/api.php?resource=artists';
  static const String artistDetails = '/api.php?resource=artists';
  static const String artistRegister = '/api.php?resource=artists';

  // Categories (MySQL Backend)
  static const String categories = '/api.php?resource=categories';

  // Events (MySQL Backend)
  static const String events = '/api.php?resource=events';
  static const String eventDetails = '/api.php?resource=events';
  static const String eventCreate = '/api.php?resource=events';

  // Government & Cultural Hubs (MySQL Backend)
  static const String government = '/api.php?resource=government';

  // Galleries & Art Centers (MySQL Backend)
  static const String galleries = '/api.php?resource=galleries';
  static const String galleryRegister = '/api.php?resource=galleries';

  // Bookings & RSVPs (MySQL Backend)
  static const String bookings = '/api.php?resource=bookings';
  static const String bookingCreate = '/api.php?resource=bookings';

  // Competitions & Open Calls (MySQL Backend)
  static const String competitions = '/api.php?resource=events';

  // Artworks & Favorites (MySQL Backend)
  static const String artworks = '/api.php?resource=artworks';
  static const String favorites = '/api.php?resource=favorites';

  // About Platform (MySQL Backend)
  static const String aboutUs = '/api.php?resource=about';
}
