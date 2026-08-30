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
      bannerUrl:
          json['banner_url'] as String? ??
          'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          json['avatar_url'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
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

  static const List<CategoryInfo> categoryList = [
    CategoryInfo(name: 'Calligraphy & Typography', emoji: '✍️'),
    CategoryInfo(name: 'Contemporary Painting', emoji: '🎨'),
    CategoryInfo(name: 'Digital Art & Sculpture', emoji: '🗿'),
    CategoryInfo(name: 'Photography', emoji: '📷'),
    CategoryInfo(name: 'Abstract Painting', emoji: '🎨'),
    CategoryInfo(name: 'Ceramics & Pottery', emoji: '🏺'),
  ];

  static List<ArtistModel> get mockArtists => const [
    // 1. Calligraphy & Typography (1)
    ArtistModel(
      id: '1',
      name: 'Fatima Al-Zahra',
      category: 'Calligraphy & Typography',
      bio:
          'Contemporary Arabic calligraphy artist blending traditional scripts with modern abstract compositions.',
      location: 'Al Fahidi Historical District, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
      isFeatured: true,
      tags: ['Calligraphy', 'Typography', 'Arabic Art'],
      worksCount: 28,
      followersCount: 980,
    ),

    // 2. Contemporary Painting (1)
    ArtistModel(
      id: '2',
      name: 'Omar Al-Mansoor',
      category: 'Contemporary Painting',
      bio:
          'Visual artist focused on large-scale expressionist oil paintings and heritage murals.',
      location: 'Alserkal Avenue, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
      isFeatured: true,
      tags: ['Painting', 'Contemporary', 'Expressionism'],
      worksCount: 35,
      followersCount: 1420,
    ),

    // 3. Digital Art & Sculpture (1)
    ArtistModel(
      id: '3',
      name: 'Sarah Jenkins',
      category: 'Digital Art & Sculpture',
      bio:
          '3D generative digital artist and sculptor exploring futuristic Middle Eastern aesthetics.',
      location: 'Dubai Design District (d3), Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300&auto=format&fit=crop',
      isFeatured: true,
      tags: ['Digital Art', '3D Motion', 'Sculpture'],
      worksCount: 19,
      followersCount: 2100,
    ),

    // 4. Photography (6)
    ArtistModel(
      id: '4',
      name: 'Mohamed Emad',
      category: 'Photography',
      bio:
          'Specialized in architectural and cityscape photography across Dubai and the UAE.',
      location: 'Downtown Dubai, UAE',
      bannerUrl:
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
      isFeatured: true,
      tags: ['Photography', 'Architecture', 'Urban'],
      worksCount: 42,
      followersCount: 1250,
    ),
    ArtistModel(
      id: '5',
      name: 'Zaid Al-Harbi',
      category: 'Photography',
      bio:
          'Desert safari and wildlife photographer documenting Arabian heritage.',
      location: 'Al Marmoom, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
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
      bannerUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Fashion', 'Editorial', 'Portrait'],
      worksCount: 56,
      followersCount: 3200,
    ),
    ArtistModel(
      id: '7',
      name: 'Tariq Mansoor',
      category: 'Photography',
      bio:
          'Aerial and drone cinematographer capturing Dubai skyline and events.',
      location: 'Dubai Marina, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1518684079-3c830dcef090?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Aerial', 'Drone', 'Skyline'],
      worksCount: 24,
      followersCount: 1650,
    ),
    ArtistModel(
      id: '8',
      name: 'Maya Lin',
      category: 'Photography',
      bio:
          'Street and cultural documentary photographer traveling across the Emirates.',
      location: 'Deira, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1518684079-3c830dcef090?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Street', 'Culture', 'Documentary'],
      worksCount: 38,
      followersCount: 2150,
    ),
    ArtistModel(
      id: '9',
      name: 'Ali Reza',
      category: 'Photography',
      bio:
          'Fine art and night exposure photographer showcasing luminous architectural installations.',
      location: 'Palm Jumeirah, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Night', 'Fine Art', 'Architecture'],
      worksCount: 18,
      followersCount: 940,
    ),

    // 5. Abstract Painting (1)
    ArtistModel(
      id: '10',
      name: 'Hassan Al-Qasimi',
      category: 'Abstract Painting',
      bio:
          'Abstract artist using mixed media and raw pigments inspired by Arabian desert sands.',
      location: 'JBR, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Abstract', 'Mixed Media', 'Pigments'],
      worksCount: 22,
      followersCount: 1100,
    ),

    // 6. Ceramics & Pottery (1)
    ArtistModel(
      id: '11',
      name: 'Layla Al-Hashimi',
      category: 'Ceramics & Pottery',
      bio:
          'Artisan ceramicist creating handmade porcelain vessels infused with natural Emirati clay tones.',
      location: 'Al Quoz Creative Zone, Dubai',
      bannerUrl:
          'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?q=80&w=1200&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
      isFeatured: false,
      tags: ['Ceramics', 'Pottery', 'Handmade'],
      worksCount: 50,
      followersCount: 1120,
    ),
  ];
}
