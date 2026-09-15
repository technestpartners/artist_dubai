import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/utils/data_translator.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';

void main() {
  group('DataTranslator Tests', () {
    test('Translates categories correctly to Arabic', () {
      expect(
        DataTranslator.translate('Contemporary Painting', isArabic: true),
        equals('الرسم المعاصر'),
      );
      expect(
        DataTranslator.translate('Arabic Calligraphy', isArabic: true),
        equals('الخط العربي'),
      );
      expect(
        DataTranslator.translate('Sculpture & Bronze', isArabic: true),
        equals('النحت والبرونز'),
      );
    });

    test('Preserves original text when isArabic is false', () {
      expect(
        DataTranslator.translate('Contemporary Painting', isArabic: false),
        equals('Contemporary Painting'),
      );
      expect(
        DataTranslator.translate('Dubai, UAE', isArabic: false),
        equals('Dubai, UAE'),
      );
    });

    test('Translates locations and statuses correctly to Arabic', () {
      expect(
        DataTranslator.translate('Dubai, UAE', isArabic: true),
        equals('دبي، الإمارات'),
      );
      expect(
        DataTranslator.translate('approved', isArabic: true),
        equals('معتمد'),
      );
      expect(
        DataTranslator.translate('pending', isArabic: true),
        equals('قيد الانتظار'),
      );
    });

    test('Translates Arabic back to English correctly', () {
      expect(
        DataTranslator.translate('الرسم المعاصر', isArabic: false),
        equals('Contemporary Painting'),
      );
      expect(
        DataTranslator.translate('دبي، الإمارات', isArabic: false),
        equals('Dubai, UAE'),
      );
      expect(
        DataTranslator.translate('معتمد', isArabic: false),
        equals('Approved'),
      );
      expect(
        DataTranslator.translate('تفاصيل الفعالية', isArabic: false),
        equals('Event Details'),
      );
      expect(
        DataTranslator.translate('فتح الاتجاهات', isArabic: false),
        equals('Open Directions'),
      );
      expect(
        DataTranslator.translate('جوجل', isArabic: false),
        equals('Google'),
      );
      expect(
        DataTranslator.translate('بيت الحكمة والفنون، دبي', isArabic: false),
        equals('House of Wisdom & Arts, Dubai'),
      );
      expect(
        DataTranslator.translate('اليوم • 11:00 صباحاً - 09:00 مساءً', isArabic: false),
        equals('Today • 11:00 AM - 09:00 PM'),
      );
    });

    test('Pattern matching for compound status and timing', () {
      expect(
        DataTranslator.translate('Open · Closes at 8:00 PM', isArabic: true),
        equals('مفتوح · يغلق في 8:00 PM'),
      );
      expect(
        DataTranslator.translate('Closed · Opens at 9:00 AM', isArabic: true),
        equals('مغلق · يفتح في 9:00 AM'),
      );
      expect(
        DataTranslator.translate('12 artists', isArabic: true),
        equals('12 فنان'),
      );
      expect(
        DataTranslator.translate('Recent', isArabic: true),
        equals('الآن'),
      );
      expect(
        DataTranslator.translate('Today • 11:00 AM - 09:00 PM', isArabic: true),
        equals('اليوم • 11:00 صباحاً - 09:00 مساءً'),
      );
      expect(
        DataTranslator.translate('This Week • 04:00 PM - 07:00 PM', isArabic: true),
        equals('هذا الأسبوع • 04:00 مساءً - 07:00 مساءً'),
      );
      expect(
        DataTranslator.translate('House of Wisdom & Arts, Dubai', isArabic: true),
        equals('بيت الحكمة والفنون، دبي'),
      );
      expect(
        DataTranslator.translate('House of Wisdom & Arts', isArabic: true),
        equals('بيت الحكمة والفنون'),
      );
      expect(
        DataTranslator.translate('Event Details', isArabic: true),
        equals('تفاصيل الفعالية'),
      );
      expect(
        DataTranslator.translate('Open Directions', isArabic: true),
        equals('فتح الاتجاهات'),
      );
      expect(
        DataTranslator.translate('Google', isArabic: true),
        equals('جوجل'),
      );
    });

    test('Translates dynamic backend cities and bios to Arabic', () {
      expect(
        DataTranslator.translate('Hannover', isArabic: true),
        equals('هانوفر'),
      );
      expect(
        DataTranslator.translate('Braunschweig', isArabic: true),
        equals('براونشفايغ'),
      );
      expect(
        DataTranslator.translate('burj', isArabic: true),
        equals('برج'),
      );
      expect(
        DataTranslator.translate('Germany', isArabic: true),
        equals('ألمانيا'),
      );
      expect(
        DataTranslator.translate('London', isArabic: true),
        equals('لندن'),
      );
    });


    test('Translates gallery strings and explore pattern matching', () {
      expect(
        DataTranslator.translate('Photo Galleries', isArabic: true),
        equals('معارض الصور'),
      );
      expect(
        DataTranslator.translate('Create Gallery', isArabic: true),
        equals('إنشاء معرض'),
      );
      expect(
        DataTranslator.translate('Featured', isArabic: true),
        equals('مميز'),
      );
      expect(
        DataTranslator.translate("Explore Shiv's collection of artworks", isArabic: true),
        equals('استكشف مجموعة أعمال Shiv الفنية'),
      );
    });

    test('Gracefully handles empty strings and pure punctuation', () {
      expect(DataTranslator.translate('', isArabic: true), equals(''));
      expect(DataTranslator.translate(null, isArabic: true), equals(''));
      expect(DataTranslator.translate('.', isArabic: true), equals('.'));
      expect(DataTranslator.translate('...', isArabic: true), equals('...'));
      expect(DataTranslator.translate('-', isArabic: true), equals('-'));
    });

    test('Translates test and demo terms accurately to Arabic', () {
      expect(DataTranslator.translate('Test', isArabic: true), equals('اختبار'));
      expect(DataTranslator.translate('test', isArabic: true), equals('اختبار'));
      expect(DataTranslator.translate('tezt', isArabic: true), equals('اختبار'));
      expect(DataTranslator.translate('demo', isArabic: true), equals('عرض تجريبي'));
      expect(DataTranslator.translate('sample', isArabic: true), equals('عينة'));
      expect(DataTranslator.translate('good', isArabic: true), equals('جيد'));
    });

    test('ArtEventModel recovers from backend dot translations using _en fallback', () {
      final json = {
        'id': 10,
        'title': '.',
        'title_en': 'test',
        'description': '.',
        'description_en': 'test',
        'category': 'Gallery Opening',
        'price': 'Free',
      };
      final model = ArtEventModel.fromJson(json);
      // In Arabic environment, title and description will be translated from 'test' -> 'اختبار'
      final arTitle = DataTranslator.translate(model.title, isArabic: true);
      final arDesc = DataTranslator.translate(model.description, isArabic: true);
      expect(arTitle, equals('اختبار'));
      expect(arDesc, equals('اختبار'));
    });

    test('Translates artwork upload limits and profile messages to Arabic', () {
      expect(
        DataTranslator.translate('Maximum 6 artwork uploads allowed.', isArabic: true),
        equals('الحد الأقصى المسموح به هو 6 أعمال فنية.'),
      );
      expect(
        DataTranslator.translate('Maximum 6 artwork uploads allowed', isArabic: true),
        equals('الحد الأقصى المسموح به هو 6 أعمال فنية.'),
      );
      expect(
        DataTranslator.translate('.Maximum 6 artwork uploads allowed', isArabic: true),
        equals('الحد الأقصى المسموح به هو 6 أعمال فنية.'),
      );
      expect(
        DataTranslator.translate('Artist Profile updated successfully!', isArabic: true),
        equals('تم تحديث الملف الفني بنجاح!'),
      );
      expect(
        DataTranslator.translate('Artist Profile & 4 Artworks created successfully!', isArabic: true),
        equals('تم إنشاء الملف الفني وإضافة 4 عمل فني بنجاح!'),
      );
    });
  });
}
