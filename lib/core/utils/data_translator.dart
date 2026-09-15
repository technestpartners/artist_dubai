import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../di/injection_container.dart';
import '../services/locale_provider.dart';
import '../services/storage_service.dart';

/// Ultra-fast client-side data translator for backend strings
/// Combines instant dictionary lookups with automatic Google Translate caching
/// for any arbitrary user-generated content (bios, custom locations, descriptions).
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

    // Test & Sample Words
    'test': 'اختبار',
    'testing': 'اختبار',
    'tezt': 'اختبار',
    'demo': 'عرض تجريبي',
    'sample': 'عينة',
    'trial': 'تجربة',
    'good': 'جيد',
    'bad': 'سيء',
    'abc': 'اي بي سي',

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

    // Cities, Locations & Landmarks
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
    'al ain': 'العين',
    'al ain, uae': 'العين، الإمارات',
    'hatta': 'حتا',
    'hata': 'حتا',
    'khorfakkan': 'خورفكان',
    'kalba': 'كلباء',
    'dibba': 'دبا',
    'hannover': 'هانوفر',
    'braunschweig': 'براونشفايغ',
    'burj': 'برج',
    'burj khalifa': 'برج خليفة',
    'at post kurunda': 'كوروندا',
    'kurunda': 'كوروندا',
    'germany': 'ألمانيا',
    'berlin': 'برلين',
    'munich': 'ميونخ',
    'frankfurt': 'فرانكفورت',
    'hamburg': 'هامبورغ',
    'cologne': 'كولونيا',
    'dusseldorf': 'دوسلدورف',
    'stuttgart': 'شتوتغارت',
    'london': 'لندن',
    'paris': 'باريس',
    'new york': 'نيويورك',
    'tokyo': 'طوكيو',
    'india': 'الهند',
    'mumbai': 'مومباي',
    'delhi': 'دلهي',
    'riyadh': 'الرياض',
    'jeddah': 'جدة',
    'cairo': 'القاهرة',
    'beirut': 'بيروت',
    'amman': 'عمان',
    'doha': 'الدوحة',
    'kuwait': 'الكويت',
    'manama': 'المنامة',
    'muscat': 'مسقط',
    'dubai design district (d3)': 'حي دبي للتصميم (d3)',
    'dubai design district': 'حي دبي للتصميم',
    'dubai design district, building 7': 'حي دبي للتصميم، مبنى 7',
    'building 7': 'مبنى 7',
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
    'house of wisdom & arts, dubai': 'بيت الحكمة والفنون، دبي',
    'house of wisdom & arts': 'بيت الحكمة والفنون',
    'house of wisdom': 'بيت الحكمة',
    'difc gate village, building 03, dubai': 'قرية البوابة، المبنى 03، مركز دبي المالي العالمي، دبي',
    'difc gate village, building 03': 'قرية البوابة، المبنى 03، مركز دبي المالي العالمي',
    'difc gate village': 'قرية البوابة، مركز دبي المالي العالمي',
    'dubai mall, level 2, downtown dubai': 'دبي مول، الطابق 2، وسط مدينة دبي',
    'dubai mall, level 2': 'دبي مول، الطابق 2',
    'dubai mall': 'دبي مول',
    'al fahidi historical neighbourhood, dubai': 'حي الفهيدي التاريخي، دبي',
    'al fahidi historical neighbourhood': 'حي الفهيدي التاريخي',
    'al fahidi': 'الفهيدي',
    'jumeirah art center, jumeirah 1, dubai': 'مركز جميرا للفنون، جميرا 1، دبي',
    'jumeirah art center': 'مركز جميرا للفنون',
    'the pottery shed, warehouse 42, al quoz, dubai': 'ذا بوتري شيد، المستودع 42، القوز، دبي',
    'the pottery shed': 'ذا بوتري شيد',
    'hatta wadi hub, located off the dubai-hatta road, dubai': 'حتا وادي هب، طريق دبي-حتا، دبي',
    'hatta wadi hub': 'حتا وادي هب',
    'dubai opera gallery, downtown dubai': 'معرض دبي أوبرا، وسط مدينة دبي',

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


    // Pricing & Plans
    'weekly plan': 'الخطة الأسبوعية',
    'monthly plan': 'الخطة الشهرية',
    'yearly plan': 'الخطة السنوية',
    'weekly': 'أسبوعي',
    'monthly': 'شهري',
    'yearly': 'سنوي',
    'gallery showcase': 'عرض المعرض الفني',
    'artist event publishing': 'نشر فعاليات الفنانين',

    // Home Tiles & Common Words
    'about us': 'من نحن',
    'artists': 'الفنانون',
    'government': 'الجهات الحكومية',
    'artist registration': 'تسجيل فنان',
    'events competition': 'الفعاليات والمسابقات',
    'galleries art center': 'المعارض والمراكز الفنية',
    'events photos': 'صور الفعاليات',
    'art venue registration': 'تسجيل المعارض الفنية',
    'art venue': 'معرض فني',
    'photos': 'صور',

    // Photo Galleries & Portfolio Details
    'featured': 'مميز',
    'photo galleries': 'معارض الصور',
    'create gallery': 'إنشاء معرض',
    'create new gallery': 'إنشاء معرض جديد',
    'gallery title': 'عنوان المعرض',
    'gallery photos': 'صور المعرض',
    'edit gallery': 'تعديل المعرض',
    'edit photo gallery': 'تعديل معرض الصور',
    'delete gallery': 'حذف المعرض',
    'save changes': 'حفظ التغييرات',
    'no photo galleries available yet': 'لا توجد معارض صور متاحة حتى الآن',
    'no artworks added yet': 'لم تتم إضافة أي أعمال فنية بعد',
    'gallery options': 'خيارات المعرض',
    'new': 'جديد',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'click to select images or drag and drop': 'انقر لتحديد الصور أو اسحبها وأفلتها',
    'please enter a gallery title': 'الرجاء إدخال عنوان المعرض',
    'please select at least one photo from your gallery': 'الرجاء تحديد صورة واحدة على الأقل من معرضك',
    'failed to delete gallery. please try again.': 'فشل حذف المعرض. يرجى المحاولة مرة أخرى.',
    'profile picture updated successfully!': 'تم تحديث صورة الملف الشخصي بنجاح!',
    'please have at least one photo in the gallery': 'يجب أن يحتوي المعرض على صورة واحدة على الأقل',
    'a gallery must have at least 1 photo': 'يجب أن يحتوي المعرض على صورة واحدة على الأقل',
    'required details missing': 'بيانات مطلوبة مفقودة',
    'upload failed': 'فشل التحميل',
    'failed to upload photos. please try again.': 'فشل تحميل الصور. يرجى المحاولة مرة أخرى.',
    'ok': 'موافق',

    // Events UI, Filters, Sorting & Dates
    "what's on": 'الفعاليات الحالية',
    'search events': 'البحث في الفعاليات',
    'today': 'اليوم',
    'this week': 'هذا الأسبوع',
    'custom dates': 'تواريخ مخصصة',
    'date': 'التاريخ',
    'filter by date': 'تصفية حسب التاريخ',
    'all dates': 'جميع التواريخ',
    'category': 'الفئة',
    'filter by category': 'تصفية حسب الفئة',
    'search categories...': 'البحث في الفئات...',
    'sort by': 'ترتيب حسب',
    'sort events': 'ترتيب الفعاليات',
    'soonest': 'الأقرب موعداً',
    'title (a - z)': 'العنوان (أ - ي)',
    'price: low to high': 'السعر: من الأقل إلى الأعلى',
    'price: high to low': 'السعر: من الأعلى إلى الأقل',
    'most popular': 'الأكثر شعبية',
    'see all': 'عرض الكل',
    'recommended for you': 'موصى به لك',
    'search results': 'نتائج البحث',
    'clear all': 'مسح الكل',
    'clear all filters': 'مسح جميع الفلاتر',
    'no events found matching your search.': 'لم يتم العثور على فعاليات تطابق بحثك.',
    'try adjusting your dates, category, or price filters.': 'جرّب تعديل التاريخ أو الفئة أو فلاتر الأسعار.',
    'reset': 'إعادة ضبط',
    'register art event': 'تسجيل فعالية فنية',
    'event details': 'تفاصيل الفعالية',
    'about event': 'حول الفعالية',
    'date & time': 'التاريخ والوقت',
    'location': 'الموقع',
    'organizer': 'المنظم',
    'book now': 'احجز الآن',
    'rsvp': 'تأكيد الحضور',
    'get directions': 'الاتجاهات',
    'share event': 'مشاركة الفعالية',

    // Specific Known Events & Cultural Venues
    'live api test exhibition 8831': 'معرض اختبار واجهة برمجة التطبيق المباشر 8831',
    'live api test exhibition': 'معرض اختبار واجهة برمجة التطبيق المباشر',
    'api test exhibition': 'معرض اختبار واجهة برمجة التطبيق',
    'api testing exhibition': 'معرض اختبار واجهة برمجة التطبيق',
    'sharjah calligraphy biennial': 'بينالي الشارقة للخط',
    'sharjah calligraphy meeting': 'ملتقى الشارقة للخط',
    'dubai modern art showcase': 'معرض دبي للفن الحديث',
    'emirates contemporary design expo 2026': 'معرض الإمارات للتصميم المعاصر 2026',
    'heart of sharjah heritage area': 'قلب الشارقة التراثي',
    'dubai opera gallery': 'معرض دبي أوبرا',
    'alserkal avenue, warehouse 42': 'جادة السركال، المستودع 42',

    // Onboarding Strings
    'welcome to dubai artists': 'مرحباً بكم في فنان دبي',
    'discover the vibrant art scene of dubai and connect with talented local artists': 'اكتشف مشهد الفن النابض في دبي وتواصل مع فنانين محليين موهوبين',
    'meet local artists': 'تعرف على الفنانين المحليين',
    'connect directly with artists, learn about their stories and commission custom works': 'تواصل مباشرة مع الفنانين وتعرف على قصصهم واطلب أعمالاً خاصة',
    'explore art galleries': 'استكشف المعارض الفنية',
    'browse through curated collections and find your next favorite piece': 'تصفح المجموعات الفنية المختارة واعثر على عملك المفضل التالي',
    'art events & exhibitions': 'الفعاليات والمعارض الفنية',
    'stay updated with the latest art events, exhibitions and cultural happenings in dubai': 'ابقَ على اطلاع بأحدث الفعاليات والمعارض والأنشطة الثقافية في دبي',
    'skip': 'تخطي',
    'previous': 'السابق',
    'next': 'التالي',
    'get started': 'ابدأ الآن',

    // Galleries & Art Centers
    'no art centers listed yet': 'لا توجد مراكز فنية مدرجة حتى الآن',
    'registered galleries and art centers will be shown here.': 'ستظهر المعارض والمراكز الفنية المسجلة هنا.',
    'please log in to register an art gallery': 'يرجى تسجيل الدخول لتسجيل معرض فني',
    'art space': 'مساحة فنية',
    'art gallery': 'معرض فني',

    // Events & My Events & Date Picker & Detail
    'open directions': 'فتح الاتجاهات',
    'google': 'جوجل',
    'read more': 'قراءة المزيد',
    'read less': 'قراءة أقل',
    'select date range': 'تحديد النطاق الزمني',
    'save': 'حفظ',
    'submitted events are sent to the administrator for review and will be published once approved.': 'يتم إرسال الفعاليات المقدمة إلى المسؤول للمراجعة وسيتم نشرها بمجرد الموافقة عليها.',
    'no images available': 'لا توجد صور متاحة',
    'close': 'إغلاق',
    'free community entry': 'دخول مجاني للمجتمع',
    'pending review': 'قيد المراجعة',
    'approved & live': 'معتمد ونشط',
    'back': 'رجوع',
    'home': 'الرئيسية',
    'directions': 'الاتجاهات',
    'share': 'مشاركة',
    'music & concerts': 'الموسيقى والحفلات الغنائية',
    'sports & fitness': 'الرياضة واللياقة',
    'al quoz 1': 'القوز 1',
    'al quoz industrial area 1': 'منطقة القوز الصناعية 1',
    'jumeirah 1': 'جميرا 1',
    'al barsha': 'البرشاء',
    'al seef': 'السيف',
    'city walk': 'سيتي ووك',
    'al satwa': 'السطوة',
    'deira': 'ديرة',
    'bur dubai': 'بر دبي',
    'tashkeel': 'تشكيل',
    'the jamjar': 'ذا جم جار',
    'jameel arts centre': 'مركز جميل للفنون',
    'maraya art centre': 'مركز مرايا للفنون',
    'sharjah art foundation': 'مؤسسة الشارقة للفنون',
    'louvre abu dhabi': 'اللوفر أبوظبي',

    // Artist Profile Creation, Artwork Uploads & Validation
    'maximum 6 artwork uploads allowed.': 'الحد الأقصى المسموح به هو 6 أعمال فنية.',
    'maximum 6 artwork uploads allowed': 'الحد الأقصى المسموح به هو 6 أعمال فنية.',
    'maximum 6 artworks allowed.': 'الحد الأقصى المسموح به هو 6 أعمال فنية.',
    'maximum 6 artworks allowed': 'الحد الأقصى المسموح به هو 6 أعمال فنية.',
    'maximum 6 artworks reached': 'تم الوصول للحد الأقصى (6 أعمال)',
    'error selecting profile picture': 'خطأ أثناء اختيار صورة الملف الشخصي',
    'error selecting banner picture': 'خطأ أثناء اختيار صورة الغلاف',
    'error selecting images': 'خطأ أثناء اختيار الصور',
    'error taking photo': 'خطأ أثناء التقاط الصورة',
    'artist profile updated successfully!': 'تم تحديث الملف الفني بنجاح!',
    'artist profile updated successfully': 'تم تحديث الملف الفني بنجاح',
    'update failed': 'فشل التحديث',
    'failed to update profile. please check your inputs.': 'فشل تحديث الملف الشخصي. يرجى التحقق من المدخلات.',
    'failed to update profile.': 'فشل تحديث الملف الشخصي.',
    'failed to update profile': 'فشل تحديث الملف الشخصي',
    'save failed': 'فشل الحفظ',
    'failed to save profile. please check your inputs.': 'فشل حفظ الملف الشخصي. يرجى التحقق من المدخلات.',
    'failed to save profile.': 'فشل حفظ الملف الشخصي.',
    'failed to save profile': 'فشل حفظ الملف الشخصي',
    'please enter your full name or stage name.': 'يرجى إدخال اسمك الكامل أو اسمك الفني.',
    'please enter your full name or stage name': 'يرجى إدخال اسمك الكامل أو اسمك الفني',
    'please enter your email address.': 'يرجى إدخال بريدك الإلكتروني.',
    'please enter your email address': 'يرجى إدخال بريدك الإلكتروني',
    'invalid phone number': 'رقم الهاتف غير صالح',
    'please enter a valid phone number (7-15 digits) or leave it empty.': 'يرجى إدخال رقم هاتف صالح (7-15 رقماً) أو تركه فارغاً.',
    'please enter a valid phone number (7-15 digits) or leave it empty': 'يرجى إدخال رقم هاتف صالح (7-15 رقماً) أو تركه فارغاً',
    'agreement required': 'الموافقة مطلوبة',
    'please agree to the privacy policy and terms & conditions.': 'يرجى الموافقة على سياسة الخصوصية والشروط والأحكام.',
    'please agree to the privacy policy and terms & conditions': 'يرجى الموافقة على سياسة الخصوصية والشروط والأحكام',
    'please complete all required fields before proceeding:': 'يرجى إكمال جميع الحقول المطلوبة قبل المتابعة:',
    'please complete all required fields before proceeding': 'يرجى إكمال جميع الحقول المطلوبة قبل المتابعة',
    '• full name': '• الاسم الكامل',
    '• email': '• البريد الإلكتروني',
    '• profile photo': '• صورة الملف الشخصي',
    '• at least one artwork': '• عمل فني واحد على الأقل',
    '• agree to terms & conditions': '• الموافقة على الشروط والأحكام',
    'saving artist profile...': 'جاري حفظ الملف الفني...',
    'saving artist profile': 'جاري حفظ الملف الفني',
    'uploading media files...': 'جاري رفع ملفات الوسائط...',
    'uploading media files': 'جاري رفع ملفات الوسائط',
    'at least one artwork is required': 'يلزم إضافة عمل فني واحد على الأقل',

    // Payment & Checkout (Step 2)
    'payment & checkout': 'الدفع وإتمام الطلب',
    'step 2 of 2: payment & verification': 'الخطوة 2 من 2: الدفع والتحقق',
    'scan the qr code or transfer via iban, then attach your receipt': 'امسح رمز QR أو حوّل عبر الآيبان، ثم أرفق إيصالك',
    'scan the qr code or transfer via iban, then attach your receipt.': 'امسح رمز QR أو حوّل عبر الآيبان، ثم أرفق إيصالك.',
    'event publishing': 'نشر الفعالية',
    'gallery registration': 'تسجيل المعرض',
    'art event listing': 'إعلان فعالية فنية',
    'art gallery registration': 'تسجيل معرض فني',
    'selected plan duration:': 'مدة الخطة المحددة:',
    'selected plan duration': 'مدة الخطة المحددة',
    'total payable:': 'إجمالي المبلغ المستحق:',
    'total payable': 'إجمالي المبلغ المستحق',
    'yearly plan (365 days)': 'الخطة السنوية (365 يوماً)',
    '6 months plan (180 days)': 'خطة 6 أشهر (180 يوماً)',
    'monthly plan (30 days)': 'الخطة الشهرية (30 يوماً)',
    'single event plan': 'خطة فعالية واحدة',
    'single event listing': 'إعلان فعالية واحدة',
    'plan:': 'الخطة:',
    'plan': 'الخطة',
    'scan qr to pay': 'امسح رمز QR للدفع',
    'scan using your uae banking app, apple pay, google pay, or qr reader': 'امسح باستخدام تطبيقك المصرفي الإماراتي، Apple Pay، Google Pay، أو قارئ QR',
    'scan using your uae banking app, apple pay, google pay, or qr reader.': 'امسح باستخدام تطبيقك المصرفي الإماراتي، Apple Pay، Google Pay، أو قارئ QR.',
    'direct bank transfer details': 'تفاصيل التحويل المصرفي المباشر',
    'bank name': 'اسم البنك',
    'bank name:': 'اسم البنك:',
    'account title': 'اسم الحساب',
    'account title:': 'اسم الحساب:',
    'account title / beneficiary': 'اسم الحساب / المستفيد',
    'account title / beneficiary:': 'اسم الحساب / المستفيد:',
    'iban / account #': 'الآيبان / رقم الحساب',
    'iban / account #:': 'الآيبان / رقم الحساب:',
    'copy': 'نسخ',
    'copied to clipboard!': 'تم النسخ إلى الحافظة!',
    'emirates nbd, dubai': 'بنك الإمارات دبي الوطني، دبي',
    'artist dubai cultural services llc': 'خدمات فنان دبي الثقافية ش.ذ.م.م',
    'please scan the qr code with your mobile banking or payment app, or transfer directly via iban. once paid, enter your transaction reference number and upload the receipt screenshot.': 'يرجى مسح رمز QR باستخدام تطبيقك المصرفي أو تطبيق الدفع، أو التحويل مباشرة عبر الآيبان. بمجرد الدفع، أدخل الرقم المرجعي للمعاملة وارفع لقطة شاشة للإيصال.',
    'please scan the qr code with your banking app or transfer via iban. once completed, enter the transaction reference and upload your receipt screenshot.': 'يرجى مسح رمز QR باستخدام تطبيقك المصرفي أو التحويل عبر الآيبان. بمجرد الانتهاء، أدخل الرقم المرجعي للمعاملة وارفع لقطة شاشة للإيصال.',
    'payment verification & proof': 'إثبات وتأكيد الدفع',
    'attach your transfer receipt screenshot and/or enter transaction id for instant verification.': 'أرفق لقطة شاشة لإيصال التحويل و/أو أدخل معرف المعاملة للتحقق الفوري.',
    'attach your transfer receipt screenshot and/or enter transaction id for instant verification': 'أرفق لقطة شاشة لإيصال التحويل و/أو أدخل معرف المعاملة للتحقق الفوري',
    'transaction reference / id (optional)': 'الرقم المرجعي للمعاملة / المعرف (اختياري)',
    '# e.g. txn-98472918 or bank ref': 'مثال: TXN-98472918 أو المرجع البنكي #',
    '# e.g. txn-98472918 or bank ref #': 'مثال: TXN-98472918 أو المرجع البنكي #',
    'e.g. txn-98472918 or bank ref #': 'مثال: TXN-98472918 أو المرجع البنكي #',
    'payment proof attached': 'تم إرفاق إثبات الدفع',
    'receipt screenshot ready for review': 'لقطة شاشة الإيصال جاهزة للمراجعة',
    'attach transfer receipt': 'إرفاق إيصال التحويل',
    'upload screenshot (png, jpg up to 10mb)': 'رفع لقطة شاشة (PNG، JPG حتى 10 ميغابايت)',
    'upload receipt screenshot': 'رفع لقطة شاشة الإيصال',
    'change receipt screenshot': 'تغيير لقطة شاشة الإيصال',
    'uploading...': 'جارٍ الرفع...',
    'payment receipt attached successfully!': 'تم إرفاق إيصال الدفع بنجاح!',
    'confirm & submit listing': 'تأكيد وإرسال الإعلان',
    'back to edit details': 'العودة لتعديل التفاصيل',
    'failed to submit listing. please verify your connection and try again.': 'فشل إرسال الإعلان. يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
    'failed to submit listing. please verify your connection and try again': 'فشل إرسال الإعلان. يرجى التحقق من اتصالك والمحاولة مرة أخرى',
    'no payment proof attached': 'لم يتم إرفاق إثبات الدفع',
    "you haven't attached a receipt screenshot or entered a transaction reference number.\n\nyou can attach your proof now for faster verification, or submit anyway as pending transfer.": "لم تقم بإرفاق لقطة شاشة للإيصال أو إدخال رقم مرجعي للمعاملة.\n\nيمكنك إرفاق الإثبات الآن لتسريع التحقق، أو الإرسال على أي حال كتحويل معلق.",
    'attach receipt': 'إرفاق الإيصال',
    'submit anyway': 'إرسال على أي حال',
    'gallery submitted for review!': 'تم تقديم المعرض للمراجعة!',
    'event submitted for review!': 'تم تقديم الفعالية للمراجعة!',
    'your gallery registration and payment proof have been submitted. once verified by our administration team, your gallery will appear publicly.': 'تم تقديم تسجيل معرضك وإثبات الدفع. بمجرد التحقق من قبل فريق الإدارة، سيظهر معرضك للجمهور.',
    'your event listing and payment proof have been submitted. our team will verify your transfer and publish your event within 24 hours.': 'تم تقديم إعلان فعاليتك وإثبات الدفع. سيقوم فريقنا بالتحقق من التحويل ونشر فعاليتك خلال 24 ساعة.',
    'back to galleries': 'العودة إلى المعارض',
    'view my events': 'عرض فعالياتي',

    // Server, network & API error messages
    'database connection error. please try again later.': 'خطأ في الاتصال بقاعدة البيانات. يرجى المحاولة مرة أخرى لاحقاً.',
    'database connection error': 'خطأ في الاتصال بقاعدة البيانات',
    'database connection failed': 'فشل الاتصال بقاعدة البيانات',
    'mysql connection error': 'خطأ في الاتصال بـ MySQL',
    'server error': 'خطأ في الخادم',
    'internal server error': 'خطأ داخلي في الخادم',
    'something went wrong': 'حدث خطأ ما',
    'something went wrong. please try again.': 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
    'something went wrong. please try again': 'حدث خطأ ما. يرجى المحاولة مرة أخرى',
    'service temporarily unavailable': 'الخدمة غير متاحة مؤقتاً',
    'please try again later': 'يرجى المحاولة مرة أخرى لاحقاً',
    'request failed': 'فشل الطلب',
    'network error': 'خطأ في الشبكة',
    'no internet connection': 'لا يوجد اتصال بالإنترنت',
    'connection timeout': 'انتهت مهلة الاتصال',
    'timeout': 'انتهت مهلة الطلب',
    'connection refused': 'تم رفض الاتصال',
    'failed to load data': 'فشل تحميل البيانات',
    'failed to load data. please check your connection.': 'فشل تحميل البيانات. يرجى التحقق من اتصالك.',
    'failed to load data. please check your connection': 'فشل تحميل البيانات. يرجى التحقق من اتصالك',
    'unable to reach the server': 'تعذّر الوصول إلى الخادم',
    'unauthorized access': 'وصول غير مصرح به',
    'session expired. please log in again.': 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
    'session expired. please log in again': 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى',
    'access denied': 'تم رفض الوصول',
    'not found': 'غير موجود',
    'invalid response from server': 'استجابة غير صالحة من الخادم',
    'error': 'خطأ',
    'validation error': 'خطأ في التحقق من البيانات',
    'invalid credentials': 'بيانات الاعتماد غير صالحة',
    'unauthorized': 'غير مصرح به',
    'invalid request': 'طلب غير صالح',
    'email already in use': 'البريد الإلكتروني مستخدم بالفعل',
    'user registered successfully': 'تم تسجيل المستخدم بنجاح',
    'login successful': 'تم تسجيل الدخول بنجاح',
    'data retrieved successfully': 'تم جلب البيانات بنجاح',
    'profile updated successfully': 'تم تحديث الملف الشخصي بنجاح',
  };

  // Lazy reversed map for Arabic to English lookups
  static Map<String, String>? _arToEn;
  static Map<String, String> get arToEn {
    if (_arToEn == null) {
      final map = <String, String>{
        // Explicit Arabic to English lookups for event titles and variations
        'معرض اختبار واجهة برمجة التطبيق المباشر 8831': 'Live API Test Exhibition 8831',
        'معرض اختبار واجهة برمجة التطبيق المباشر': 'Live API Test Exhibition',
        'معرض اختبار واجهة برمجة التطبيق': 'API Test Exhibition',
        'بينالي الشارقة للخط': 'Sharjah Calligraphy Biennial',
        'ملتقى الشارقة للخط': 'Sharjah Calligraphy Meeting',
        'معرض دبي للفن الحديث': 'Dubai Modern Art Showcase',
        'معرض الإمارات للتصميم المعاصر 2026': 'Emirates Contemporary Design Expo 2026',
        'قلب الشارقة التراثي': 'Heart of Sharjah Heritage Area',
        'معرض دبي أوبرا': 'Dubai Opera Gallery',
        'جادة السركال، المستودع 42': 'Alserkal Avenue, Warehouse 42',
        'الفعاليات الحالية': "What's On",
        'المميزة': 'Featured',
        'عرض الكل': 'SEE ALL',
        'موصى به لك': 'Recommended for You',
        'البحث في الفعاليات': 'Search Events',
        'اليوم': 'Today',
        'هذا الأسبوع': 'This Week',
        'تواريخ مخصصة': 'Custom Dates',
        'تاريخ مخصص': 'Custom Dates',
        'التاريخ': 'Date',
        'تصفية حسب التاريخ': 'Filter by Date',
        'جميع التواريخ': 'All Dates',
        'الفئة': 'Category',
        'تصفية حسب الفئة': 'Filter by Category',
        'جميع الفئات': 'All Categories',
        'البحث في الفئات...': 'Search categories...',
        'ترتيب حسب': 'Sort By',
        'ترتيب الفعاليات': 'Sort Events',
        'الأقرب موعداً': 'Soonest',
        'العنوان (أ - ي)': 'Title (A - Z)',
        'السعر: من الأقل إلى الأعلى': 'Price: Low to High',
        'السعر: من الأعلى إلى الأقل': 'Price: High to Low',
        'الأكثر شعبية': 'Most Popular',
        'نتائج البحث': 'Search Results',
        'مسح الكل': 'Clear All',
        'مسح جميع الفلاتر': 'Clear All Filters',
        'إعادة ضبط': 'Reset',
        'تسجيل فعالية فنية': 'Register Art Event',
        'معرض فني': 'Art Exhibition',
        'معرض': 'Exhibition',
        'دخول مجاني': 'Free Entry',
        'مجاني': 'Free',
        'نشط': 'Active',
        'مرحباً بكم في فنان دبي': 'Welcome to Dubai Artists',
        'اكتشف مشهد الفن النابض في دبي وتواصل مع فنانين محليين موهوبين': 'Discover the vibrant art scene of Dubai and connect with talented local artists',
        'تعرف على الفنانين المحليين': 'Meet Local Artists',
        'تواصل مباشرة مع الفنانين وتعرف على قصصهم واطلب أعمالاً خاصة': 'Connect directly with artists, learn about their stories and commission custom works',
        'استكشف المعارض الفنية': 'Explore Art Galleries',
        'تصفح المجموعات الفنية المختارة واعثر على عملك المفضل التالي': 'Browse through curated collections and find your next favorite piece',
        'الفعاليات والمعارض الفنية': 'Art Events & Exhibitions',
        'ابقَ على اطلاع بأحدث الفعاليات والمعارض والأنشطة الثقافية في دبي': 'Stay updated with the latest art events, exhibitions and cultural happenings in Dubai',
        'تخطي': 'Skip',
        'السابق': 'Previous',
        'التالي': 'Next',
        'ابدأ الآن': 'Get Started',
        'تفاصيل الفعالية': 'Event Details',
        'فتح الاتجاهات': 'Open Directions',
        'جوجل': 'Google',
        'قراءة المزيد': 'Read More',
        'قراءة أقل': 'Read Less',
        'بيت الحكمة والفنون، دبي': 'House of Wisdom & Arts, Dubai',
        'بيت الحكمة والفنون': 'House of Wisdom & Arts',
      };
      _enToAr.forEach((en, ar) {
        map.putIfAbsent(ar.trim().toLowerCase(), () => en);
      });
      _arToEn = map;
    }
    return _arToEn!;
  }

  // Dynamic Cache for arbitrary live backend strings
  static final Map<String, String> _dynamicCache = {};
  static final Set<String> _pendingTranslations = {};
  static final ValueNotifier<int> translationNotifier = ValueNotifier<int>(0);

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  static bool _cacheInitialized = false;

  /// Ensure persistent cache is loaded into memory
  static void _ensureCacheLoaded() {
    if (_cacheInitialized) return;
    _cacheInitialized = true;
    try {
      if (sl.isRegistered<StorageService>()) {
        final raw = sl<StorageService>().getString('cached_dynamic_translations_v1');
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              if (k is String && v is String) {
                final trimmedV = v.trim();
                final isJunk = trimmedV.isEmpty ||
                    !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(trimmedV) ||
                    (k.startsWith('en_ar:') && !RegExp(r'[\u0600-\u06FF]').hasMatch(trimmedV));
                if (!isJunk) {
                  _dynamicCache[k] = v;
                }
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  /// Persist dynamic translations to storage
  static void _saveCache() {
    try {
      if (sl.isRegistered<StorageService>()) {
        sl<StorageService>().setString(
          'cached_dynamic_translations_v1',
          jsonEncode(_dynamicCache),
        );
      }
    } catch (_) {}
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
    // Return early if text is pure punctuation or symbols
    if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(trimmed)) {
      return trimmed;
    }
    final lower = trimmed.toLowerCase();

    _ensureCacheLoaded();

    if (ar) {
      // 1. Direct dictionary match
      if (_enToAr.containsKey(lower)) {
        return _enToAr[lower]!;
      }
      final strippedDots = lower.replaceAll(RegExp(r'^\.+|\.+$'), '').trim();
      if (strippedDots.isNotEmpty && _enToAr.containsKey(strippedDots)) {
        return _enToAr[strippedDots]!;
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
      if (lower.startsWith('today • ') || lower.startsWith('today · ') || lower.startsWith('today - ')) {
        final timePart = trimmed.substring(7).trim();
        return 'اليوم • ${_translateTimePart(timePart)}';
      }
      if (lower.startsWith('this week • ') || lower.startsWith('this week · ') || lower.startsWith('this week - ')) {
        final timePart = trimmed.substring(11).trim();
        return 'هذا الأسبوع • ${_translateTimePart(timePart)}';
      }
      if (lower.startsWith('explore ') && lower.contains('collection of artworks')) {
        final name = trimmed
            .substring(8, trimmed.toLowerCase().indexOf('collection of artworks'))
            .replaceAll(RegExp(r"['’]s?\s*$"), '')
            .trim();
        final trName = _enToAr[name.toLowerCase()] ?? name;
        return 'استكشف مجموعة أعمال $trName الفنية';
      }

      // Bullet & dot separated composite strings (e.g. "Art Exhibition • Dubai, UAE")
      if (trimmed.contains(' • ')) {
        final parts = trimmed.split(' • ');
        final trParts = parts.map((p) => translate(p, isArabic: true)).toList();
        return trParts.join(' • ');
      }
      if (trimmed.contains(' · ')) {
        final parts = trimmed.split(' · ');
        final trParts = parts.map((p) => translate(p, isArabic: true)).toList();
        return trParts.join(' · ');
      }

      // Trailing colon lookups
      if (lower.endsWith(':')) {
        final withoutColon = lower.substring(0, lower.length - 1).trim();
        if (_enToAr.containsKey(withoutColon)) {
          return '${_enToAr[withoutColon]}:';
        }
      }

      // Copied notification
      if (lower.startsWith('copied ') && lower.endsWith(' to clipboard!')) {
        final inner = trimmed.substring(7, trimmed.length - 14).trim();
        final trInner = translate(inner, isArabic: true);
        return 'تم نسخ $trInner إلى الحافظة!';
      }

      // Confirm & submit listing
      if (lower.startsWith('confirm & submit listing')) {
        final rest = trimmed.substring(24).trim();
        return ('تأكيد وإرسال الإعلان $rest').trim();
      }

      // Plan prefix
      if (lower.startsWith('plan:')) {
        final rest = trimmed.substring(5).trim();
        return 'الخطة: ${translate(rest, isArabic: true)}';
      }

      // Dynamic profile creation & upload error patterns
      if (lower.startsWith('maximum 6 artworks allowed. added ') && lower.contains('artwork(s)')) {
        final count = trimmed.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst('6', '');
        return 'الحد الأقصى المسموح به هو 6 أعمال فنية. تمت إضافة $count عمل (أعمال).';
      }
      if (lower.startsWith('artist profile & ') && lower.contains('artworks created successfully!')) {
        final count = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        return 'تم إنشاء الملف الفني وإضافة $count عمل فني بنجاح!';
      }
      if (lower.startsWith('error selecting profile picture: ')) {
        final err = trimmed.substring(32).trim();
        return 'خطأ أثناء اختيار صورة الملف الشخصي: $err';
      }
      if (lower.startsWith('error selecting banner picture: ')) {
        final err = trimmed.substring(31).trim();
        return 'خطأ أثناء اختيار صورة الغلاف: $err';
      }
      if (lower.startsWith('error selecting images: ')) {
        final err = trimmed.substring(24).trim();
        return 'خطأ أثناء اختيار الصور: $err';
      }
      if (lower.startsWith('error taking photo: ')) {
        final err = trimmed.substring(20).trim();
        return 'خطأ أثناء التقاط الصورة: $err';
      }
      if (lower.startsWith('failed to save profile: ')) {
        final err = trimmed.substring(24).trim();
        return 'فشل حفظ الملف الشخصي: $err';
      }
      if (lower.startsWith('failed to update profile: ')) {
        final err = trimmed.substring(26).trim();
        return 'فشل تحديث الملف الشخصي: $err';
      }
      if (trimmed.contains('\n')) {
        final lines = trimmed.split('\n');
        final trLines = lines.map((l) => translate(l, isArabic: true)).toList();
        return trLines.join('\n');
      }

      // 3. Dynamic cache lookup
      final cacheKey = 'en_ar:$lower';
      if (_dynamicCache.containsKey(cacheKey)) {
        final cached = _dynamicCache[cacheKey]!;
        if (_isValidCandidate(cached, targetLang: 'ar', originalLower: lower)) {
          return cached;
        }
        _dynamicCache.remove(cacheKey);
      }

      // 4. If text already has Arabic and no Latin letters, return as is
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed) &&
          !RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
        return trimmed;
      }

      // 5. Trigger asynchronous translation in background
      _fetchAndCacheTranslation(trimmed, targetLang: 'ar');

      return trimmed;
    } else {
      // Arabic -> English lookup
      if (arToEn.containsKey(lower)) {
        return _capitalize(arToEn[lower]!);
      }

      // Dynamic cache lookup
      final cacheKey = 'ar_en:$lower';
      if (_dynamicCache.containsKey(cacheKey)) {
        final cached = _dynamicCache[cacheKey]!;
        if (_isValidCandidate(cached, targetLang: 'en', originalLower: lower)) {
          return cached;
        }
        _dynamicCache.remove(cacheKey);
      }

      if (trimmed.startsWith('اليوم • ') || trimmed.startsWith('اليوم · ')) {
        final timePart = trimmed.substring(7).trim();
        final enTime = timePart
            .replaceAll('صباحاً', 'AM')
            .replaceAll('مساءً', 'PM');
        return 'Today • $enTime';
      }
      if (trimmed.startsWith('هذا الأسبوع • ') || trimmed.startsWith('هذا الأسبوع · ')) {
        final timePart = trimmed.substring(13).trim();
        final enTime = timePart
            .replaceAll('صباحاً', 'AM')
            .replaceAll('مساءً', 'PM');
        return 'This Week • $enTime';
      }

      // If no Arabic characters, it is already English/Latin
      if (!RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) {
        if (trimmed.length < 25 && !trimmed.contains(':') && !trimmed.contains('.') && !trimmed.contains('\n')) {
          return _capitalize(trimmed);
        }
        return trimmed;
      }

      // Trigger asynchronous translation in background
      _fetchAndCacheTranslation(trimmed, targetLang: 'en');

      return trimmed;
    }
  }

  static String _translateTimePart(String time) {
    return time
        .replaceAll(RegExp(r'\bAM\b', caseSensitive: false), 'صباحاً')
        .replaceAll(RegExp(r'\bPM\b', caseSensitive: false), 'مساءً');
  }

  static bool _isValidCandidate(
    String candidate, {
    required String targetLang,
    required String originalLower,
  }) {
    if (candidate.isEmpty) return false;
    if (candidate.toUpperCase().contains('MYMEMORY WARNING')) return false;
    if (candidate.toLowerCase() == originalLower) return false;
    // Reject pure punctuation or whitespace
    if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(candidate)) return false;

    // For Arabic target, it must contain at least one Arabic letter
    if (targetLang == 'ar' && !RegExp(r'[\u0600-\u06FF]').hasMatch(candidate)) {
      return false;
    }
    return true;
  }

  /// Asynchronously fetch translation and notify listeners
  static Future<String?> _fetchAndCacheTranslation(
    String text, {
    required String targetLang,
  }) async {
    final lower = text.trim().toLowerCase();
    final cacheKey = '${targetLang == "ar" ? "en_ar" : "ar_en"}:$lower';

    if (_dynamicCache.containsKey(cacheKey)) {
      return _dynamicCache[cacheKey];
    }
    if (_pendingTranslations.contains(cacheKey)) {
      return null;
    }
    _pendingTranslations.add(cacheKey);

    try {
      final encoded = Uri.encodeComponent(text.trim());
      final sl = targetLang == 'ar' ? 'en' : 'ar';

      // 1. Primary: MyMemory Translation API (reliable, no 429 rate limit)
      try {
        final myMemoryUrl =
            'https://api.mymemory.translated.net/get?q=$encoded&langpair=$sl|$targetLang';
        final response = await _dio.get(myMemoryUrl);
        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data as Map;
          final resData = data['responseData'];
          String? bestCandidate;
          if (resData is Map && resData['translatedText'] != null) {
            final t = resData['translatedText'].toString().trim();
            if (_isValidCandidate(t, targetLang: targetLang, originalLower: lower)) {
              bestCandidate = t;
            }
          }
          if (bestCandidate == null && data['matches'] is List) {
            for (final m in data['matches']) {
              if (m is Map && m['translation'] != null) {
                final t = m['translation'].toString().trim();
                if (_isValidCandidate(t, targetLang: targetLang, originalLower: lower)) {
                  bestCandidate = t;
                  break;
                }
              }
            }
          }
          if (bestCandidate != null) {
            _dynamicCache[cacheKey] = bestCandidate;
            _saveCache();
            translationNotifier.value++;
            return bestCandidate;
          }
        }
      } catch (_) {}

      // 2. Secondary Fallback: Google Translate API with browser headers
      final url =
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=$encoded';
      final response = await _dio.get(
        url,
        options: Options(
          headers: kIsWeb
              ? null
              : {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        if (list.isNotEmpty && list[0] is List) {
          final chunks = list[0] as List;
          final buffer = StringBuffer();
          for (final chunk in chunks) {
            if (chunk is List && chunk.isNotEmpty && chunk[0] != null) {
              buffer.write(chunk[0].toString());
            }
          }
          final translated = buffer.toString().trim();
          if (_isValidCandidate(translated, targetLang: targetLang, originalLower: lower)) {
            _dynamicCache[cacheKey] = translated;
            _saveCache();
            translationNotifier.value++;
            return translated;
          }
        }
      }
    } catch (_) {
      // Graceful fallback for offline mode
    } finally {
      _pendingTranslations.remove(cacheKey);
    }
    return null;
  }


  /// Batch prefetch translations for dynamic lists (e.g. from backend API)
  static Future<void> prefetchBatch(
    List<String?> texts, {
    bool isArabic = true,
  }) async {
    _ensureCacheLoaded();
    final targetLang = isArabic ? 'ar' : 'en';

    final toFetch = <String>[];
    for (final raw in texts) {
      if (raw == null) continue;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      final cacheKey = '${isArabic ? "en_ar" : "ar_en"}:$lower';

      if (isArabic) {
        if (_enToAr.containsKey(lower)) continue;
        if (_dynamicCache.containsKey(cacheKey)) continue;
        if (_pendingTranslations.contains(cacheKey)) continue;
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed) &&
            !RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
          continue;
        }
      } else {
        if (arToEn.containsKey(lower)) continue;
        if (_dynamicCache.containsKey(cacheKey)) continue;
        if (_pendingTranslations.contains(cacheKey)) continue;
        if (!RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed)) continue;
      }
      toFetch.add(trimmed);
    }

    if (toFetch.isEmpty) return;

    // Process in batches of 4 concurrent requests
    const batchSize = 4;
    for (var i = 0; i < toFetch.length; i += batchSize) {
      final end = (i + batchSize < toFetch.length) ? i + batchSize : toFetch.length;
      final chunk = toFetch.sublist(i, end);
      await Future.wait(
        chunk.map((item) => _fetchAndCacheTranslation(item, targetLang: targetLang)),
      );
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
    const minorWords = {'of', 'and', 'the', 'in', 'on', 'at', 'to', 'for', 'a', 'an'};
    final words = s.split(' ');
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;
      final wClean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (wClean == 'uae') {
        words[i] = word.toUpperCase();
      } else if (i > 0 && minorWords.contains(wClean)) {
        words[i] = word.toLowerCase();
      } else {
        words[i] = word[0].toUpperCase() + word.substring(1);
      }
    }
    return words.join(' ');
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
