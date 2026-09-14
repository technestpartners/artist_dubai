import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/utils/share_helper.dart';
import 'package:artist_dubai/app/routes/route_names.dart';
import 'package:artist_dubai/app/routes/app_router.dart';
import 'package:artist_dubai/core/constants/api_endpoints.dart';

void main() {
  group('Share System & Deep Linking Unit Tests', () {
    test('Share URLs point to api.php with resource=share and correct query parameters', () {
      final artistUrl = ShareHelper.getArtistShareUrl('42');
      expect(artistUrl, contains('api.php?resource=share&artist=42'));

      final eventUrl = ShareHelper.getEventShareUrl('88');
      expect(eventUrl, contains('api.php?resource=share&event=88'));

      final artworkUrl = ShareHelper.getArtworkShareUrl('101', artistId: '42');
      expect(artworkUrl, contains('api.php?resource=share&artist=42&artwork=101'));

      final artworkSoloUrl = ShareHelper.getArtworkShareUrl('101');
      expect(artworkSoloUrl, contains('api.php?resource=share&artwork=101'));

      final galleryUrl = ShareHelper.getGalleryShareUrl('7');
      expect(galleryUrl, contains('api.php?resource=share&gallery=7'));

      final profileUrl = ShareHelper.getProfileShareUrl(profileId: 'john');
      expect(profileUrl, contains('api.php?resource=share&profile=john'));
    });

    test('RouteNames helper generators generate valid route strings', () {
      expect(RouteNames.artistDetailWithId('99'), '/artist/99');
      expect(RouteNames.eventDetailWithId('105'), '/event-detail?id=105');
    });

    test('resolveImageUrl correctly resolves relative and absolute paths', () {
      expect(ShareHelper.resolveImageUrl(null), isNull);
      expect(ShareHelper.resolveImageUrl(''), isNull);

      const absoluteUrl = 'https://images.unsplash.com/photo-1541701494587-cb58502866ab';
      expect(ShareHelper.resolveImageUrl(absoluteUrl), absoluteUrl);

      const relativePath = 'uploads/artworks/art_123.jpg';
      final resolved = ShareHelper.resolveImageUrl(relativePath);
      expect(resolved, isNotNull);
      expect(resolved!, startsWith(ApiEndpoints.baseUrl));
      expect(resolved, endsWith(relativePath));
    });

    test('AppRouter.parseDeepLink parses both web and custom scheme deep links', () {
      // api.php links (Single backend file architecture)
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/api.php?resource=share&artist=18')),
        '/artist/18',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/api.php?resource=share&event=42')),
        '/event-detail?id=42',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/api.php?resource=share&artist=18&artwork=99')),
        '/artist/18?artwork=99',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/api.php?resource=share&gallery=3')),
        '/galleries?id=3',
      );

      // share.php backward compatibility
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/share.php?artist=18')),
        '/artist/18',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('https://technestpartners.com/api/share.php?event=42')),
        '/event-detail?id=42',
      );

      // Custom scheme deep links (artistdubai://)
      expect(
        AppRouter.parseDeepLink(Uri.parse('artistdubai://artist/18')),
        '/artist/18',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('artistdubai://event/55')),
        '/event-detail?id=55',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('artistdubai://gallery/3')),
        '/galleries?id=3',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('artistdubai://artwork/77')),
        '/artworks?id=77',
      );
      expect(
        AppRouter.parseDeepLink(Uri.parse('artistdubai://profile')),
        '/profile',
      );
    });
  });
}
