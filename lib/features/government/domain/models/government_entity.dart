import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

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

  String localizedText([BuildContext? context]) => text.trData(context);
  String localizedRelativeTime([BuildContext? context]) => relativeTime.trData(context);

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
    final rawText = json['text'] as String? ?? '';
    final isAr = DataTranslator.isAppArabic;

    return ReviewModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      entityName: json['entity_name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Reviewer',
      authorPhoto: json['author_photo'] as String?,
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      text: DataTranslator.translate(rawText, isArabic: isAr),
      relativeTime: DataTranslator.translate(relativeTime, isArabic: isAr),
      isLocalGuide: json['is_local_guide'] == 1 || json['is_local_guide'] == true || json['is_local_guide'] == '1',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class GovernmentEntity {
  final int? id;
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
    this.id,
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

  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedCategory([BuildContext? context]) => category.trData(context);
  String localizedLocation([BuildContext? context]) => location.trData(context);
  String localizedDefaultTiming([BuildContext? context]) => defaultTiming.trData(context);
  String localizedLiveTiming([BuildContext? context]) => liveTimingText.trData(context);

  factory GovernmentEntity.fromJson(Map<String, dynamic> json) {
    final locationName = (json['name'] as String? ?? 'Dubai').replaceAll(' ', '+');
    final defaultMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$locationName+Dubai';
    final rawName = json['name'] as String? ?? 'Entity';
    final rawCat = json['category'] as String? ?? 'Government';
    final rawLoc = json['location'] as String? ?? 'Dubai, UAE';
    final rawTiming = json['default_timing'] as String? ?? 'Open · Closes at 20:00';
    final rawNotice = json['seasonal_notice'] as String?;
    final isAr = DataTranslator.isAppArabic;

    return GovernmentEntity(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: DataTranslator.translate(rawName, isArabic: isAr),
      defaultIsOpen: json['default_is_open'] == 1 || json['default_is_open'] == true || json['is_open'] == true,
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      category: DataTranslator.translate(rawCat, isArabic: isAr),
      location: DataTranslator.translate(rawLoc, isArabic: isAr),
      defaultTiming: DataTranslator.translate(rawTiming, isArabic: isAr),
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
      seasonalNotice: rawNotice != null ? DataTranslator.translate(rawNotice, isArabic: isAr) : null,
    );
  }

  /// Returns open state based on seasonal notice or defaultIsOpen
  bool get isCurrentlyOpen {
    if (seasonalNotice != null) return false;
    return defaultIsOpen;
  }

  /// Returns exact formatted timing text as configured in database
  String get liveTimingText {
    if (seasonalNotice != null) {
      return seasonalNotice!;
    }
    if (defaultTiming.isNotEmpty) {
      return defaultTiming;
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

  static const List<GovernmentEntity> entities = [];
}
