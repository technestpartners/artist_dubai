class PublishingPricingModel {
  final int id;
  final String itemType; // 'event' or 'gallery'
  final String itemName;
  final String weeklyPrice;
  final String monthlyPrice;
  final String yearlyPrice;
  final String currency;
  final bool isActive;
  final String? description;
  final String? updatedAt;

  const PublishingPricingModel({
    required this.id,
    required this.itemType,
    required this.itemName,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.currency = 'AED',
    this.isActive = true,
    this.description,
    this.updatedAt,
  });

  factory PublishingPricingModel.fromJson(Map<String, dynamic> json) {
    return PublishingPricingModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemType: (json['item_type'] ?? json['type'] ?? 'event').toString().toLowerCase().trim(),
      itemName: (json['item_name'] ?? json['name'] ?? 'Publishing Plan').toString(),
      weeklyPrice: (json['weekly_price'] ?? json['weekly'] ?? 'AED 150').toString(),
      monthlyPrice: (json['monthly_price'] ?? json['monthly'] ?? 'AED 500').toString(),
      yearlyPrice: (json['yearly_price'] ?? json['yearly'] ?? 'AED 4,500').toString(),
      currency: (json['currency'] ?? 'AED').toString(),
      isActive: json['is_active'] == null || json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
      description: json['description']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_type': itemType,
    'item_name': itemName,
    'weekly_price': weeklyPrice,
    'monthly_price': monthlyPrice,
    'yearly_price': yearlyPrice,
    'currency': currency,
    'is_active': isActive ? 1 : 0,
    'description': description,
    'updated_at': updatedAt,
  };

  PublishingPricingModel copyWith({
    int? id,
    String? itemType,
    String? itemName,
    String? weeklyPrice,
    String? monthlyPrice,
    String? yearlyPrice,
    String? currency,
    bool? isActive,
    String? description,
    String? updatedAt,
  }) {
    return PublishingPricingModel(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemName: itemName ?? this.itemName,
      weeklyPrice: weeklyPrice ?? this.weeklyPrice,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getPriceForPlan(String plan) {
    switch (plan.toLowerCase().trim()) {
      case 'yearly':
      case 'year':
      case 'annual':
        return yearlyPrice;
      case 'monthly':
      case 'month':
        return monthlyPrice;
      case 'weekly':
      case 'week':
      default:
        return weeklyPrice;
    }
  }
}
