import 'dart:convert';

class ListingPlanItem {
  final int? id;
  final String title;
  final String category;
  final String badge;
  final String price;
  final String description;
  final List<String> features;
  final String buttonText;
  final String itemType;
  final bool isActive;
  final int sortOrder;
  final String duration;
  final int durationDays;

  const ListingPlanItem({
    this.id,
    required this.title,
    required this.category,
    this.badge = 'One-time',
    required this.price,
    required this.description,
    required this.features,
    this.buttonText = 'Pay from My Listings',
    required this.itemType,
    this.isActive = true,
    this.sortOrder = 0,
    this.duration = '30 Days',
    this.durationDays = 30,
  });

  /// Comprehensive baseline plans covering all 5 core categories
  static const List<ListingPlanItem> defaultBaselinePlans = [
    ListingPlanItem(
      id: 1,
      title: 'Event Listing',
      category: 'Events',
      badge: 'Popular',
      price: 'AED 199',
      description:
          '30-day verified event showcase across mobile app and website',
      features: [
        '30-day verified event showcase across mobile app and website',
        'Event calendar & push notification highlight',
        'Direct ticket booking & RSVP link integration',
        'Interactive venue map pin & directions',
        'Featured badge & social media spotlight',
      ],
      buttonText: 'Pay from My Listings',
      itemType: 'event',
      isActive: true,
      sortOrder: 1,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 2,
      title: 'Gallery Listing',
      category: 'Galleries',
      badge: 'Premium',
      price: 'AED 149',
      description: 'Publish a single gallery on Artist Dubai.',
      features: [
        'Full digital gallery showroom & map listing',
        'Unlimited exhibition postings for 12 months',
        'Featured spot on Galleries directory',
        'Direct visitor booking & VIP inquiries',
        'Social media & push broadcast spotlight',
      ],
      buttonText: 'Pay from My Listings',
      itemType: 'gallery',
      isActive: true,
      sortOrder: 2,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),
    ListingPlanItem(
      id: 3,
      title: 'Art Centre Listing',
      category: 'Art Centres',
      badge: 'VIP Partner',
      price: 'AED 299',
      description: 'Publish a single art centre on Artist Dubai.',
      features: [
        'Official verified institution partner badge',
        'Unlimited event & workshop listings',
        'Direct ticket booking with instant notifications',
        'Top banner rotation on mobile home screen',
        'Dedicated account manager & support',
      ],
      buttonText: 'Pay from My Listings',
      itemType: 'art_centre',
      isActive: true,
      sortOrder: 3,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),
    ListingPlanItem(
      id: 4,
      title: 'Starter Plan',
      category: 'Messaging',
      badge: 'Default',
      price: 'Free',
      description: 'Free monthly allowance to connect with artists across Dubai',
      features: [
        '10 direct messages per month',
        'Direct artist collaboration inquiries',
        'Flyer & artwork attachment support',
        'Allowance auto-resets on the 1st',
      ],
      buttonText: 'Select Plan',
      itemType: 'chat',
      isActive: true,
      sortOrder: 4,
      duration: 'Monthly Reset',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 5,
      title: 'Pro Artist',
      category: 'Messaging',
      badge: 'Most Popular',
      price: 'AED 49',
      description: '50 direct messages per month for active networking',
      features: [
        '50 direct messages per month',
        'Direct artist outreach & networking',
        'Priority delivery in artist inboxes',
        'High-resolution flyer attachments',
        'Monthly reset on the 1st',
      ],
      buttonText: 'Upgrade to Pro',
      itemType: 'chat',
      isActive: true,
      sortOrder: 5,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 6,
      title: 'Unlimited VIP',
      category: 'Messaging',
      badge: 'For Agencies & Curators',
      price: 'AED 99',
      description:
          'Unlimited direct artist messages with verified VIP sender badge',
      features: [
        'Unlimited direct artist messages',
        'Verified VIP sender badge',
        'Ideal for galleries, curators & agencies',
        'Priority instant customer support',
      ],
      buttonText: 'Upgrade to VIP',
      itemType: 'chat',
      isActive: true,
      sortOrder: 6,
      duration: 'Monthly Subscription',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 7,
      title: 'Artist Portfolio',
      category: 'Visual Arts',
      badge: 'Free',
      price: 'Free',
      description:
          'Free artist profile, unlimited artwork uploads & direct collector messaging',
      features: [
        'Free verified artist profile & portfolio',
        'Unlimited artwork & portfolio showcase uploads',
        'Direct collector messaging & inquiry channel',
        'Verified Artist badge on public profile',
        'Priority ranking in search & category exploration',
      ],
      buttonText: 'Create Free Profile',
      itemType: 'artist',
      isActive: true,
      sortOrder: 5,
      duration: 'Permanent Free Profile',
      durationDays: 3650,
    ),
  ];

  static String normalizePrice(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'AED 199';
    if (trimmed.toLowerCase() == 'free' ||
        trimmed == '0' ||
        trimmed.toLowerCase() == '0 aed' ||
        trimmed.toLowerCase() == 'aed 0') {
      return 'Free';
    }
    final match = RegExp(
      r'^(?:aed\s*)?([0-9]+(?:,[0-9]+)*(?:\.[0-9]+)?)(?:\s*aed)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      final amount = match.group(1);
      return 'AED $amount';
    }
    return trimmed;
  }

  factory ListingPlanItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] is List) {
      parsedFeatures =
          (json['features'] as List).map((e) => e.toString()).toList();
    } else if (json['features_json'] != null) {
      try {
        final decoded = jsonDecode(json['features_json'].toString());
        if (decoded is List) {
          parsedFeatures = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final itemType = json['item_type']?.toString() ?? 'event';
    if (parsedFeatures.isEmpty) {
      parsedFeatures = defaultFeaturesForItemType(itemType);
    }

    String duration = json['duration']?.toString().trim() ?? '';
    int? durationDays = int.tryParse(json['duration_days']?.toString() ?? '');
    if (duration.isEmpty) {
      final t = itemType.toLowerCase();
      final titleLower = (json['title'] ?? '').toString().toLowerCase();
      if (t == 'gallery' || titleLower.contains('gallery') || t == 'art_centre' || titleLower.contains('center')) {
        duration = '1 Year (365 Days)';
        durationDays ??= 365;
      } else if (t == 'artist' || titleLower.contains('artist')) {
        duration = 'Permanent Free Profile';
        durationDays ??= 3650;
      } else {
        duration = '30 Days';
        durationDays ??= 30;
      }
    }
    durationDays ??= 30;

    return ListingPlanItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'One-time',
      price: normalizePrice(json['price']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      features: parsedFeatures,
      buttonText: json['button_text']?.toString() ?? 'Pay from My Listings',
      itemType: itemType,
      isActive:
          json['is_active'] == null ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == true,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      duration: duration,
      durationDays: durationDays,
    );
  }

  static List<String> defaultFeaturesForItemType(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return [
          '30-day verified event showcase across mobile app and website',
          'Event calendar & push notification highlight',
          'Direct ticket booking & RSVP link integration',
          'Interactive venue map pin & directions',
          'Featured badge & social media spotlight',
        ];
      case 'artist':
        return [
          'Unlimited artwork & portfolio showcase uploads',
          'Direct collector messaging & inquiry channel',
          'Verified Artist badge on public profile',
          'Priority ranking in search & category exploration',
          'Custom biography, exhibition history & press links',
        ];
      case 'gallery':
        return [
          'Official gallery exhibition listing & virtual tour',
          'Curator and featured artist roster spotlight',
          'Event host privileges with verified venue badge',
          'Direct collector inquiries & VIP preview access',
        ];
      case 'chat':
      case 'messaging':
        return [
          'Unlimited direct messaging with artists & collectors',
          'Direct artwork purchase inquiries & commissions',
          'High-res flyer & artwork attachments support',
          'Instant push notification alerts on response',
          'Priority delivery in recipient inbox',
        ];
      case 'art_centre':
      case 'center':
        return [
          'Complete art centre profile & workshop schedule',
          'Community event & exhibition hosting spotlight',
          'Direct inquiry channel for studio bookings',
          'Featured placement in Cultural Venues directory',
        ];
      default:
        return [
          'Verified public listing across mobile app and website',
          'Direct customer messaging and inquiries',
          'Priority visibility in category search & filters',
          'Dedicated support and verified badge',
        ];
    }
  }

  List<String> get effectiveFeatures =>
      features.isNotEmpty ? features : defaultFeaturesForItemType(itemType);

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'category': category,
    'badge': badge,
    'price': price,
    'description': description,
    'features': features,
    'features_json': jsonEncode(features),
    'button_text': buttonText,
    'item_type': itemType,
    'is_active': isActive ? 1 : 0,
    'sort_order': sortOrder,
    'duration': duration,
    'duration_days': durationDays,
  };

  ListingPlanItem copyWith({
    int? id,
    String? title,
    String? category,
    String? badge,
    String? price,
    String? description,
    List<String>? features,
    String? buttonText,
    String? itemType,
    bool? isActive,
    int? sortOrder,
    String? duration,
    int? durationDays,
  }) {
    return ListingPlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      badge: badge ?? this.badge,
      price: price ?? this.price,
      description: description ?? this.description,
      features: features ?? this.features,
      buttonText: buttonText ?? this.buttonText,
      itemType: itemType ?? this.itemType,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      duration: duration ?? this.duration,
      durationDays: durationDays ?? this.durationDays,
    );
  }
}

typedef ListingPlanModel = ListingPlanItem;
