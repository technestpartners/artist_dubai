import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/admin/domain/models/menu_permission_model.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Menu Permission & Coming Soon Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const secure = FlutterSecureStorage();
      storage = StorageServiceImpl(prefs: prefs, secureStorage: secure);
      if (sl.isRegistered<StorageService>()) {
        sl.unregister<StorageService>();
      }
      sl.registerSingleton<StorageService>(storage);
    });

    test('All default menu permissions are enabled by default', () {
      final defaults = MenuPermissionModel.defaultPermissions();
      expect(defaults.length, 10);

      for (final item in defaults) {
        expect(storage.isMenuPermissionEnabled(item.routeName), isTrue);
      }
    });

    test('Disabling a menu permission is stored and detected correctly', () async {
      // Turn OFF artists permission
      await storage.setMenuPermissionEnabled('/artists', false);

      expect(storage.isMenuPermissionEnabled('/artists'), isFalse);
      expect(storage.isMenuPermissionEnabled('/government'), isTrue);

      // Turn OFF events permission (also covers /events-competition)
      await storage.setMenuPermissionEnabled('/events', false);
      expect(storage.isMenuPermissionEnabled('/events'), isFalse);
      expect(storage.isMenuPermissionEnabled('/events-competition'), isFalse);

      // Re-enable
      await storage.setMenuPermissionEnabled('/artists', true);
      expect(storage.isMenuPermissionEnabled('/artists'), isTrue);
    });

    test('MenuPermissionModel serialization and localized titles', () {
      final item = const MenuPermissionModel(
        key: 'artists',
        title: 'ARTISTS',
        routeName: '/artists',
        imagePath: 'assets/images/artists-9NH3TeXO.jpg',
        isEnabled: false,
      );

      final json = item.toJson();
      expect(json['key'], 'artists');
      expect(json['is_enabled'], 0);

      final reconstructed = MenuPermissionModel.fromJson(json);
      expect(reconstructed.key, 'artists');
      expect(reconstructed.isEnabled, isFalse);
      expect(reconstructed.routeName, '/artists');
    });
  });
}
