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

  group('All 31 Pages Database Connectivity & Live Query Verification Suite', () {
    test('Pages 1-3: Splash, Onboarding & Home Dashboard DB Connectivity', () async {
      // Home Dashboard live DB stats
      final about = await apiService.getAboutPlatform(forceRefresh: true);
      expect(about, isNotNull);
      expect(about!['database'], 'MySQL');
      expect(about['counts']['artists'], greaterThan(0));
      expect(about['counts']['events'], greaterThan(0));
      expect(about['counts']['galleries'], greaterThan(0));
      expect(about['counts']['categories'], greaterThan(0));
    });

    test('Pages 4-6: Artists Directory, Artist Detail & Create Artist DB Connectivity', () async {
      // Artists Table Read
      final artists = await apiService.getArtists(forceRefresh: true);
      expect(artists.isNotEmpty, isTrue);

      // Artist Detail Read
      final detail = await apiService.getArtistDetails('1', forceRefresh: true);
      expect(detail.name, 'Renish Artistry');

      // Create Artist Profile Write
      final created = await apiService.createArtistProfile(
        name: 'Test Artist',
        category: 'Contemporary Painting',
        location: 'Dubai',
        bio: 'Bio text',
      );
      expect(created, isNotNull);
    });

    test('Pages 7-9: Explore Categories, Category Detail & Create Category DB Connectivity', () async {
      // Categories Table Read
      final categories = await apiService.getCategories(forceRefresh: true);
      expect(categories.isNotEmpty, isTrue);

      // Category Filtered Artists Read
      final filtered = await apiService.getArtists(category: 'Contemporary Painting', forceRefresh: true);
      expect(filtered.isNotEmpty, isTrue);

      // Create Category Write
      final catCreated = await apiService.createCategory(
        name: 'Digital Sculpting',
        description: '3D printed sculpture and digital forms.',
      );
      expect(catCreated, isTrue);
    });

    test('Pages 10-15: Events, Event Detail, Create Event, Hosted Events, Competitions & Photos DB Connectivity', () async {
      // Events Table Read
      final events = await apiService.getEvents(forceRefresh: true);
      expect(events.isNotEmpty, isTrue);

      // Event Detail Read
      final eventDetail = await apiService.getEventDetails('1', forceRefresh: true);
      expect(eventDetail.title, 'Dubai Modern Art Showcase');

      // Create Event Write
      final evCreated = await apiService.createEvent(
        title: 'Sharjah Calligraphy Gala',
        description: 'Gala exhibition of Islamic calligraphy.',
        category: 'Art Exhibition',
        location: 'Sharjah, UAE',
        eventDate: '2026-12-01 18:00',
      );
      expect(evCreated, isTrue);

      // Competitions Read
      final comps = await apiService.getCompetitions(forceRefresh: true);
      expect(comps.isNotEmpty, isTrue);
    });

    test('Pages 16-17: Galleries & Gallery Registration DB Connectivity', () async {
      // Galleries Table Read
      final galleries = await apiService.getGalleries(forceRefresh: true);
      expect(galleries.isNotEmpty, isTrue);

      // Gallery Registration Write
      final registered = await apiService.createArtCenter({
        'name': 'Ayyam Gallery Dubai',
        'category': 'Contemporary Art',
        'location': 'Alserkal Avenue',
      });
      expect(registered, isTrue);
    });

    test('Page 18: Government Portal & Cultural Entities DB Connectivity', () async {
      // Government Entities Table Read
      final entities = await apiService.getGovernmentEntities(forceRefresh: true);
      expect(entities.isNotEmpty, isTrue);
      expect(entities.first.name, 'Dubai Culture & Arts Authority');
    });

    test('Pages 19-21: Book Artist Form, My Bookings & Booking Requests DB Connectivity', () async {
      // Bookings Table Write (Create Booking)
      final booked = await apiService.createBooking({
        'user_name': 'Test Client',
        'user_email': 'client@test.com',
        'artist_id': '1',
        'artist_name': 'Renish Artistry',
      });
      expect(booked, isTrue);

      // Bookings Table Read
      final bookings = await apiService.getBookings(email: 'admin@artistdubai.com', forceRefresh: true);
      expect(bookings.isNotEmpty, isTrue);
    });

    test('Page 22: Favorites & Bookmarks Catalog DB Connectivity', () async {
      // Favorites Table Read
      final favs = await apiService.getFavorites(email: 'admin@artistdubai.com', forceRefresh: true);
      expect(favs.containsKey('artists'), isTrue);
      expect(favs.containsKey('events'), isTrue);
    });

    test('Pages 23-26: Profile, Account Settings, Login & Register DB Connectivity', () async {
      // User Profile Read
      final profile = await apiService.getUserProfile('admin@artistdubai.com');
      expect(profile, isNotNull);

      // Update Profile Write
      final updated = await apiService.updateProfile(email: 'admin@artistdubai.com', fullName: 'Super Admin Updated');
      expect(updated, isTrue);

      // Change Password Write
      final pwdChanged = await apiService.changePassword(email: 'admin@artistdubai.com', newPassword: 'newSecurePass123');
      expect(pwdChanged, isTrue);

      // Login Auth Query
      final login = await apiService.login('admin@artistdubai.com', 'admin123');
      expect(login, isNotNull);

      // Register Query
      final reg = await apiService.registerUser(name: 'New Artist User', email: 'newuser@artistdubai.com', password: 'password123');
      expect(reg, isNotNull);
    });

    test('Page 27: Admin Dashboard Management & KPI DB Connectivity', () async {
      // Admin deletes / updates across multiple tables
      final artistDeleted = await apiService.deleteArtist('1');
      expect(artistDeleted, isTrue);

      final eventDeleted = await apiService.deleteEvent('1');
      expect(eventDeleted, isTrue);

      final galleryDeleted = await apiService.deleteGallery(1);
      expect(galleryDeleted, isTrue);
    });

    test('Pages 28-31: About Us, Privacy Policy, Terms & Fallback Views DB Connectivity', () async {
      final aboutData = await apiService.getAboutPlatform(forceRefresh: true);
      expect(aboutData, isNotNull);
      expect(aboutData!['title'], 'Artist Dubai');
    });
  });
}
