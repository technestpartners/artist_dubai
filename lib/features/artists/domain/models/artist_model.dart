class CategoryInfo {
  final String name;
  final String emoji;

  const CategoryInfo({required this.name, required this.emoji});
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
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    final exp = json['experience_level'] as String?;
    final rate = json['booking_rate'] as String? ?? json['price'] as String?;
    return ArtistModel(
      id: json['id']?.toString() ?? '0',
      name: json['name'] as String? ?? 'Unknown Artist',
      category: json['category'] as String? ?? 'Mixed Media',
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? 'Dubai, UAE',
      bannerUrl: json['banner_url'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      experienceLevel: (exp != null && exp.isNotEmpty) ? exp : 'Professional (5+ years)',
      bookingRate: (rate != null && rate.isNotEmpty) ? rate : 'AED 1500+',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['status'] == 'active' || json['status'] == null,
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

  static final ArtistModel sampleArtist = ArtistModel(
    id: '1',
    name: 'Fatima Al-Hashimi',
    category: 'Calligraphy & Typography',
    bio: 'Renowned Emirati contemporary calligrapher merging classical Thuluth script with modern architectural abstraction.',
    location: 'Dubai Design District (d3), Dubai',
    bannerUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    worksCount: 18,
    followersCount: 1240,
    likesCount: 890,
  );

  static List<ArtistModel> get mockArtists => [sampleArtist];
}
