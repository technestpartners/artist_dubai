import 'package:flutter/widgets.dart';
import '../di/injection_container.dart';
import '../services/locale_provider.dart';
import '../services/storage_service.dart';

/// Ultra-fast client-side data translator for backend strings
/// Provides instant localization & fallback translation for offline/cached responses.
class DataTranslator {
  static const Map<String, String> _enToAr = {
    // Categories (Artists, Events, Galleries)
    'contemporary painting': 'الرسم المعاصر',
    'arabic calligraphy': 'الخط العربي',
    'sculpture & bronze': 'النحت والبرونز',
    'digital & generative art': 'الفن الرقمي والتوليدي',
    'fine art photography': 'التصوير الفوتوغرافي الفني',
    'calligraphy & typography': 'الخط والطباعة الفنية',
    'digital art & sculpture': 'الفن الرقمي والنحت',
    'abstract painting': 'الرسم التجريدي',
    'ceramics & pottery': 'الخزف والفخار',
    'visual arts': 'الفنون البصرية',
    'painting & drawing': 'الرسم والتلوين',
    'sculpture & 3d art': 'النحت والفنون ثلاثية الأبعاد',
    'digital art & illustration': 'الفن الرقمي والرسم التوضيحي',
    'performing arts & music': 'الفنون الأدائية والموسيقى',
    'crafts & calligraphy': 'الحرف اليدوية والخط العربي',
    'other art form': 'أشكال فنية أخرى',
    'art exhibition': 'معرض فني',
    'gallery opening': 'افتتاح معرض',
    'art workshop': 'ورشة عمل فنية',
    'artist talk': 'حوار مع فنان',
    'art fair': 'معرض فني تجاري',
    'sculpture installation': 'تركيب نحتي',
    'photography exhibition': 'معرض تصوير فوتوغرافي',
    'cultural festival': 'مهرجان ثقافي',
    'art competition': 'مسابقة فنية',
    'community art project': 'مشروع فني مجتمعي',
    'calligraphy festival': 'مهرجان الخط العربي',
    'painting': 'رسم',
    'calligraphy': 'خط عربي',
    'sculpture': 'نحت',
    'digital art': 'فن رقمي',
    'photography': 'تصوير فوتوغرافي',
    'mixed media': 'وسائط متعددة',
    'traditional': 'فن تقليدي',
    'contemporary': 'فن معاصر',
    'fine art': 'فنون جميلة',
    'abstract': 'تجريدي',
    'realism': 'واقعي',
    'modern art': 'فن حديث',
    'street art': 'فن الشوارع',
    'illustration': 'رسم توضيحي',
    'all': 'الكل',
    'all categories': 'جميع الفئات',

    // Statuses & Availability
    'pending': 'قيد الانتظار',
    'approved': 'معتمد',
    'rejected': 'مرفوض',
    'cancelled': 'ملغى',
    'completed': 'مكتمل',
    'active': 'نشط',
    'inactive': 'غير نشط',
    'available': 'متاح',
    'sold': 'تم البيع',
    'reserved': 'محجوز',
    'confirmed': 'مؤكد',
    'upcoming': 'قادم',
    'ongoing': 'جاري',
    'closed': 'مغلق',
    'open': 'مفتوح',
    'free': 'مجاني',
    'paid': 'مدفوع',
    'free entry': 'دخول مجاني',
    'free admission': 'الدخول مجاني',
    'verified artist': 'فنان معتمد',

    // Experience Levels
    'beginner (1-2 years)': 'مبتدئ (١-٢ سنة)',
    'beginner 1-2 years': 'مبتدئ (١-٢ سنة)',
    'intermediate (3-5 years)': 'متوسط (٣-٥ سنوات)',
    'intermediate 3-5 years': 'متوسط (٣-٥ سنوات)',
    'advanced (5-10 years)': 'متقدم (٥-١٠ سنوات)',
    'advanced 5-10 years': 'متقدم (٥-١٠ سنوات)',
    'professional (5+ years)': 'محترف (٥+ سنوات)',
    'professional 5+ years': 'محترف (٥+ سنوات)',
    'professional (10+ years)': 'محترف (١٠+ سنوات)',
    'professional 10+ years': 'محترف (١٠+ سنوات)',
    'senior / 9 years': 'خبير / ٩ سنوات',
    'master / 12 years': 'رائد / ١٢ سنة',
    'senior / 14 years': 'خبير / ١٤ سنة',
    'expert / 8 years': 'متخصص / ٨ سنوات',
    'mid-senior / 6 years': 'متوسط الخبرة / ٦ سنوات',
    'emerging': 'فنان صاعد',
    'mid-career': 'متوسط الخبرة',
    'established': 'فنان متمرس',
    'master': 'فنان رائد',
    'beginner': 'مبتدئ',
    'intermediate': 'متوسط',
    'advanced': 'متقدم',
    'professional': 'محترف',
    'amateur': 'هاوٍ',

    // Mediums & Materials
    'oil & acrylic on canvas': 'زيت وأكريليك على قماش',
    'mixed media with gold flakes': 'وسائط متعددة مع رقائق الذهب',
    '24k gold leaf & ink': 'ورق ذهب عيار 24 وحبر',
    'oil on canvas': 'زيت على قماش',
    'acrylic on canvas': 'أكريليك على قماش',
    'watercolor on paper': 'ألوان مائية على ورق',
    'watercolor': 'ألوان مائية',
    'digital painting': 'رسم رقمي',
    'bronze & marble': 'برونز ورخام',
    'canvas': 'قماش',
    'paper': 'ورق',
    'wood': 'خشب',
    'metal': 'معدن',

    // Cities & Locations
    'dubai, uae': 'دبي، الإمارات',
    'abu dhabi, uae': 'أبوظبي، الإمارات',
    'sharjah, uae': 'الشارقة، الإمارات',
    'ajman, uae': 'عجمان، الإمارات',
    'ras al khaimah, uae': 'رأس الخيمة، الإمارات',
    'fujairah, uae': 'الفجيرة، الإمارات',
    'umm al quwain, uae': 'أم القيوين، الإمارات',
    'dubai': 'دبي',
    'abu dhabi': 'أبوظبي',
    'sharjah': 'الشارقة',
    'ajman': 'عجمان',
    'ras al khaimah': 'رأس الخيمة',
    'fujairah': 'الفجيرة',
    'umm al quwain': 'أم القيوين',
    'uae': 'الإمارات',
    'united arab emirates': 'الإمارات العربية المتحدة',
    'dubai design district (d3)': 'حي دبي للتصميم (d3)',
    'dubai design district': 'حي دبي للتصميم',
    'dubai design district (d3), dubai': 'حي دبي للتصميم (d3)، دبي',
    'alserkal avenue, al quoz, dubai': 'جادة السركال، القوز، دبي',
    'alserkal avenue': 'جادة السركال',
    'al quoz': 'القوز',
    'al quoz creative zone': 'منطقة القوز الإبداعية',
    'downtown dubai, uae': 'وسط مدينة دبي، الإمارات',
    'downtown dubai': 'وسط مدينة دبي',
    'difc, dubai': 'مركز دبي المالي العالمي، دبي',
    'difc': 'مركز دبي المالي العالمي',
    'al shindagha historic district, dubai': 'حي الشندغة التاريخي، دبي',
    'al shindagha historic district': 'حي الشندغة التاريخي',
    'al shindagha, dubai': 'الشندغة، دبي',
    'jaddaf waterfront, dubai': 'واجهة الجداف البحرية، دبي',
    'jaddaf waterfront': 'واجهة الجداف البحرية',
    'madinat jumeirah, dubai': 'مدينة جميرا، دبي',
    'madinat jumeirah': 'مدينة جميرا',
    'dubai marina, uae': 'دبي مارينا، الإمارات',
    'dubai marina': 'دبي مارينا',
    'palm jumeirah, dubai': 'نخلة جميرا، دبي',
    'palm jumeirah': 'نخلة جميرا',
    'jumeirah, dubai': 'جميرا، دبي',
    'jumeirah': 'جميرا',
    'jumeirah beach road': 'شارع شاطئ جميرا',
    'business bay, dubai': 'الخليج التجاري، دبي',
    'business bay': 'الخليج التجاري',
    'dubai media city': 'مدينة دبي للإعلام',

    // Government Entities & Cultural Centers
    'dubai culture & arts authority': 'هيئة الثقافة والفنون في دبي (دبي للثقافة)',
    'ministry of culture & youth': 'وزارة الثقافة والشباب',
    'art dubai': 'آرت دبي',
    'dubai opera': 'دبي أوبرا',
    'government · cultural authority': 'حكومي · هيئة ثقافية',
    'government · federal ministry': 'حكومي · وزارة اتحادية',
    'creative hub · design district': 'مركز إبداعي · حي التصميم',
    'art fair · cultural event': 'معرض فني · حدث ثقافي',
    'arts district · gallery hub': 'حي الفنون · مجمع معارض',
    'performing arts · venue': 'فنون أدائية · مسرح وفعاليات',

    // Galleries
    'custot gallery dubai': 'معرض كوستوت دبي',
    'leila heller gallery': 'معرض ليلى هيلر',
    'the third line': 'ذا ثيرد لاين',
    'jameel arts centre': 'مركز جميل للفنون',
    'contemporary art institution': 'مؤسسة للفن المعاصر',
    'contemporary middle eastern': 'معاصر من الشرق الأوسط',
    'modern & contemporary': 'حديث ومعاصر',
    'contemporary art': 'فن معاصر',

    // Events & Showcase Titles
    'dubai modern art showcase': 'معرض دبي للفن الحديث',
    'sharjah calligraphy biennial': 'بينالي الشارقة للخط العربي',
    'al quoz bronze & sculpture gala': 'احتفالية القوز للنحت والبرونز',
    'generative art & spatial 3d expo': 'معرض الفن التوليدي والأبعاد الثلاثية',
    'emirates contemporary design expo 2026': 'معرض الإمارات للتصميم المعاصر 2026',

    // Pricing & Plans
    'weekly plan': 'الخطة الأسبوعية',
    'monthly plan': 'الخطة الشهرية',
    'yearly plan': 'الخطة السنوية',
    'weekly': 'أسبوعي',
    'monthly': 'شهري',
    'yearly': 'سنوي',
    'gallery showcase': 'عرض المعرض الفني',
    'artist event publishing': 'نشر فعاليات الفنانين',

    // Home Tiles
    'about us': 'من نحن',
    'artists': 'الفنانون',
    'government': 'الجهات الحكومية',
    'artist registration': 'تسجيل فنان',
    'events competition': 'الفعاليات والمسابقات',
    'galleries art center': 'المعارض والمراكز الفنية',
    'events photos': 'صور الفعاليات',
    'art venue registration': 'تسجيل المعارض الفنية',
    'art venue': 'معرض فني',
    'artist': 'فنان',
    'registration': 'تسجيل',
    'events': 'فعاليات',
    'competition': 'مسابقة',
    'galleries': 'معارض فنية',
    'art center': 'مركز فني',
    'photos': 'صور',
  };

  // Lazy reversed map for Arabic to English lookups
  static Map<String, String>? _arToEn;
  static Map<String, String> get arToEn {
    if (_arToEn == null) {
      final map = <String, String>{};
      _enToAr.forEach((en, ar) {
        map[ar.trim().toLowerCase()] = en;
      });
      _arToEn = map;
    }
    return _arToEn!;
  }

  /// Check whether the current app locale is Arabic.
  static bool get isAppArabic {
    try {
      if (sl.isRegistered<LocaleProvider>()) {
        return sl<LocaleProvider>().isArabic;
      }
      if (sl.isRegistered<StorageService>()) {
        final loc = sl<StorageService>().getString('app_locale');
        return loc == 'ar';
      }
    } catch (_) {}
    return false;
  }

  /// Fast helper to translate with BuildContext
  static String tr(BuildContext context, dynamic text) {
    return translate(text, context: context);
  }

  /// Flexible translation method:
  /// Can be called as:
  /// - `DataTranslator.translate(text, isArabic: true/false)`
  /// - `DataTranslator.translate(text, context: context)`
  /// - `DataTranslator.translate(text)` (uses app-wide locale)
  static String translate(
    dynamic text, {
    bool? isArabic,
    BuildContext? context,
  }) {
    bool ar = false;
    if (context != null) {
      try {
        ar = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        ar = isAppArabic;
      }
    } else if (isArabic != null) {
      ar = isArabic;
    } else {
      ar = isAppArabic;
    }

    final sText = text?.toString();
    if (sText == null || sText.trim().isEmpty) return '';
    final trimmed = sText.trim();
    final lower = trimmed.toLowerCase();

    if (ar) {
      // 1. Direct dictionary match
      if (_enToAr.containsKey(lower)) {
        return _enToAr[lower]!;
      }

      // 2. Pattern matching for compound status and timing strings
      if (lower.startsWith('open · closes at ')) {
        final timePart = trimmed.substring(17).trim();
        return 'مفتوح · يغلق في $timePart';
      }
      if (lower.startsWith('open · next show at ')) {
        final timePart = trimmed.substring(20).trim();
        return 'مفتوح · العرض القادم في $timePart';
      }
      if (lower.startsWith('closed · opens at ')) {
        final timePart = trimmed.substring(18).trim();
        return 'مغلق · يفتح في $timePart';
      }
      if (lower.startsWith('closed · opens tomorrow at ')) {
        final timePart = trimmed.substring(27).trim();
        return 'مغلق · يفتح غداً في $timePart';
      }
      if (lower.startsWith('closed · opens monday at ')) {
        final timePart = trimmed.substring(25).trim();
        return 'مغلق · يفتح الإثنين في $timePart';
      }
      if (lower.startsWith('closed · opens ')) {
        final rest = trimmed.substring(15).trim();
        return 'مغلق · يفتح في $rest';
      }
      if (lower.endsWith(' artists')) {
        final count = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return '$count فنان';
      }
      if (lower.endsWith(' photos')) {
        final count = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return '$count صورة';
      }
      if (lower == 'recent' || lower == 'just now') {
        return 'الآن';
      }
      if (lower.endsWith('m ago')) {
        final mins = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return 'منذ $mins دقيقة';
      }
      if (lower.endsWith('h ago')) {
        final hrs = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return 'منذ $hrs ساعة';
      }
      if (lower.endsWith('d ago')) {
        final days = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return 'منذ $days يوم';
      }

      return trimmed;
    } else {
      // Arabic -> English lookup
      if (arToEn.containsKey(lower)) {
        return _capitalize(arToEn[lower]!);
      }
      return trimmed;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    const specialCases = {
      'uae': 'UAE',
      'dubai, uae': 'Dubai, UAE',
      'abu dhabi, uae': 'Abu Dhabi, UAE',
      'sharjah, uae': 'Sharjah, UAE',
      'ajman, uae': 'Ajman, UAE',
      'ras al khaimah, uae': 'Ras Al Khaimah, UAE',
      'fujairah, uae': 'Fujairah, UAE',
      'umm al quwain, uae': 'Umm Al Quwain, UAE',
    };
    if (specialCases.containsKey(s.toLowerCase().trim())) {
      return specialCases[s.toLowerCase().trim()]!;
    }
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      final wClean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (wClean == 'uae') return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

/// Helpful extension on String for translating dynamic backend data in widgets
extension BackendDataTranslationExtension on String {
  /// Translates this string based on current app locale from Flutter context
  String trData([BuildContext? context]) {
    bool isArabic = false;
    if (context != null) {
      try {
        isArabic = Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        isArabic = DataTranslator.isAppArabic;
      }
    } else {
      isArabic = DataTranslator.isAppArabic;
    }
    return DataTranslator.translate(this, isArabic: isArabic);
  }
}
