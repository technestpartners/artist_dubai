import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Dynamic Base URL Resolution (Connects to XAMPP Apache/PHP)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/dubai/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/dubai/api';
    }
    return 'http://localhost/dubai/api';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';
  static const String userProfile = '/auth/profile.php';

  // Artists
  static const String artists = '/artists/index.php';
  static const String artistDetails = '/artists/detail.php';
  static const String artistRegister = '/artists/register.php';

  // Categories
  static const String categories = '/categories/index.php';

  // Events
  static const String events = '/events/index.php';
  static const String eventDetails = '/events/detail.php';
  static const String eventCreate = '/events/create.php';

  // Government & Cultural Hubs
  static const String government = '/government/index.php';

  // Galleries & Art Centers
  static const String galleries = '/galleries/index.php';
  static const String galleryRegister = '/galleries/register.php';

  // Bookings & RSVPs
  static const String bookings = '/bookings/index.php';
  static const String bookingCreate = '/bookings/create.php';

  // Competitions & Open Calls
  static const String competitions = '/competitions/index.php';

  // About Platform
  static const String aboutUs = '/about/index.php';
}
