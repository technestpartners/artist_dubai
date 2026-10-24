class OnboardingItem {
  final String title;
  final String description;
  final String emoji;
  final String? imagePath;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.emoji,
    this.imagePath,
  });

  static const List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Welcome to Artist Dubai',
      description:
          'A modern digital platform connecting artists, art lovers, galleries, museums, and cultural events across Dubai. Discover exhibitions, photography, competitions, and cultural venues—all in one place.',
      emoji: '🎨',
      imagePath: 'assets/images/about-us-DEBERP_G.jpg',
    ),
    OnboardingItem(
      title: 'Meet Local Artists',
      description:
          'Discover artists of all kinds, from emerging talents and hobby artists to established professionals. Explore their stories, connect with them directly, showcase their work, and commission unique, custom-made artworks.\n\nEvery artist deserves to be seen. Every story deserves to be shared.',
      emoji: '👨‍🎨',
      imagePath: 'assets/images/artists-9NH3TeXO.jpg',
    ),
    OnboardingItem(
      title: 'Art Events & Exhibitions',
      description:
          'Stay up to date with inspiring art events, exhibitions, and cultural happenings in Dubai and around the world. Discover exciting opportunities across Europe, America, and beyond. Explore the beauty, creativity, innovation, and diversity of the international art scene—all in one place.\n\nDiscover. Connect. Experience Art Worldwide.',
      emoji: '🌟',
      imagePath: 'assets/images/events-competition-DvLzKG_2.jpg',
    ),
    OnboardingItem(
      title: 'Explore Art Galleries in Dubai',
      description:
          'Discover Dubai’s finest art galleries with just one click. Explore gallery locations, discover current exhibitions, connect with talented artists, and experience the city’s vibrant art scene. From contemporary art spaces to internationally renowned galleries, find the best of Dubai’s art world in one place.',
      emoji: '🖼️',
      imagePath: 'assets/images/galleries-DjK8LuXg.jpg',
    ),
    OnboardingItem(
      title: 'Global Art Guide',
      description:
          'Discover artists, art history, and cultural origins in Dubai, across the UAE, and worldwide.',
      emoji: '✨',
      imagePath: 'assets/images/ai-hub.png',
    ),
  ];
}
