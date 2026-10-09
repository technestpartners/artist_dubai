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
  });

  factory ListingPlanItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] is List) {
      parsedFeatures = (json['features'] as List).map((e) => e.toString()).toList();
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

    return ListingPlanItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'One-time',
      price: json['price']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      features: parsedFeatures,
      buttonText: json['button_text']?.toString() ?? 'Pay from My Listings',
      itemType: itemType,
      isActive: json['is_active'] == null ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == true,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
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
    );
  }
}

typedef ListingPlanModel = ListingPlanItem;
