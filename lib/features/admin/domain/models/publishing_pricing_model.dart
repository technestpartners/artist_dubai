import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';

class PublishingPricingModel {
  final int id;
  final String itemType; // 'event' or 'gallery'
  final String itemName;
  final String weeklyPrice;
  final String monthlyPrice;
  final String threeMonthPrice;
  final String sixMonthPrice;
  final String yearlyPrice;
  final String threeMonthBadge;
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
    this.threeMonthPrice = 'AED 2,000',
    this.sixMonthPrice = 'AED 3,000',
    required this.yearlyPrice,
    this.threeMonthBadge = 'Special Offer',
    this.sixMonthBadge = 'Save 25%',
    this.yearlyBadge = 'Best Value',
    this.currency = 'AED',
    this.isActive = true,
    this.description,
    this.updatedAt,
  });

  String localizedItemName([BuildContext? context]) => itemName.trData(context);

  factory PublishingPricingModel.fromJson(Map<String, dynamic> json) {
    final type =
        (json['item_type'] ?? json['type'] ?? 'event')
            .toString()
            .toLowerCase()
            .trim();
    final defaultThreeMonth = type == 'gallery' ? 'AED 2,000' : 'AED 1,200';
    final defaultSixMonth = type == 'gallery' ? 'AED 3,000' : 'AED 2,500';
    final defaultYearly = type == 'gallery' ? 'AED 5,000' : 'AED 4,500';
    final defaultThreeMonthBadge =
        type == 'gallery' ? 'Special Offer' : 'Popular';
    final defaultSixMonthBadge = type == 'gallery' ? 'Save 25%' : 'Save 17%';
    final defaultYearlyBadge = type == 'gallery' ? 'Best Value' : 'Best Value';
    final defaultDesc = type == 'gallery'
        ? 'Feature your gallery on curated maps and event calendars, with professional event photography.'
        : 'Publish art events and exhibitions across Dubai';
    return PublishingPricingModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemType: type,
      itemName:
          (json['item_name'] ?? json['name'] ?? 'Publishing Plan').toString(),
      weeklyPrice:
          (json['weekly_price'] ??
                  json['weekly'] ??
                  (type == 'gallery' ? 'AED 250' : 'AED 150'))
              .toString(),
      monthlyPrice:
          (json['monthly_price'] ??
                  json['monthly'] ??
                  (type == 'gallery' ? 'AED 800' : 'AED 500'))
              .toString(),
      threeMonthPrice:
          (json['three_month_price'] ??
                  json['three_month'] ??
                  json['threeMonthPrice'] ??
                  defaultThreeMonth)
              .toString(),
      sixMonthPrice:
          (json['six_month_price'] ??
                  json['six_month'] ??
                  json['sixMonthPrice'] ??
                  defaultSixMonth)
              .toString(),
      yearlyPrice:
          (json['yearly_price'] ??
                  json['yearly'] ??
                  defaultYearly)
              .toString(),
      threeMonthBadge:
          (json['three_month_badge'] ??
                  json['threeMonthBadge'] ??
                  defaultThreeMonthBadge)
              .toString(),
      sixMonthBadge:
          (json['six_month_badge'] ??
                  json['sixMonthBadge'] ??
                  defaultSixMonthBadge)
              .toString(),
      yearlyBadge:
          (json['yearly_badge'] ?? json['yearlyBadge'] ?? defaultYearlyBadge)
              .toString(),
      currency: (json['currency'] ?? 'AED').toString(),
      isActive:
          json['is_active'] == null ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == true,
      description: json['description']?.toString() ?? defaultDesc,
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_type': itemType,
    'item_name': itemName,
    'weekly_price': weeklyPrice,
    'monthly_price': monthlyPrice,
    'three_month_price': threeMonthPrice,
    'six_month_price': sixMonthPrice,
    'yearly_price': yearlyPrice,
    'three_month_badge': threeMonthBadge,
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
    String? threeMonthPrice,
    String? sixMonthPrice,
    String? yearlyPrice,
    String? threeMonthBadge,
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
      threeMonthPrice: threeMonthPrice ?? this.threeMonthPrice,
      sixMonthPrice: sixMonthPrice ?? this.sixMonthPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      threeMonthBadge: threeMonthBadge ?? this.threeMonthBadge,
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
      case '12month':
      case '12months':
      case '12_month':
      case 'twelve_month':
        return yearlyPrice;
      case 'six_month':
      case '6month':
      case '6months':
      case '6_month':
      case 'semi_annual':
      case 'half_year':
        return sixMonthPrice;
      case 'three_month':
      case '3month':
      case '3months':
      case '3_month':
      case 'quarterly':
        return threeMonthPrice;
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
