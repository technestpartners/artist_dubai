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
      title: 'Welcome to ⚜️ Artist Dubai ⚜️',
      description:
          'A modern digital platform connecting artists, art lovers, galleries, museums, and cultural events across Dubai. Discover exhibitions, photography, competitions, and cultural venues—all in one place.\n\nComing soon, don\'t miss out!',
      emoji: '🎨',
      imagePath: 'assets/icons/dashboard/about_us.png',
    ),
    OnboardingItem(
      title: 'Meet Local Artists',
      description:
          'Connect directly with artists, learn about their stories and commission custom works',
      emoji: '👨‍🎨',
      imagePath: 'assets/icons/dashboard/artists.png',
    ),
    OnboardingItem(
      title: 'Explore Art Galleries',
      description:
          'Browse through curated collections and find your next favorite piece',
      emoji: '🖼️',
      imagePath: 'assets/icons/dashboard/galleries.png',
    ),
    OnboardingItem(
      title: 'Art Events & Exhibitions',
      description:
          'Stay updated with the latest art events, exhibitions and cultural happenings in Dubai',
      emoji: '🌟',
      imagePath: 'assets/icons/dashboard/events_competition.png',
    ),
  ];
}
