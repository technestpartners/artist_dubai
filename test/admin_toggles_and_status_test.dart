import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/artists/domain/models/artist_model.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/government/domain/models/government_entity.dart';

void main() {
  group('Admin Toggles - Status & Open/Closed Model Tests', () {
    test('ArtistModel isActive handles all permutations correctly', () {
      // 1. Explicitly inactive via is_active = 0
      final a1 = ArtistModel.fromJson({'id': 1, 'name': 'Artist 1', 'is_active': 0, 'status': 'active'});
      expect(a1.isActive, isFalse);

      // 2. Explicitly inactive via is_active = '0'
      final a2 = ArtistModel.fromJson({'id': 2, 'name': 'Artist 2', 'is_active': '0'});
      expect(a2.isActive, isFalse);

      // 3. Explicitly inactive via status = 'inactive'
      final a3 = ArtistModel.fromJson({'id': 3, 'name': 'Artist 3', 'status': 'inactive', 'is_active': 1});
      expect(a3.isActive, isFalse);

      // 4. Explicitly active via is_active = 1
      final a4 = ArtistModel.fromJson({'id': 4, 'name': 'Artist 4', 'is_active': 1, 'status': 'active'});
      expect(a4.isActive, isTrue);

      // 5. Default when is_active is null and status is null -> defaults to active
      final a5 = ArtistModel.fromJson({'id': 5, 'name': 'Artist 5'});
      expect(a5.isActive, isTrue);
    });

    test('ArtEventModel isActive handles active/inactive correctly', () {
      final evInactive = ArtEventModel.fromJson({
        'id': '10',
        'title': 'Past Event',
        'is_active': 0,
        'status': 'inactive',
      });
      expect(evInactive.isActive, isFalse);

      final evActive = ArtEventModel.fromJson({
        'id': '11',
        'title': 'Live Event',
        'is_active': 1,
        'status': 'active',
      });
      expect(evActive.isActive, isTrue);
    });

    test('GovernmentEntity defaultIsOpen and isCurrentlyOpen handle overrides', () {
      // 1. Admin toggles entity closed (defaultIsOpen = false)
      final closedEntity = GovernmentEntity.fromJson({
        'id': 1,
        'name': 'Dubai Culture',
        'default_is_open': 0,
        'is_open': false,
        'open_hour': 0,
        'close_hour': 24, // Operating hours encompass entire day
      });
      expect(closedEntity.defaultIsOpen, isFalse);
      expect(closedEntity.isCurrentlyOpen, isFalse);

      // 2. Entity open
      final openEntity = GovernmentEntity.fromJson({
        'id': 2,
        'name': 'Alserkal Avenue',
        'default_is_open': 1,
        'is_open': true,
      });
      expect(openEntity.defaultIsOpen, isTrue);
      expect(openEntity.isCurrentlyOpen, isTrue);
    });
  });
}
