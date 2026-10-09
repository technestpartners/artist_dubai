import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

class CategoryInfo {
  final int id;
  final String name;
  final String emoji;
  final String description;
  final String type;
  final int artistCount;
  final int eventCount;

  const CategoryInfo({
    this.id = 0,
    required this.name,
    required this.emoji,
    this.description = '',
    this.type = 'general',
    this.artistCount = 0,
    this.eventCount = 0,
  });

  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedDescription([BuildContext? context]) => description.trData(context);

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawDesc = json['description']?.toString() ?? '';
    final isAr = DataTranslator.isAppArabic;
    return CategoryInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: DataTranslator.translate(rawName, isArabic: isAr),
      emoji: json['emoji']?.toString() ?? '🎨',
      description: DataTranslator.translate(rawDesc, isArabic: isAr),
      type: json['type']?.toString() ?? 'general',
      artistCount: int.tryParse(json['artist_count']?.toString() ?? '0') ?? 0,
      eventCount: int.tryParse(json['event_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'type': type,
  };
}

class ExperienceLevelModel {
  final int id;
  final String name;
  final String yearsRange;
  final int displayOrder;

  const ExperienceLevelModel({
    required this.id,
    required this.name,
    this.yearsRange = '',
    this.displayOrder = 0,
  });

  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedYearsRange([BuildContext? context]) => yearsRange.trData(context);

  factory ExperienceLevelModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final isAr = DataTranslator.isAppArabic;
    return ExperienceLevelModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: DataTranslator.translate(rawName, isArabic: isAr),
      yearsRange: json['years_range']?.toString() ?? '',
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'years_range': yearsRange,
    'display_order': displayOrder,
  };
}

class LocationModel {
  final int id;
  final String name;
  final String city;
  final String country;
  final int displayOrder;

  const LocationModel({
    required this.id,
    required this.name,
    this.city = 'Dubai',
    this.country = 'UAE',
    this.displayOrder = 0,
  });

  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedCity([BuildContext? context]) => city.trData(context);
  String localizedCountry([BuildContext? context]) => country.trData(context);

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawCity = json['city']?.toString() ?? 'Dubai';
    final rawCountry = json['country']?.toString() ?? 'UAE';
    final isAr = DataTranslator.isAppArabic;
    return LocationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: DataTranslator.translate(rawName, isArabic: isAr),
      city: DataTranslator.translate(rawCity, isArabic: isAr),
      country: DataTranslator.translate(rawCountry, isArabic: isAr),
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'country': country,
    'display_order': displayOrder,
  };
}

class ArtistModel {
  final String id;
  final String name;
  final String category;
  final String bio;
  final String location;
  final String bannerUrl;
  final String avatarUrl;
  final bool isFeatured;
  final List<String> tags;
  final int worksCount;
  final int followersCount;
  final int likesCount;
  final String experienceLevel;
  final String bookingRate;
  final String email;
  final String phone;
  final String website;
  final String instagram;
  final String status;
  final bool isActive;
  final String createdAt;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.category,
    required this.bio,
    required this.location,
    required this.bannerUrl,
    required this.avatarUrl,
    this.isFeatured = false,
    this.tags = const [],
    this.worksCount = 0,
    this.followersCount = 0,
    this.likesCount = 0,
    this.experienceLevel = 'Professional (5+ years)',
    this.bookingRate = 'AED 1500+',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.instagram = '',
    this.status = 'active',
    this.isActive = true,
    this.createdAt = '',
  });

  String localizedName([BuildContext? context]) => name.trData(context);
  String localizedCategory([BuildContext? context]) => category.trData(context);
  String localizedLocation([BuildContext? context]) => location.trData(context);
  String localizedBio([BuildContext? context]) => bio.trData(context);
  String localizedExperienceLevel([BuildContext? context]) => experienceLevel.trData(context);
  String localizedBookingRate([BuildContext? context]) => bookingRate.trData(context);
  String localizedStatus([BuildContext? context]) => status.trData(context);

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    final exp = json['experience_level'] as String?;
    final rate = json['booking_rate'] as String? ?? json['price'] as String?;
    final rawName = json['name'] as String? ?? 'Unknown Artist';
    final rawCat = json['category'] as String? ?? 'Mixed Media';
    final rawLoc = json['location'] as String? ?? 'Dubai, UAE';
    final rawBio = json['bio'] as String? ?? '';
    final rawExp = (exp != null && exp.isNotEmpty) ? exp : 'Professional (5+ years)';
    final rawStatus = json['status'] as String? ?? 'active';
    final isAr = DataTranslator.isAppArabic;

    return ArtistModel(
      id: json['id']?.toString() ?? '0',
      name: DataTranslator.translate(rawName, isArabic: isAr),
      category: DataTranslator.translate(rawCat, isArabic: isAr),
      bio: DataTranslator.translate(rawBio, isArabic: isAr),
      location: DataTranslator.translate(rawLoc, isArabic: isAr),
      bannerUrl: json['banner_url'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      experienceLevel: DataTranslator.translate(rawExp, isArabic: isAr),
      bookingRate: (rate != null && rate.isNotEmpty) ? rate : 'AED 1500+',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      status: DataTranslator.translate(rawStatus, isArabic: isAr),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['status'] == 'active' || json['status'] == null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'bio': bio,
      'location': location,
      'banner_url': bannerUrl,
      'avatar_url': avatarUrl,
      'works_count': worksCount,
      'followers_count': followersCount,
      'likes_count': likesCount,
      'experience_level': experienceLevel,
      'booking_rate': bookingRate,
      'email': email,
      'phone': phone,
      'website': website,
      'instagram': instagram,
      'created_at': createdAt,
    };
  }

  ArtistModel copyWith({
    String? id,
    String? name,
    String? category,
    String? bio,
    String? location,
    String? bannerUrl,
    String? avatarUrl,
    bool? isFeatured,
    List<String>? tags,
    int? worksCount,
    int? followersCount,
    int? likesCount,
    String? experienceLevel,
    String? bookingRate,
    String? email,
    String? phone,
    String? website,
    String? instagram,
    String? status,
    bool? isActive,
    String? createdAt,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      worksCount: worksCount ?? this.worksCount,
      followersCount: followersCount ?? this.followersCount,
      likesCount: likesCount ?? this.likesCount,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      bookingRate: bookingRate ?? this.bookingRate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<CategoryInfo> categoryList = [
    CategoryInfo(name: 'Calligraphy & Typography', emoji: '✍️'),
    CategoryInfo(name: 'Contemporary Painting', emoji: '🎨'),
    CategoryInfo(name: 'Digital Art & Sculpture', emoji: '🗿'),
    CategoryInfo(name: 'Photography', emoji: '📷'),
    CategoryInfo(name: 'Abstract Painting', emoji: '🎨'),
    CategoryInfo(name: 'Ceramics & Pottery', emoji: '🏺'),
  ];

  static List<ArtistModel> get mockArtists => const [
        ArtistModel(
          id: '1',
          name: 'Fatima Al-Zahra',
          category: 'Arabic Calligraphy',
          bio: 'Contemporary Arabic calligraphy artist blending traditional scripts with modern abstract compositions.',
          location: 'Al Fahidi Historical District, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
          isFeatured: true,
          tags: ['Calligraphy', 'Typography', 'Arabic Art'],
          worksCount: 28,
          followersCount: 980,
        ),
        ArtistModel(
          id: '2',
          name: 'Omar Al-Mansoor',
          category: 'Contemporary Painting',
          bio: 'Visual artist focused on large-scale expressionist oil paintings and heritage murals.',
          location: 'Alserkal Avenue, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
          isFeatured: true,
          tags: ['Painting', 'Contemporary', 'Expressionism'],
          worksCount: 35,
          followersCount: 1420,
        ),
        ArtistModel(
          id: '3',
          name: 'Sarah Jenkins',
          category: 'Digital Art & Sculpture',
          bio: '3D generative digital artist and sculptor exploring futuristic Middle Eastern aesthetics.',
          location: 'Dubai Design District (d3), Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300&auto=format&fit=crop',
          isFeatured: true,
          tags: ['Digital Art', '3D Motion', 'Sculpture'],
          worksCount: 19,
          followersCount: 2100,
        ),
        ArtistModel(
          id: '4',
          name: 'Mohamed Emad',
          category: 'Photography',
          bio: 'Specialized in architectural and cityscape photography across Dubai and the UAE.',
          location: 'Downtown Dubai, UAE',
          bannerUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
          isFeatured: true,
          tags: ['Photography', 'Architecture', 'Urban'],
          worksCount: 42,
          followersCount: 1250,
        ),
        ArtistModel(
          id: '5',
          name: 'Zaid Al-Harbi',
          category: 'Photography',
          bio: 'Desert safari and wildlife photographer documenting Arabian heritage.',
          location: 'Al Marmoom, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Landscape', 'Wildlife', 'Desert'],
          worksCount: 30,
          followersCount: 890,
        ),
        ArtistModel(
          id: '6',
          name: 'Elena Rostova',
          category: 'Photography',
          bio: 'Fashion and portrait photographer based in Dubai Media City.',
          location: 'Dubai Media City, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Fashion', 'Editorial', 'Portrait'],
          worksCount: 56,
          followersCount: 3200,
        ),
        ArtistModel(
          id: '7',
          name: 'Tariq Mansoor',
          category: 'Photography',
          bio: 'Aerial and drone cinematographer capturing Dubai skyline and events.',
          location: 'Dubai Marina, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Aerial', 'Drone', 'Skyline'],
          worksCount: 24,
          followersCount: 1650,
        ),
        ArtistModel(
          id: '8',
          name: 'Maya Lin',
          category: 'Photography',
          bio: 'Street and cultural documentary photographer traveling across the Emirates.',
          location: 'Deira, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Street', 'Culture', 'Documentary'],
          worksCount: 38,
          followersCount: 2150,
        ),
        ArtistModel(
          id: '9',
          name: 'Ali Reza',
          category: 'Photography',
          bio: 'Fine art and night exposure photographer showcasing luminous architectural installations.',
          location: 'Palm Jumeirah, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Night', 'Fine Art', 'Architecture'],
          worksCount: 18,
          followersCount: 940,
        ),
        ArtistModel(
          id: '10',
          name: 'Hassan Al-Qasimi',
          category: 'Abstract Painting',
          bio: 'Abstract artist using mixed media and raw pigments inspired by Arabian desert sands.',
          location: 'JBR, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Abstract', 'Mixed Media', 'Pigments'],
          worksCount: 22,
          followersCount: 1100,
        ),
        ArtistModel(
          id: '11',
          name: 'Layla Al-Hashimi',
          category: 'Ceramics & Pottery',
          bio: 'Artisan ceramicist creating handmade porcelain vessels infused with natural Emirati clay tones.',
          location: 'Al Quoz Creative Zone, Dubai',
          bannerUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?q=80&w=1200&auto=format&fit=crop',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
          isFeatured: false,
          tags: ['Ceramics', 'Pottery', 'Handmade'],
          worksCount: 50,
          followersCount: 1120,
        ),
      ];
}
