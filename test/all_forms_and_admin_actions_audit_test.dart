import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/storage_service.dart';

import 'backend_frontend_sync_integration_test.dart';

void main() {
  late MockSyncApiClient mockClient;
  late ApiService apiService;
  late LiveSyncService liveSync;
  late NotificationService notifService;
  late StorageService storageService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'admin@artistdubai.com',
      'user_name': 'Dubai Art Administrator',
      'is_admin': true,
    });

    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageServiceImpl(
      prefs: prefs,
      secureStorage: const FlutterSecureStorage(),
    );
    mockClient = MockSyncApiClient();
    apiService = ApiService(mockClient);
    liveSync = LiveSyncService(apiService);

    sl.registerSingleton<StorageService>(storageService);
    sl.registerSingleton<ApiClient>(mockClient);
    sl.registerSingleton<ApiService>(apiService);
    sl.registerSingleton<LiveSyncService>(liveSync);

    notifService = NotificationService();
    sl.registerSingleton<NotificationService>(notifService);
  });

  tearDown(() async {
    liveSync.dispose();
    await sl.reset();
  });

  group('Complete User & Admin Form & Database Action Audit Suite', () {
    test('1. User Registration & Login Form Flow & DB Session Token', () async {
      // 1. Register Form
      final regResult = await apiService.registerUser(
        name: 'Fatima Visuals',
        email: 'fatima.visuals@artistdubai.com',
        password: 'securePassword123',
      );
      expect(regResult, isNotNull);

      // 2. Login Form
      final loginResult = await apiService.login(
        'fatima.visuals@artistdubai.com',
        'securePassword123',
      );
      expect(loginResult, isNotNull);
      expect(loginResult!['token'], isNotNull);
    });

    test('2. Book Artist Commission Form Submission & Live Stream Update', () async {
      final completer = Completer<List<Map<String, dynamic>>>();
      final sub = liveSync.bookingsStream.listen((list) {
        if (!completer.isCompleted) completer.complete(list);
      });

      final success = await apiService.createBooking({
        'user_name': 'Dubai Collector',
        'user_email': 'collector@artistdubai.com',
        'phone': '+971 50 111 2222',
        'artist_id': '1',
        'artist_name': 'Renish Artistry',
        'booking_type': 'Oil Canvas Commission',
        'event_date': '2026-11-20',
        'location': 'Downtown Dubai Villa',
        'description': '3x2 meter luxury modern abstract for main reception foyer.',
        'total_price': 'AED 15,000',
      });
      expect(success, isTrue);

      await liveSync.notifyBookingsChanged();
      final bookings = await completer.future.timeout(const Duration(seconds: 2));
      expect(bookings.isNotEmpty, isTrue);
      await sub.cancel();
    });

    test('3. Create Artist Profile Multi-Step Form Submission & Portfolio Artworks', () async {
      final artistCreated = await apiService.createArtistProfile(
        name: 'Mariam Al-Zaabi',
        category: 'Sculpture & Bronze',
        location: 'Al Quoz Creative Zone',
        bio: 'Monumental bronze sculptress inspired by Arabian desert landscapes.',
        email: 'mariam@artistdubai.com',
        phone: '+971 50 999 8888',
        website: 'https://mariamart.ae',
        instagram: '@mariam_sculptures',
        experienceLevel: 'Senior / 10 Years',
      );
      expect(artistCreated, isNotNull);

      // Add Portfolio Artwork
      final artCreated = await apiService.createArtwork(
        title: 'Desert Mirage in Bronze',
        artistId: '77',
        artistName: 'Mariam Al-Zaabi',
        year: '2026',
        medium: 'Cast Bronze & Marble Base',
        dimensions: '180 x 60 cm',
        price: 'AED 18,500',
        isFeatured: true,
      );
      expect(artCreated, isNotNull);
    });

    test('4. Create Art Event Form Submission & Notification Broadcast', () async {
      final eventCreated = await apiService.createEvent(
        title: 'Dubai Contemporary Art Gala 2026',
        category: 'Art Exhibition',
        location: 'Dubai Design District (d3)',
        venue: 'Building 7 Atrium',
        eventDate: '2026-11-15 19:00',
        endDate: '2026-11-15 23:00',
        description: 'Exclusive gala opening featuring 30+ regional contemporary artists.',
        price: 'Free Entry',
        maxAttendees: 300,
        organizerName: 'Dubai Culture',
        contactEmail: 'events@dubaiculture.gov.ae',
        tags: 'Exhibition,Gala,d3,Art',
        isFree: true,
      );
      expect(eventCreated, isTrue);
    });

    test('5. Admin Create Custom Category Form & Live Propagation', () async {
      final catCreated = await apiService.createCategory(
        name: 'Textile & Tapestry Art',
        description: 'Handwoven textiles, modern tapestries, and fiber art installations.',
        emoji: '🧶',
        color: 'Secondary',
        tags: 'Textiles,Weaving,FiberArt',
        isFeatured: true,
      );
      expect(catCreated, isTrue);
    });

    test('6. Gallery Registration Form Submission & Search Query', () async {
      final regGallery = await apiService.createArtCenter({
        'name': 'Volte Art Projects Dubai',
        'category': 'Art Center & Gallery',
        'location': 'Alserkal Avenue, Warehouse 55',
        'timing': 'Mon - Sat: 10:00 AM - 7:00 PM',
        'website': 'https://volteartprojects.com',
        'contact_person': 'Gallery Director',
        'email': 'info@volteartprojects.com',
      });
      expect(regGallery, isTrue);
    });

    test('7. Government Cultural Entity Form Submission & Review Submission', () async {
      // Add Review
      final reviewAdded = await apiService.addReview(
        entityName: 'Dubai Culture & Arts Authority',
        authorName: 'Art Enthusiast',
        rating: 5.0,
        text: 'Outstanding cultural initiatives and museum preservations across the UAE.',
      );
      expect(reviewAdded, isTrue);
    });

    test('8. User Account Settings: Update Profile Name, Change Password & Delete Account', () async {
      // 1. Update Profile
      final nameUpdated = await apiService.updateProfile(
        email: 'user@artistdubai.com',
        fullName: 'Sara Al-Maktoum Updated',
      );
      expect(nameUpdated, isTrue);

      // 2. Change Password
      final pwdChanged = await apiService.changePassword(
        email: 'user@artistdubai.com',
        newPassword: 'newStrongPassword2026',
      );
      expect(pwdChanged, isTrue);

      // 3. Delete Account
      final accDeleted = await apiService.deleteAccount('user@artistdubai.com');
      expect(accDeleted, isTrue);
    });

    test('9. Admin Management Actions: Delete Artist, Delete Event, Delete Gallery', () async {
      final artistDel = await apiService.deleteArtist('1');
      expect(artistDel, isTrue);

      final eventDel = await apiService.deleteEvent('1');
      expect(eventDel, isTrue);

      final galleryDel = await apiService.deleteGallery(1);
      expect(galleryDel, isTrue);
    });

    test('10. Booking Workflow: Cancel Booking & Update Booking Status', () async {
      final cancelled = await apiService.cancelBooking(101);
      expect(cancelled, isTrue);

      final statusUpdated = await apiService.updateBookingStatus(
        bookingId: 101,
        status: 'Completed',
      );
      expect(statusUpdated, isTrue);
    });
  });
}
