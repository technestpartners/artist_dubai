import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

/// Ultra-Fast, Load-Free ApiService with In-Memory Caching & Stale-While-Revalidate
class ApiService {
  final ApiClient _client;

  // In-Memory Fast Caches
  List<CategoryInfo>? _cachedCategories;
  List<ArtistModel>? _cachedArtists;
  final Map<String, ArtistModel> _cachedArtistDetails = {};
  List<ArtEventModel>? _cachedEvents;
  final Map<String, ArtEventModel> _cachedEventDetails = {};
  List<GovernmentEntity>? _cachedGovEntities;
  List<Map<String, dynamic>>? _cachedGalleries;
  Map<String, dynamic>? _cachedAbout;
  List<Map<String, dynamic>>? _cachedCompetitions;

  ApiService(this._client);

  bool _isSuccess(dynamic res) =>
      res is Map<String, dynamic> && (res['status'] == 'success' || res['success'] == true);

  // 1. Categories (Instant Cache-First from MySQL)
  Future<List<CategoryInfo>> getCategories({String type = 'artist', bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }

    try {
      final res = await _client.get(
        ApiEndpoints.categories,
        queryParameters: {'type': type},
      );
      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        _cachedCategories = list.map((item) {
          return CategoryInfo(
            name: item['name'] as String? ?? 'General',
            emoji: item['emoji'] as String? ?? '🎨',
          );
        }).toList();
        return _cachedCategories!;
      }
    } catch (_) {}

    return _cachedCategories ?? ArtistModel.categoryList;
  }

  // 1b. Event Categories (Dynamic from MySQL)
  Future<List<String>> getEventCategories({bool forceRefresh = false}) async {
    try {
      final res = await _client.get(
        ApiEndpoints.categories,
        queryParameters: {'type': 'event'},
      );
      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        final fetched = list
            .map((item) => (item['name'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList();
        if (fetched.isNotEmpty) {
          if (!fetched.contains('All Categories')) {
            return ['All Categories', ...fetched];
          }
          return fetched;
        }
      }
    } catch (_) {}

    return ArtEventModel.categories;
  }

  // 2. Artists (Instant Cache-First)
  Future<List<ArtistModel>> getArtists({
    String? category,
    String? query,
    bool? featured,
    bool forceRefresh = false,
  }) async {
    final isDefaultQuery = (category == null || category == 'All') && (query == null || query.isEmpty) && featured == null;

    if (!forceRefresh && isDefaultQuery && _cachedArtists != null && _cachedArtists!.isNotEmpty) {
      return _cachedArtists!;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'All' && category != 'All Categories') {
        queryParams['category'] = category;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (featured != null) {
        queryParams['featured'] = featured ? 1 : 0;
      }

      final res = await _client.get(
        ApiEndpoints.artists,
        queryParameters: queryParams,
      );

      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        final artists = list.map((e) => ArtistModel.fromJson(e as Map<String, dynamic>)).toList();
        if (isDefaultQuery) {
          _cachedArtists = artists;
        }
        return artists;
      }
    } catch (_) {}

    return _cachedArtists ?? [];
  }

  // 2b. Create Artist Profile (Save dynamically to MySQL)
  Future<bool> createArtistProfile({
    required String name,
    required String category,
    required String location,
    required String bio,
    String? email,
    String? phone,
    String? website,
    String? instagram,
    String? experienceLevel,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.artists,
        data: {
          'name': name,
          'category': category,
          'location': location,
          'bio': bio,
          'email': email ?? '',
          'phone': phone ?? '',
          'website': website ?? '',
          'instagram': instagram ?? '',
          'experience_level': experienceLevel ?? '',
        },
      );
      if (_isSuccess(res)) {
        _cachedArtists = null;
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 3. Artist Details
  Future<ArtistModel> getArtistDetails(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedArtistDetails.containsKey(id)) {
      return _cachedArtistDetails[id]!;
    }

    try {
      final res = await _client.get(
        ApiEndpoints.artistDetails,
        queryParameters: {'id': id},
      );
      if (_isSuccess(res)) {
        final artist = ArtistModel.fromJson(res['data'] as Map<String, dynamic>);
        _cachedArtistDetails[id] = artist;
        return artist;
      }
    } catch (_) {}

    return _cachedArtistDetails[id] ??
        ArtistModel.mockArtists.firstWhere(
          (a) => a.id == id,
          orElse: () => ArtistModel.mockArtists.first,
        );
  }

  // 4. Artist Registration
  Future<bool> registerArtist(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.artistRegister,
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedArtists = null; // Invalidate cache for fresh live read
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 5. Events (Instant Cache-First)
  Future<List<ArtEventModel>> getEvents({
    String? category,
    String? query,
    bool forceRefresh = false,
  }) async {
    final isDefaultQuery = (category == null || category == 'All' || category == 'All Categories') && (query == null || query.isEmpty);

    if (!forceRefresh && isDefaultQuery && _cachedEvents != null && _cachedEvents!.isNotEmpty) {
      return _cachedEvents!;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'All Categories' && category != 'All') {
        queryParams['category'] = category;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final res = await _client.get(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        final events = list.map((e) {
          final m = e as Map<String, dynamic>;
          final galleriesList = (m['galleries'] as List<dynamic>?) ?? [];
          final galleries = galleriesList.map((g) {
            final gm = g as Map<String, dynamic>;
            final imgsList = (gm['images'] as List<dynamic>?) ?? [];
            final images = imgsList.map((im) {
              final imm = im as Map<String, dynamic>;
              return GalleryImageItem(
                title: imm['title'] as String? ?? 'Image',
                imageUrl: imm['image_url'] as String? ?? '',
                caption: imm['caption'] as String? ?? 'Event highlight',
              );
            }).toList();

            return EventPhotoGallery(
              title: gm['title'] as String? ?? 'Gallery',
              subtitle: gm['subtitle'] as String?,
              photoCount: (gm['photo_count'] as num?)?.toInt() ?? images.length,
              date: gm['date'] as String? ?? '',
              imageUrl: gm['image_url'] as String? ?? '',
              images: images,
            );
          }).toList();

          List<String> parsedTags = [];
          if (m['tags'] is List) {
            parsedTags = (m['tags'] as List).map((e) => e.toString()).toList();
          } else if (m['tags'] is String && (m['tags'] as String).isNotEmpty) {
            parsedTags = (m['tags'] as String)
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          final dateStr = (m['event_date'] ?? m['date_time'] ?? m['dateTime'] ?? '') as String;
          final formattedDate = (m['formatted_date'] ?? m['event_date'] ?? dateStr) as String;

          return ArtEventModel(
            id: m['id']?.toString() ?? '0',
            title: m['title'] as String? ?? 'Art Event',
            category: m['category'] as String? ?? 'Art Exhibition',
            price: m['price'] as String? ?? 'Free',
            description: m['description'] as String? ?? '',
            requirements: m['requirements'] as String? ?? 'Open to all.',
            dateTime: dateStr,
            formattedDate: formattedDate,
            timeRange: (m['time_range'] ?? '10:00 AM - 08:00 PM') as String,
            location: (m['location'] ?? 'Dubai') as String,
            locationCity: (m['venue'] ?? m['location_city'] ?? m['location'] ?? 'Dubai') as String?,
            attendeesCount: (m['attendees_count'] as num?)?.toInt() ?? 0,
            maxAttendees: (m['max_attendees'] as num?)?.toInt() ?? 100,
            organizer: (m['organizer_name'] ?? m['organizer'] ?? 'Artist Dubai') as String,
            organizerEmail: (m['contact_email'] ?? m['organizer_email']) as String?,
            tags: parsedTags,
            imageUrl: m['image_url'] as String?,
            galleries: galleries,
          );
        }).toList();

        if (isDefaultQuery) {
          _cachedEvents = events;
        }
        return events;
      }
    } catch (_) {}

    return _cachedEvents ?? ArtEventModel.mockEvents;
  }

  // 5b. Event Details (Instant Cache-First)
  Future<ArtEventModel> getEventDetails(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEventDetails.containsKey(id)) {
      return _cachedEventDetails[id]!;
    }

    try {
      final res = await _client.get(
        ApiEndpoints.eventDetails,
        queryParameters: {'id': id},
      );
      if (_isSuccess(res)) {
        final m = res['data'] as Map<String, dynamic>;
        List<String> parsedTags = [];
        if (m['tags'] is List) {
          parsedTags = (m['tags'] as List).map((e) => e.toString()).toList();
        } else if (m['tags'] is String && (m['tags'] as String).isNotEmpty) {
          parsedTags = (m['tags'] as String)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        final dateStr = (m['event_date'] ?? m['date_time'] ?? m['dateTime'] ?? '') as String;
        final formattedDate = (m['formatted_date'] ?? m['event_date'] ?? dateStr) as String;

        final event = ArtEventModel(
          id: m['id']?.toString() ?? '0',
          title: m['title'] as String? ?? 'Art Event',
          category: m['category'] as String? ?? 'Art Exhibition',
          price: m['price'] as String? ?? 'Free',
          description: m['description'] as String? ?? '',
          requirements: m['requirements'] as String? ?? 'Open to all.',
          dateTime: dateStr,
          formattedDate: formattedDate,
          timeRange: (m['time_range'] ?? '10:00 AM - 08:00 PM') as String,
          location: (m['location'] ?? 'Dubai') as String,
          locationCity: (m['venue'] ?? m['location_city'] ?? m['location'] ?? 'Dubai') as String?,
          attendeesCount: (m['attendees_count'] as num?)?.toInt() ?? 0,
          maxAttendees: (m['max_attendees'] as num?)?.toInt() ?? 100,
          organizer: (m['organizer_name'] ?? m['organizer'] ?? 'Artist Dubai') as String,
          organizerEmail: (m['contact_email'] ?? m['organizer_email']) as String?,
          tags: parsedTags,
          imageUrl: m['image_url'] as String?,
        );
        _cachedEventDetails[id] = event;
        return event;
      }
    } catch (_) {}

    return _cachedEventDetails[id] ??
        ArtEventModel.mockEvents.firstWhere(
          (e) => e.id == id,
          orElse: () => ArtEventModel.mockEvents.first,
        );
  }

  // 5c. Create Event (Save dynamically to MySQL)
  Future<bool> createEvent({
    required String title,
    required String description,
    required String category,
    required String eventDate,
    String? endDate,
    required String location,
    String? venue,
    bool isFree = true,
    String? price,
    String? organizerName,
    String? contactEmail,
    String? contactPhone,
    String? tags,
    String? imageUrl,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.events,
        data: {
          'title': title,
          'description': description,
          'category': category,
          'event_date': eventDate,
          'end_date': endDate ?? '',
          'location': location,
          'venue': venue ?? '',
          'is_free': isFree ? 1 : 0,
          'price': isFree ? 'Free' : (price ?? 'AED 50'),
          'organizer_name': organizerName ?? 'Artist Dubai',
          'contact_email': contactEmail ?? '',
          'contact_phone': contactPhone ?? '',
          'tags': tags ?? '',
          'image_url': imageUrl ?? '',
        },
      );
      if (_isSuccess(res)) {
        _cachedEvents = null;
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 6. Government Entities (Instant Cache-First)
  Future<List<GovernmentEntity>> getGovernmentEntities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGovEntities != null && _cachedGovEntities!.isNotEmpty) {
      return _cachedGovEntities!;
    }

    try {
      final res = await _client.get(ApiEndpoints.government);
      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        _cachedGovEntities = list.map((e) => GovernmentEntity.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedGovEntities!;
      }
    } catch (_) {}

    return _cachedGovEntities ?? GovernmentEntity.entities;
  }

  // 7. Galleries (Instant Cache-First)
  Future<List<Map<String, dynamic>>> getGalleries({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGalleries != null && _cachedGalleries!.isNotEmpty) {
      return _cachedGalleries!;
    }

    try {
      final res = await _client.get(ApiEndpoints.galleries);
      if (_isSuccess(res)) {
        _cachedGalleries = (res['data'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        return _cachedGalleries!;
      }
    } catch (_) {}

    return _cachedGalleries ?? [];
  }

  // 7b. Artworks (Instant Cache-First)
  Future<List<Map<String, dynamic>>> getArtworks({bool forceRefresh = false}) async {
    try {
      final res = await _client.get(ApiEndpoints.artworks);
      if (_isSuccess(res)) {
        return (res['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // 8. Gallery Registration
  Future<bool> registerGallery(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.galleryRegister,
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedGalleries = null; // Invalidate cache
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 9. Auth Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    if (_isSuccess(res)) {
      return res['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // 10. Auth Register
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _client.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone ?? '',
      },
    );
    if (_isSuccess(res)) {
      return res['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // 11. Bookings
  Future<bool> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.bookingCreate,
        data: data,
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  Future<bool> cancelBooking(dynamic bookingId) async {
    try {
      final res = await _client.post(
        ApiEndpoints.bookings,
        data: {
          'action': 'cancel',
          'id': bookingId,
        },
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  // 12. About Us (Instant Cache-First)
  Future<Map<String, dynamic>?> getAboutData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAbout != null) {
      return _cachedAbout;
    }

    try {
      final res = await _client.get(ApiEndpoints.aboutUs);
      if (_isSuccess(res)) {
        _cachedAbout = res['data'] as Map<String, dynamic>?;
        return _cachedAbout;
      }
    } catch (_) {}

    return _cachedAbout;
  }

  // 13. Competitions & Open Calls (Instant Cache-First)
  Future<List<Map<String, dynamic>>> getCompetitions({
    String? status,
    String? query,
    bool forceRefresh = false,
  }) async {
    final isDefaultQuery = (status == null || status.isEmpty) && (query == null || query.isEmpty);

    if (!forceRefresh && isDefaultQuery && _cachedCompetitions != null && _cachedCompetitions!.isNotEmpty) {
      return _cachedCompetitions!;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final res = await _client.get(
        ApiEndpoints.competitions,
        queryParameters: queryParams,
      );

      if (_isSuccess(res)) {
        final list = (res['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (isDefaultQuery) {
          _cachedCompetitions = list;
        }
        return list;
      }
    } catch (_) {}

    return (_cachedCompetitions != null && _cachedCompetitions!.isNotEmpty)
        ? _cachedCompetitions!
        : _defaultCompetitions;
  }

  static const List<Map<String, dynamic>> _defaultCompetitions = [
    {
      'id': 'comp-1',
      'title': 'Dubai Art Prize 2026',
      'status': 'open',
      'category': 'Visual Arts & Sculpture',
      'theme': 'Future Horizons & Desert Dreams',
      'organizer': 'Dubai Culture & Arts Authority',
      'deadline': '30 Sep 2026',
      'prize_pool': '100,000 AED',
      'fee': 'Free Entry',
      'description': 'Annual national art competition celebrating contemporary UAE and regional artists.',
      'location': 'Alserkal Avenue, Dubai',
      'eligibility': 'Open to all UAE residents and international artists aged 18+.'
    },
    {
      'id': 'comp-2',
      'title': 'Emerging Artists Showcase Call',
      'status': 'open',
      'category': 'Digital Art & Photography',
      'theme': 'Urban Landscapes & Digital Frontiers',
      'organizer': 'Alserkal Avenue',
      'deadline': '15 Oct 2026',
      'prize_pool': '50,000 AED',
      'fee': 'Free Entry',
      'description': 'Open call for early-career digital creators, animators, and photographers.',
      'location': 'Al Quoz Creative Zone, Dubai',
      'eligibility': 'Early-career artists with under 5 years professional experience.'
    },
    {
      'id': 'comp-3',
      'title': 'Emirates Calligraphy & Typography Award',
      'status': 'upcoming',
      'category': 'Calligraphy & Typography',
      'theme': 'Tradition meets Innovation',
      'organizer': 'Dubai Design District (d3)',
      'deadline': '1 Dec 2026',
      'prize_pool': '75,000 AED',
      'fee': 'Free Entry',
      'description': 'Honoring classic Arabic calligraphy and modern experimental typography.',
      'location': 'Dubai Design District (d3)',
      'eligibility': 'Global entry open to all calligraphers and graphic designers.'
    },
    {
      'id': 'comp-4',
      'title': 'Dubai Public Art Commissioning Grant',
      'status': 'upcoming',
      'category': '3D Installation & Sculpture',
      'theme': 'Outdoor Sculptures & Environmental Installations',
      'organizer': 'Dubai Culture',
      'deadline': '15 Jan 2027',
      'prize_pool': '200,000 AED',
      'fee': 'Free Entry',
      'description': 'Grant initiative to commission permanent public artworks across Dubai parks.',
      'location': 'Public Parks & Waterfront Promenades, Dubai',
      'eligibility': 'Sculptors, architects, and public art collectives.'
    },
    {
      'id': 'comp-5',
      'title': 'Dubai Annual Photography Biennale 2025',
      'status': 'closed',
      'category': 'Photography',
      'theme': 'Light & Shadows of the Gulf',
      'organizer': 'HIPA International Photography Award',
      'deadline': '15 May 2025',
      'prize_pool': '120,000 AED',
      'fee': 'Free Entry',
      'description': 'International photography competition capturing architecture and culture.',
      'location': 'Dubai International Financial Centre (DIFC)',
      'eligibility': 'All professional and amateur photographers.'
    },
  ];

  // 14. My Bookings (user's booking history)
  Future<List<Map<String, dynamic>>> getBookings({
    String? userId,
    String? artistId,
    String? email,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null && userId.isNotEmpty) queryParams['user_id'] = userId;
      if (artistId != null && artistId.isNotEmpty) queryParams['artist_id'] = artistId;
      if (email != null && email.isNotEmpty) queryParams['email'] = email;

      final res = await _client.get(
        ApiEndpoints.bookings,
        queryParameters: queryParams,
      );

      if (_isSuccess(res)) {
        return (res['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // 15. User Profile (Dynamic MySQL read)
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    if (email.isEmpty) return null;
    try {
      final res = await _client.get(
        ApiEndpoints.userProfile,
        queryParameters: {'email': email},
      );
      if (_isSuccess(res)) {
        return res['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // 16. Change Password (MySQL Backend)
  Future<bool> changePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.login}&action=change_password',
        data: {
          'email': email,
          'new_password': newPassword,
        },
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  // 17. Delete Account (MySQL Backend)
  Future<bool> deleteAccount(String email) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.login}&action=delete_account',
        data: {'email': email},
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }
}