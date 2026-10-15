import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Environment-driven Configuration (loaded via AppConfig)
  static const String liveProductionUrl = AppConfig.liveProductionUrl;
  static const String localDevUrl = AppConfig.localDevUrl;

  // Use live Hostinger API setting
  static const bool useLiveApi = AppConfig.useLiveApi;

  // Base API Server URL (Production Only)
  static String get baseUrl => AppConfig.liveProductionUrl;

  static Duration get connectionTimeout =>
      Duration(seconds: AppConfig.connectionTimeoutSeconds);
  static Duration get receiveTimeout =>
      Duration(seconds: AppConfig.receiveTimeoutSeconds);

  // Auth (MySQL Backend)
  static const String login = 'api.php?resource=login';
  static const String register = 'api.php?resource=register';
  static const String userProfile = 'api.php?resource=login&action=profile';
  static const String users = 'api.php?resource=users';

  // Artists (MySQL Backend)
  static const String artists = 'api.php?resource=artists';
  static const String artistDetails = 'api.php?resource=artists';
  static const String artistRegister = 'api.php?resource=artists';

  // Categories & Masters (MySQL Backend)
  static const String categories = 'api.php?resource=categories';
  static const String experienceLevels = 'api.php?resource=experience_levels';
  static const String locations = 'api.php?resource=locations';

  // Events (MySQL Backend)
  static const String events = 'api.php?resource=events';
  static const String eventDetails = 'api.php?resource=events';
  static const String eventCreate = 'api.php?resource=events';

  // Government & Cultural Hubs (MySQL Backend)
  static const String government = 'api.php?resource=government';

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
  static const String aboutUs = 'api.php?resource=about_us';

  // Publishing Pricing & Plans (MySQL Backend)
  static const String publishingPricing = 'api.php?resource=publishing_pricing';
  static const String listingPlans = 'api.php?resource=listing_plans';
  static const String userPlans = 'api.php?resource=user_plans';

  // Payment QR & Bank Settings (MySQL Backend)
  static const String paymentSettings = 'api.php?resource=payment_settings';

  // AI Chat & Guides (MySQL Backend)
  static const String aiChat = 'api.php?resource=ai_chat';

  // Artist Chat & Messaging (MySQL Backend)
  static const String messages = 'api.php?resource=messages';

  // Menu Permissions & Access Control (MySQL Backend)
  static const String menuPermissions = 'api.php?resource=menu_permissions';

  // Stripe Payment Gateway (PHP Backend — secret key stays server-side)
  static const String stripeGateway = 'api.php?resource=stripe';
  static const String stripePaymentIntent =
      'api.php?resource=stripe&action=create_payment_intent';
  static const String stripeConfig = 'api.php?resource=stripe&action=config';
}
