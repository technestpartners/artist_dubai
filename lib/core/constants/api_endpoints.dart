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
  static const Duration receiveTimeout = Duration(seconds: 45);

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
  static const String aboutUs = 'api.php?resource=about';

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
  static const String stripeConfig =
      'api.php?resource=stripe&action=config';
}

