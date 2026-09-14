import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

class PublishingPricingModel {
  final int id;
  final String itemType; // 'event' or 'gallery'
  final String itemName;
  final String weeklyPrice;
  final String monthlyPrice;
  final String sixMonthPrice;
  final String yearlyPrice;
  final String sixMonthBadge;
  final String yearlyBadge;
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
    this.sixMonthPrice = 'AED 2,500',
    required this.yearlyPrice,
    this.sixMonthBadge = 'Save 17%',
    this.yearlyBadge = 'Best Value',
    this.currency = 'AED',
    this.isActive = true,
    this.description,
    this.updatedAt,
  });

  String localizedItemName([BuildContext? context]) => itemName.trData(context);

  factory PublishingPricingModel.fromJson(Map<String, dynamic> json) {
    final type = (json['item_type'] ?? json['type'] ?? 'event').toString().toLowerCase().trim();
    final defaultSixMonth = type == 'gallery' ? 'AED 3,800' : 'AED 2,500';
    final defaultSixMonthBadge = type == 'gallery' ? 'Save 15%' : 'Save 17%';
    return PublishingPricingModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemType: type,
      itemName: (json['item_name'] ?? json['name'] ?? 'Publishing Plan').toString(),
      weeklyPrice: (json['weekly_price'] ?? json['weekly'] ?? (type == 'gallery' ? 'AED 200' : 'AED 150')).toString(),
      monthlyPrice: (json['monthly_price'] ?? json['monthly'] ?? (type == 'gallery' ? 'AED 750' : 'AED 500')).toString(),
      sixMonthPrice: (json['six_month_price'] ?? json['six_month'] ?? json['sixMonthPrice'] ?? defaultSixMonth).toString(),
      yearlyPrice: (json['yearly_price'] ?? json['yearly'] ?? (type == 'gallery' ? 'AED 6,500' : 'AED 4,500')).toString(),
      sixMonthBadge: (json['six_month_badge'] ?? json['sixMonthBadge'] ?? defaultSixMonthBadge).toString(),
      yearlyBadge: (json['yearly_badge'] ?? json['yearlyBadge'] ?? 'Best Value').toString(),
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
    'six_month_price': sixMonthPrice,
    'yearly_price': yearlyPrice,
    'six_month_badge': sixMonthBadge,
    'yearly_badge': yearlyBadge,
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
    String? sixMonthPrice,
    String? yearlyPrice,
    String? sixMonthBadge,
    String? yearlyBadge,
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
      sixMonthPrice: sixMonthPrice ?? this.sixMonthPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      sixMonthBadge: sixMonthBadge ?? this.sixMonthBadge,
      yearlyBadge: yearlyBadge ?? this.yearlyBadge,
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
      case '1year':
      case '1_year':
        return yearlyPrice;
      case 'six_month':
      case '6month':
      case '6months':
      case '6_month':
      case 'semi_annual':
      case 'half_year':
        return sixMonthPrice;
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
