import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/features/artists/domain/models/artist_model.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/government/domain/models/government_entity.dart';

/// Mock ApiClient that mirrors pure MySQL backend responses for synchronous deterministic testing
class MockSyncApiClient implements ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.parse(path);
    final resource = uri.queryParameters['resource'] ?? (queryParameters?['resource'] ?? '');
    final action = uri.queryParameters['action'] ?? (queryParameters?['action'] ?? '');

    if (resource == 'login' || resource == 'auth') {
      if (action == 'profile') {
        return {
          'status': 'success',
          'success': true,
          'data': {
            'id': 1,
            'full_name': 'Dubai Art Administrator',
            'email': queryParameters?['email'] ?? 'admin@artistdubai.com',
            'role': 'admin',
          },
        };
      }
    }

    if (resource == 'categories') {
      return {
        'status': 'success',
        'success': true,
        'data': [
          {'id': 1, 'name': 'Contemporary Painting', 'emoji': '🎨', 'type': 'general'},
          {'id': 2, 'name': 'Arabic Calligraphy', 'emoji': '✒️', 'type': 'general'},
          {'id': 3, 'name': 'Digital & Generative Art', 'emoji': '💻', 'type': 'general'},
          {'id': 4, 'name': 'Sculpture & Bronze', 'emoji': '🗿', 'type': 'general'},
          {'id': 5, 'name': 'Fine Art Photography', 'emoji': '📷', 'type': 'general'},
        ],
      };
    }

    if (resource == 'artists') {
      final id = uri.queryParameters['id'] ?? queryParameters?['id'];
      if (id != null) {
        return {
          'status': 'success',
          'success': true,
          'data': {
            'id': id.toString(),
            'name': 'Renish Artistry',
            'category': 'Contemporary Painting',
            'location': 'Dubai Design District (d3)',
            'bio': 'Celebrated UAE visual artist specializing in modern abstract canvas.',
            'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            'banner_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
            'followers_count': 1420,
            'works_count': 38,
            'is_featured': true,
            'tags': ['Contemporary', 'Abstract', 'UAE'],
            'email': 'renish@artistdubai.com',
            'phone': '+971 50 123 4567',
          },
        };
      }
      return {
        'status': 'success',
        'success': true,
        'data': [
          {
            'id': '1',
            'name': 'Renish Artistry',
            'category': 'Contemporary Painting',
            'location': 'Dubai Design District (d3)',
            'bio': 'Celebrated UAE visual artist.',
            'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            'banner_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
            'followers_count': 1420,
            'works_count': 38,
            'is_featured': true,
            'tags': ['Contemporary', 'Abstract'],
          },
          {
            'id': '2',
            'name': 'Fatima Al-Hashemi',
            'category': 'Arabic Calligraphy',
            'location': 'Al Shindagha Historic District',
            'bio': 'Master calligrapher blending classical scripts.',
            'avatar_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2',
            'banner_url': 'https://images.unsplash.com/photo-1582561424760-0321d75e81fa',
            'followers_count': 980,
            'works_count': 24,
            'is_featured': true,
            'tags': ['Calligraphy', 'GoldLeaf'],
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 50,
          'total': 2,
          'total_pages': 1,
          'has_more': false,
        },
      };
    }

    if (resource == 'events') {
      final id = uri.queryParameters['id'] ?? queryParameters?['id'];
      if (id != null) {
        return {
          'status': 'success',
          'success': true,
          'data': {
            'id': id.toString(),
            'title': 'Dubai Modern Art Showcase',
            'category': 'Art Exhibition',
            'price': 'Free',
            'description': 'A premier art gathering in Dubai.',
            'event_date': '2026-10-15 18:00',
            'end_date': '2026-10-15 22:00',
            'location': 'Dubai, UAE',
            'venue': 'Alserkal Avenue, Warehouse 42',
            'is_free': true,
            'attendees_count': 120,
            'max_attendees': 200,
            'organizer_name': 'Renish Artistry',
            'contact_email': 'renish@gmail.com',
            'tags': 'Art,Exhibition,Dubai',
            'image_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
          },
        };
      }
      return {
        'status': 'success',
        'success': true,
        'data': [
          {
            'id': '1',
            'title': 'Dubai Modern Art Showcase',
            'category': 'Art Exhibition',
            'price': 'Free',
            'description': 'A premier art gathering in Dubai.',
            'event_date': '2026-10-15 18:00',
            'location': 'Dubai, UAE',
            'venue': 'Alserkal Avenue, Warehouse 42',
            'is_free': true,
            'attendees_count': 120,
            'organizer_name': 'Renish Artistry',
            'image_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
          },
        ],
      };
    }

    if (resource == 'bookings') {
      return {
        'status': 'success',
        'success': true,
        'data': [
          {
            'id': '101',
            'user_name': 'Client User',
            'user_email': 'client@artistdubai.com',
            'artist_name': 'Renish Artistry',
            'event_title': 'Dubai Modern Art Showcase',
            'status': 'Confirmed',
            'booking_date': '2026-10-15',
            'tickets_count': 2,
            'total_price': 'Free',
          },
        ],
      };
    }

    if (resource == 'galleries') {
      return {
        'status': 'success',
        'success': true,
        'data': [
          {
            'id': 1,
            'name': 'Custot Gallery Dubai',
            'category': 'Contemporary Art',
            'location': 'Alserkal Avenue, Street 8, Al Quoz 1, Dubai',
            'timing': 'Tue - Sat: 10:00 AM - 7:00 PM',
            'website': 'https://custotgallerydubai.com',
            'image_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
          },
        ],
      };
    }

    if (resource == 'government') {
      return {
        'status': 'success',
        'success': true,
        'data': [
          {
            'id': 1,
            'name': 'Dubai Culture & Arts Authority',
            'category': 'Government Authority · Cultural Council',
            'location': 'Al Shindagha Historic District, Bur Dubai, Dubai',
            'base_rating': 4.8,
            'base_review_count': 1420,
            'default_timing': 'Daily: 07:30 AM - 10:00 PM',
            'default_is_open': 1,
            'website_url': 'https://dubaiculture.gov.ae',
            'directions_url': 'https://maps.google.com/?q=Dubai+Culture',
            'google_maps_reviews_url': 'https://www.google.com/maps',
            'open_hour': 7,
            'open_minute': 30,
            'close_hour': 22,
            'close_minute': 0,
            'closed_days': '',
          },
        ],
      };
    }

    if (resource == 'notifications') {
      return {
        'status': 'success',
        'success': true,
        'data': {
          'notifications': [
            {
              'id': '1',
              'title': 'Welcome to Artist Dubai',
              'body': 'Explore top UAE visual artists and events.',
              'type': 'welcome',
              'route': '/artists',
              'is_read': 0,
              'time_ago': 'Just now',
            },
          ],
        },
      };
    }

    if (resource == 'favorites') {
      return {
        'status': 'success',
        'success': true,
        'data': {
          'artists': [
            {
              'id': '1',
              'name': 'Renish Artistry',
              'category': 'Contemporary Painting',
              'location': 'Dubai Design District (d3)',
              'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            },
          ],
          'events': [
            {
              'id': '1',
              'title': 'Dubai Modern Art Showcase',
              'category': 'Art Exhibition',
              'location': 'Dubai, UAE',
            },
          ],
        },
      };
    }

    if (resource == 'about') {
      return {
        'status': 'success',
        'success': true,
        'data': {
          'title': 'Artist Dubai',
          'version': '6.3.0',
          'database': 'MySQL',
          'status': 'online',
          'counts': {
            'artists': 5,
            'events': 4,
            'galleries': 4,
            'categories': 5,
            'bookings': 12,
            'cultural_entities': 4,
          },
          'mission': 'Empowering Emirati and UAE-based creative visionaries.',
        },
      };
    }

    return {'status': 'success', 'success': true, 'data': []};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.parse(path);
    final resource = uri.queryParameters['resource'] ?? '';
    final action = uri.queryParameters['action'] ?? (data is Map ? data['action'] : '');

    if (resource == 'login' || resource == 'auth') {
      if (action == 'profile') {
        return {
          'status': 'success',
          'success': true,
          'data': {
            'id': 1,
            'full_name': 'Dubai Art Administrator',
            'email': 'admin@artistdubai.com',
            'role': 'admin',
          },
        };
      }
      if (action == 'change_password') {
        return {'status': 'success', 'success': true, 'message': 'Password changed successfully in MySQL!'};
      }
      return {
        'status': 'success',
        'success': true,
        'data': {
          'user': {
            'id': 1,
            'full_name': 'Dubai Art Administrator',
            'email': 'admin@artistdubai.com',
            'role': 'admin',
          },
          'token': 'mock_jwt_token_sample_artist_dubai',
        },
      };
    }

    if (resource == 'register') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Account registered successfully in MySQL!',
        'data': {
          'id': 99,
          'full_name': data?['name'] ?? 'New User',
          'email': data?['email'] ?? 'user@artistdubai.com',
        },
      };
    }

    if (resource == 'artists') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Artist mutation saved in MySQL!',
        'data': {'id': '77', 'name': data?['name'] ?? 'New Artist'},
      };
    }

    if (resource == 'events') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Event mutation saved in MySQL!',
        'data': {'id': '88', 'title': data?['title'] ?? 'New Event'},
      };
    }

    if (resource == 'categories') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Category saved in MySQL!',
        'data': {'id': 9, 'name': data?['name'] ?? 'New Category'},
      };
    }

    if (resource == 'bookings') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Booking saved in MySQL!',
        'data': {'id': 105, 'status': 'Confirmed'},
      };
    }

    if (resource == 'galleries') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Gallery saved in MySQL!',
        'data': {'id': 10, 'name': data?['name'] ?? 'New Gallery'},
      };
    }

    if (resource == 'government') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Government entity saved in MySQL!',
        'data': {'id': 5, 'name': data?['name'] ?? 'New Entity'},
      };
    }

    if (resource == 'artworks') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Artwork saved in MySQL!',
        'data': {
          'id': 101,
          'title': data?['title'] ?? 'Artwork',
          'artist_id': data?['artist_id'] ?? '77',
        },
      };
    }

    if (resource == 'reviews') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Review saved in MySQL!',
        'data': {'id': 1},
      };
    }

    if (resource == 'favorites') {
      return {
        'status': 'success',
        'success': true,
        'is_favorite': true,
        'message': 'Favorite state updated in MySQL!',
      };
    }

    if (resource == 'notifications') {
      return {
        'status': 'success',
        'success': true,
        'message': 'Notification state updated in MySQL!',
      };
    }

    return {'status': 'success', 'success': true, 'message': 'Operation completed'};
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }
}

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

  group('Backend & Frontend Full System Sync Audit Suite', () {
    test('1. Auth Backend Sync: Login, Register, Profile & Password APIs', () async {
      // Login
      final loginRes = await apiService.login('admin@artistdubai.com', 'admin123');
      expect(loginRes, isNotNull);
      expect(loginRes!['user']['email'], 'admin@artistdubai.com');
      expect(loginRes['user']['role'], 'admin');

      // Register
      final regRes = await apiService.registerUser(
        name: 'Sara Visuals',
        email: 'sara@artistdubai.com',
        password: 'password123',
      );
      expect(regRes, isNotNull);

      // User Profile
      final profileRes = await apiService.getUserProfile('admin@artistdubai.com');
      expect(profileRes, isNotNull);
      expect(profileRes!['email'], 'admin@artistdubai.com');

      // Change Password
      final pwdSuccess = await apiService.changePassword(
        email: 'admin@artistdubai.com',
        newPassword: 'newAdminPassword123',
      );
      expect(pwdSuccess, isTrue);
    });

    test('2. Artists Live Sync: Fetch, Detail, Create, Update, Delete & Like', () async {
      // Paged Fetch
      final paged = await apiService.getArtistsPaged();
      expect(paged.data.length, greaterThanOrEqualTo(2));
      expect(paged.data.first.name, 'Renish Artistry');

      // Simple Fetch
      final artists = await apiService.getArtists(forceRefresh: true);
      expect(artists.length, greaterThanOrEqualTo(2));

      // Detail
      final detail = await apiService.getArtistDetails('1', forceRefresh: true);
      expect(detail.id, '1');
      expect(detail.name, 'Renish Artistry');
      expect(detail.category, 'Contemporary Painting');

      // Create
      final createRes = await apiService.createArtistProfile(
        name: 'Nouf Al-Mehairi',
        category: 'Fine Art Photography',
        location: 'Dubai Media City',
        bio: 'Celebrated Emirati architectural and landscape photographer.',
      );
      expect(createRes, isNotNull);

      // Like
      final likeSuccess = await apiService.likeArtist(
        artistId: '1',
        userEmail: 'admin@artistdubai.com',
      );
      expect(likeSuccess, isNotNull);

      // Update
      final updateSuccess = await apiService.updateArtist({
        'id': '1',
        'name': 'Renish Artistry (Updated)',
      });
      expect(updateSuccess, isTrue);

      // Delete
      final deleteSuccess = await apiService.deleteArtist('1');
      expect(deleteSuccess, isTrue);
    });

    test('3. Categories Live Sync: Fetch Categories & Create Category with Stream propagation', () async {
      // Get Categories
      final cats = await apiService.getCategories(forceRefresh: true);
      expect(cats.length, greaterThanOrEqualTo(5));
      expect(cats.first.name, 'Contemporary Painting');

      // Get Event Categories
      final eventCats = await apiService.getEventCategories(forceRefresh: true);
      expect(eventCats, contains('All Categories'));

      // Create Category
      final created = await apiService.createCategory(
        name: 'Ceramics & Pottery',
        description: 'Handcrafted stoneware, ceramic pottery and glaze art.',
        emoji: '🏺',
        color: 'Primary',
        tags: 'Ceramics,Pottery,Clay',
        isFeatured: true,
      );
      expect(created, isTrue);

      // LiveSync Stream Emission
      final completer = Completer<List<CategoryInfo>>();
      final sub = liveSync.categoriesStream.listen((list) {
        if (!completer.isCompleted) completer.complete(list);
      });

      await liveSync.notifyCategoriesChanged(cats);
      final receivedCats = await completer.future.timeout(const Duration(seconds: 2));
      expect(receivedCats.length, cats.length);
      await sub.cancel();
    });

    test('4. Events Live Sync: Fetch, Detail, Create, Update, Delete & Stream broadcast', () async {
      // Get Events
      final events = await apiService.getEvents(forceRefresh: true);
      expect(events.isNotEmpty, isTrue);
      expect(events.first.title, 'Dubai Modern Art Showcase');

      // Event Detail
      final eventDetail = await apiService.getEventDetails('1', forceRefresh: true);
      expect(eventDetail.id, '1');
      expect(eventDetail.title, 'Dubai Modern Art Showcase');

      // Create Event
      final created = await apiService.createEvent(
        title: 'Emirati Heritage Art Expo',
        category: 'Art Exhibition',
        location: 'Dubai, UAE',
        description: 'Premier heritage art expo.',
        eventDate: '2026-11-10 17:00',
        isFree: true,
      );
      expect(created, isTrue);

      // Delete Event
      final deleted = await apiService.deleteEvent('1');
      expect(deleted, isTrue);

      // LiveSync Event Stream Test
      final completer = Completer<List<ArtEventModel>>();
      final sub = liveSync.eventsStream.listen((list) {
        if (!completer.isCompleted) completer.complete(list);
      });

      await liveSync.notifyEventsChanged(events);
      final receivedEvents = await completer.future.timeout(const Duration(seconds: 2));
      expect(receivedEvents.first.title, 'Dubai Modern Art Showcase');
      await sub.cancel();
    });

    test('5. Bookings & Tickets Live Sync: Create Booking, Fetch Bookings, Cancel Booking', () async {
      // Create Booking
      final bookingCreated = await apiService.createBooking({
        'user_name': 'Dubai VIP Guest',
        'user_email': 'vip@artistdubai.com',
        'artist_id': '1',
        'artist_name': 'Renish Artistry',
        'booking_date': '2026-10-15',
        'tickets_count': 2,
        'total_price': 'Free',
      });
      expect(bookingCreated, isTrue);

      // Fetch Bookings
      final bookings = await apiService.getBookings(
        email: 'admin@artistdubai.com',
        forceRefresh: true,
      );
      expect(bookings.isNotEmpty, isTrue);
      expect(bookings.first['artist_name'], 'Renish Artistry');

      // Cancel Booking
      final cancelled = await apiService.cancelBooking(101);
      expect(cancelled, isTrue);
    });

    test('6. Galleries & Art Centers Live Sync: Fetch, Create, Update, Delete', () async {
      // Fetch Galleries
      final galleries = await apiService.getGalleries(forceRefresh: true);
      expect(galleries.isNotEmpty, isTrue);
      expect(galleries.first['name'], 'Custot Gallery Dubai');

      // Create Gallery
      final created = await apiService.createArtCenter({
        'name': 'Alserkal Arts Foundation',
        'category': 'Art Center',
        'location': 'Alserkal Avenue, Dubai',
      });
      expect(created, isTrue);

      // Update Gallery
      final updated = await apiService.updateArtCenter({
        'id': 1,
        'name': 'Custot Gallery Dubai (Updated)',
      });
      expect(updated, isTrue);

      // Delete Gallery
      final deleted = await apiService.deleteGallery(1);
      expect(deleted, isTrue);
    });

    test('7. Government Cultural Portal Live Sync: Entities Fetch, Create, Update, Delete', () async {
      // Fetch Government Entities
      final entities = await apiService.getGovernmentEntities(forceRefresh: true);
      expect(entities.isNotEmpty, isTrue);
      expect(entities.first.name, 'Dubai Culture & Arts Authority');

      // Create Government Entity
      final created = await apiService.createGovernmentEntity({
        'name': 'Sharjah Art Foundation',
        'category': 'Cultural Foundation',
        'location': 'Sharjah Historic Heritage Area',
      });
      expect(created, isTrue);

      // Update Entity
      final updated = await apiService.updateGovernmentEntity({
        'id': 1,
        'name': 'Dubai Culture & Arts Authority (Updated)',
      });
      expect(updated, isTrue);

      // Delete Entity
      final deleted = await apiService.deleteGovernmentEntity(id: 1);
      expect(deleted, isTrue);
    });

    test('8. Favorites & Artworks Live Sync: Toggle Favorite, Fetch Favorites, Delete Artwork', () async {
      // Toggle Favorite
      final favToggled = await apiService.toggleFavorite(
        itemType: 'artist',
        itemId: '1',
        email: 'admin@artistdubai.com',
      );
      expect(favToggled, isTrue);

      // Fetch Favorites
      final favs = await apiService.getFavorites(
        email: 'admin@artistdubai.com',
        forceRefresh: true,
      );
      expect(favs.containsKey('artists'), isTrue);
      expect(favs.containsKey('events'), isTrue);

      // Delete Artwork
      final artDeleted = await apiService.deleteArtwork(1);
      expect(artDeleted, isTrue);
    });

    test('9. Notifications & Platform Metrics Live Sync: Notification State & About Platform', () async {
      // Sync notifications
      await notifService.syncWithBackend();
      expect(notifService.notifications.length, greaterThanOrEqualTo(1));
      expect(notifService.notifications.first.title, 'Welcome to Artist Dubai');
      expect(notifService.unreadCount, greaterThanOrEqualTo(1));

      // Mark single read
      await notifService.markAsRead('1');
      expect(notifService.notifications.first.isRead, isTrue);

      // Mark all read
      await notifService.markAllAsRead();
      expect(notifService.unreadCount, 0);

      // About Platform Metrics
      final about = await apiService.getAboutPlatform(forceRefresh: true);
      expect(about, isNotNull);
      expect(about!['title'], 'Artist Dubai');
      expect(about['version'], '6.3.0');
      expect(about['database'], 'MySQL');
      expect(about['counts']['artists'], 5);
      expect(about['counts']['events'], 4);
    });

    test('10. LiveSync Multi-Stream Global Sync: syncAllSilently updates all subscribers', () async {
      final artistCompleter = Completer<List<ArtistModel>>();
      final eventCompleter = Completer<List<ArtEventModel>>();
      final galleryCompleter = Completer<List<Map<String, dynamic>>>();
      final govCompleter = Completer<List<GovernmentEntity>>();
      final catCompleter = Completer<List<CategoryInfo>>();

      final s1 = liveSync.artistsStream.listen((data) {
        if (!artistCompleter.isCompleted) artistCompleter.complete(data);
      });
      final s2 = liveSync.eventsStream.listen((data) {
        if (!eventCompleter.isCompleted) eventCompleter.complete(data);
      });
      final s3 = liveSync.galleriesStream.listen((data) {
        if (!galleryCompleter.isCompleted) galleryCompleter.complete(data);
      });
      final s4 = liveSync.governmentStream.listen((data) {
        if (!govCompleter.isCompleted) govCompleter.complete(data);
      });
      final s5 = liveSync.categoriesStream.listen((data) {
        if (!catCompleter.isCompleted) catCompleter.complete(data);
      });

      // Trigger full silent synchronization
      await liveSync.syncAllSilently();

      final a = await artistCompleter.future.timeout(const Duration(seconds: 2));
      final e = await eventCompleter.future.timeout(const Duration(seconds: 2));
      final g = await galleryCompleter.future.timeout(const Duration(seconds: 2));
      final gov = await govCompleter.future.timeout(const Duration(seconds: 2));
      final c = await catCompleter.future.timeout(const Duration(seconds: 2));

      expect(a.isNotEmpty, isTrue);
      expect(e.isNotEmpty, isTrue);
      expect(g.isNotEmpty, isTrue);
      expect(gov.isNotEmpty, isTrue);
      expect(c.isNotEmpty, isTrue);

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await s4.cancel();
      await s5.cancel();
    });
  });
}
