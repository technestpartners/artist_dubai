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
    // --- Events (1 Month, 3 Months, 6 Months, 12 Months) ---
    ListingPlanItem(
      id: 1,
      title: 'Event Listing',
      category: 'Exhibitions & Events',
      badge: 'Popular',
      price: 'AED 199',
      description:
          'Publish your upcoming exhibition or art event to reach thousands of collectors',
      features: [
        'Featured in Events calendar',
        'Direct ticket & RSVP links',
        'Social media push notification',
        'Listed until event ends',
      ],
      buttonText: 'Publish Event',
      itemType: 'event',
      isActive: true,
      sortOrder: 1,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 2,
      title: 'Event Showcase (3 Months)',
      category: 'Exhibitions & Openings',
      badge: 'Popular',
      price: 'AED 1,200',
      description:
          '90-day comprehensive event campaign with multi-weekend spotlight',
      features: [
        '90-day comprehensive event showcase on mobile app and website',
        'Featured spotlight in top event carousels',
        'Multi-weekend push notification broadcasts',
        'Direct ticket booking & RSVP link integration',
        'Analytics & attendee click metrics',
      ],
      buttonText: 'Select 3 Month Plan',
      itemType: 'event',
      isActive: true,
      sortOrder: 2,
      duration: '90 Days (3 Months)',
      durationDays: 90,
    ),
    ListingPlanItem(
      id: 3,
      title: 'Event Showcase (6 Months)',
      category: 'Exhibitions & Openings',
      badge: 'Save 25%',
      price: 'AED 2,500',
      description:
          'Half-year seasonal campaign for major exhibitions and festival runs',
      features: [
        '180-day continuous event promotion across all channels',
        'Bi-weekly push broadcast spotlights',
        'Featured top banner rotation on mobile home screen',
        'VIP RSVP collection & direct attendee ticketing',
        'Dedicated event promo coverage & social blast',
      ],
      buttonText: 'Select 6 Month Plan',
      itemType: 'event',
      isActive: true,
      sortOrder: 3,
      duration: '180 Days (6 Months)',
      durationDays: 180,
    ),
    ListingPlanItem(
      id: 4,
      title: 'Event Showcase (12 Months)',
      category: 'Exhibitions & Openings',
      badge: 'Best Value',
      price: 'AED 4,500',
      description:
          'Full annual event calendar coverage with unlimited schedule updates',
      features: [
        '365-day annual event calendar coverage with unlimited updates',
        'Top banner placement throughout Dubai art season',
        'Priority notification broadcast to all app subscribers',
        'Direct ticketing with zero commission fees',
        'VIP curator & press kit distribution',
      ],
      buttonText: 'Select 12 Month Plan',
      itemType: 'event',
      isActive: true,
      sortOrder: 4,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),

    // --- Galleries (1 Month, 3 Months, 6 Months, 12 Months) ---
    ListingPlanItem(
      id: 5,
      title: 'Gallery Listing',
      category: 'Art Spaces',
      badge: 'Verified Space',
      price: 'AED 149',
      description:
          'Permanent gallery profile with exhibitions showcase and visitor directions',
      features: [
        'Dedicated gallery profile page',
        'Showcase current & upcoming exhibitions',
        'Interactive location map pin',
        'Direct visitor inquiry channel',
      ],
      buttonText: 'List Gallery',
      itemType: 'gallery',
      isActive: true,
      sortOrder: 5,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 6,
      title: 'Gallery Showcase (3 Months)',
      category: 'Galleries & Spaces',
      badge: 'Special Offer',
      price: 'AED 2,000',
      description:
          '3-month quarterly gallery showcase with interactive maps and directory spotlight',
      features: [
        'Full digital gallery showroom & interactive map pin',
        'Showcase up to 3 exhibitions during the quarter',
        'Featured spot on Galleries directory',
        'Direct visitor booking & VIP inquiries',
        'Social media spotlight and monthly feature',
      ],
      buttonText: 'Select 3 Month Plan',
      itemType: 'gallery',
      isActive: true,
      sortOrder: 6,
      duration: '90 Days (3 Months)',
      durationDays: 90,
    ),
    ListingPlanItem(
      id: 7,
      title: 'Gallery Showcase (6 Months)',
      category: 'Galleries & Spaces',
      badge: 'Save 25%',
      price: 'AED 3,000',
      description:
          'Half-year prominent gallery positioning with continuous collector reach',
      features: [
        'Full digital gallery showroom with 360 tour integration',
        'Unlimited exhibition postings for 6 months',
        'Featured spot on Galleries directory and search top ranking',
        'Direct visitor inquiry & VIP booking concierge',
        'Bi-weekly social & push broadcast spotlight',
      ],
      buttonText: 'Select 6 Month Plan',
      itemType: 'gallery',
      isActive: true,
      sortOrder: 7,
      duration: '180 Days (6 Months)',
      durationDays: 180,
    ),
    ListingPlanItem(
      id: 8,
      title: 'Gallery Showcase (12 Months)',
      category: 'Galleries & Spaces',
      badge: 'Best Value',
      price: 'AED 5,000',
      description:
          'Premier annual directory listing, verified badge, and premier Dubai gallery spotlight',
      features: [
        'Full premier digital showroom on Dubai art map',
        'Unlimited exhibition postings for the entire year',
        'Top search ranking on Galleries directory',
        'Direct VIP collector inquiry & concierge link',
        'Year-round social spotlight & editorial highlights',
      ],
      buttonText: 'Select 12 Month Plan',
      itemType: 'gallery',
      isActive: true,
      sortOrder: 8,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),

    // --- Art Centres (1 Month, 3 Months, 6 Months, 12 Months) ---
    ListingPlanItem(
      id: 9,
      title: 'Art Centre Listing',
      category: 'Institutions',
      badge: 'Institutional',
      price: 'AED 299',
      description:
          'Comprehensive hub profile for art centres, studios, and cultural institutions',
      features: [
        'Full institutional profile page',
        'Host workshops & art activities',
        'Promote residency programs',
        'Priority placement in directory',
      ],
      buttonText: 'List Centre',
      itemType: 'art_centre',
      isActive: true,
      sortOrder: 9,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 10,
      title: 'Art Centre Partner (3 Months)',
      category: 'Institutions & Venues',
      badge: 'Special Offer',
      price: 'AED 499',
      description:
          'Quarterly institutional partner showcase with workshop & event hosting',
      features: [
        'Official verified institution partner badge',
        'Host unlimited workshops & events for 3 months',
        'Direct ticket booking with instant notifications',
        'Directory spotlight on institutions map',
      ],
      buttonText: 'Select 3 Month Plan',
      itemType: 'art_centre',
      isActive: true,
      sortOrder: 10,
      duration: '90 Days (3 Months)',
      durationDays: 90,
    ),
    ListingPlanItem(
      id: 11,
      title: 'Art Centre Partner (6 Months)',
      category: 'Institutions & Venues',
      badge: 'Save 20%',
      price: 'AED 799',
      description:
          '6-month institutional partner page with priority event syndication',
      features: [
        'Official verified institution partner badge',
        'Host unlimited workshops & events for 6 months',
        'Top banner rotation on mobile home screen',
        'Direct ticket booking with instant notifications',
        'Dedicated account manager & support',
      ],
      buttonText: 'Select 6 Month Plan',
      itemType: 'art_centre',
      isActive: true,
      sortOrder: 11,
      duration: '180 Days (6 Months)',
      durationDays: 180,
    ),
    ListingPlanItem(
      id: 12,
      title: 'Art Centre Partner (12 Months)',
      category: 'Institutions & Venues',
      badge: 'VIP Partner',
      price: 'AED 1,299',
      description:
          'Full annual institution hub page, workshop hosting & priority event syndication',
      features: [
        'Official verified institution partner badge',
        'Unlimited event & workshop listings for 1 year',
        'Top banner rotation throughout Dubai art season',
        'Direct ticket booking with instant notifications',
        'Dedicated account manager & 24/7 priority support',
      ],
      buttonText: 'Select 12 Month Plan',
      itemType: 'art_centre',
      isActive: true,
      sortOrder: 12,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),

    // --- Chat / VIP Messaging (Starter, 1 Month, 3 Months, 6 Months, 12 Months) ---
    ListingPlanItem(
      id: 13,
      title: 'Starter Plan',
      category: 'Messaging',
      badge: 'Default',
      price: 'Free',
      description: 'Free monthly allowance to connect with artists across Dubai',
      features: [
        '10 direct messages per month',
        'Direct artist collaboration inquiries',
        'Flyer & artwork attachment support',
        'Allowance auto-resets on the 1st of each month',
      ],
      buttonText: 'Current Plan',
      itemType: 'chat',
      isActive: true,
      sortOrder: 13,
      duration: 'Monthly Reset',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 14,
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
        'Monthly reset on the 1st of each month',
      ],
      buttonText: 'Upgrade to Pro',
      itemType: 'chat',
      isActive: true,
      sortOrder: 14,
      duration: '30 Days',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 15,
      title: 'Pro Artist Chat (3 Months)',
      category: 'Messaging & Inquiries',
      badge: 'Special Offer',
      price: 'AED 129',
      description:
          'Quarterly networking pass with 50 messages per month for active artists',
      features: [
        '50 direct messages per month (150 total)',
        'Priority delivery in artist inboxes',
        'High-resolution artwork & PDF attachments',
        'Direct collector messaging channel',
      ],
      buttonText: 'Select 3 Month Plan',
      itemType: 'chat',
      isActive: true,
      sortOrder: 15,
      duration: '90 Days (3 Months)',
      durationDays: 90,
    ),
    ListingPlanItem(
      id: 16,
      title: 'Pro Artist Chat (6 Months)',
      category: 'Messaging & Inquiries',
      badge: 'Save 25%',
      price: 'AED 229',
      description:
          'Half-year continuous outreach pass with priority delivery and verified badge',
      features: [
        '50 direct messages per month (300 total)',
        'Priority delivery in artist inboxes',
        'High-resolution artwork & PDF attachments',
        'VIP chat badge next to your profile',
      ],
      buttonText: 'Select 6 Month Plan',
      itemType: 'chat',
      isActive: true,
      sortOrder: 16,
      duration: '180 Days (6 Months)',
      durationDays: 180,
    ),
    ListingPlanItem(
      id: 17,
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
      sortOrder: 17,
      duration: 'Monthly Subscription',
      durationDays: 30,
    ),
    ListingPlanItem(
      id: 18,
      title: 'Unlimited VIP (12 Months)',
      category: 'Messaging & Inquiries',
      badge: 'Best Value',
      price: 'AED 899',
      description:
          'Annual unlimited artist messaging with verified VIP sender badge for agencies and curators',
      features: [
        'Unlimited direct messages with all artists',
        'Verified VIP sender badge on all messages',
        'Priority instant customer support',
        'Full access for galleries, curators and agencies',
      ],
      buttonText: 'Select 12 Month Plan',
      itemType: 'chat',
      isActive: true,
      sortOrder: 18,
      duration: '1 Year (365 Days)',
      durationDays: 365,
    ),

    // --- Artists ---
    ListingPlanItem(
      id: 19,
      title: 'Artist Portfolio',
      category: 'Featured Profile',
      badge: 'Free',
      price: 'Free',
      description:
          'Free verified artist profile, unlimited artwork uploads & direct collector messaging',
      features: [
        'Verified Artist Badge on public profile',
        'Unlimited portfolio artwork uploads',
        'Featured spot on Artist Discovery grid',
        'Direct WhatsApp & inquiry link to artist',
        'Direct collector messaging & inquiry channel',
      ],
      buttonText: 'Create Free Profile',
      itemType: 'artist',
      isActive: true,
      sortOrder: 19,
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
