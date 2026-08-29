import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Dynamic Base URL Resolution (Connects to Live PHP MySQL Server)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const Duration connectionTimeout = Duration(seconds: 3);
  static const Duration receiveTimeout = Duration(seconds: 3);

  // Auth (MySQL Backend)
  static const String login = '/api.php?resource=login';
  static const String register = '/api.php?resource=login';
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

  // About Platform (MySQL Backend)
  static const String aboutUs = '/api.php?resource=about';
}
