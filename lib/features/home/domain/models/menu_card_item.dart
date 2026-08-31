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
      title: 'Gal | Art Center',
      subtitle: 'Registration',
      imagePath: 'assets/images/gallery-registration-DU8u0zfk.jpg',
      routeName: '/gallery-registration',
    ),
  ];
}
