class ReviewModel {
  final int? id;
  final String entityName;
  final String authorName;
  final String? authorPhoto;
  final double rating;
  final String text;
  final String relativeTime;
  final bool isLocalGuide;
  final int likesCount;

  const ReviewModel({
    this.id,
    required this.entityName,
    required this.authorName,
    this.authorPhoto,
    required this.rating,
    required this.text,
    this.relativeTime = 'Recent',
    this.isLocalGuide = true,
    this.likesCount = 0,
  });

  static String calculateRelativeTime(dynamic createdAtRaw, String? fallback) {
    if (createdAtRaw != null && createdAtRaw.toString().isNotEmpty) {
      final parsed = DateTime.tryParse(createdAtRaw.toString());
      if (parsed != null) {
        final now = DateTime.now();
        final diff = now.difference(parsed.toLocal());
        if (diff.inSeconds < 60) return 'Just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        if (diff.inDays < 7) return '${diff.inDays}d ago';
        if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
        if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
        return '${(diff.inDays / 365).floor()}y ago';
      }
    }
    return fallback ?? 'Recent';
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'] ?? json['timestamp'];
    final relativeTime = calculateRelativeTime(
      rawCreatedAt,
      json['relative_time'] as String?,
    );

    return ReviewModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      entityName: json['entity_name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Reviewer',
      authorPhoto: json['author_photo'] as String?,
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      text: json['text'] as String? ?? '',
      relativeTime: relativeTime,
      isLocalGuide: json['is_local_guide'] == 1 || json['is_local_guide'] == true || json['is_local_guide'] == '1',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}

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
  final List<ReviewModel> reviews;

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
    this.reviews = const [],
    this.openHour,
    this.openMinute = 0,
    this.closeHour,
    this.closeMinute = 0,
    this.closedDays,
    this.seasonalNotice,
  });

  factory GovernmentEntity.fromJson(Map<String, dynamic> json) {
    final locationName = (json['name'] as String? ?? 'Dubai').replaceAll(' ', '+');
    final defaultMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$locationName+Dubai';

    return GovernmentEntity(
      name: json['name'] as String,
      defaultIsOpen: json['default_is_open'] as bool? ?? true,
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      category: json['category'] as String,
      location: json['location'] as String,
      defaultTiming: json['default_timing'] as String? ?? 'Open · Closes at 20:00',
      websiteUrl: json['website_url'] as String? ?? 'https://dubaiculture.gov.ae/',
      directionsUrl: json['directions_url'] as String? ?? defaultMapsUrl,
      googleMapsReviewsUrl: json['google_maps_reviews_url'] as String? ?? defaultMapsUrl,
      reviews: (json['reviews'] as List?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      openHour: (json['open_hour'] as num?)?.toInt(),
      openMinute: (json['open_minute'] as num?)?.toInt() ?? 0,
      closeHour: (json['close_hour'] as num?)?.toInt(),
      closeMinute: (json['close_minute'] as num?)?.toInt() ?? 0,
      closedDays:
          (json['closed_days'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList(),
      seasonalNotice: json['seasonal_notice'] as String?,
    );
  }

  /// Computes live Open/Closed state based on Dubai GST Time (UTC+4)
  bool get isCurrentlyOpen {
    if (seasonalNotice != null) return false;
    if (openHour == null || closeHour == null) return defaultIsOpen;

    final nowUtc = DateTime.now().toUtc();
    final dubaiTime = nowUtc.add(
      const Duration(hours: 4),
    ); // Gulf Standard Time (GST)

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
      rating: 4.8,
      reviewCount: 420,
      category: 'Government Department',
      location: 'Dubai Design District, Building 1',
      defaultTiming: '07:30 AM - 03:30 PM',
      websiteUrl: 'https://dubaiculture.gov.ae',
      directionsUrl: 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority',
      openHour: 7,
      openMinute: 30,
      closeHour: 15,
      closeMinute: 30,
      closedDays: [5, 6],
    ),
    GovernmentEntity(
      name: 'Dubai Design District (d3)',
      defaultIsOpen: true,
      rating: 4.7,
      reviewCount: 310,
      category: 'Creative Free Zone',
      location: 'Ras Al Khor Road, Dubai',
      defaultTiming: '08:00 AM - 06:00 PM',
      websiteUrl: 'https://dubaidesigndistrict.com',
      directionsUrl: 'https://maps.google.com/?q=Dubai+Design+District',
      openHour: 8,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
    ),
  ];
}
