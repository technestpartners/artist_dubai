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

  static const Duration connectionTimeout = Duration(seconds: 3);
  static const Duration receiveTimeout = Duration(seconds: 3);

  // Auth
  static const String login = '/api.php?resource=login';
  static const String register = '/api.php?resource=login';
  static const String userProfile = '/api.php?resource=login&action=profile';

  // Artists
  static const String artists = '/api.php?resource=artists';
  static const String artistDetails = '/api.php?resource=artists';
  static const String artistRegister = '/api.php?resource=artists';

  // Categories
  static const String categories = '/api.php?resource=categories';

  // Events
  static const String events = '/api.php?resource=events';
  static const String eventDetails = '/api.php?resource=events';
  static const String eventCreate = '/api.php?resource=events';

  // Government & Cultural Hubs
  static const String government = '/api.php?resource=government';

  // Galleries & Art Centers
  static const String galleries = '/api.php?resource=galleries';
  static const String galleryRegister = '/api.php?resource=galleries';

  // Bookings & RSVPs
  static const String bookings = '/api.php?resource=bookings';
  static const String bookingCreate = '/api.php?resource=bookings';

  // Competitions & Open Calls
  static const String competitions = '/api.php?resource=events';

  // About Platform
  static const String aboutUs = '/api.php?resource=about';
}
