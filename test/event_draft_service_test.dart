import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/event_draft_service.dart';
import 'package:artist_dubai/features/events/domain/models/event_draft_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    if (sl.isRegistered<StorageService>()) {
      sl.unregister<StorageService>();
    }
    sl.registerSingleton<StorageService>(
      StorageServiceImpl(prefs: prefs, secureStorage: secureStorage),
    );
  });

  group('EventDraftModel Tests', () {
    test('Serializes to and from JSON correctly', () {
      final model = EventDraftModel(
        title: 'Dubai Modern Art Night',
        subtitle: 'Art Exhibition • Alserkal Avenue',
        description: 'An exclusive gathering of contemporary artists.',
        category: 'Art Exhibition',
        eventDate: '2026-11-20',
        endDate: '2026-11-22',
        location: 'Alserkal Avenue, Dubai',
        venue: 'Warehouse 42',
        isFree: true,
        price: 'Free Entry',
        maxAttendees: 250,
        organizerName: 'Mona Art Studio',
        contactEmail: 'mona@artdubai.com',
        contactPhone: '+971501234567',
        tags: 'contemporary, modern, gallery',
        imageUrl: 'https://technestpartners.com/api/uploads/sample.jpg',
        planId: 'six_month',
        planName: '6 Months Plan (180 Days)',
        planAmount: 'AED 4,500',
        rawFormData: {
          'title': 'Dubai Modern Art Night',
          'description': 'An exclusive gathering of contemporary artists.',
          'category': 'Art Exhibition',
          'event_date': '2026-11-20',
          'planId': 'six_month',
        },
      );

      final encoded = model.encode();
      final decoded = EventDraftModel.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.title, 'Dubai Modern Art Night');
      expect(decoded.category, 'Art Exhibition');
      expect(decoded.location, 'Alserkal Avenue, Dubai');
      expect(decoded.maxAttendees, 250);
      expect(decoded.planId, 'six_month');
      expect(decoded.planAmount, 'AED 4,500');

      final paymentArgs = decoded.toPaymentArgs();
      expect(paymentArgs['itemType'], 'event');
      expect(paymentArgs['title'], 'Dubai Modern Art Night');
      expect(paymentArgs['planId'], 'six_month');
      expect(paymentArgs['planAmount'], 'AED 4,500');
      expect(paymentArgs['formData'], isA<Map>());
    });
  });

  group('EventDraftService Tests', () {
    test('Saves, retrieves, and clears event draft', () async {
      expect(EventDraftService.hasDraft(), isFalse);

      await EventDraftService.saveDraft(
        title: 'Expo City Sculpture Walk',
        subtitle: 'Sculpture Showcase • Expo City Dubai',
        planId: 'yearly',
        planName: 'Yearly Plan (365 Days)',
        planAmount: 'AED 6,500',
        formData: {
          'title': 'Expo City Sculpture Walk',
          'category': 'Sculpture & Installations',
          'location': 'Expo City Dubai',
          'event_date': '2026-12-01',
          'contact_email': 'artist@dubai.ae',
        },
        userEmail: 'artist@dubai.ae',
      );

      expect(EventDraftService.hasDraft('artist@dubai.ae'), isTrue);

      final retrieved = EventDraftService.getDraft('artist@dubai.ae');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Expo City Sculpture Walk');
      expect(retrieved.planId, 'yearly');
      expect(retrieved.planAmount, 'AED 6,500');

      await EventDraftService.clearDraft('artist@dubai.ae');
      expect(EventDraftService.hasDraft('artist@dubai.ae'), isFalse);
    });

    test('Draft persists across fallback active key', () async {
      await EventDraftService.saveDraft(
        title: 'Guest Event Without Email',
        planId: 'monthly',
        planName: 'Monthly Plan (30 Days)',
        planAmount: 'AED 500',
        formData: {
          'title': 'Guest Event Without Email',
          'location': 'Downtown Dubai',
        },
      );

      final draft = EventDraftService.getDraft();
      expect(draft, isNotNull);
      expect(draft!.title, 'Guest Event Without Email');
      expect(draft.planAmount, 'AED 500');

      await EventDraftService.clearDraft();
      expect(EventDraftService.getDraft(), isNull);
    });
  });

  group('MyEventsView Draft Rendering Widget Tests', () {
    testWidgets('Renders draft card and Continue Payment button when draft exists',
        (tester) async {
      await EventDraftService.saveDraft(
        title: 'Dubai Twilight Art Gala',
        subtitle: 'Art Exhibition • Dubai Marina',
        planId: 'six_month',
        planName: '6 Months Plan (180 Days)',
        planAmount: 'AED 4,500',
        formData: {
          'title': 'Dubai Twilight Art Gala',
          'category': 'Art Exhibition',
          'location': 'Dubai Marina',
          'event_date': '2026-11-25',
          'contact_email': 'testuser@artistdubai.com',
        },
        userEmail: 'testuser@artistdubai.com',
      );

      final draft = EventDraftService.getDraft('testuser@artistdubai.com');
      expect(draft, isNotNull);
      expect(draft!.title, 'Dubai Twilight Art Gala');
      expect(draft.planAmount, 'AED 4,500');
    });
  });
}

