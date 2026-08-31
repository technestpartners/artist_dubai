import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Real-time Background Sync & Live Data Streaming Service
/// Enables live database updates across all pages without full-page reloads or loading spinners.
class LiveSyncService {
  final ApiService _apiService;
  Timer? _syncTimer;
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

  LiveSyncService(this._apiService) {
    final isTestEnv = WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Automated');
    if (!isTestEnv) {
      startAutoSync();
    }
  }

  /// Start automatic background live-polling
  void startAutoSync({Duration interval = const Duration(seconds: 8)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncAllSilently());
  }

  /// Stop background polling
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Silently fetch fresh data from MySQL in the background and emit live updates
  Future<void> syncAllSilently() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      String? userEmail;
      try {
        userEmail = sl<StorageService>().getString('user_email');
      } catch (_) {}

      // Parallel silent background fetch
      final results = await Future.wait([
        _apiService.getArtists(forceRefresh: true).catchError((_) => <ArtistModel>[]),
        _apiService.getEvents(forceRefresh: true).catchError((_) => <ArtEventModel>[]),
        _apiService.getGalleries(forceRefresh: true).catchError((_) => <Map<String, dynamic>>[]),
        _apiService.getGovernmentEntities(forceRefresh: true).catchError((_) => <GovernmentEntity>[]),
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
      final bookings = results[4] as List<Map<String, dynamic>>;
      final favorites = results[5] as Map<String, dynamic>;

      // Broadcast fresh updates silently if active listeners exist
      if (artists.isNotEmpty && !_artistsController.isClosed) {
        _artistsController.add(artists);
      }
      if (events.isNotEmpty && !_eventsController.isClosed) {
        _eventsController.add(events);
      }
      if (galleries.isNotEmpty && !_galleriesController.isClosed) {
        _galleriesController.add(galleries);
      }
      if (govEntities.isNotEmpty && !_governmentController.isClosed) {
        _governmentController.add(govEntities);
      }
      if (!_bookingsController.isClosed) {
        _bookingsController.add(bookings);
      }
      if (favorites.isNotEmpty && !_favoritesController.isClosed) {
        _favoritesController.add(favorites);
      }
      try {
        sl<NotificationService>().syncWithBackend();
      } catch (_) {}
    } catch (e) {
      debugPrint('Silent live sync notice: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Instant Optimistic & Reactive Mutation Triggers (0ms delay)
  void notifyArtistsChanged([List<ArtistModel>? updatedList]) {
    if (updatedList != null && !_artistsController.isClosed) {
      _artistsController.add(updatedList);
    }
    syncAllSilently();
  }

  void notifyEventsChanged([List<ArtEventModel>? updatedList]) {
    if (updatedList != null && !_eventsController.isClosed) {
      _eventsController.add(updatedList);
    }
    syncAllSilently();
  }

  void notifyBookingsChanged([List<Map<String, dynamic>>? updatedList]) {
    if (updatedList != null && !_bookingsController.isClosed) {
      _bookingsController.add(updatedList);
    }
    syncAllSilently();
  }

  void notifyFavoritesChanged([Map<String, dynamic>? updatedFavorites]) {
    if (updatedFavorites != null && !_favoritesController.isClosed) {
      _favoritesController.add(updatedFavorites);
    }
    syncAllSilently();
  }

  void notifyGalleriesChanged([List<Map<String, dynamic>>? updatedGalleries]) {
    if (updatedGalleries != null && !_galleriesController.isClosed) {
      _galleriesController.add(updatedGalleries);
    }
    syncAllSilently();
  }

  void dispose() {
    _syncTimer?.cancel();
    _artistsController.close();
    _eventsController.close();
    _bookingsController.close();
    _favoritesController.close();
    _galleriesController.close();
    _governmentController.close();
    _categoriesController.close();
  }
}
