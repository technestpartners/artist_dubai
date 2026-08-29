import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/utils/validators.dart';
import 'package:artist_dubai/core/utils/date_formatter.dart';
import 'package:artist_dubai/features/artists/domain/models/artist_model.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/government/domain/models/government_entity.dart';
import 'package:artist_dubai/features/home/domain/models/dashboard_item.dart';
import 'package:artist_dubai/core/errors/exceptions.dart';
import 'package:artist_dubai/core/errors/failures.dart';

void main() {
  group('1. Core Utility & Validator Unit Tests', () {
    test('Email validator should correctly identify valid and invalid emails', () {
      expect(Validators.validateEmail('allenbaiyee@me.com'), isNull);
      expect(Validators.validateEmail('user@domain.co.ae'), isNull);
      expect(Validators.validateEmail(''), equals('Email address is required'));
      expect(Validators.validateEmail('invalid-email'), equals('Please enter a valid email address'));
      expect(Validators.validateEmail('test@'), equals('Please enter a valid email address'));
    });

    test('Password validator should enforce min length rules', () {
      expect(Validators.validatePassword('12345678'), isNull);
      expect(Validators.validatePassword('secretPass1'), isNull);
      expect(Validators.validatePassword(''), equals('Password is required'));
      expect(Validators.validatePassword('12345'), equals('Password must be at least 6 characters'));
    });

    test('Name & Required Field validators', () {
      expect(Validators.validateRequired('Allen Baiyee', 'Full Name'), isNull);
      expect(Validators.validateRequired('', 'Full Name'), equals('Full Name is required'));
      expect(Validators.validateRequired('   ', 'Location'), equals('Location is required'));
    });

    test('DateFormatter formatting utility', () {
      final now = DateTime(2026, 8, 27, 10, 30);
      final formatted = DateFormatter.formatShortDate(now);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Aug'));
    });
  });

  group('2. Domain Models Serialization & Equality Tests', () {
    test('ArtistModel instantiation & json mapping', () {
      final json = {
        'id': 1,
        'name': 'Fatima Al Qasimi',
        'category': 'Calligraphy & Typography',
        'location': 'Sharjah, UAE',
        'bio': 'Traditional calligrapher',
        'avatar_url': 'https://example.com/avatar.jpg',
        'banner_url': 'https://example.com/banner.jpg',
        'followers_count': 1200,
        'works_count': 6,
      };

      final model = ArtistModel.fromJson(json);
      expect(model.id, equals('1'));
      expect(model.name, equals('Fatima Al Qasimi'));
      expect(model.category, equals('Calligraphy & Typography'));
      expect(model.followersCount, equals(1200));

      final toJson = model.toJson();
      expect(toJson['name'], equals('Fatima Al Qasimi'));
      expect(toJson['followers_count'], equals(1200));
    });

    test('ArtEventModel instantiation & property verification', () {
      const model = ArtEventModel(
        id: 'event_10',
        title: 'Dubai Art Night',
        category: 'Exhibition',
        price: 'Free',
        description: 'Annual art gathering',
        dateTime: '2026-11-01',
        location: 'Alserkal Avenue',
        attendeesCount: 15,
        maxAttendees: 50,
        organizer: 'Dubai Culture',
        tags: ['Art', 'Dubai'],
      );

      expect(model.id, equals('event_10'));
      expect(model.title, equals('Dubai Art Night'));
      expect(model.spotsRemaining, equals(35));
    });

    test('GovernmentEntity model mapping', () {
      const entity = GovernmentEntity(
        name: 'Dubai Culture & Arts Authority',
        defaultIsOpen: true,
        rating: 4.5,
        reviewCount: 120,
        category: 'Government · Cultural Authority',
        location: 'Al Shindagha, Dubai',
        defaultTiming: 'Open · Closes at 15:00',
        websiteUrl: 'https://www.dubaiculture.gov.ae/',
        directionsUrl: 'https://maps.google.com/',
      );

      expect(entity.name, contains('Dubai Culture'));
      expect(entity.rating, equals(4.5));
      expect(entity.defaultIsOpen, isTrue);
    });

    test('DashboardItem model property integrity', () {
      const item = DashboardItem(
        title: 'Featured Artists',
        subtitle: 'Explore 500+ UAE talents',
        iconPath: 'assets/icons/artist.png',
        route: '/artists',
      );

      expect(item.title, equals('Featured Artists'));
      expect(item.route, equals('/artists'));
    });
  });

  group('3. Core Exceptions & Failures Tests', () {
    test('ServerException & ServerFailure mapping', () {
      const exception = ServerException(message: 'API Endpoint Timeout');
      expect(exception.message, equals('API Endpoint Timeout'));

      const failure = ServerFailure(message: 'Database Error');
      expect(failure.message, equals('Database Error'));
    });

    test('NetworkException & NetworkFailure mapping', () {
      const exception = NetworkException(message: 'No internet connectivity');
      expect(exception.message, equals('No internet connectivity'));

      const failure = NetworkFailure(message: 'Connection reset');
      expect(failure.message, equals('Connection reset'));
    });
  });
}
