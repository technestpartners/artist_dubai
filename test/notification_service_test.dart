import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/local_notification_service.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:flutter/material.dart';

class _FakeStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearAuthSession() async => _data.clear();

  @override
  Future<void> deleteSecure(String key) async => _data.remove(key);

  @override
  Future<String?> readSecure(String key) async => _data[key] as String?;

  @override
  Future<void> writeSecure(String key, String value) async =>
      _data[key] = value;

  @override
  bool isMenuPermissionEnabled(String routeName) => true;

  @override
  Future<void> setMenuPermissionEnabled(
    String routeName,
    bool isEnabled,
  ) async {}

  @override
  Map<String, bool> getAllMenuPermissions() => {};

  @override
  Future<void> saveAllMenuPermissions(Map<String, bool> permissions) async {}
}

class _FakeApiService extends Fake implements ApiService {
  bool clearAllCalled = false;
  int? deletedNotificationId;

  @override
  Future<Map<String, dynamic>> getNotifications({
    String? email,
    bool forceRefresh = false,
  }) async {
    return {'notifications': [], 'unread_count': 0, 'total': 0};
  }

  @override
  Future<bool> clearAllNotifications({String? email}) async {
    clearAllCalled = true;
    return true;
  }

  @override
  Future<bool> deleteNotification(int id) async {
    deletedNotificationId = id;
    return true;
  }
}

class _FakeLocalNotificationService extends Fake implements LocalNotificationService {
  int showCallCount = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) async {
    showCallCount++;
    lastTitle = title;
    lastBody = body;
  }
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<StorageService>(_FakeStorageService());
    sl.registerSingleton<ApiService>(_FakeApiService());
    sl.registerSingleton<LocalNotificationService>(_FakeLocalNotificationService());
  });

  tearDown(() async {
    await sl.reset();
  });

  test(
    'NotificationService clearAll clears in-memory list and notifies backend',
    () async {
      final service = NotificationService();
      service.addNotification(
        title: 'Test Notification',
        body: 'Test Body',
        icon: Icons.notifications,
      );

      expect(service.notifications.length, 1);

      await service.clearAll();

      expect(service.notifications.isEmpty, true);
      final fakeApi = sl<ApiService>() as _FakeApiService;
      expect(fakeApi.clearAllCalled, true);
    },
  );

  test(
    'NotificationService dismiss removes notification and deletes on backend',
    () async {
      final service = NotificationService();
      service.addNotification(
        title: 'Notice',
        body: 'Body',
        icon: Icons.notifications,
      );

      expect(service.notifications.length, 1);
      final id = service.notifications.first.id;

      await service.dismiss(id);

      expect(service.notifications.isEmpty, true);
    },
  );

  test(
    'NotificationService isolates notifications by user email and ignores other users',
    () async {
      final storage = sl<StorageService>() as _FakeStorageService;
      await storage.setString('user_email', 'user1@test.com');

      final fakeApi = _UserSpecificFakeApi();
      await sl.reset();
      sl.registerSingleton<StorageService>(storage);
      sl.registerSingleton<ApiService>(fakeApi);
      sl.registerSingleton<LocalNotificationService>(_FakeLocalNotificationService());

      final service = NotificationService();
      await service.syncWithBackend();

      // Only user1@test.com notification should be loaded, user2@test.com must be skipped
      expect(service.notifications.length, 1);
      expect(service.notifications.first.title, 'Message for User 1');
    },
  );

  test(
    'NotificationService triggers LocalNotificationService when notification is added',
    () async {
      final fakeLocal = _FakeLocalNotificationService();
      await sl.reset();
      sl.registerSingleton<StorageService>(_FakeStorageService());
      sl.registerSingleton<ApiService>(_FakeApiService());
      sl.registerSingleton<LocalNotificationService>(fakeLocal);

      final service = NotificationService();
      service.addNotification(
        title: 'New Event Alert',
        body: 'Art Exhibition starting soon',
        type: 'event',
      );

      expect(fakeLocal.showCallCount, 1);
      expect(fakeLocal.lastTitle, 'New Event Alert');
      expect(fakeLocal.lastBody, 'Art Exhibition starting soon');
    },
  );
}

class _UserSpecificFakeApi extends Fake implements ApiService {
  @override
  Future<Map<String, dynamic>> getNotifications({
    String? email,
    bool forceRefresh = false,
  }) async {
    return {
      'notifications': [
        {
          'id': '101',
          'title': 'Message for User 1',
          'body': 'Hello User 1',
          'type': 'message',
          'user_email': 'user1@test.com',
          'is_read': 0,
        },
        {
          'id': '102',
          'title': 'Message for User 2',
          'body': 'Hello User 2',
          'type': 'message',
          'user_email': 'user2@test.com',
          'is_read': 0,
        },
      ],
      'unread_count': 2,
      'total': 2,
    };
  }

  @override
  Future<bool> clearAllNotifications({String? email}) async => true;

  @override
  Future<bool> deleteNotification(int id) async => true;
}
