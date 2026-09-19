import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/admin/domain/models/publishing_pricing_model.dart';
import '../../features/admin/domain/models/payment_settings_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/government/domain/models/government_entity.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Real-Time Multi-Device Database Synchronization &amp; Live Data Streaming Service
/// Combines instant optimistic mutations with continuous background MySQL live streaming.
class LiveSyncService with WidgetsBindingObserver {
  final ApiService _apiService;
  bool _isSyncing = false;
  Timer? _syncTimer;
  bool _isPausedByLifecycle = false;

  // Data fingerprints — store length+hash to skip redundant stream broadcasts
  final Map<String, int> _streamFingerprints = {};

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
  final StreamController<List<PublishingPricingModel>> _publishingPricingController =
      StreamController<List<PublishingPricingModel>>.broadcast();
  final StreamController<PaymentSettingsModel> _paymentSettingsController =
      StreamController<PaymentSettingsModel>.broadcast();
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
  Stream<List<PublishingPricingModel>> get publishingPricingStream => _publishingPricingController.stream;
  Stream<PaymentSettingsModel> get paymentSettingsStream => _paymentSettingsController.stream;
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
      _isPausedByLifecycle = false;
      syncAllSilently(forceRefresh: true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause background polling when app is not visible to save battery & bandwidth
      _isPausedByLifecycle = true;
    } else if (state == AppLifecycleState.detached) {
      // Engine view is being torn down (hot-restart, tab close, process kill).
      // Stop the timer immediately so no async callbacks can schedule frames
      // against a disposed EngineFlutterView.
      _isPausedByLifecycle = true;
      stopMultiDeviceSync();
    }
  }

  /// Emit to a stream only if data fingerprint changed — prevents unnecessary widget rebuilds
  bool _shouldEmit(String key, dynamic data) {
    final fingerprint = data is List ? data.length ^ data.hashCode : data.hashCode;
    if (_streamFingerprints[key] == fingerprint) return false;
    _streamFingerprints[key] = fingerprint;
    return true;
  }

  /// Trigger auth state notification to immediately update UI everywhere
  void notifyAuthChanged(bool isLoggedIn) {
    if (!_authController.isClosed) {
      _authController.add(isLoggedIn);
    }
  }

  bool _isCurrentUserAdmin() {
    try {
      final role = sl<StorageService>().getString('role')?.toLowerCase();
      final email = sl<StorageService>().getString('user_email')?.toLowerCase() ?? '';
      return role == 'admin' || email.contains('admin');
    } catch (_) {
      return false;
    }
  }

  /// Trigger sync for artists when an Add / Update / Delete / View occurs
  Future<void> notifyArtistsChanged([List<ArtistModel>? updatedList]) async {
    if (updatedList != null && !_artistsController.isClosed) {
      _artistsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getArtists(forceRefresh: true);
      if (!_artistsController.isClosed && _shouldEmit('artists', fresh)) _artistsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for events when an Add / Update / Delete / View occurs
  Future<void> notifyEventsChanged([List<ArtEventModel>? updatedList]) async {
    if (updatedList != null && !_eventsController.isClosed) {
      _eventsController.add(updatedList);
    }
    try {
      final isAdmin = _isCurrentUserAdmin();
      final fresh = await _apiService.getEvents(forceRefresh: true, isAdmin: isAdmin);
      if (!_eventsController.isClosed && _shouldEmit('events', fresh)) _eventsController.add(fresh);
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
        if (!_bookingsController.isClosed && _shouldEmit('bookings', fresh)) _bookingsController.add(fresh);
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
      if (!_favoritesController.isClosed && _shouldEmit('favorites', fresh)) _favoritesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for galleries when an Add / Update / Delete / View occurs
  Future<void> notifyGalleriesChanged([List<Map<String, dynamic>>? updatedGalleries]) async {
    if (updatedGalleries != null && !_galleriesController.isClosed) {
      _galleriesController.add(updatedGalleries);
    }
    try {
      final isAdmin = _isCurrentUserAdmin();
      final fresh = await _apiService.getGalleries(forceRefresh: true, isAdmin: isAdmin);
      if (!_galleriesController.isClosed && _shouldEmit('galleries', fresh)) _galleriesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for government entities when an Add / Update / Delete / View occurs
  Future<void> notifyGovernmentChanged([List<GovernmentEntity>? updatedList]) async {
    if (updatedList != null && !_governmentController.isClosed) {
      _governmentController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getGovernmentEntities(forceRefresh: true);
      if (!_governmentController.isClosed && _shouldEmit('government', fresh)) _governmentController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for categories when an Add / Update / Delete / View occurs
  Future<void> notifyCategoriesChanged([List<CategoryInfo>? updatedList]) async {
    if (updatedList != null && !_categoriesController.isClosed) {
      _categoriesController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getCategories(forceRefresh: true);
      if (!_categoriesController.isClosed && _shouldEmit('categories', fresh)) _categoriesController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for experience levels when an Add / Update / Delete occurs
  Future<void> notifyExperienceLevelsChanged([List<ExperienceLevelModel>? updatedList]) async {
    if (updatedList != null && !_experienceLevelsController.isClosed) {
      _experienceLevelsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getExperienceLevels(forceRefresh: true);
      if (!_experienceLevelsController.isClosed && _shouldEmit('expLevels', fresh)) _experienceLevelsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for locations when an Add / Update / Delete occurs
  Future<void> notifyLocationsChanged([List<LocationModel>? updatedList]) async {
    if (updatedList != null && !_locationsController.isClosed) {
      _locationsController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getLocations(forceRefresh: true);
      if (!_locationsController.isClosed && _shouldEmit('locations', fresh)) _locationsController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for publishing pricing when an Admin Update occurs
  Future<void> notifyPublishingPricingChanged([List<PublishingPricingModel>? updatedList]) async {
    if (updatedList != null && !_publishingPricingController.isClosed) {
      _publishingPricingController.add(updatedList);
    }
    try {
      final fresh = await _apiService.getPublishingPricing(forceRefresh: true);
      if (!_publishingPricingController.isClosed && _shouldEmit('pricing', fresh)) _publishingPricingController.add(fresh);
    } catch (_) {}
  }

  /// Trigger sync for payment settings (QR Code &amp; Bank Details) when an Admin Update occurs
  Future<void> notifyPaymentSettingsChanged([PaymentSettingsModel? updatedSettings]) async {
    if (updatedSettings != null && !_paymentSettingsController.isClosed) {
      _paymentSettingsController.add(updatedSettings);
    }
    try {
      final fresh = await _apiService.getPaymentSettings(forceRefresh: true);
      if (!_paymentSettingsController.isClosed && _shouldEmit('payment', fresh)) _paymentSettingsController.add(fresh);
    } catch (_) {}
  }

  bool _hasLoadedMasters = false;

  /// Starts real-time multi-device database synchronization loop
  /// Poll interval increased to 60s — halves background API requests vs previous 30s
  void startMultiDeviceSync({Duration? interval}) {
    if (_isTesting) return;
    _syncTimer?.cancel();
    final pollInterval = interval ?? const Duration(seconds: 60);
    _syncTimer = Timer.periodic(pollInterval, (_) {
      if (!_isPausedByLifecycle) {
        syncAllSilently(forceRefresh: true);
      }
    });
  }

  /// Stop live sync timer
  void stopMultiDeviceSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Force an immediate re-sync of all data and masters when locale toggles
  Future<void> forceLocaleRefresh() async {
    _isSyncing = false;
    _hasLoadedMasters = false;
    _streamFingerprints.clear();
    await syncAllSilently(forceRefresh: true, syncMasters: true);
  }

  /// Lightweight multi-device sync for active data from MySQL database
  Future<void> syncAllSilently({bool forceRefresh = true, bool syncMasters = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final effectiveEmail = _getEffectiveEmail();
      final isAdmin = _isCurrentUserAdmin();

      // Phase 1: High-priority core streams (Artists, Events, Categories)
      final artists = await _apiService.getArtists(forceRefresh: forceRefresh).catchError((_) => <ArtistModel>[]);
      if (artists.isNotEmpty && !_artistsController.isClosed && _shouldEmit('artists', artists)) {
        _artistsController.add(artists);
      }

      final events = await _apiService.getEvents(forceRefresh: forceRefresh, isAdmin: isAdmin).catchError((_) => <ArtEventModel>[]);
      if (events.isNotEmpty && !_eventsController.isClosed && _shouldEmit('events', events)) {
        _eventsController.add(events);
      }

      final categories = await _apiService.getCategories(forceRefresh: forceRefresh).catchError((_) => <CategoryInfo>[]);
      if (categories.isNotEmpty && !_categoriesController.isClosed && _shouldEmit('categories', categories)) {
        _categoriesController.add(categories);
      }

      // Phase 2: Secondary streams (Galleries, Government, Favorites)
      final galleries = await _apiService.getGalleries(forceRefresh: forceRefresh, isAdmin: isAdmin).catchError((_) => <Map<String, dynamic>>[]);
      if (!_galleriesController.isClosed && _shouldEmit('galleries', galleries)) _galleriesController.add(galleries);

      final govEntities = await _apiService.getGovernmentEntities(forceRefresh: forceRefresh).catchError((_) => <GovernmentEntity>[]);
      if (!_governmentController.isClosed && _shouldEmit('government', govEntities)) _governmentController.add(govEntities);

      final favorites = await _apiService.getFavorites(email: effectiveEmail, forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{});
      if (!_favoritesController.isClosed && _shouldEmit('favorites', favorites)) _favoritesController.add(favorites);

      // Phase 3: Masters (Experience Levels, Locations, Publishing Pricing & Payment Settings)
      // Only fetch once at startup or when explicitly requested, as they are static admin configurations.
      if (!_hasLoadedMasters || syncMasters) {
        final experienceLevels = await _apiService.getExperienceLevels(forceRefresh: forceRefresh).catchError((_) => <ExperienceLevelModel>[]);
        if (!_experienceLevelsController.isClosed && _shouldEmit('expLevels', experienceLevels)) _experienceLevelsController.add(experienceLevels);

        final locations = await _apiService.getLocations(forceRefresh: forceRefresh).catchError((_) => <LocationModel>[]);
        if (!_locationsController.isClosed && _shouldEmit('locations', locations)) _locationsController.add(locations);

        final publishingPricing = await _apiService.getPublishingPricing(forceRefresh: forceRefresh).catchError((_) => <PublishingPricingModel>[]);
        if (!_publishingPricingController.isClosed && _shouldEmit('pricing', publishingPricing)) _publishingPricingController.add(publishingPricing);

        final paymentSettings = await _apiService.getPaymentSettings(forceRefresh: forceRefresh).catchError((_) => PaymentSettingsModel.defaultSettings());
        if (!_paymentSettingsController.isClosed && _shouldEmit('payment', paymentSettings)) _paymentSettingsController.add(paymentSettings);

        _hasLoadedMasters = true;
      }

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
    _publishingPricingController.close();
    _paymentSettingsController.close();
    _authController.close();
  }
}
