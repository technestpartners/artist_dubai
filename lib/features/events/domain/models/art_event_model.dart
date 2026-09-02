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
  });

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
      isActive: isActive ?? this.isActive,
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
    return ArtEventModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Art Event',
      category: json['category'] as String? ?? 'Art Exhibition',
      price: json['price'] as String? ?? 'Free',
      description: json['description'] as String? ?? '',
      requirements: json['requirements'] as String? ?? '',
      dateTime: dateStr,
      formattedDate: json['formatted_date'] as String? ?? dateStr,
      timeRange: json['time_range'] as String? ?? '',
      location: json['location'] as String? ?? json['venue'] as String? ?? 'Dubai, UAE',
      locationCity: json['location_city'] as String? ?? 'Dubai',
      attendeesCount: (json['attendees_count'] as num?)?.toInt() ?? 0,
      maxAttendees: (json['max_attendees'] as num?)?.toInt() ?? 100,
      organizer: json['organizer_name'] as String? ?? json['organizer'] as String? ?? 'Artist Dubai',
      organizerEmail: json['contact_email'] as String? ?? json['organizerEmail'] as String?,
      tags: parsedTags,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      galleries: parsedGalleries,
      status: json['status'] as String? ?? 'active',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['status'] == 'active' || json['status'] == null,
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

  static final ArtEventModel sampleEvent = ArtEventModel(
    id: '1',
    title: 'Dubai Modern Art Exhibition',
    category: 'Art Exhibition',
    price: 'Free',
    description: 'A celebration of contemporary Middle Eastern and global art.',
    dateTime: '2026-10-15',
    formattedDate: 'Oct 15, 2026',
    timeRange: '10:00 AM - 08:00 PM',
    location: 'Alserkal Avenue, Dubai',
    locationCity: 'Dubai',
    attendeesCount: 25,
    maxAttendees: 100,
    organizer: 'Dubai Culture',
    tags: const ['Exhibition', 'Contemporary', 'Dubai'],
  );

  static List<ArtEventModel> get mockEvents => [sampleEvent];
}
