class ApiEndpoints {
  ApiEndpoints._();

  // Live Hostinger Production URL (Must end with / so relative paths append correctly)
  static const String liveProductionUrl = 'https://technestpartners.com/api/';
  static const String localDevUrl = 'https://technestpartners.com/api/';

  // Always use live Hostinger API across the whole app
  static const bool useLiveApi = true;

  // Live Production Hostinger PHP MySQL API Server
  static String get baseUrl => liveProductionUrl;

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth (MySQL Backend)
  static const String login = 'api.php?resource=login';
  static const String register = 'api.php?resource=register';
  static const String userProfile = 'api.php?resource=login&action=profile';

  // Artists (MySQL Backend)
  static const String artists = 'api.php?resource=artists';
  static const String artistDetails = 'api.php?resource=artists';
  static const String artistRegister = 'api.php?resource=artists';

  // Categories (MySQL Backend)
  static const String categories = 'api.php?resource=categories';

  // Events (MySQL Backend)
  static const String events = 'api.php?resource=events';
  static const String eventDetails = 'api.php?resource=events';
  static const String eventCreate = 'api.php?resource=events';

  // Government & Cultural Hubs (MySQL Backend)
  static const String government = 'api.php?resource=government';

  // Reviews (MySQL Backend)
  static const String reviews = 'api.php?resource=reviews';

  // Galleries & Art Centers (MySQL Backend)
  static const String galleries = 'api.php?resource=galleries';
  static const String galleryRegister = 'api.php?resource=galleries';

  // Bookings & RSVPs (MySQL Backend)
  static const String bookings = 'api.php?resource=bookings';
  static const String bookingCreate = 'api.php?resource=bookings';

  // Competitions & Open Calls (MySQL Backend)
  static const String competitions = 'api.php?resource=events';

  // Artworks & Favorites (MySQL Backend)
  static const String artworks = 'api.php?resource=artworks';
  static const String favorites = 'api.php?resource=favorites';

  // Upload
  static const String upload = 'api.php?resource=upload';

  // Notifications (MySQL Backend)
  static const String notifications = 'api.php?resource=notifications';

  // About Platform (MySQL Backend)
  static const String aboutUs = 'api.php?resource=about';
}
