import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/utils/data_translator.dart';

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
    });

    test('Gracefully handles unknown or empty strings', () {
      expect(DataTranslator.translate('', isArabic: true), equals(''));
      expect(DataTranslator.translate(null, isArabic: true), equals(''));
      expect(
        DataTranslator.translate('Custom Unknown Category', isArabic: true),
        equals('Custom Unknown Category'),
      );
    });
  });
}
