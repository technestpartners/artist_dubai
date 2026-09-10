import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MenuCardItem {
  final String title;
  final String? subtitle;
  final String imagePath;
  final String routeName;

  const MenuCardItem({
    required this.title,
    this.subtitle,
    required this.imagePath,
    required this.routeName,
  });

  bool get isLongTitle => title.contains('|') || title.length > 15;

  String getLocalizedTitle(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (isAr) {
      final l10n = AppLocalizations.of(context);
      switch (routeName) {
        case '/about-us':
          return l10n.aboutUs;
        case '/artists':
          return l10n.artists;
        case '/government':
          return l10n.government;
        case '/artist-registration':
          return l10n.artistRegistration;
        case '/events':
          return l10n.eventsCompetition;
        case '/galleries':
          return l10n.galleriesArtCenter;
        case '/events-photos':
          return l10n.eventsPhotos;
        case '/gallery-registration':
          return l10n.galleryRegistration;
        default:
          return title;
      }
    }
    return title;
  }

  String? getLocalizedSubtitle(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (isAr) {
      return null;
    }
    return subtitle;
  }

  static const List<MenuCardItem> items = [
    // Row 1
    MenuCardItem(
      title: 'ABOUT US',
      imagePath: 'assets/images/about-us-DEBERP_G.jpg',
      routeName: '/about-us',
    ),
    MenuCardItem(
      title: 'ARTISTS',
      imagePath: 'assets/images/artists-9NH3TeXO.jpg',
      routeName: '/artists',
    ),

    // Row 2
    MenuCardItem(
      title: 'GOVERNMENT',
      imagePath: 'assets/images/government-CWANBIsX.jpg',
      routeName: '/government',
    ),
    MenuCardItem(
      title: 'ARTIST',
      subtitle: 'REGISTRATION',
      imagePath: 'assets/images/artist-registration-DqgORA9-.jpg',
      routeName: '/artist-registration',
    ),

    // Row 3
    MenuCardItem(
      title: 'EVENTS',
      subtitle: 'COMPETITION',
      imagePath: 'assets/images/events-competition-DvLzKG_2.jpg',
      routeName: '/events',
    ),
    MenuCardItem(
      title: 'GALLERIES',
      subtitle: 'ART CENTER',
      imagePath: 'assets/images/galleries-DjK8LuXg.jpg',
      routeName: '/galleries',
    ),

    // Row 4
    MenuCardItem(
      title: 'EVENTS',
      subtitle: 'PHOTOS',
      imagePath: 'assets/images/events-photos-CckY-T_x.jpg',
      routeName: '/events-photos',
    ),
    MenuCardItem(
      title: 'ART VENUE',
      subtitle: 'REGISTRATION',
      imagePath: 'assets/images/gallery-registration-DU8u0zfk.jpg',
      routeName: '/gallery-registration',
    ),
  ];
}
