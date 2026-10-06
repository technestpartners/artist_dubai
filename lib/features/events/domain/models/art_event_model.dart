import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

class GalleryImageItem {
  final String title;
  final String imageUrl;
  final String caption;

  const GalleryImageItem({
    required this.title,
    required this.imageUrl,
    this.caption = 'Event highlight',
  });
}

class EventPhotoGallery {
  final String title;
  final String? subtitle;
  final int photoCount;
  final String date;
  final String imageUrl;
  final List<GalleryImageItem> images;

  const EventPhotoGallery({
    required this.title,
    this.subtitle,
    required this.photoCount,
    required this.date,
    required this.imageUrl,
    this.images = const [],
  });
}

class ArtEventModel {
  final String id;
  final String title;
  final String category;
  final String price;
  final String description;
  final String requirements;
  final String dateTime;
  final String formattedDate;
  final String timeRange;
  final String location;
  final String? locationCity;
  final int attendeesCount;
  final int maxAttendees;
  final String organizer;
  final String? organizerEmail;
  final List<String> tags;
  final String? imageUrl;
  final List<EventPhotoGallery> galleries;
  final String status;
  final bool isActive;
  final String? publishingPlan;
  final String? publishingAmount;
  final String? paymentStatus;
  final String? paymentProofUrl;
  final String? paymentReference;
  final String? titleEn;
  final String? titleAr;
  final String? categoryEn;
  final String? locationEn;
  final String? descriptionEn;

  const ArtEventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.description,
    this.requirements = '',
    required this.dateTime,
    this.formattedDate = '',
    this.timeRange = '',
    required this.location,
    this.locationCity,
    required this.attendeesCount,
    required this.maxAttendees,
    required this.organizer,
    this.organizerEmail,
    required this.tags,
    this.imageUrl,
    this.galleries = const [],
    this.status = 'active',
    this.isActive = true,
    this.publishingPlan,
    this.publishingAmount,
    this.paymentStatus,
    this.paymentProofUrl,
    this.paymentReference,
    this.titleEn,
    this.titleAr,
    this.categoryEn,
    this.locationEn,
    this.descriptionEn,
  });

  String localizedTitle([BuildContext? context]) {
    bool isArabic = false;
    if (context != null) {
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = DataTranslator.isAppArabic;
      }
    } else {
      isArabic = DataTranslator.isAppArabic;
    }

    if (!isArabic) {
      if (titleEn != null && titleEn!.trim().isNotEmpty && !RegExp(r'[\u0600-\u06FF]').hasMatch(titleEn!)) {
        return titleEn!.trim();
      }
    } else {
      if (titleAr != null && titleAr!.trim().isNotEmpty && RegExp(r'[\u0600-\u06FF]').hasMatch(titleAr!)) {
        return titleAr!.trim();
      }
    }
    return title.trData(context);
  }

  String localizedCategory([BuildContext? context]) {
    bool isArabic = false;
    if (context != null) {
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = DataTranslator.isAppArabic;
      }
    } else {
      isArabic = DataTranslator.isAppArabic;
    }

    if (!isArabic && categoryEn != null && categoryEn!.trim().isNotEmpty && !RegExp(r'[\u0600-\u06FF]').hasMatch(categoryEn!)) {
      return categoryEn!.trim();
    }
    return category.trData(context);
  }

  String localizedPrice([BuildContext? context]) => price.trData(context);

  String localizedDescription([BuildContext? context]) {
    bool isArabic = false;
    if (context != null) {
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = DataTranslator.isAppArabic;
      }
    } else {
      isArabic = DataTranslator.isAppArabic;
    }

    if (!isArabic && descriptionEn != null && descriptionEn!.trim().isNotEmpty && !RegExp(r'[\u0600-\u06FF]').hasMatch(descriptionEn!)) {
      return descriptionEn!.trim();
    }
    return description.trData(context);
  }

  String localizedLocation([BuildContext? context]) {
    bool isArabic = false;
    if (context != null) {
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = DataTranslator.isAppArabic;
      }
    } else {
      isArabic = DataTranslator.isAppArabic;
    }

    if (!isArabic && locationEn != null && locationEn!.trim().isNotEmpty && !RegExp(r'[\u0600-\u06FF]').hasMatch(locationEn!)) {
      return locationEn!.trim();
    }
    return location.trData(context);
  }

  String localizedVenue([BuildContext? context]) => (locationCity != null && locationCity!.isNotEmpty ? locationCity! : location).trData(context);
  String localizedStatus([BuildContext? context]) => status.trData(context);
  String localizedRequirements([BuildContext? context]) => requirements.trData(context);

  /// Returns a clean, non-redundant schedule string (e.g. "Today • 09:00 AM - 06:00 PM"
  /// or "06:00 AM • 27 Nov - 29 Nov").
  /// Guarantees that time is never duplicated if dateTime already contains it.
  String get displaySchedule {
    final dt = dateTime.trim();
    final tr = timeRange.trim();
    final fd = formattedDate.trim();

    if (dt.isNotEmpty) {
      if (tr.isNotEmpty) {
        if (dt.toLowerCase().contains(tr.toLowerCase())) {
          return dt;
        }
        final hasTimeInDt = RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(dt) ||
            dt.contains('AM') ||
            dt.contains('PM');
        if (hasTimeInDt) {
          return dt;
        }
        return '$tr • $dt';
      }
      return dt;
    }
    if (fd.isNotEmpty && tr.isNotEmpty) {
      return '$tr • $fd';
    }
    if (tr.isNotEmpty) return tr;
    if (fd.isNotEmpty) return fd;
    return '06:00 AM • 27 Nov - 29 Nov';
  }

  ArtEventModel copyWith({
    String? id,
    String? title,
    String? category,
    String? price,
    String? description,
    String? requirements,
    String? dateTime,
    String? formattedDate,
    String? timeRange,
    String? location,
    String? locationCity,
    int? attendeesCount,
    int? maxAttendees,
    String? organizer,
    String? organizerEmail,
    List<String>? tags,
    String? imageUrl,
    List<EventPhotoGallery>? galleries,
    String? status,
    bool? isActive,
    String? publishingPlan,
    String? publishingAmount,
    String? paymentStatus,
    String? paymentProofUrl,
    String? paymentReference,
    String? titleEn,
    String? titleAr,
    String? categoryEn,
    String? locationEn,
    String? descriptionEn,
  }) {
    return ArtEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      dateTime: dateTime ?? this.dateTime,
      formattedDate: formattedDate ?? this.formattedDate,
      timeRange: timeRange ?? this.timeRange,
      location: location ?? this.location,
      locationCity: locationCity ?? this.locationCity,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      organizer: organizer ?? this.organizer,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      galleries: galleries ?? this.galleries,
      status: status ?? this.status,
      isActive: isActive ??
          (status != null
              ? (status.trim().toLowerCase() == 'active' || status.trim().toLowerCase() == 'scheduled')
              : this.isActive),
      publishingPlan: publishingPlan ?? this.publishingPlan,
      publishingAmount: publishingAmount ?? this.publishingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      categoryEn: categoryEn ?? this.categoryEn,
      locationEn: locationEn ?? this.locationEn,
      descriptionEn: descriptionEn ?? this.descriptionEn,
    );
  }

  factory ArtEventModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedTags = (json['tags'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final galleriesList = (json['galleries'] as List<dynamic>?) ?? [];
    final parsedGalleries = galleriesList.map((g) {
      if (g is EventPhotoGallery) return g;
      final gm = g as Map<String, dynamic>;
      final imgsList = (gm['images'] as List<dynamic>?) ?? [];
      final images = imgsList.map((im) {
        if (im is GalleryImageItem) return im;
        if (im is String) {
          return GalleryImageItem(title: 'Photo', imageUrl: im);
        }
        final imm = im as Map<String, dynamic>;
        return GalleryImageItem(
          title: imm['title'] as String? ?? 'Photo',
          imageUrl: imm['image_url'] as String? ?? imm['imageUrl'] as String? ?? '',
          caption: imm['caption'] as String? ?? 'Gallery photo',
        );
      }).toList();

      return EventPhotoGallery(
        title: gm['title'] as String? ?? gm['name'] as String? ?? 'Event Gallery',
        subtitle: gm['subtitle'] as String? ?? gm['description'] as String?,
        photoCount: (gm['photo_count'] as num?)?.toInt() ?? images.length,
        date: gm['date'] as String? ?? gm['created_at'] as String? ?? '',
        imageUrl: gm['image_url'] as String? ?? gm['imageUrl'] as String? ?? (images.isNotEmpty ? images.first.imageUrl : ''),
        images: images,
      );
    }).toList();

    final dateStr = (json['event_date'] ?? json['date_time'] ?? json['dateTime'] ?? '') as String;
    
    final rawTitleEn = (json['title_en'] as String?)?.trim();
    final rawTitleAr = (json['title_ar'] as String?)?.trim();
    final rawCatEn = (json['category_en'] as String?)?.trim();
    final rawDescEn = (json['description_en'] as String?)?.trim();
    final rawLocEn = (json['location_en'] as String?)?.trim();

    final isAr = DataTranslator.isAppArabic;

    // Robust fallback: if current locale is English (!isAr), prefer English keys from backend
    final alphanumericRegex = RegExp(r'[\p{L}\p{N}]', unicode: true);
    String resolveField(String primaryKey, String enKey, String fallback) {
      if (!isAr) {
        final en = (json[enKey] as String?)?.trim() ?? '';
        if (en.isNotEmpty && alphanumericRegex.hasMatch(en)) {
          return en;
        }
      }
      final primary = (json[primaryKey] as String?)?.trim() ?? '';
      if (primary.isNotEmpty && alphanumericRegex.hasMatch(primary)) {
        return primary;
      }
      final en = (json[enKey] as String?)?.trim() ?? '';
      if (en.isNotEmpty && alphanumericRegex.hasMatch(en)) {
        return en;
      }
      return fallback;
    }

    final rawTitle = resolveField('title', 'title_en', 'Art Event');
    final rawCat = resolveField('category', 'category_en', 'Art Exhibition');
    final rawPrice = resolveField('price', 'price_en', 'Free');
    final rawDesc = resolveField('description', 'description_en', '');
    final rawReq = resolveField('requirements', 'requirements_en', '');
    final rawLoc = resolveField('location', 'location_en', (json['venue'] as String?) ?? 'Dubai, UAE');
    final rawCity = resolveField('location_city', 'location_city_en', 'Dubai');
    final rawStatus = resolveField('status', 'status_en', 'active').toLowerCase();

    return ArtEventModel(
      id: json['id']?.toString() ?? '',
      title: DataTranslator.translate(rawTitle, isArabic: isAr),
      category: DataTranslator.translate(rawCat, isArabic: isAr),
      price: DataTranslator.translate(rawPrice, isArabic: isAr),
      description: DataTranslator.translate(rawDesc, isArabic: isAr),
      requirements: DataTranslator.translate(rawReq, isArabic: isAr),
      dateTime: dateStr,
      formattedDate: json['formatted_date'] as String? ?? dateStr,
      timeRange: json['time_range'] as String? ?? '',
      location: DataTranslator.translate(rawLoc, isArabic: isAr),
      locationCity: DataTranslator.translate(rawCity, isArabic: isAr),
      attendeesCount: (json['attendees_count'] as num?)?.toInt() ?? 0,
      maxAttendees: (json['max_attendees'] as num?)?.toInt() ?? 100,
      organizer: json['organizer_name'] as String? ?? json['organizer'] as String? ?? 'Artist Dubai',
      organizerEmail: json['contact_email'] as String? ?? json['organizerEmail'] as String?,
      tags: parsedTags,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      galleries: parsedGalleries,
      status: DataTranslator.translate(rawStatus, isArabic: isAr),
      titleEn: rawTitleEn,
      titleAr: rawTitleAr ??
          (RegExp(r'[\u0600-\u06FF]').hasMatch(json['title']?.toString() ?? '')
              ? json['title']?.toString()
              : null),
      categoryEn: rawCatEn,
      locationEn: rawLocEn,
      descriptionEn: rawDescEn,
      isActive: () {
        final rawStatus = (json['status'] ?? '').toString().trim().toLowerCase();
        final rawActive = json['is_active'];
        final isExplicitlyInactive = rawActive == 0 ||
            rawActive == false ||
            rawActive == '0' ||
            rawStatus == 'cancelled' ||
            rawStatus == 'inactive' ||
            rawStatus == 'draft' ||
            rawStatus == 'deleted';
        if (isExplicitlyInactive) return false;
        return rawActive == 1 ||
            rawActive == true ||
            rawActive == '1' ||
            rawStatus == 'active' ||
            rawStatus == 'scheduled' ||
            rawStatus.isEmpty;
      }(),
      publishingPlan: json['publishing_plan'] as String?,
      publishingAmount: json['publishing_amount'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentProofUrl: (json['payment_proof_url'] ?? json['receipt_url']) as String?,
      paymentReference: (json['payment_reference'] ?? json['transaction_id']) as String?,
    );
  }

  int get spotsRemaining =>
      (maxAttendees - attendeesCount).clamp(0, maxAttendees);

  static const List<String> categories = [
    'All Categories',
    'Art Exhibition',
    'Gallery Opening',
    'Art Workshop',
    'Artist Talk',
    'Art Fair',
    'Sculpture Installation',
    'Photography Exhibition',
    'Cultural Festival',
    'Art Competition',
    'Community Art Project',
  ];

  static List<ArtEventModel> get mockEvents => const <ArtEventModel>[];
}
