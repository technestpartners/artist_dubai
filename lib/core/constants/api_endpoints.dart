import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Live Hostinger Production URL
  static const String liveProductionUrl = 'https://technestpartners.com/api';
  static const String localDevUrl = 'http://localhost:8000';

  // Set to true to use live Hostinger API across the whole app
  static bool useLiveApi = true;

  // Dynamic Base URL Resolution (Connects to Live Hostinger PHP MySQL Server)
  static String get baseUrl {
    if (useLiveApi) {
      return liveProductionUrl;
    }
    if (kIsWeb) {
      if (Uri.base.host.isNotEmpty &&
          Uri.base.host != 'localhost' &&
          Uri.base.host != '127.0.0.1') {
        return '${Uri.base.origin}/api';
      }
      return localDevUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return localDevUrl;
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

  // Reviews (MySQL Backend)
  static const String reviews = '/api.php?resource=reviews';

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

  // Upload
  static const String upload = '/api.php?resource=upload';

  // Notifications (MySQL Backend)
  static const String notifications = '/api.php?resource=notifications';

  // About Platform (MySQL Backend)
  static const String aboutUs = '/api.php?resource=about';
}
