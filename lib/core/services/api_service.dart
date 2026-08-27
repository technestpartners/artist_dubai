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

  ApiService(this._client);

  // 1. Categories (Instant Cache-First)
  Future<List<CategoryInfo>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }

    try {
      final res = await _client.get(ApiEndpoints.categories);
      if (res is Map<String, dynamic> && res['status'] == 'success') {
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

      if (res is Map<String, dynamic> && res['status'] == 'success') {
        final list = res['data'] as List<dynamic>;
        final artists = list.map((e) => ArtistModel.fromJson(e as Map<String, dynamic>)).toList();
        if (isDefaultQuery) {
          _cachedArtists = artists;
        }
        return artists;
      }
    } catch (_) {}

    return _cachedArtists ?? ArtistModel.mockArtists;
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
      if (res is Map<String, dynamic> && res['status'] == 'success') {
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
      if (res is Map<String, dynamic> && res['status'] == 'success') {
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

      if (res is Map<String, dynamic> && res['status'] == 'success') {
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

          return ArtEventModel(
            id: m['id']?.toString() ?? '0',
            title: m['title'] as String? ?? 'Art Event',
            category: m['category'] as String? ?? 'Art Exhibition',
            price: m['price'] as String? ?? 'Free',
            description: m['description'] as String? ?? '',
            requirements: m['requirements'] as String? ?? 'Open to all.',
            dateTime: m['date_time'] as String? ?? '',
            formattedDate: m['formatted_date'] as String? ?? '',
            timeRange: m['time_range'] as String? ?? '',
            location: m['location'] as String? ?? 'Dubai',
            locationCity: m['location_city'] as String? ?? 'Dubai',
            attendeesCount: (m['attendees_count'] as num?)?.toInt() ?? 0,
            maxAttendees: (m['max_attendees'] as num?)?.toInt() ?? 100,
            organizer: m['organizer'] as String? ?? 'Artist Dubai',
            organizerEmail: m['organizer_email'] as String?,
            tags: (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        final m = res['data'] as Map<String, dynamic>;
        final event = ArtEventModel(
          id: m['id']?.toString() ?? '0',
          title: m['title'] as String? ?? 'Art Event',
          category: m['category'] as String? ?? 'Art Exhibition',
          price: m['price'] as String? ?? 'Free',
          description: m['description'] as String? ?? '',
          requirements: m['requirements'] as String? ?? 'Open to all.',
          dateTime: m['date_time'] as String? ?? '',
          formattedDate: m['formatted_date'] as String? ?? '',
          timeRange: m['time_range'] as String? ?? '',
          location: m['location'] as String? ?? 'Dubai',
          locationCity: m['location_city'] as String? ?? 'Dubai',
          attendeesCount: (m['attendees_count'] as num?)?.toInt() ?? 0,
          maxAttendees: (m['max_attendees'] as num?)?.toInt() ?? 100,
          organizer: m['organizer'] as String? ?? 'Artist Dubai',
          organizerEmail: m['organizer_email'] as String?,
          tags: (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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

  // 6. Government Entities (Instant Cache-First)
  Future<List<GovernmentEntity>> getGovernmentEntities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGovEntities != null && _cachedGovEntities!.isNotEmpty) {
      return _cachedGovEntities!;
    }

    try {
      final res = await _client.get(ApiEndpoints.government);
      if (res is Map<String, dynamic> && res['status'] == 'success') {
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
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        _cachedGalleries = (res['data'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        return _cachedGalleries!;
      }
    } catch (_) {}

    return _cachedGalleries ?? [];
  }

  // 8. Gallery Registration
  Future<bool> registerGallery(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.galleryRegister,
        data: data,
      );
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        _cachedGalleries = null; // Invalidate cache
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 9. Auth Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        return res['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // 10. Auth Register
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '',
        },
      );
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        return res['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // 11. Bookings
  Future<bool> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.bookingCreate,
        data: data,
      );
      return res is Map<String, dynamic> && res['status'] == 'success';
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
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        _cachedAbout = res['data'] as Map<String, dynamic>?;
        return _cachedAbout;
      }
    } catch (_) {}

    return _cachedAbout;
  }
}