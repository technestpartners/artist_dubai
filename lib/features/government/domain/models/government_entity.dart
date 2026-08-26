class GovernmentEntity {
  final String name;
  final bool defaultIsOpen;
  final double rating;
  final int reviewCount;
  final String category;
  final String location;
  final String defaultTiming;
  final String websiteUrl;
  final String directionsUrl;
  final String? googleMapsReviewsUrl;
  
  // Operating hours in 24h format for dynamic status calculation (Dubai GST: UTC+4)
  final int? openHour;
  final int? openMinute;
  final int? closeHour;
  final int? closeMinute;
  final List<int>? closedDays; // 1=Mon, 7=Sun (e.g. [6, 7] for Sat/Sun)
  final String? seasonalNotice;

  const GovernmentEntity({
    required this.name,
    required this.defaultIsOpen,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.location,
    required this.defaultTiming,
    required this.websiteUrl,
    required this.directionsUrl,
    this.googleMapsReviewsUrl,
    this.openHour,
    this.openMinute = 0,
    this.closeHour,
    this.closeMinute = 0,
    this.closedDays,
    this.seasonalNotice,
  });

  /// Computes live Open/Closed state based on Dubai GST Time (UTC+4)
  bool get isCurrentlyOpen {
    if (seasonalNotice != null) return false;
    if (openHour == null || closeHour == null) return defaultIsOpen;

    final nowUtc = DateTime.now().toUtc();
    final dubaiTime = nowUtc.add(const Duration(hours: 4)); // Gulf Standard Time (GST)
    
    if (closedDays != null && closedDays!.contains(dubaiTime.weekday)) {
      return false;
    }

    final currentMinutes = dubaiTime.hour * 60 + dubaiTime.minute;
    final openMinutes = (openHour ?? 0) * 60 + (openMinute ?? 0);
    final closeMinutes = (closeHour ?? 0) * 60 + (closeMinute ?? 0);

    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  /// Formats live timing string based on current Dubai time
  String get liveTimingText {
    if (seasonalNotice != null) {
      return seasonalNotice!;
    }
    if (openHour == null || closeHour == null) {
      return defaultTiming;
    }

    final nowUtc = DateTime.now().toUtc();
    final dubaiTime = nowUtc.add(const Duration(hours: 4));

    if (closedDays != null && closedDays!.contains(dubaiTime.weekday)) {
      return 'Closed · Opens Monday at ${_formatTime(openHour!, openMinute ?? 0)}';
    }

    final currentMinutes = dubaiTime.hour * 60 + dubaiTime.minute;
    final openMinutes = (openHour ?? 0) * 60 + (openMinute ?? 0);
    final closeMinutes = (closeHour ?? 0) * 60 + (closeMinute ?? 0);

    if (currentMinutes >= openMinutes && currentMinutes < closeMinutes) {
      return 'Open · Closes at ${_formatTime(closeHour!, closeMinute ?? 0)}';
    } else if (currentMinutes < openMinutes) {
      return 'Closed · Opens at ${_formatTime(openHour!, openMinute ?? 0)}';
    } else {
      return 'Closed · Opens tomorrow at ${_formatTime(openHour!, openMinute ?? 0)}';
    }
  }

  static String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const List<GovernmentEntity> entities = [
    GovernmentEntity(
      name: 'Dubai Culture & Arts Authority',
      defaultIsOpen: true,
      rating: 4.5,
      reviewCount: 120,
      category: 'Government · Cultural Authority',
      location: 'Al Shindagha, Dubai',
      defaultTiming: 'Open · Closes at 15:00',
      websiteUrl: 'https://www.dubaiculture.gov.ae/',
      directionsUrl: 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha',
      openHour: 7,
      openMinute: 30,
      closeHour: 15,
      closeMinute: 0,
      closedDays: [6, 7], // Sat, Sun
    ),
    GovernmentEntity(
      name: 'Ministry of Culture & Youth',
      defaultIsOpen: true,
      rating: 4.2,
      reviewCount: 98,
      category: 'Government · Federal Ministry',
      location: 'Abu Dhabi, UAE',
      defaultTiming: 'Open · Closes at 14:30',
      websiteUrl: 'https://www.moccae.gov.ae/',
      directionsUrl: 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi',
      openHour: 7,
      openMinute: 30,
      closeHour: 14,
      closeMinute: 30,
      closedDays: [6, 7], // Sat, Sun
    ),
    GovernmentEntity(
      name: 'Dubai Design District (d3)',
      defaultIsOpen: true,
      rating: 4.7,
      reviewCount: 215,
      category: 'Creative Hub · Design District',
      location: 'Dubai Design District, Dubai',
      defaultTiming: 'Open · Closes at 22:00',
      websiteUrl: 'https://dubaidesigndistrict.com/',
      directionsUrl: 'https://maps.google.com/?q=Dubai+Design+District',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Dubai+Design+District',
      openHour: 8,
      openMinute: 0,
      closeHour: 22,
      closeMinute: 0,
    ),
    GovernmentEntity(
      name: 'Art Dubai',
      defaultIsOpen: false,
      rating: 4.6,
      reviewCount: 180,
      category: 'Art Fair · Cultural Event',
      location: 'Madinat Jumeirah, Dubai',
      defaultTiming: 'Closed · Opens Mar 2026',
      websiteUrl: 'https://www.artdubai.ae/',
      directionsUrl: 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai',
      seasonalNotice: 'Closed · Opens Mar 2026',
    ),
    GovernmentEntity(
      name: 'Alserkal Avenue',
      defaultIsOpen: true,
      rating: 4.8,
      reviewCount: 310,
      category: 'Arts District · Gallery Hub',
      location: 'Al Quoz, Dubai',
      defaultTiming: 'Open · Closes at 20:00',
      websiteUrl: 'https://alserkal.online/',
      directionsUrl: 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz',
      openHour: 10,
      openMinute: 0,
      closeHour: 20,
      closeMinute: 0,
    ),
    GovernmentEntity(
      name: 'Dubai Opera',
      defaultIsOpen: true,
      rating: 4.9,
      reviewCount: 450,
      category: 'Performing Arts · Venue',
      location: 'Downtown Dubai',
      defaultTiming: 'Open · Next show at 19:30',
      websiteUrl: 'https://www.dubaiopera.com/en',
      directionsUrl: 'https://maps.google.com/?q=Dubai+Opera+Downtown',
      googleMapsReviewsUrl: 'https://maps.google.com/?q=Dubai+Opera+Downtown',
      openHour: 10,
      openMinute: 0,
      closeHour: 23,
      closeMinute: 0,
    ),
  ];
}
