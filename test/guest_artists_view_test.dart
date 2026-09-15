import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/artists/domain/models/artist_model.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/utils/data_translator.dart';
import 'package:dio/dio.dart';

class MockFailingApiClient implements ApiClient {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Network connection failed',
      type: DioExceptionType.connectionError,
    );
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();

  @override
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();
}

void main() {
  group('Guest / Non-Logged-In Artist Browsing Verification', () {
    test('ArtistModel.mockArtists provides a rich roster of artists across Dubai categories', () {
      final artists = ArtistModel.mockArtists;
      expect(artists.length, greaterThanOrEqualTo(8));
      
      // Verify active status and non-empty fields
      for (final artist in artists) {
        expect(artist.isActive, isTrue);
        expect(artist.name, isNotEmpty);
        expect(artist.category, isNotEmpty);
        expect(artist.location, isNotEmpty);
      }

      // Verify category coverage
      final categories = artists.map((a) => a.category).toSet();
      expect(categories, contains('Arabic Calligraphy'));
      expect(categories, contains('Contemporary Painting'));
      expect(categories, contains('Digital Art & Sculpture'));
      expect(categories, contains('Abstract Painting'));
      expect(categories, contains('Photography'));
      expect(categories, contains('Ceramics & Pottery'));
    });

    test('ApiService.getArtists() falls back to mock artists for guest users on offline/empty cache', () async {
      final failingClient = MockFailingApiClient();
      final apiService = ApiService(failingClient);

      // Verify cache is initially empty
      expect(apiService.cachedArtists, isNull);

      // Attempt to get artists
      final artists = await apiService.getArtists(forceRefresh: true);
      expect(artists, isNotEmpty);
      expect(artists.length, greaterThanOrEqualTo(8));
      expect(artists.first.name, isNotEmpty);
    });

    test('ApiService.getArtistsPaged() falls back to mock artists for guest users', () async {
      final failingClient = MockFailingApiClient();
      final apiService = ApiService(failingClient);

      final pagedResult = await apiService.getArtistsPaged(page: 1, limit: 10);
      expect(pagedResult.data, isNotEmpty);
      expect(pagedResult.data.length, greaterThanOrEqualTo(8));
    });

    test('DataTranslator translates mock artist categories seamlessly to Arabic', () {
      expect(
        DataTranslator.translate('Arabic Calligraphy', isArabic: true),
        equals('الخط العربي'),
      );
      expect(
        DataTranslator.translate('Contemporary Painting', isArabic: true),
        equals('الرسم المعاصر'),
      );
      expect(
        DataTranslator.translate('Digital Art & Sculpture', isArabic: true),
        equals('الفن الرقمي والنحت'),
      );
      expect(
        DataTranslator.translate('Ceramics & Pottery', isArabic: true),
        equals('الخزف والفخار'),
      );
    });
  });
}
