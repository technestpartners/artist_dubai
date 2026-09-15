import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/events/domain/models/art_event_model.dart';
import 'api_service.dart';
import 'live_sync_service.dart';
import 'storage_service.dart';

/// Centralized, persistent Favorites Service that provides:
/// 1. Instant optimistic UI updates
/// 2. Permanent local SharedPreferences persistence (survives screen navigation, guest mode, & restarts)
/// 3. Asynchronous background synchronization with backend (MySQL)
/// 4. Merge-safe sync so background polling NEVER wipes out user favorites
class FavoritesService extends ChangeNotifier {
  final StorageService _storage;
  final ApiService _api;
  final LiveSyncService _liveSync;

  static const String _keyFavEvents = 'local_fav_event_ids';
  static const String _keyFavArtists = 'local_fav_artist_ids';
  static const String _keyFavArtworks = 'local_fav_artwork_ids';

  final Set<String> _eventIds = {};
  final Set<String> _artistIds = {};
  final Set<String> _artworkIds = {};

  StreamSubscription<Map<String, dynamic>>? _liveSyncSub;

  Set<String> get eventIds => Set.unmodifiable(_eventIds);
  Set<String> get artistIds => Set.unmodifiable(_artistIds);
  Set<String> get artworkIds => Set.unmodifiable(_artworkIds);

  FavoritesService({
    required StorageService storage,
    required ApiService api,
    required LiveSyncService liveSync,
  })  : _storage = storage,
        _api = api,
        _liveSync = liveSync {
    _loadFromLocal();
    _listenToLiveSync();
    refreshFromServer();
  }

  void _loadFromLocal() {
    try {
      final evJson = _storage.getString(_keyFavEvents);
      if (evJson != null && evJson.isNotEmpty) {
        final list = (jsonDecode(evJson) as List<dynamic>).map((e) => e.toString().trim());
        _eventIds.addAll(list.where((e) => e.isNotEmpty));
      }

      final arJson = _storage.getString(_keyFavArtists);
      if (arJson != null && arJson.isNotEmpty) {
        final list = (jsonDecode(arJson) as List<dynamic>).map((e) => e.toString().trim());
        _artistIds.addAll(list.where((e) => e.isNotEmpty));
      }

      final awJson = _storage.getString(_keyFavArtworks);
      if (awJson != null && awJson.isNotEmpty) {
        final list = (jsonDecode(awJson) as List<dynamic>).map((e) => e.toString().trim());
        _artworkIds.addAll(list.where((e) => e.isNotEmpty));
      }
    } catch (_) {}
  }

  void _saveToLocal() {
    try {
      _storage.setString(_keyFavEvents, jsonEncode(_eventIds.toList()));
      _storage.setString(_keyFavArtists, jsonEncode(_artistIds.toList()));
      _storage.setString(_keyFavArtworks, jsonEncode(_artworkIds.toList()));
    } catch (_) {}
  }

  String getEffectiveEmail() {
    try {
      String? email = _storage.getString('user_email');
      if (email != null && email.isNotEmpty) return email.trim();
      email = _storage.getString('device_guest_id');
      if (email != null && email.isNotEmpty) return email.trim();
      final newId = 'guest_${DateTime.now().millisecondsSinceEpoch}@artistdubai.com';
      _storage.setString('device_guest_id', newId);
      return newId;
    } catch (_) {
      return 'user@artistdubai.com';
    }
  }

  bool isEventFavorite(String id) => _eventIds.contains(id.trim());
  bool isArtistFavorite(String id) => _artistIds.contains(id.trim());
  bool isArtworkFavorite(String id) => _artworkIds.contains(id.trim());

  /// Toggle event favorite with instant local persistence and backend sync
  Future<bool> toggleEventFavorite(String rawId) async {
    final id = rawId.trim();
    final willBeFavorite = !_eventIds.contains(id);

    if (willBeFavorite) {
      _eventIds.add(id);
    } else {
      _eventIds.remove(id);
    }
    _saveToLocal();
    notifyListeners();

    final email = getEffectiveEmail();
    try {
      await _api.toggleFavorite(
        email: email,
        itemType: 'event',
        itemId: id,
      );
    } catch (_) {}

    return willBeFavorite;
  }

  /// Toggle artist favorite with instant local persistence and backend sync
  Future<bool> toggleArtistFavorite(String rawId) async {
    final id = rawId.trim();
    final willBeFavorite = !_artistIds.contains(id);

    if (willBeFavorite) {
      _artistIds.add(id);
    } else {
      _artistIds.remove(id);
    }
    _saveToLocal();
    notifyListeners();

    final email = getEffectiveEmail();
    try {
      await _api.likeArtist(
        artistId: id,
        userEmail: email,
        action: willBeFavorite ? 'like' : 'unlike',
      );
      await _api.toggleFavorite(
        email: email,
        itemType: 'artist',
        itemId: id,
      );
    } catch (_) {}

    return willBeFavorite;
  }

  /// Toggle artwork favorite with instant local persistence and backend sync
  Future<bool> toggleArtworkFavorite(String rawId) async {
    final id = rawId.trim();
    final willBeFavorite = !_artworkIds.contains(id);

    if (willBeFavorite) {
      _artworkIds.add(id);
    } else {
      _artworkIds.remove(id);
    }
    _saveToLocal();
    notifyListeners();

    final email = getEffectiveEmail();
    try {
      await _api.toggleFavorite(
        email: email,
        itemType: 'artwork',
        itemId: id,
      );
    } catch (_) {}

    return willBeFavorite;
  }

  /// Merge favorites received from backend into local set
  /// Note: We union/merge so background polling does not erase newly added favorites
  void updateFromServer(Map<String, dynamic> favData) {
    if (favData.isEmpty) return;

    final serverEvIds = <String>{};
    if (favData['event_ids'] is List) {
      for (final item in favData['event_ids'] as List) {
        final s = item.toString().trim();
        if (s.isNotEmpty) serverEvIds.add(s);
      }
    }
    if (favData['events'] is List) {
      for (final ev in favData['events'] as List) {
        if (ev is ArtEventModel) {
          serverEvIds.add(ev.id.trim());
        } else if (ev is Map<String, dynamic> && ev['id'] != null) {
          serverEvIds.add(ev['id'].toString().trim());
        }
      }
    }

    final serverArIds = <String>{};
    if (favData['artist_ids'] is List) {
      for (final item in favData['artist_ids'] as List) {
        final s = item.toString().trim();
        if (s.isNotEmpty) serverArIds.add(s);
      }
    }
    if (favData['artists'] is List) {
      for (final ar in favData['artists'] as List) {
        if (ar is ArtistModel) {
          serverArIds.add(ar.id.trim());
        } else if (ar is Map<String, dynamic> && ar['id'] != null) {
          serverArIds.add(ar['id'].toString().trim());
        }
      }
    }

    final serverAwIds = <String>{};
    if (favData['artwork_ids'] is List) {
      for (final item in favData['artwork_ids'] as List) {
        final s = item.toString().trim();
        if (s.isNotEmpty) serverAwIds.add(s);
      }
    }
    if (favData['artworks'] is List) {
      for (final aw in favData['artworks'] as List) {
        if (aw is Map<String, dynamic> && aw['id'] != null) {
          serverAwIds.add(aw['id'].toString().trim());
        }
      }
    }

    bool changed = false;
    if (serverEvIds.isNotEmpty) {
      final before = _eventIds.length;
      _eventIds.addAll(serverEvIds);
      if (_eventIds.length != before) changed = true;
    }
    if (serverArIds.isNotEmpty) {
      final before = _artistIds.length;
      _artistIds.addAll(serverArIds);
      if (_artistIds.length != before) changed = true;
    }
    if (serverAwIds.isNotEmpty) {
      final before = _artworkIds.length;
      _artworkIds.addAll(serverAwIds);
      if (_artworkIds.length != before) changed = true;
    }

    if (changed) {
      _saveToLocal();
      notifyListeners();
    }
  }

  void addServerArtistIds(Iterable<String> ids) {
    final clean = ids.map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (clean.isEmpty) return;
    final before = _artistIds.length;
    _artistIds.addAll(clean);
    if (_artistIds.length != before) {
      _saveToLocal();
      notifyListeners();
    }
  }

  void addServerEventIds(Iterable<String> ids) {
    final clean = ids.map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (clean.isEmpty) return;
    final before = _eventIds.length;
    _eventIds.addAll(clean);
    if (_eventIds.length != before) {
      _saveToLocal();
      notifyListeners();
    }
  }

  void addServerArtworkIds(Iterable<String> ids) {
    final clean = ids.map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (clean.isEmpty) return;
    final before = _artworkIds.length;
    _artworkIds.addAll(clean);
    if (_artworkIds.length != before) {
      _saveToLocal();
      notifyListeners();
    }
  }

  void _listenToLiveSync() {
    _liveSyncSub?.cancel();
    _liveSyncSub = _liveSync.favoritesStream.listen((favData) {
      updateFromServer(favData);
    });
  }

  Future<void> refreshFromServer() async {
    try {
      final email = getEffectiveEmail();
      final fresh = await _api.getFavorites(email: email, forceRefresh: true);
      updateFromServer(fresh);
    } catch (_) {}
  }

  @override
  void dispose() {
    _liveSyncSub?.cancel();
    super.dispose();
  }
}
