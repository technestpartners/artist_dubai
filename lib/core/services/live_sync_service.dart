import 'dart:async';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Pure Event-Driven Mutation & Live Data Streaming Service
/// Triggers database API queries ONLY on explicit actions (Add, Update, View, Delete) — NO auto loop/polling.
class LiveSyncService {
  final ApiService _apiService;
  bool _isSyncing = false;

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

  // Public Streams for UI consumption
  Stream<List<ArtistModel>> get artistsStream => _artistsController.stream;
  Stream<List<ArtEventModel>> get eventsStream => _eventsController.stream;
  Stream<List<Map<String, dynamic>>> get bookingsStream => _bookingsController.stream;
  Stream<Map<String, dynamic>> get favoritesStream => _favoritesController.stream;
  Stream<List<Map<String, dynamic>>> get galleriesStream => _galleriesController.stream;
  Stream<List<GovernmentEntity>> get governmentStream => _governmentController.stream;
  Stream<List<CategoryInfo>> get categoriesStream => _categoriesController.stream;

  LiveSyncService(this._apiService);

  /// Trigger sync for artists when an Add / Update / Delete / View occurs
  Future<void> notifyArtistsChanged([List<ArtistModel>? updatedList]) async {
    if (updatedList != null && !_artistsController.isClosed) {
      _artistsController.add(updatedList);
    } else {
      try {
        final fresh = await _apiService.getArtists(forceRefresh: true);
        if (!_artistsController.isClosed) _artistsController.add(fresh);
      } catch (_) {}
    }
  }

  /// Trigger sync for events when an Add / Update / Delete / View occurs
  Future<void> notifyEventsChanged([List<ArtEventModel>? updatedList]) async {
    if (updatedList != null && !_eventsController.isClosed) {
      _eventsController.add(updatedList);
    } else {
      try {
        final fresh = await _apiService.getEvents(forceRefresh: true);
        if (!_eventsController.isClosed) _eventsController.add(fresh);
      } catch (_) {}
    }
  }

  /// Trigger sync for bookings when an Add / Update / Delete / View occurs
  Future<void> notifyBookingsChanged([List<Map<String, dynamic>>? updatedList]) async {
    if (updatedList != null && !_bookingsController.isClosed) {
      _bookingsController.add(updatedList);
    } else {
      try {
        String? userEmail = sl<StorageService>().getString('user_email');
        if (userEmail != null && userEmail.isNotEmpty) {
          final fresh = await _apiService.getBookings(email: userEmail, forceRefresh: true);
          if (!_bookingsController.isClosed) _bookingsController.add(fresh);
        }
      } catch (_) {}
    }
  }

  /// Trigger sync for favorites when an Add / Update / Delete / View occurs
  Future<void> notifyFavoritesChanged([Map<String, dynamic>? updatedFavorites]) async {
    if (updatedFavorites != null && !_favoritesController.isClosed) {
      _favoritesController.add(updatedFavorites);
    } else {
      try {
        String? userEmail = sl<StorageService>().getString('user_email');
        if (userEmail != null && userEmail.isNotEmpty) {
          final fresh = await _apiService.getFavorites(email: userEmail, forceRefresh: true);
          if (!_favoritesController.isClosed) _favoritesController.add(fresh);
        }
      } catch (_) {}
    }
  }

  /// Trigger sync for galleries when an Add / Update / Delete / View occurs
  Future<void> notifyGalleriesChanged([List<Map<String, dynamic>>? updatedGalleries]) async {
    if (updatedGalleries != null && !_galleriesController.isClosed) {
      _galleriesController.add(updatedGalleries);
    } else {
      try {
        final fresh = await _apiService.getGalleries(forceRefresh: true);
        if (!_galleriesController.isClosed) _galleriesController.add(fresh);
      } catch (_) {}
    }
  }

  /// Trigger sync for government entities when an Add / Update / Delete / View occurs
  Future<void> notifyGovernmentChanged([List<GovernmentEntity>? updatedList]) async {
    if (updatedList != null && !_governmentController.isClosed) {
      _governmentController.add(updatedList);
    } else {
      try {
        final fresh = await _apiService.getGovernmentEntities(forceRefresh: true);
        if (!_governmentController.isClosed) _governmentController.add(fresh);
      } catch (_) {}
    }
  }

  /// Trigger sync for categories when an Add / Update / Delete / View occurs
  Future<void> notifyCategoriesChanged([List<CategoryInfo>? updatedList]) async {
    if (updatedList != null && !_categoriesController.isClosed) {
      _categoriesController.add(updatedList);
    } else {
      try {
        final fresh = await _apiService.getCategories(forceRefresh: true);
        if (!_categoriesController.isClosed) _categoriesController.add(fresh);
      } catch (_) {}
    }
  }

  /// On-demand manual or pull-to-refresh sync for all active data (no auto loop)
  Future<void> syncAllSilently() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      String? userEmail;
      try {
        userEmail = sl<StorageService>().getString('user_email');
      } catch (_) {}

      final results = await Future.wait([
        _apiService.getArtists(forceRefresh: true).catchError((_) => <ArtistModel>[]),
        _apiService.getEvents(forceRefresh: true).catchError((_) => <ArtEventModel>[]),
        _apiService.getGalleries(forceRefresh: true).catchError((_) => <Map<String, dynamic>>[]),
        _apiService.getGovernmentEntities(forceRefresh: true).catchError((_) => <GovernmentEntity>[]),
        _apiService.getCategories(forceRefresh: true).catchError((_) => <CategoryInfo>[]),
        if (userEmail != null && userEmail.isNotEmpty)
          _apiService.getBookings(email: userEmail, forceRefresh: true).catchError((_) => <Map<String, dynamic>>[])
        else
          Future.value(<Map<String, dynamic>>[]),
        if (userEmail != null && userEmail.isNotEmpty)
          _apiService.getFavorites(email: userEmail, forceRefresh: true).catchError((_) => <String, dynamic>{})
        else
          Future.value(<String, dynamic>{}),
      ]);

      final artists = results[0] as List<ArtistModel>;
      final events = results[1] as List<ArtEventModel>;
      final galleries = results[2] as List<Map<String, dynamic>>;
      final govEntities = results[3] as List<GovernmentEntity>;
      final categories = results[4] as List<CategoryInfo>;
      final bookings = results[5] as List<Map<String, dynamic>>;
      final favorites = results[6] as Map<String, dynamic>;

      if (artists.isNotEmpty && !_artistsController.isClosed) _artistsController.add(artists);
      if (events.isNotEmpty && !_eventsController.isClosed) _eventsController.add(events);
      if (galleries.isNotEmpty && !_galleriesController.isClosed) _galleriesController.add(galleries);
      if (govEntities.isNotEmpty && !_governmentController.isClosed) _governmentController.add(govEntities);
      if (categories.isNotEmpty && !_categoriesController.isClosed) _categoriesController.add(categories);
      if (!_bookingsController.isClosed) _bookingsController.add(bookings);
      if (favorites.isNotEmpty && !_favoritesController.isClosed) _favoritesController.add(favorites);

      try {
        sl<NotificationService>().syncWithBackend();
      } catch (_) {}
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _artistsController.close();
    _eventsController.close();
    _bookingsController.close();
    _favoritesController.close();
    _galleriesController.close();
    _governmentController.close();
    _categoriesController.close();
  }
}
