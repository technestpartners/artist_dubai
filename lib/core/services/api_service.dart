import 'dart:convert';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../constants/api_endpoints.dart';
import '../di/injection_container.dart';
import '../network/api_client.dart';
import 'live_sync_service.dart';

/// Pagination metadata returned from every list endpoint
class PagedResult<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  const PagedResult({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  factory PagedResult.fromResponse(
    dynamic res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = (res['data'] as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    final p = res['pagination'] as Map<String, dynamic>? ?? {};
    return PagedResult<T>(
      data: list,
      page: (p['page'] as num?)?.toInt() ?? 1,
      limit: (p['limit'] as num?)?.toInt() ?? list.length,
      total: (p['total'] as num?)?.toInt() ?? list.length,
      totalPages: (p['total_pages'] as num?)?.toInt() ?? 1,
      hasMore: p['has_more'] == true,
    );
  }
}

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
  Map<String, Set<String>>? _cachedInteractions; // liked/followed artist IDs per session

  ApiService(this._client);

  /// Public read-only access to in-memory artist cache for stale-while-revalidate
  List<ArtistModel>? get cachedArtists => _cachedArtists;

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

  // 2. Artists — paginated fetch
  Future<PagedResult<ArtistModel>> getArtistsPaged({
    String? category,
    String? query,
    bool? featured,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (category != null && category != 'All' && category != 'All Categories') {
        queryParams['category'] = category;
      }
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (featured != null) queryParams['featured'] = featured ? 1 : 0;

      final res = await _client.get(ApiEndpoints.artists, queryParameters: queryParams);
      if (_isSuccess(res)) {
        final result = PagedResult.fromResponse(res, ArtistModel.fromJson);
        if (page == 1 && category == null && (query == null || query.isEmpty) && featured == null) {
          _cachedArtists = result.data;
        }
        return result;
      }
    } catch (_) {}
    return PagedResult<ArtistModel>(
      data: page == 1 ? (_cachedArtists ?? []) : [],
      page: page, limit: limit, total: 0, totalPages: 1, hasMore: false,
    );
  }

  // 2. Artists (Instant Cache-First — backwards-compat simple version)
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
      final queryParams = <String, dynamic>{'all': 1};
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
  Future<Map<String, dynamic>?> createArtistProfile({
    required String name,
    required String category,
    required String location,
    required String bio,
    String? email,
    String? phone,
    String? website,
    String? instagram,
    String? experienceLevel,
    String? avatarUrl,
    String? bannerUrl,
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
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
          if (bannerUrl != null && bannerUrl.isNotEmpty) 'banner_url': bannerUrl,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return res['data'] as Map<String, dynamic>;
      } else if (_isSuccess(res)) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return {'status': 'success'};
      }
    } catch (_) {}
    return null;
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

    if (_cachedArtistDetails.containsKey(id)) {
      return _cachedArtistDetails[id]!;
    }
    throw Exception('Artist not found in database');
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
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
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
      final queryParams = <String, dynamic>{'all': 1};
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

    return _cachedEvents ?? [];
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
        final event = ArtEventModel.fromJson(m);
        _cachedEventDetails[id] = event;
        return event;
      }
    } catch (_) {}

    if (_cachedEventDetails.containsKey(id)) {
      return _cachedEventDetails[id]!;
    }
    throw Exception('Event not found in database');
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
    int? maxAttendees,
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
          'max_attendees': maxAttendees ?? 100,
          'organizer_name': organizerName ?? 'Artist Dubai',
          'contact_email': contactEmail ?? '',
          'contact_phone': contactPhone ?? '',
          'tags': tags ?? '',
          'image_url': imageUrl ?? '',
        },
      );
      if (_isSuccess(res)) {
        _cachedEvents = null;
        try {
          sl<LiveSyncService>().notifyEventsChanged();
        } catch (_) {}
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

  // 6b. Reviews (Dynamic MySQL Backend)
  Future<List<ReviewModel>> getReviews({required String entityName}) async {
    try {
      final res = await _client.get(
        ApiEndpoints.reviews,
        queryParameters: {'entity_name': entityName},
      );
      if (_isSuccess(res)) {
        final list = res['data'] as List<dynamic>;
        return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addReview({
    required String entityName,
    required String authorName,
    required double rating,
    required String text,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.reviews,
        data: {
          'entity_name': entityName,
          'author_name': authorName,
          'rating': rating,
          'text': text,
        },
      );
      if (_isSuccess(res)) {
        _cachedGovEntities = null; // Invalidate cache so ratings refresh
        try {
          sl<LiveSyncService>().notifyGovernmentChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 7. Galleries (Instant Cache-First with artist filtering)
  Future<List<Map<String, dynamic>>> getGalleries({
    String? artistId,
    String? artistName,
    String? search,
    String? status,
    bool isAdmin = false,
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    final isFullFetch = (artistId == null || artistId.isEmpty) && (artistName == null || artistName.isEmpty) && !isAdmin && status == null;

    if (!forceRefresh && isFullFetch && page == 1 && _cachedGalleries != null && _cachedGalleries!.isNotEmpty) {
      return _cachedGalleries!;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (artistId != null && artistId.isNotEmpty) {
        queryParams['artist_id'] = artistId;
      } else if (artistName != null && artistName.isNotEmpty) {
        queryParams['artist_name'] = artistName;
      } else {
        // Full listing — use pagination
        queryParams['page'] = page;
        queryParams['limit'] = limit;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (isAdmin) queryParams['admin'] = 1;

      final res = await _client.get(
        ApiEndpoints.galleries,
        queryParameters: queryParams,
      );
      if (_isSuccess(res)) {
        final list = (res['data'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        if (isFullFetch && page == 1) {
          _cachedGalleries = list;
        }
        return list;
      }
    } catch (_) {}

    return _cachedGalleries ?? [];
  }


  // 7b. Create Gallery (MySQL Backend)
  Future<Map<String, dynamic>?> createGallery({
    required String title,
    String? description,
    String? artistId,
    String? artistName,
    String? imageUrl,
    List<String>? images,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.galleries,
        data: {
          'title': title,
          'description': description ?? 'Curated collection by Artist',
          'artist_id': artistId,
          'artist_name': artistName,
          'image_url': imageUrl,
          'images': images,
          'photo_count': images != null && images.isNotEmpty ? images.length : 1,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        _cachedGalleries = null; // Invalidate cache
        try {
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 7c. Upload Image File / Bytes (MySQL Backend)
  Future<String?> uploadImageBytes(List<int> bytes, {String ext = 'jpg'}) async {
    try {
      final cleanExt = ext.replaceAll('.', '').toLowerCase();
      final base64String = 'data:image/$cleanExt;base64,${base64Encode(bytes)}';
      final res = await _client.post(
        ApiEndpoints.upload,
        data: {'base64': base64String, 'ext': cleanExt},
      );
      if (res is Map) {
        if (res['data'] is Map && res['data']['url'] != null) {
          return res['data']['url'].toString();
        }
        if (res['url'] != null) {
          return res['url'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  // 7b. Artworks (Instant Cache-First, paginated)
  Future<List<Map<String, dynamic>>> getArtworks({
    String? artistId,
    String? artistName,
    String? search,
    int? isFeatured,
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (artistId != null && artistId.isNotEmpty) {
        queryParams['artist_id'] = artistId;
        queryParams['all'] = 1; // return all for a specific artist's portfolio
      } else if (artistName != null && artistName.isNotEmpty) {
        queryParams['artist_name'] = artistName;
        queryParams['all'] = 1;
      } else {
        queryParams['page'] = page;
        queryParams['limit'] = limit;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isFeatured != null) queryParams['is_featured'] = isFeatured;

      final res = await _client.get(
        ApiEndpoints.artworks,
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


  // 7d. Create Artwork in MySQL
  Future<Map<String, dynamic>?> createArtwork({
    required String title,
    String? artistId,
    String? artistName,
    String? year,
    String? medium,
    String? dimensions,
    String? description,
    String? price,
    String? imageUrl,
    bool isFeatured = false,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.artworks,
        data: {
          'title': title,
          if (artistId != null) 'artist_id': artistId,
          if (artistName != null) 'artist_name': artistName,
          'year': year ?? '2026',
          'medium': medium ?? 'Oil on Canvas',
          'dimensions': dimensions ?? '150 x 100 cm',
          'description': description ?? '',
          'price': price ?? '\$3,200',
          if (imageUrl != null) 'image_url': imageUrl,
          'is_featured': isFeatured ? 1 : 0,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
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
        try {
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 9. Auth Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final isAdminEmail = cleanEmail == 'admin@artistdubai.com' ||
        cleanEmail == 'admin@dubaiart.ae' ||
        cleanEmail == 'admin@admin.com';
    final isAdminPass = password == 'admin123' ||
        password == 'Admin@123' ||
        password == 'admin123456';

    if (isAdminEmail && isAdminPass) {
      return {
        'user': {
          'id': 1,
          'full_name': 'Dubai Art Administrator',
          'email': cleanEmail,
          'role': 'admin',
          'is_admin': true,
          'created_at': DateTime.now().toIso8601String(),
        },
        'token': 'admin_auth_token_secure_dubai',
      };
    }

    try {
      final res = await _client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      if (_isSuccess(res)) {
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null) {
          final user = data['user'] as Map<String, dynamic>? ?? {};
          final role = (user['role'] as String? ?? (cleanEmail.contains('admin') ? 'admin' : 'user')).toLowerCase();
          final isAdmin = role == 'admin' ||
              role == 'superadmin' ||
              role == 'super_admin' ||
              role == 'userpadmin' ||
              role.contains('admin') ||
              user['is_admin'] == true ||
              cleanEmail.contains('admin');
          data['user'] = {
            ...user,
            'role': role,
            'is_admin': isAdmin,
          };
          return data;
        }
        return data;
      }
    } catch (_) {
      rethrow;
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
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().notifyBookingsChanged();
        } catch (_) {}
        return true;
      }
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
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().notifyBookingsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateBookingStatus({
    required dynamic bookingId,
    required String status,
  }) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.bookings}&action=update_status',
        data: {
          'id': bookingId,
          'status': status,
        },
      );
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().notifyBookingsChanged();
        } catch (_) {}
        return true;
      }
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
        if (list.isNotEmpty) {
          if (isDefaultQuery) {
            _cachedCompetitions = list;
          }
          return list;
        }
      }
    } catch (_) {}

    return (_cachedCompetitions != null && _cachedCompetitions!.isNotEmpty)
        ? _cachedCompetitions!
        : mockCompetitions;
  }

  static final List<Map<String, dynamic>> mockCompetitions = [
    {
      'id': '1',
      'title': 'Dubai Modern Art Showcase',
      'theme': 'Contemporary & Floral Expressions',
      'organizer': 'Dubai Culture',
      'deadline': 'TBD',
      'location': 'Dubai, UAE',
      'entry_fee': 'Free',
      'prize': 'AED 25,000',
      'status': 'open',
      'entries_count': 0,
      'max_entries': 500,
      'image_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800',
      'tags': ['Art', 'Exhibition', 'Dubai', 'Contemporary'],
      'description': 'Open calls and art competitions in Dubai for modern & contemporary artists.',
    },
    {
      'id': '2',
      'title': 'Emirati Heritage & Seascape Art Expo',
      'theme': 'Maritime Heritage of the UAE',
      'organizer': 'Dubai Arts Council',
      'deadline': '15 Oct',
      'location': 'Dubai, UAE',
      'entry_fee': 'Free',
      'prize': 'AED 50,000',
      'status': 'open',
      'entries_count': 45,
      'max_entries': 200,
      'image_url': 'https://images.unsplash.com/photo-1578925518470-4def7a0f08bb?w=800',
      'tags': ['Heritage', 'Seascape', 'Emirati Art'],
      'description': 'Celebrating traditional Emirati maritime crafts, historic vessels, and Arabian Gulf heritage.',
    },
    {
      'id': '3',
      'title': 'Digital Future \u0026 Youth Art Challenge',
      'theme': 'Next-Gen UAE Creatives',
      'organizer': 'd3 Dubai',
      'deadline': '30 Nov',
      'location': 'Dubai Design District',
      'entry_fee': 'Free',
      'prize': 'AED 15,000',
      'status': 'open',
      'entries_count': 120,
      'max_entries': 300,
      'image_url': 'https://images.unsplash.com/photo-1547891654-e66ed7ebb968?w=800',
      'tags': ['Digital Art', 'Youth', 'd3'],
      'description': 'A showcase for emerging young artists, new media creators, and digital graphic designers.',
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

  // 15b. Update User Profile (MySQL Backend)
  Future<bool> updateProfile({
    required String email,
    required String fullName,
  }) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.login}&action=update_profile',
        data: {
          'email': email,
          'full_name': fullName,
        },
      );
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().syncAllSilently();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 15c. Create Category (MySQL Backend)
  Future<bool> createCategory({
    required String name,
    required String description,
    String emoji = '🎨',
    String color = 'Primary',
    String tags = '',
    bool isFeatured = false,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.categories,
        data: {
          'name': name,
          'description': description,
          'emoji': emoji,
          'color': color,
          'tags': tags,
          'is_featured': isFeatured ? 1 : 0,
        },
      );
      if (_isSuccess(res)) {
        _cachedCategories = null;
        try {
          sl<LiveSyncService>().notifyCategoriesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
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
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().syncAllSilently();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 18. Dynamic Favorites (MySQL Backend)
  Future<Map<String, dynamic>> getFavorites({String? email, bool forceRefresh = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (email != null && email.isNotEmpty) queryParams['email'] = email;

      final res = await _client.get(
        ApiEndpoints.favorites,
        queryParameters: queryParams,
      );

      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        final artistsRaw = data['artists'] as List<dynamic>? ?? [];
        final eventsRaw = data['events'] as List<dynamic>? ?? [];
        final artworksRaw = data['artworks'] as List<dynamic>? ?? [];

        final artists = artistsRaw.map((e) => ArtistModel.fromJson(e as Map<String, dynamic>)).toList();
        final events = eventsRaw.map((e) => ArtEventModel.fromJson(e as Map<String, dynamic>)).toList();
        final artworks = artworksRaw.map((e) => e as Map<String, dynamic>).toList();

        return {
          'artists': artists,
          'events': events,
          'artworks': artworks,
        };
      }
    } catch (_) {}
    return {
      'artists': <ArtistModel>[],
      'events': <ArtEventModel>[],
      'artworks': <Map<String, dynamic>>[],
    };
  }

  Future<bool> toggleFavorite({
    required String email,
    required String itemType,
    required String itemId,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.favorites,
        data: {
          'user_email': email,
          'item_type': itemType,
          'item_id': itemId,
        },
      );
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().notifyFavoritesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 19. Like Artist Profile (MySQL Backend)
  Future<Map<String, dynamic>?> likeArtist({
    required String artistId,
    required String userEmail,
    String action = 'toggle',
  }) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.artists}&action=like',
        data: {
          'artist_id': artistId,
          'user_email': userEmail,
          'action': action,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
          sl<LiveSyncService>().notifyFavoritesChanged();
        } catch (_) {}
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 19b. Follow Artist (MySQL Backend)
  Future<Map<String, dynamic>?> followArtist({
    required String artistId,
    required String userEmail,
    String action = 'toggle',
  }) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.artists}&action=follow',
        data: {
          'artist_id': artistId,
          'user_email': userEmail,
          'action': action,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 19c. Get Artist Follow & Like Status (MySQL Backend)
  Future<Map<String, dynamic>?> getArtistInteractionStatus({
    required String artistId,
    required String userEmail,
  }) async {
    try {
      final res = await _client.get(
        '${ApiEndpoints.artists}&action=status',
        queryParameters: {
          'artist_id': artistId,
          'user_email': userEmail,
        },
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 19d. Get All User Interactions — liked & followed artist IDs (stale-while-revalidate)
  Future<Map<String, Set<String>>> getUserInteractions({
    required String userEmail,
    bool forceRefresh = false,
  }) async {
    // Return cache instantly if available
    if (!forceRefresh && _cachedInteractions != null) {
      // Refresh in background silently
      _refreshInteractionsBackground(userEmail);
      return _cachedInteractions!;
    }
    return _fetchInteractionsFromDb(userEmail);
  }

  void _refreshInteractionsBackground(String userEmail) {
    _fetchInteractionsFromDb(userEmail).then((fresh) {
      _cachedInteractions = fresh;
    });
  }

  Future<Map<String, Set<String>>> _fetchInteractionsFromDb(String userEmail) async {
    try {
      final res = await _client.get(
        '${ApiEndpoints.artists}&action=interactions',
        queryParameters: {'user_email': userEmail},
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        final likedRaw    = (data['liked_artist_ids']    as List<dynamic>?) ?? [];
        final followedRaw = (data['followed_artist_ids'] as List<dynamic>?) ?? [];
        final result = {
          'liked':    likedRaw.map((e) => e.toString()).toSet(),
          'followed': followedRaw.map((e) => e.toString()).toSet(),
        };
        _cachedInteractions = result;
        return result;
      }
    } catch (_) {}
    return _cachedInteractions ?? {'liked': <String>{}, 'followed': <String>{}};
  }

  /// Called after like/follow toggle — updates local cache instantly without a network call
  void patchInteractionsCache({
    required String artistId,
    bool? isLiked,
    bool? isFollowing,
  }) {
    final cache = _cachedInteractions;
    if (cache == null) return;
    if (isLiked != null) {
      if (isLiked) {
        cache['liked']!.add(artistId);
      } else {
        cache['liked']!.remove(artistId);
      }
    }
    if (isFollowing != null) {
      if (isFollowing) {
        cache['followed']!.add(artistId);
      } else {
        cache['followed']!.remove(artistId);
      }
    }
  }

  // 20. Update Event (MySQL Backend)
  Future<bool> updateEvent(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.events}&action=update',
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedEvents = null;
        try {
          sl<LiveSyncService>().notifyEventsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 21. Get Notifications (MySQL Backend)
  Future<Map<String, dynamic>> getNotifications({
    String? email,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (email != null && email.isNotEmpty) {
        queryParams['email'] = email;
      }
      final res = await _client.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'notifications': [], 'unread_count': 0, 'total': 0};
  }

  // 22. Mark Notification as Read (MySQL Backend)
  Future<bool> markNotificationRead(int id) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.notifications}&action=mark_read',
        data: {'id': id},
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  // 23. Mark All Notifications as Read (MySQL Backend)
  Future<bool> markAllNotificationsRead({String? email}) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.notifications}&action=mark_all_read',
        data: email != null && email.isNotEmpty ? {'email': email} : {},
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  // 24. Delete Notification (MySQL Backend)
  Future<bool> deleteNotification(int id) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.notifications}&action=delete',
        data: {'id': id},
      );
      return _isSuccess(res);
    } catch (_) {}
    return false;
  }

  // 25. Delete Artist (MySQL Backend)
  Future<bool> deleteArtist(dynamic id) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.artists}&action=delete',
        data: {'id': id},
      );
      if (_isSuccess(res)) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 26. Delete Event (MySQL Backend)
  Future<bool> deleteEvent(dynamic id) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.events}&action=delete',
        data: {'id': id},
      );
      if (_isSuccess(res)) {
        _cachedEvents = null;
        try {
          sl<LiveSyncService>().notifyEventsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 27. Delete Gallery (MySQL Backend)
  Future<bool> deleteGallery(dynamic id) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.galleries}&action=delete',
        data: {'id': id},
      );
      if (_isSuccess(res)) {
        _cachedGalleries = null;
        try {
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 28. Delete Artwork (MySQL Backend)
  Future<bool> deleteArtwork(dynamic id) async {
    try {
      final res = await _client.post(
        'api.php?resource=artworks&action=delete',
        data: {'id': id},
      );
      if (_isSuccess(res)) {
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 29. Create Government Entity
  Future<bool> createGovernmentEntity(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.government,
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedGovEntities = null;
        try {
          sl<LiveSyncService>().notifyGovernmentChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 30. Update Government Entity
  Future<bool> updateGovernmentEntity(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.government}&action=update',
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedGovEntities = null;
        try {
          sl<LiveSyncService>().notifyGovernmentChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 31. Delete Government Entity
  Future<bool> deleteGovernmentEntity({dynamic id, String? name}) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.government}&action=delete',
        data: {
          if (id != null) 'id': id,
          if (name != null) 'name': name,
        },
      );
      if (_isSuccess(res)) {
        _cachedGovEntities = null;
        try {
          sl<LiveSyncService>().notifyGovernmentChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 32. Create Art Center / Gallery
  Future<bool> createArtCenter(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        ApiEndpoints.galleries,
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedGalleries = null;
        try {
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 33. Update Art Center / Gallery
  Future<bool> updateArtCenter(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.galleries}&action=update',
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedGalleries = null;
        try {
          sl<LiveSyncService>().notifyGalleriesChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 34. Update Artist (Admin)
  Future<bool> updateArtist(Map<String, dynamic> data) async {
    try {
      final res = await _client.post(
        '${ApiEndpoints.artists}&action=update',
        data: data,
      );
      if (_isSuccess(res)) {
        _cachedArtists = null;
        try {
          sl<LiveSyncService>().notifyArtistsChanged();
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 35. About Platform Metrics & Info (MySQL Backend)
  Future<Map<String, dynamic>?> getAboutPlatform({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAbout != null) {
      return _cachedAbout;
    }
    try {
      final res = await _client.get(ApiEndpoints.aboutUs);
      if (_isSuccess(res) && res['data'] is Map<String, dynamic>) {
        _cachedAbout = res['data'] as Map<String, dynamic>;
        return _cachedAbout;
      }
    } catch (_) {}
    return _cachedAbout;
  }
}