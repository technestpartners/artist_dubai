import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/favorites_service.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await sl.reset();
    await initDependencyInjection();
  });

  group('FavoritesService Tests', () {
    test('Toggling favorites updates state and persists immediately to SharedPreferences', () async {
      final service = sl<FavoritesService>();
      final storage = sl<StorageService>();

      expect(service.isEventFavorite('2'), isFalse);

      // Toggle favorite on
      final isFavNow = await service.toggleEventFavorite('2');
      expect(isFavNow, isTrue);
      expect(service.isEventFavorite('2'), isTrue);

      // Verify stored in SharedPreferences
      final storedJson = storage.getString('local_fav_event_ids');
      expect(storedJson, isNotNull);
      final list = jsonDecode(storedJson!) as List;
      expect(list, contains('2'));

      // Toggle favorite off
      final isFavAfter = await service.toggleEventFavorite('2');
      expect(isFavAfter, isFalse);
      expect(service.isEventFavorite('2'), isFalse);

      final storedJsonAfter = storage.getString('local_fav_event_ids');
      final listAfter = jsonDecode(storedJsonAfter!) as List;
      expect(listAfter, isNot(contains('2')));
    });

    test('updateFromServer merges new favorites without wiping out locally toggled ones', () async {
      final service = sl<FavoritesService>();

      // User marked event '10' as favorite locally
      await service.toggleEventFavorite('10');
      expect(service.isEventFavorite('10'), isTrue);

      // Background server poll returns only event '5' (server does not know about '10' yet)
      service.updateFromServer({
        'event_ids': ['5'],
      });

      // Both '10' and '5' must be present!
      expect(service.isEventFavorite('10'), isTrue);
      expect(service.isEventFavorite('5'), isTrue);
    });

    test('Artist and Artwork favorites persist properly and support guest ID', () async {
      final service = sl<FavoritesService>();
      final storage = sl<StorageService>();

      expect(service.getEffectiveEmail(), contains('@artistdubai.com'));

      await service.toggleArtistFavorite('artist_1');
      await service.toggleArtworkFavorite('artwork_42');

      expect(service.isArtistFavorite('artist_1'), isTrue);
      expect(service.isArtworkFavorite('artwork_42'), isTrue);

      // Check SharedPreferences
      final storedArtists = jsonDecode(storage.getString('local_fav_artist_ids')!) as List;
      expect(storedArtists, contains('artist_1'));

      final storedArtworks = jsonDecode(storage.getString('local_fav_artwork_ids')!) as List;
      expect(storedArtworks, contains('artwork_42'));
    });
  });
}
