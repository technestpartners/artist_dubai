import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Real-Time Multi-Device Database Synchronization & Live Data Streaming Service
/// Combines instant optimistic mutations with continuous background MySQL live streaming.
class LiveSyncService with WidgetsBindingObserver {
  final ApiService _apiService;
  bool _isSyncing = false;
  Timer? _syncTimer;

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  // Reactive Stream Controllers for live UI subscriptions
  final StreamController<List<ArtistModel>> _artistsController =
      StreamController<List<ArtistModel>>.broadcast();
  final StreamController<List<ArtEventModel>> _eventsController =
      StreamController<List<ArtEventModel>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _bookingsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _favoritesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _galleriesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<GovernmentEntity>> _governmentController =
      StreamController<List<GovernmentEntity>>.broadcast();
  final StreamController<List<CategoryInfo>> _categoriesController =
      StreamController<List<CategoryInfo>>.broadcast();
  final StreamController<List<ExperienceLevelModel>> _experienceLevelsController =
      StreamController<List<ExperienceLevelModel>>.broadcast();
  final StreamController<List<LocationModel>> _locationsController =
      StreamController<List<LocationModel>>.broadcast();
  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();

  // Public Streams for UI consumption
  Stream<List<ArtistModel>> get artistsStream => _artistsController.stream;
  Stream<List<ArtEventModel>> get eventsStream => _eventsController.stream;
  Stream<List<Map<String, dynamic>>> get bookingsStream => _bookingsController.stream;
  Stream<Map<String, dynamic>> get favoritesStream => _favoritesController.stream;
  Stream<List<Map<String, dynamic>>> get galleriesStream => _galleriesController.stream;
  Stream<List<GovernmentEntity>> get governmentStream => _governmentController.stream;
  Stream<List<CategoryInfo>> get categoriesStream => _categoriesController.stream;
  Stream<List<ExperienceLevelModel>> get experienceLevelsStream => _experienceLevelsController.stream;
  Stream<List<LocationModel>> get locationsStream => _locationsController.stream;
  Stream<bool> get authStream => _authController.stream;

  LiveSyncService(this._apiService) {
    if (!_isTesting) {
      try {
        WidgetsBinding.instance.addObserver(this);
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncAllSilently(forceRefresh: true);
    }
  }

  /// Trigger auth state notification to immediately update UI everywhere
  void notifyAuthChanged(bool isLoggedIn) {
    if (!_authController.isClosed) {
      _authController.add(isLoggedIn);
    }
  }

  /// Trigger sync for artists when an Add / Update / Delete / View occurs
  Future<void> notifyArtistsChanged([List<ArtistModel>? updatedList]) async {
    if (updatedList != null && !_artistsController.isClosed) {
      _artistsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getArtists(forceRefresh: true);
      if (!_artistsController.isClosed) _artistsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for events when an Add / Update / Delete / View occurs
  Future<void> notifyEventsChanged([List<ArtEventModel>? updatedList]) async {
    if (updatedList != null && !_eventsController.isClosed) {
      _eventsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getEvents(forceRefresh: true);
      if (!_eventsController.isClosed) _eventsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for bookings when an Add / Update / Delete / View occurs
  Future<void> notifyBookingsChanged([List<Map<String, dynamic>>? updatedList]) async {
    if (updatedList != null && !_bookingsController.isClosed) {
      _bookingsController.add(updatedList);
    }
    try {
      String? userEmail = sl<StorageService>().getString('user_email');
      if (userEmail != null && userEmail.isNotEmpty) {
        final fresh = await _apiService.getBookings(email: userEmail, forceRefresh: true);
        if (!_bookingsController.isClosed) _bookingsController.add(fresh);
      }
    } catch (_) {}
  }

  String _getEffectiveEmail() {
    try {
      String? email = sl<StorageService>().getString('user_email');
      if (email != null && email.isNotEmpty) return email;
      email = sl<StorageService>().getString('device_guest_id');
      if (email != null && email.isNotEmpty) return email;
      final newId = 'guest_${DateTime.now().millisecondsSinceEpoch}@artistdubai.com';
      sl<StorageService>().setString('device_guest_id', newId);
      return newId;
    } catch (_) {
      return 'user@artistdubai.com';
    }
  }

  /// Trigger sync for favorites when an Add / Update / Delete / View occurs
  Future<void> notifyFavoritesChanged([Map<String, dynamic>? updatedFavorites]) async {
    if (updatedFavorites != null && !_favoritesController.isClosed) {
      _favoritesController.add(updatedFavorites);
    }
    try {
      final email = _getEffectiveEmail();
      final fresh = await _apiService.getFavorites(email: email, forceRefresh: true);
      if (!_favoritesController.isClosed) _favoritesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for galleries when an Add / Update / Delete / View occurs
  Future<void> notifyGalleriesChanged([List<Map<String, dynamic>>? updatedGalleries]) async {
    if (updatedGalleries != null && !_galleriesController.isClosed) {
      _galleriesController.add(updatedGalleries);
    }
    try {
      final fresh = await _apiService.getGalleries(forceRefresh: true);
      if (!_galleriesController.isClosed) _galleriesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for government entities when an Add / Update / Delete / View occurs
  Future<void> notifyGovernmentChanged([List<GovernmentEntity>? updatedList]) async {
    if (updatedList != null && !_governmentController.isClosed) {
      _governmentController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getGovernmentEntities(forceRefresh: true);
      if (!_governmentController.isClosed) _governmentController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for categories when an Add / Update / Delete / View occurs
  Future<void> notifyCategoriesChanged([List<CategoryInfo>? updatedList]) async {
    if (updatedList != null && !_categoriesController.isClosed) {
      _categoriesController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getCategories(forceRefresh: true);
      if (!_categoriesController.isClosed) _categoriesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for experience levels when an Add / Update / Delete occurs
  Future<void> notifyExperienceLevelsChanged([List<ExperienceLevelModel>? updatedList]) async {
    if (updatedList != null && !_experienceLevelsController.isClosed) {
      _experienceLevelsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getExperienceLevels(forceRefresh: true);
      if (!_experienceLevelsController.isClosed) _experienceLevelsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for locations when an Add / Update / Delete occurs
  Future<void> notifyLocationsChanged([List<LocationModel>? updatedList]) async {
    if (updatedList != null && !_locationsController.isClosed) {
      _locationsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getLocations(forceRefresh: true);
      if (!_locationsController.isClosed) _locationsController.add(fresh);
    } catch (_) {}
  }

  /// Starts real-time multi-device database synchronization loop
  void startMultiDeviceSync({Duration? interval}) {
    if (_isTesting) return;
    _syncTimer?.cancel();
    final pollInterval = interval ?? const Duration(seconds: 4);
    _syncTimer = Timer.periodic(pollInterval, (_) {
      syncAllSilently(forceRefresh: true);
    });
  }

  /// Stop live sync timer
  void stopMultiDeviceSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Lightweight multi-device sync for all active data from MySQL database
  Future<void> syncAllSilently({bool forceRefresh = true}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final effectiveEmail = _getEffectiveEmail();

      // Phase 1: High-priority core streams (Artists, Events, Categories)
      final coreBatch = await Future.wait([
        _apiService.getArtists(forceRefresh: forceRefresh).catchError((_) => <ArtistModel>[]),
        _apiService.getEvents(forceRefresh: forceRefresh).catchError((_) => <ArtEventModel>[]),
        _apiService.getCategories(forceRefresh: forceRefresh).catchError((_) => <CategoryInfo>[]),
      ]);

      final artists = coreBatch[0] as List<ArtistModel>;
      final events = coreBatch[1] as List<ArtEventModel>;
      final categories = coreBatch[2] as List<CategoryInfo>;

      if (!_artistsController.isClosed) _artistsController.add(artists);
      if (!_eventsController.isClosed) _eventsController.add(events);
      if (!_categoriesController.isClosed) _categoriesController.add(categories);

      // Phase 2: Secondary streams (Galleries, Government, Favorites)
      final secondaryBatch = await Future.wait([
        _apiService.getGalleries(forceRefresh: forceRefresh).catchError((_) => <Map<String, dynamic>>[]),
        _apiService.getGovernmentEntities(forceRefresh: forceRefresh).catchError((_) => <GovernmentEntity>[]),
        _apiService.getFavorites(email: effectiveEmail, forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      ]);

      final galleries = secondaryBatch[0] as List<Map<String, dynamic>>;
      final govEntities = secondaryBatch[1] as List<GovernmentEntity>;
      final favorites = secondaryBatch[2] as Map<String, dynamic>;

      if (!_galleriesController.isClosed) _galleriesController.add(galleries);
      if (!_governmentController.isClosed) _governmentController.add(govEntities);
      if (!_favoritesController.isClosed) _favoritesController.add(favorites);

      // Phase 3: Masters (Experience Levels & Locations)
      final mastersBatch = await Future.wait([
        _apiService.getExperienceLevels(forceRefresh: forceRefresh).catchError((_) => <ExperienceLevelModel>[]),
        _apiService.getLocations(forceRefresh: forceRefresh).catchError((_) => <LocationModel>[]),
      ]);

      final experienceLevels = mastersBatch[0] as List<ExperienceLevelModel>;
      final locations = mastersBatch[1] as List<LocationModel>;

      if (!_experienceLevelsController.isClosed) _experienceLevelsController.add(experienceLevels);
      if (!_locationsController.isClosed) _locationsController.add(locations);

      try {
        sl<NotificationService>().syncWithBackend();
      } catch (_) {}
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    if (!_isTesting) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    }
    stopMultiDeviceSync();
    _artistsController.close();
    _eventsController.close();
    _bookingsController.close();
    _favoritesController.close();
    _galleriesController.close();
    _governmentController.close();
    _categoriesController.close();
    _experienceLevelsController.close();
    _locationsController.close();
    _authController.close();
  }
}
