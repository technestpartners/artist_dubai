import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/onboarding/domain/models/onboarding_item.dart';
import 'package:artist_dubai/features/home/domain/models/menu_card_item.dart';
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';

void main() {
  group('Section Ordering and Consistency Tests', () {
    test('Onboarding items follow exact specified sequence', () {
      final items = OnboardingItem.items;
      expect(items.length, 5);

      // 1. Welcome
      expect(items[0].title, contains('Welcome'));

      // 2. Meet Local Artists
      expect(items[1].title, 'Meet Local Artists');
      expect(items[1].description, contains('Discover artists of all kinds'));
      expect(items[1].description, contains('Every artist deserves to be seen. Every story deserves to be shared.'));

      // 3. Art Events & Exhibitions
      expect(items[2].title, 'Art Events & Exhibitions');
      expect(items[2].description, contains('Stay up to date with inspiring art events'));
      expect(items[2].description, contains('Discover. Connect. Experience Art Worldwide.'));

      // 4. Explore Art Galleries in Dubai
      expect(items[3].title, 'Explore Art Galleries in Dubai');
      expect(items[3].description, contains('Discover Dubai’s finest art galleries with just one click.'));

      // 5. Global Art Guide – Artists, History & Origins
      expect(items[4].title, 'Global Art Guide – Artists, History & Origins');
      expect(items[4].description, contains('Discover artists, art history, and cultural origins'));
    });

    test('Home MenuCardItems maintain logical sequence', () {
      final cards = MenuCardItem.items;
      expect(cards.length, 10);

      // Core pillars sequence: Artists -> Events -> Galleries -> AI / Global Guide
      final artistIndex = cards.indexWhere((c) => c.routeName == '/artists');
      final eventIndex = cards.indexWhere((c) => c.routeName == '/events');
      final galleryIndex = cards.indexWhere((c) => c.routeName == '/galleries');
      final aiIndex = cards.indexWhere((c) => c.routeName == '/ai');

      expect(artistIndex, isNonNegative);
      expect(eventIndex, isNonNegative);
      expect(galleryIndex, isNonNegative);
      expect(aiIndex, isNonNegative);

      // Assert sequential ordering of pillars
      expect(artistIndex < eventIndex, isTrue);
      expect(eventIndex < galleryIndex, isTrue);
      expect(galleryIndex < aiIndex, isTrue);
    });

    test('AdminTab enum maintains domain sequence', () {
      const tabs = AdminTab.values;
      final artistIndex = tabs.indexOf(AdminTab.artists);
      final eventIndex = tabs.indexOf(AdminTab.events);
      final galleryIndex = tabs.indexOf(AdminTab.galleries);

      expect(artistIndex < eventIndex, isTrue);
      expect(eventIndex < galleryIndex, isTrue);
    });
  });
}
