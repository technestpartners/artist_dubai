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
      title: 'Welcome to Dubai Artists',
      description:
          'Discover the vibrant art scene of Dubai and connect with talented local artists',
      emoji: '🎨',
    ),
    OnboardingItem(
      title: 'Meet Local Artists',
      description:
          'Connect directly with artists, learn about their stories and commission custom works',
      emoji: '👨‍🎨',
    ),
    OnboardingItem(
      title: 'Explore Art Galleries',
      description:
          'Browse through curated collections and find your next favorite piece',
      emoji: '🖼️',
    ),
    OnboardingItem(
      title: 'Art Events & Exhibitions',
      description:
          'Stay updated with the latest art events, exhibitions and cultural happenings in Dubai',
      emoji: '🌟',
    ),
  ];
}
