import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

/// Professional Domain Model for Galleries and Art Centers
class GalleryModel {
  final int id;
  final String name;
  final String category;
  final String location;
  final String description;
  final String timing;
  final String website;
  final String imageUrl;
  final String contactPerson;
  final String email;
  final String phone;
  final String about;
  final String artistId;
  final String artistName;
  final String eventName;
  final String eventId;
  final int photoCount;
  final List<String> images;
  final String status;
  final bool isPublic;
  final bool isApproved;
  final String? createdAt;

  const GalleryModel({
    required this.id,
    required this.name,
    this.category = 'Art Gallery',
    this.location = 'Dubai, UAE',
    this.description = '',
    this.timing = '',
    this.website = '',
    this.imageUrl = '',
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
    this.about = '',
    this.artistId = '',
    this.artistName = '',
    this.eventName = '',
    this.eventId = '',
    this.photoCount = 1,
    this.images = const [],
    this.status = 'approved',
    this.isPublic = true,
    this.isApproved = true,
    this.createdAt,
  });

  /// Translated localized getters for bilingual UI support
  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedCategory([BuildContext? context]) => category.trData(context);
  String localizedLocation([BuildContext? context]) => location.trData(context);
  String localizedDescription([BuildContext? context]) => description.trData(context);
  String localizedAbout([BuildContext? context]) => about.trData(context);

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['images_json'] is String && (json['images_json'] as String).isNotEmpty) {
      try {
        final decoded = (json['images_json'] as String);
        if (decoded.startsWith('[')) {
          parsedImages = List<String>.from(
            (_decodeJson(decoded) as List<dynamic>).map((e) => e.toString()),
          );
        }
      } catch (_) {}
    }

    final idVal = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final photoCountVal = int.tryParse(json['photo_count']?.toString() ?? '1') ?? 
        (parsedImages.isNotEmpty ? parsedImages.length : 1);

    return GalleryModel(
      id: idVal,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? json['type']?.toString() ?? 'Art Gallery',
      location: json['location']?.toString() ?? json['address']?.toString() ?? 'Dubai, UAE',
      description: json['description']?.toString() ?? json['subtitle']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      photoCount: photoCountVal,
      images: parsedImages,
      status: json['status']?.toString() ?? 'approved',
      isPublic: json['is_public'] == 1 || json['is_public'] == true || json['is_public'] == '1',
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true || json['is_approved'] == '1',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'location': location,
    'description': description,
    'timing': timing,
    'website': website,
    'image_url': imageUrl,
    'contact_person': contactPerson,
    'email': email,
    'phone': phone,
    'about': about,
    'artist_id': artistId,
    'artist_name': artistName,
    'event_name': eventName,
    'event_id': eventId,
    'photo_count': photoCount,
    'images': images,
    'status': status,
    'is_public': isPublic ? 1 : 0,
    'is_approved': isApproved ? 1 : 0,
    if (createdAt != null) 'created_at': createdAt,
  };
}

dynamic _decodeJson(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return [];
  }
}
