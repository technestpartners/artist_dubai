class DashboardItem {
  final String title;
  final String? subtitle;
  final String iconPath;
  final String? imagePath;
  final String route;

  const DashboardItem({
    required this.title,
    this.subtitle,
    required this.iconPath,
    this.imagePath,
    required this.route,
  });

  static const List<DashboardItem> items = [
    DashboardItem(
      title: 'ABOUT US',
      iconPath: 'assets/icons/dashboard/about_us.png',
      imagePath: 'assets/images/about-us-DEBERP_G.jpg',
      route: '/about-us',
    ),
    DashboardItem(
      title: 'ARTISTS',
      iconPath: 'assets/icons/dashboard/artists.png',
      imagePath: 'assets/images/artists-9NH3TeXO.jpg',
      route: '/artists',
    ),
    DashboardItem(
      title: 'GOVERNMENT',
      iconPath: 'assets/icons/dashboard/government.png',
      imagePath: 'assets/images/government-CWANBIsX.jpg',
      route: '/government',
    ),
    DashboardItem(
      title: 'ARTIST',
      subtitle: 'REGISTRATION',
      iconPath: 'assets/icons/dashboard/artist_registration.png',
      imagePath: 'assets/images/artist-registration-DqgORA9-.jpg',
      route: '/artist-registration',
    ),
    DashboardItem(
      title: 'EVENTS',
      subtitle: 'COMPETITION',
      iconPath: 'assets/icons/dashboard/events_competition.png',
      imagePath: 'assets/images/events-competition-DvLzKG_2.jpg',
      route: '/events-competition',
    ),
    DashboardItem(
      title: 'GALLERIES',
      subtitle: 'ART CENTER',
      iconPath: 'assets/icons/dashboard/galleries.png',
      imagePath: 'assets/images/galleries-DjK8LuXg.jpg',
      route: '/galleries',
    ),
    DashboardItem(
      title: 'EVENTS',
      subtitle: 'PHOTOS',
      iconPath: 'assets/icons/dashboard/events_photos.png',
      imagePath: 'assets/images/events-photos-CckY-T_x.jpg',
      route: '/events-photos',
    ),
    DashboardItem(
      title: 'GALLERIES | ART CENTERS',
      subtitle: 'REGISTRATION',
      iconPath: 'assets/icons/dashboard/galleries_registration.png',
      imagePath: 'assets/images/gallery-registration-DU8u0zfk.jpg',
      route: '/gallery-registration',
    ),
  ];
}
