import 'package:flutter/widgets.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class MenuPermissionModel {
  final String key;
  final String title;
  final String? subtitle;
  final String routeName;
  final String imagePath;
  final bool isEnabled;

  const MenuPermissionModel({
    required this.key,
    required this.title,
    this.subtitle,
    required this.routeName,
    required this.imagePath,
    this.isEnabled = true,
  });

  MenuPermissionModel copyWith({
    String? key,
    String? title,
    String? subtitle,
    String? routeName,
    String? imagePath,
    bool? isEnabled,
  }) {
    return MenuPermissionModel(
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      routeName: routeName ?? this.routeName,
      imagePath: imagePath ?? this.imagePath,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'route_name': routeName,
    'image_path': imagePath,
    'is_enabled': isEnabled ? 1 : 0,
  };

  factory MenuPermissionModel.fromJson(Map<String, dynamic> json) {
    return MenuPermissionModel(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      routeName: json['route_name']?.toString() ?? json['routeName']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? json['imagePath']?.toString() ?? '',
      isEnabled: json['is_enabled'] == null ||
          json['is_enabled'] == 1 ||
          json['is_enabled'] == '1' ||
          json['is_enabled'] == true,
    );
  }

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
        case '/ai':
          return 'الذكاء الاصطناعي';
        case '/login':
          return l10n.logIn;
        default:
          return title;
      }
    }
    return title;
  }

  static List<MenuPermissionModel> defaultPermissions() {
    return const [
      MenuPermissionModel(
        key: 'about_us',
        title: 'ABOUT US',
        routeName: '/about-us',
        imagePath: 'assets/images/about-us-DEBERP_G.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'artists',
        title: 'ARTISTS',
        routeName: '/artists',
        imagePath: 'assets/images/artists-9NH3TeXO.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'government',
        title: 'GOVERNMENT',
        routeName: '/government',
        imagePath: 'assets/images/government-CWANBIsX.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'artist_registration',
        title: 'ARTIST REGISTRATION',
        subtitle: 'REGISTRATION',
        routeName: '/artist-registration',
        imagePath: 'assets/images/artist-registration-DqgORA9-.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'events_competition',
        title: 'EVENTS COMPETITION',
        subtitle: 'COMPETITION',
        routeName: '/events',
        imagePath: 'assets/images/events-competition-DvLzKG_2.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'galleries_art_center',
        title: 'GALLERIES ART CENTER',
        subtitle: 'ART CENTER',
        routeName: '/galleries',
        imagePath: 'assets/images/galleries-DjK8LuXg.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'events_photos',
        title: 'EVENTS PHOTOS',
        subtitle: 'PHOTOS',
        routeName: '/events-photos',
        imagePath: 'assets/images/events-photos-CckY-T_x.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'gallery_registration',
        title: 'GALLERIES | ART CENTERS REGISTRATION',
        subtitle: 'REGISTRATION',
        routeName: '/gallery-registration',
        imagePath: 'assets/images/gallery-registration-DU8u0zfk.jpg',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'login_portal',
        title: 'LOGIN',
        subtitle: 'PORTAL',
        routeName: '/login',
        imagePath: 'assets/images/login-portal.png',
        isEnabled: true,
      ),
      MenuPermissionModel(
        key: 'ai_art',
        title: 'AI',
        subtitle: 'Art | Artist',
        routeName: '/ai',
        imagePath: 'assets/images/ai-hub.png',
        isEnabled: true,
      ),
    ];
  }
}
