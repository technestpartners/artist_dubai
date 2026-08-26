class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.artistdubai.com/v1';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String userProfile = '/auth/profile';

  // Artists & Bookings
  static const String artists = '/artists';
  static const String artistDetails = '/artists/';
  static const String categories = '/categories';
  static const String bookings = '/bookings';
}
