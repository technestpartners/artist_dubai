import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/locale_provider.dart';
import 'package:provider/provider.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../domain/models/publishing_pricing_model.dart';
import '../../domain/models/menu_permission_model.dart';
import '../../../chat/domain/models/listing_plan_model.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../government/domain/models/government_entity.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/widgets/app_cached_image.dart';

enum AdminTab {
  overview,
  artists,
  events,
  calendar,
  galleries,
  artCenters,
  government,
  masters,
  permissions,
  aboutUs,
  users,
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  AdminTab _selectedTab = AdminTab.overview;

  List<ArtistModel> _artists = [];
  List<ArtEventModel> _events = [];
  List<Map<String, dynamic>> _galleries = [];
  List<Map<String, dynamic>> _artCenters = [];
  List<GovernmentEntity> _govEntities = [];
  List<CategoryInfo> _categories = [];
  List<ExperienceLevelModel> _experienceLevels = [];
  List<LocationModel> _locations = [];
  List<PublishingPricingModel> _publishingPricing = [];
  List<ListingPlanItem> _listingPlans = List.from(
    ApiService.defaultListingPlans,
  );
  // 0=Events, 1=Galleries, 2=Artists, 3=Chat, 4=Art Centres
  int _listingPlanTypeTab = 0;
  Map<String, bool> _menuPermissions = {};
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  String _userSearchQuery = '';
  String _userRoleFilter = 'all';
  String _categorySearchQuery = '';
  String _categoryTypeFilter = 'all';

  // About Us Page Management Controllers
  final TextEditingController _aboutTitleEnCtrl =
      TextEditingController(text: 'ABOUT US');
  final TextEditingController _aboutTitleArCtrl =
      TextEditingController(text: 'من نحن');
  final TextEditingController _aboutWhatMeansTitleEnCtrl =
      TextEditingController(text: 'What does it mean to be an artist?');
  final TextEditingController _aboutWhatMeansTitleArCtrl =
      TextEditingController(text: 'ماذا يعني أن تكون فناناً؟');
  final TextEditingController _aboutWhatMeansBodyEnCtrl = TextEditingController(
    text:
        "The word artist has a long history. It is rooted in the idea of art and originally described people with exceptional knowledge, skills and abilities. Today, an artist is someone who creates, interprets and gives expression to ideas, emotions and visions.\n\nBut we believe art can be more.",
  );
  final TextEditingController _aboutWhatMeansBodyArCtrl = TextEditingController(
    text:
        "إن كلمة فنان لها تاريخ طويل، وجذورها متأصلة في فكرة الفن، وكانت في الأصل تصف الأشخاص ذوي المعرفة والمهارات والقدرات الاستثنائية. اليوم، الفنان هو شخص يبدع ويفسر ويعبر عن الأفكار والمشاعر والرؤى.\n\nلكننا نؤمن بأن الفن يمكن أن يكون أكثر من ذلك.",
  );
  final TextEditingController _aboutQuoteTextEnCtrl = TextEditingController(
    text: '“Art does not reproduce the visible; rather, it makes visible.”',
  );
  final TextEditingController _aboutQuoteTextArCtrl = TextEditingController(
    text: '«الفن لا يعيد إنتاج المرئي، بل يجعله مرئياً.»',
  );
  final TextEditingController _aboutConnectBodyEnCtrl = TextEditingController(
    text:
        'Our platform was created to connect artists across disciplines, cultures, languages and levels of experience. From photography, painting and music to sculpture, digital art and many other creative forms, our platform gives artists a place to discover, share, connect and collaborate.',
  );
  final TextEditingController _aboutConnectBodyArCtrl = TextEditingController(
    text:
        'تم إنشاء منصتنا لربط الفنانين عبر مختلف التخصصات والثقافات واللغات ومستويات الخبرة. من التصوير الفوتوغرافي والرسم والموسيقى إلى النحت والفن الرقمي والعديد من الأشكال الإبداعية الأخرى، تمنح منصتنا الفنانين مساحة للاكتشاف والمشاركة والتواصل والتعاون.',
  );
  final TextEditingController _aboutOpportunitiesBodyEnCtrl =
      TextEditingController(
    text:
        'Artists can explore different forms of art, discover galleries and art associations, connect directly with them, showcase their work and take part in events, competitions and creative challenges. Most importantly, the platform creates opportunities for meaningful exchange, inspiration and collaboration.',
  );
  final TextEditingController _aboutOpportunitiesBodyArCtrl =
      TextEditingController(
    text:
        'يمكن للفنانين استكشاف أشكال مختلفة من الفن، واكتشاف صالات العرض والجمعيات الفنية، والتواصل معها مباشرة، وعرض أعمالهم والمشاركة في الفعاليات والمسابقات والتحديات الإبداعية. والأهم من ذلك، تخلق المنصة فرصاً للتبادل الهادف والإلهام والتعاون.',
  );
  final TextEditingController _aboutFusionBodyEnCtrl = TextEditingController(
    text:
        "Because when different artists, cultures and creative perspectives come together, something new can emerge.\n\nPerhaps even a form of art that has never existed before.",
  );
  final TextEditingController _aboutFusionBodyArCtrl = TextEditingController(
    text:
        "لأنه عندما يلتقي فنانون وثقافات ورؤى إبداعية مختلفة، يمكن أن يولد شيء جديد تماماً.\n\nوربما حتى شكل فني لم يكن موجوداً من قبل.",
  );
  final TextEditingController _aboutDubaiVisionBodyEnCtrl =
      TextEditingController(
    text:
        "Dubai is a unique place for this vision. With people from more than 180 nationalities, countless cultures, languages and perspectives meet here. Art has the power to connect these differences and create something that belongs to everyone.\n\nOur digital world allows us to bring these creative forces together beyond borders and distances.",
  );
  final TextEditingController _aboutDubaiVisionBodyArCtrl =
      TextEditingController(
    text:
        "دبي هي المكان الأمثل لتحقيق هذه الرؤية. مع وجود أشخاص من أكثر من 180 جنسية، تلتقي هنا ثقافات ولغات ورؤى لا حصر لها. يمتلك الفن القدرة على الجمع بين هذه الاختلافات وخلق شيء ينتمي للجميع.\n\nعالمنا الرقمي يتيح لنا جمع هذه الطاقات الإبداعية متجاوزين كل الحدود والمسافات.",
  );
  final TextEditingController _aboutOurVisionBodyEnCtrl = TextEditingController(
    text:
        "Our vision is more than simply creating a platform for artists.\n\nWe want to create a space where encounters become inspiration, inspiration becomes collaboration, and collaboration becomes new art.",
  );
  final TextEditingController _aboutOurVisionBodyArCtrl = TextEditingController(
    text:
        "رؤيتنا تتجاوز مجرد إنشاء منصة للفنانين.\n\nنريد خلق مساحة يتحول فيها اللقاء إلى إلهام، والإلهام إلى تعاون، والتعاون إلى فن جديد.",
  );
  final TextEditingController _aboutClosingBordersEnCtrl =
      TextEditingController(text: 'Because art has no borders.');
  final TextEditingController _aboutClosingBordersArCtrl =
      TextEditingController(text: 'لأن الفن لا يعرف حدوداً.');
  final TextEditingController _aboutClosingImpossibleEnCtrl =
      TextEditingController(
    text:
        'And when people, ideas and talents come together, artists have the power to make the impossible possible.',
  );
  final TextEditingController _aboutClosingImpossibleArCtrl =
      TextEditingController(
    text:
        'وعندما تجتمع العقول والأفكار والمواهب، يمتلك الفنانون القدرة على جعل المستحيل ممكناً.',
  );
  bool _isLoadingAboutUs = false;
  bool _isSavingAboutUs = false;
  int _aboutLanguageSubTab = 0; // 0 = English, 1 = Arabic
  bool _aboutAutoSyncEnabled = true;
  bool _isAutoSyncingAboutUs = false;
  bool _isSyncingAllAboutFields = false;
  int _syncingFieldsCount = 0;
  final Map<TextEditingController, String> _lastSyncedValues = {};
  Timer? _aboutSyncDebounceTimer;
  StreamSubscription<Map<String, dynamic>>? _aboutUsSub;

  StreamSubscription<List<ArtistModel>>? _artistsSub;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<List<GovernmentEntity>>? _govSub;
  StreamSubscription<List<CategoryInfo>>? _categoriesSub;
  StreamSubscription<List<ExperienceLevelModel>>? _experienceLevelsSub;
  StreamSubscription<List<LocationModel>>? _locationsSub;
  StreamSubscription<List<PublishingPricingModel>>? _publishingPricingSub;
  StreamSubscription<List<ListingPlanItem>>? _listingPlansSub;
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;
  StreamSubscription<Map<String, bool>>? _menuPermissionsSub;
  final Set<String> _togglingEventIds = {};
  Timer? _periodicSyncTimer;
  int _masterSubTab =
      0; // 0 = Categories, 1 = Experience Levels, 2 = Locations, 3 = Listing Plans
  int _eventFilterIndex = 0; // 0 = All, 1 = Pending Review, 2 = Active

  int get _activeMenuCount {
    int count = 0;
    for (final item in MenuPermissionModel.defaultPermissions()) {
      if (_menuPermissions[item.routeName] ?? true) {
        count++;
      }
    }
    return count;
  }

  int get _comingSoonMenuCount {
    return MenuPermissionModel.defaultPermissions().length - _activeMenuCount;
  }

  Future<void> _pickAndUploadImageForField(
    TextEditingController controller,
    StateSetter setModalState,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final nameParts = picked.name.split('.');
        final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
        final url = await sl<ApiService>().uploadImageBytes(bytes, ext: ext);
        if (url != null && url.isNotEmpty) {
          setModalState(() {
            controller.text = url;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _menuPermissions = sl<StorageService>().getAllMenuPermissions();
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
    _loadAllData();
    _subscribeLiveStreams();
    _loadAboutUsData();
    _initAboutUsAutoSync();
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  void _subscribeLiveStreams() {
    final liveSync = sl<LiveSyncService>();
    _aboutUsSub = liveSync.aboutStream.listen((data) {
      if (mounted && data.isNotEmpty && !_isSavingAboutUs) {
        _populateAboutUsFields(data);
      }
    });
    _artistsSub = liveSync.artistsStream.listen((list) {
      if (mounted) {
        setState(() => _artists = list);
      }
    });
    _eventsSub = liveSync.eventsStream.listen((list) {
      if (mounted) {
        final currentPending =
            _events
                .where(
                  (e) => e.status.toLowerCase() == 'pending' || !e.isActive,
                )
                .toList();
        final incomingPending =
            list
                .where(
                  (e) => e.status.toLowerCase() == 'pending' || !e.isActive,
                )
                .toList();
        if (currentPending.isNotEmpty && incomingPending.isEmpty) {
          final merged = List<ArtEventModel>.from(list);
          for (final p in currentPending) {
            if (!merged.any((e) => e.id == p.id)) {
              merged.insert(0, p);
            }
          }
          setState(() => _events = merged);
        } else {
          setState(() => _events = list);
        }
      }
    });
    _govSub = liveSync.governmentStream.listen((list) {
      if (mounted) {
        setState(() => _govEntities = list);
      }
    });
    _categoriesSub = liveSync.categoriesStream.listen((list) {
      if (mounted) {
        setState(() => _categories = list);
      }
    });
    _experienceLevelsSub = liveSync.experienceLevelsStream.listen((list) {
      if (mounted) {
        setState(() => _experienceLevels = list);
      }
    });
    _locationsSub = liveSync.locationsStream.listen((list) {
      if (mounted) {
        setState(() => _locations = list);
      }
    });
    _publishingPricingSub = liveSync.publishingPricingStream.listen((list) {
      if (mounted) {
        setState(() => _publishingPricing = list);
      }
    });
    _listingPlansSub = liveSync.listingPlansStream.listen((list) {
      if (mounted) {
        setState(() => _listingPlans = list);
      }
    });
    _galleriesSub = liveSync.galleriesStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        final photoGalleries =
            list.where((item) {
              final cat = (item['category'] ?? '').toString().toLowerCase();
              final artistId = (item['artist_id'] ?? '').toString();
              final artistName = (item['artist_name'] ?? '').toString();
              final eventName = (item['event_name'] ?? '').toString();
              final images = item['images_json'] ?? item['images'];
              return cat.contains('photo') ||
                  cat.contains('artist') ||
                  cat.contains('album') ||
                  artistId.isNotEmpty ||
                  artistName.isNotEmpty ||
                  eventName.isNotEmpty ||
                  (images != null &&
                      images.toString().isNotEmpty &&
                      images.toString() != '[]');
            }).toList();

        final artCenters =
            list.where((item) {
              final cat = (item['category'] ?? '').toString().toLowerCase();
              final artistId = (item['artist_id'] ?? '').toString();
              final artistName = (item['artist_name'] ?? '').toString();
              final eventName = (item['event_name'] ?? '').toString();
              final images = item['images_json'] ?? item['images'];
              final isPhoto =
                  cat.contains('photo') ||
                  cat.contains('artist') ||
                  cat.contains('album') ||
                  artistId.isNotEmpty ||
                  artistName.isNotEmpty ||
                  eventName.isNotEmpty ||
                  (images != null &&
                      images.toString().isNotEmpty &&
                      images.toString() != '[]');
              return !isPhoto;
            }).toList();

        // Protective merge for pending galleries so background sync never drops them
        final currentPendingGalleries =
            _galleries.where((g) => _isItemPending(g)).toList();
        final incomingPendingGalleries =
            photoGalleries.where((g) => _isItemPending(g)).toList();
        List<Map<String, dynamic>> mergedGalleries = photoGalleries;
        if (currentPendingGalleries.isNotEmpty &&
            incomingPendingGalleries.isEmpty) {
          mergedGalleries = List<Map<String, dynamic>>.from(photoGalleries);
          for (final p in currentPendingGalleries) {
            if (!mergedGalleries.any((g) => g['id'] == p['id'])) {
              mergedGalleries.insert(0, p);
            }
          }
        }

        // Protective merge for pending art centers so background sync never drops them
        final currentPendingCenters =
            _artCenters.where((c) => _isItemPending(c)).toList();
        final incomingPendingCenters =
            artCenters.where((c) => _isItemPending(c)).toList();
        List<Map<String, dynamic>> mergedCenters = artCenters;
        if (currentPendingCenters.isNotEmpty &&
            incomingPendingCenters.isEmpty) {
          mergedCenters = List<Map<String, dynamic>>.from(artCenters);
          for (final p in currentPendingCenters) {
            if (!mergedCenters.any((c) => c['id'] == p['id'])) {
              mergedCenters.insert(0, p);
            }
          }
        }

        setState(() {
          if (mergedGalleries.isNotEmpty) _galleries = mergedGalleries;
          if (mergedCenters.isNotEmpty) _artCenters = mergedCenters;
        });
      }
    });
    _menuPermissionsSub = liveSync.menuPermissionsStream.listen((perms) {
      if (mounted) {
        setState(() => _menuPermissions = perms);
      }
    });
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _periodicSyncTimer?.cancel();
    _aboutUsSub?.cancel();
    _artistsSub?.cancel();
    _eventsSub?.cancel();
    _galleriesSub?.cancel();
    _govSub?.cancel();
    _categoriesSub?.cancel();
    _experienceLevelsSub?.cancel();
    _locationsSub?.cancel();
    _publishingPricingSub?.cancel();
    _listingPlansSub?.cancel();
    _menuPermissionsSub?.cancel();
    _aboutTitleEnCtrl.dispose();
    _aboutTitleArCtrl.dispose();
    _aboutWhatMeansTitleEnCtrl.dispose();
    _aboutWhatMeansTitleArCtrl.dispose();
    _aboutWhatMeansBodyEnCtrl.dispose();
    _aboutWhatMeansBodyArCtrl.dispose();
    _aboutQuoteTextEnCtrl.dispose();
    _aboutQuoteTextArCtrl.dispose();
    _aboutConnectBodyEnCtrl.dispose();
    _aboutConnectBodyArCtrl.dispose();
    _aboutOpportunitiesBodyEnCtrl.dispose();
    _aboutOpportunitiesBodyArCtrl.dispose();
    _aboutFusionBodyEnCtrl.dispose();
    _aboutFusionBodyArCtrl.dispose();
    _aboutDubaiVisionBodyEnCtrl.dispose();
    _aboutDubaiVisionBodyArCtrl.dispose();
    _aboutOurVisionBodyEnCtrl.dispose();
    _aboutOurVisionBodyArCtrl.dispose();
    _aboutClosingBordersEnCtrl.dispose();
    _aboutClosingBordersArCtrl.dispose();
    _aboutClosingImpossibleEnCtrl.dispose();
    _aboutClosingImpossibleArCtrl.dispose();
    _aboutSyncDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        sl<ApiService>()
            .getArtists(forceRefresh: true)
            .catchError((_) => <ArtistModel>[]),
        sl<ApiService>()
            .getEvents(forceRefresh: true, isAdmin: true)
            .catchError((_) => <ArtEventModel>[]),
        sl<ApiService>()
            .getGalleries(forceRefresh: true, isAdmin: true)
            .catchError((_) => <Map<String, dynamic>>[]),
        sl<ApiService>()
            .getGovernmentEntities(forceRefresh: true)
            .catchError((_) => <GovernmentEntity>[]),
        sl<ApiService>()
            .getCategories(type: 'all', forceRefresh: true)
            .catchError((_) => <CategoryInfo>[]),
        sl<ApiService>()
            .getExperienceLevels(forceRefresh: true)
            .catchError((_) => <ExperienceLevelModel>[]),
        sl<ApiService>()
            .getLocations(forceRefresh: true)
            .catchError((_) => <LocationModel>[]),
        sl<ApiService>()
            .getPublishingPricing(forceRefresh: true)
            .catchError((_) => <PublishingPricingModel>[]),
        sl<ApiService>()
            .getListingPlans(forceRefresh: true)
            .catchError((_) => <ListingPlanItem>[]),
        sl<ApiService>()
            .getMenuPermissions(forceRefresh: true)
            .catchError((_) => <String, bool>{}),
        sl<ApiService>().getUsers().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        if ((results[9] as Map<String, bool>).isNotEmpty) {
          _menuPermissions = results[9] as Map<String, bool>;
        } else {
          _menuPermissions = sl<StorageService>().getAllMenuPermissions();
        }
        _users = results[10] as List<Map<String, dynamic>>;
        final allItems = results[2] as List<Map<String, dynamic>>;

        // 1. Separate Photo Galleries (created by artists or event albums)
        final photoGalleries =
            allItems.where((item) {
              final cat = (item['category'] ?? '').toString().toLowerCase();
              final artistId = (item['artist_id'] ?? '').toString();
              final artistName = (item['artist_name'] ?? '').toString();
              final eventName = (item['event_name'] ?? '').toString();
              final images = item['images_json'] ?? item['images'];
              return cat.contains('photo') ||
                  cat.contains('artist') ||
                  cat.contains('album') ||
                  artistId.isNotEmpty ||
                  artistName.isNotEmpty ||
                  eventName.isNotEmpty ||
                  (images != null &&
                      images.toString().isNotEmpty &&
                      images.toString() != '[]');
            }).toList();

        // 2. Separate Physical Art Centers & Venues
        final artCenters =
            allItems.where((item) {
              final cat = (item['category'] ?? '').toString().toLowerCase();
              final artistId = (item['artist_id'] ?? '').toString();
              final artistName = (item['artist_name'] ?? '').toString();
              final eventName = (item['event_name'] ?? '').toString();
              final images = item['images_json'] ?? item['images'];
              final isPhoto =
                  cat.contains('photo') ||
                  cat.contains('artist') ||
                  cat.contains('album') ||
                  artistId.isNotEmpty ||
                  artistName.isNotEmpty ||
                  eventName.isNotEmpty ||
                  (images != null &&
                      images.toString().isNotEmpty &&
                      images.toString() != '[]');
              return !isPhoto;
            }).toList();

        final finalPhotoGalleries = photoGalleries;

        setState(() {
          _artists = results[0] as List<ArtistModel>;
          _events = results[1] as List<ArtEventModel>;
          _galleries = finalPhotoGalleries;
          _artCenters = artCenters;
          _govEntities = results[3] as List<GovernmentEntity>;
          _categories = results[4] as List<CategoryInfo>;
          _experienceLevels = results[5] as List<ExperienceLevelModel>;
          _locations = results[6] as List<LocationModel>;
          _publishingPricing = results[7] as List<PublishingPricingModel>;
          _listingPlans = results[8] as List<ListingPlanItem>;
        });
      }
    } catch (_) {}
  }

  void _confirmDelete({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(
              0xFF3B1E78,
            ), // Royal purple dialog background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // Red delete button
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await onConfirm();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
    );
  }

  // --- Modal Dialog: New Government Entry & Edit Entry (Screenshots 3 & 4) ---
  void _showGovernmentDialog({GovernmentEntity? existing, int? index}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final typeCtrl = TextEditingController(
      text: existing?.category ?? 'Government · Cultural Authority',
    );
    final addressCtrl = TextEditingController(text: existing?.location ?? '');
    final websiteCtrl = TextEditingController(text: existing?.websiteUrl ?? '');
    final ratingCtrl = TextEditingController(
      text: existing != null ? '${existing.rating}' : '0',
    );
    final reviewsCtrl = TextEditingController(
      text: existing != null ? '${existing.reviewCount}' : '0',
    );
    final orderCtrl = TextEditingController(
      text: index != null ? '${index + 1}' : '0',
    );
    final statusTextCtrl = TextEditingController(
      text: existing?.defaultTiming ?? 'Open · Closes at 15:00',
    );
    bool isCurrentlyOpen = existing?.defaultIsOpen ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit entry' : 'New government entry',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Name',
                        controller: nameCtrl,
                        isFocused: true,
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Type',
                        controller: typeCtrl,
                        hint: 'Government · Cultural Authority',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Address',
                        controller: addressCtrl,
                        hint: 'Al Shindagha, Dubai',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Website',
                        controller: websiteCtrl,
                        hint: 'https://...',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: 'Rating',
                              controller: ratingCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormField(
                              label: 'Reviews',
                              controller: reviewsCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormField(
                              label: 'Order',
                              controller: orderCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Status text',
                        controller: statusTextCtrl,
                        hint: 'Open · Closes at 15:00',
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Currently open',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Switch(
                              value: isCurrentlyOpen,
                              activeThumbColor: const Color(0xFF6A2777),
                              activeTrackColor: const Color(0xFFD8B4E2),
                              onChanged: (val) {
                                setModalState(() => isCurrentlyOpen = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          final payload = {
                            if (existing?.id != null) 'id': existing!.id,
                            'name': existing?.name ?? name,
                            'new_name': name,
                            'type': typeCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                            'website': websiteCtrl.text.trim(),
                            'rating':
                                double.tryParse(ratingCtrl.text.trim()) ?? 4.5,
                            'reviews':
                                int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                            'status_text': statusTextCtrl.text.trim(),
                            'currently_open': isCurrentlyOpen ? 1 : 0,
                          };

                          Navigator.pop(ctx);

                          if (isEdit) {
                            final updated = GovernmentEntity(
                              id: existing.id,
                              name: name,
                              defaultIsOpen: isCurrentlyOpen,
                              rating:
                                  double.tryParse(ratingCtrl.text.trim()) ??
                                  4.5,
                              reviewCount:
                                  int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                              category: typeCtrl.text.trim(),
                              location: addressCtrl.text.trim(),
                              defaultTiming: statusTextCtrl.text.trim(),
                              websiteUrl: websiteCtrl.text.trim(),
                              directionsUrl: existing.directionsUrl,
                              googleMapsReviewsUrl:
                                  existing.googleMapsReviewsUrl,
                              reviews: existing.reviews,
                              openHour: existing.openHour,
                              openMinute: existing.openMinute,
                              closeHour: existing.closeHour,
                              closeMinute: existing.closeMinute,
                              closedDays: existing.closedDays,
                              seasonalNotice: existing.seasonalNotice,
                            );
                            if (index != null && index < _govEntities.length) {
                              setState(() => _govEntities[index] = updated);
                            }
                            await sl<ApiService>().updateGovernmentEntity(
                              payload,
                            );
                          } else {
                            final newEntity = GovernmentEntity(
                              name: name,
                              defaultIsOpen: isCurrentlyOpen,
                              rating:
                                  double.tryParse(ratingCtrl.text.trim()) ??
                                  4.5,
                              reviewCount:
                                  int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                              category: typeCtrl.text.trim(),
                              location: addressCtrl.text.trim(),
                              defaultTiming: statusTextCtrl.text.trim(),
                              websiteUrl: websiteCtrl.text.trim(),
                              directionsUrl:
                                  'https://www.google.com/maps/search/?api=1&query=$name+Dubai',
                            );
                            setState(() => _govEntities.insert(0, newEntity));
                            await sl<ApiService>().createGovernmentEntity(
                              payload,
                            );
                          }
                          try {
                            sl<LiveSyncService>().notifyGovernmentChanged();
                          } catch (_) {}
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // --- Modal Dialog: New Art Center & Edit Art Center ---
  void _showArtCenterDialog({Map<String, dynamic>? existing, int? index}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final typeCtrl = TextEditingController(
      text: existing?['category'] ?? 'Gallery · Exhibition space',
    );
    final addressCtrl = TextEditingController(
      text: existing?['location'] ?? '',
    );
    final hoursCtrl = TextEditingController(
      text: existing?['timing'] ?? 'Sat–Thu 10:00–20:00',
    );
    final websiteCtrl = TextEditingController(text: existing?['website'] ?? '');
    final imageCtrl = TextEditingController(text: existing?['image_url'] ?? '');
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final orderCtrl = TextEditingController(
      text: '${existing?['display_order'] ?? 0}',
    );
    bool isCurrentlyOpen =
        (existing?['currently_open'] == 1 ||
            existing?['currently_open'] == true);
    bool isApproved =
        (existing?['status'] ?? 'approved').toString().toLowerCase() !=
            'pending' &&
        existing?['is_approved'] != 0 &&
        existing?['is_approved'] != '0' &&
        existing?['is_public'] != 0 &&
        existing?['is_public'] != '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit art center' : 'New art center',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Name',
                        controller: nameCtrl,
                        isFocused: true,
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Type',
                        controller: typeCtrl,
                        hint: 'Gallery · Exhibition space',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Address',
                        controller: addressCtrl,
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Website',
                        controller: websiteCtrl,
                        hint: 'https://...',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Image URL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.upload_file_outlined,
                              size: 14,
                              color: Color(0xFF6A2777),
                            ),
                            label: const Text(
                              'Upload photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6A2777),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed:
                                () => _pickAndUploadImageForField(
                                  imageCtrl,
                                  setModalState,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildFormField(
                        label: '',
                        controller: imageCtrl,
                        hint: 'https://... or click Upload',
                        onChanged: (_) => setModalState(() {}),
                      ),
                      if (imageCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppCachedImage(
                                imageUrl: imageCtrl.text.trim(),
                                fit: BoxFit.cover,
                                placeholder: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF6A2777),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: Container(
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(12),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: Color(0xFF94A3B8),
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Image preview not available',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setModalState(() {
                                        imageCtrl.clear();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Description',
                        controller: descCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Display order',
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Currently open',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Switch(
                              value: isCurrentlyOpen,
                              activeThumbColor: const Color(0xFF6A2777),
                              activeTrackColor: const Color(0xFFD8B4E2),
                              onChanged: (val) {
                                setModalState(() => isCurrentlyOpen = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Approved & Published',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  isApproved
                                      ? 'Visible in public app'
                                      : 'Pending admin review',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isApproved,
                              activeThumbColor: const Color(0xFF16A34A),
                              activeTrackColor: const Color(0xFFBBF7D0),
                              onChanged: (val) {
                                setModalState(() => isApproved = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          final payload = {
                            if (existing?['id'] != null) 'id': existing!['id'],
                            'name': name,
                            'category': typeCtrl.text.trim(),
                            'location': addressCtrl.text.trim(),
                            'timing': hoursCtrl.text.trim(),
                            'website': websiteCtrl.text.trim(),
                            'image_url': imageCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'currently_open': isCurrentlyOpen ? 1 : 0,
                            'status': isApproved ? 'approved' : 'pending',
                            'is_approved': isApproved ? 1 : 0,
                            'is_public': isApproved ? 1 : 0,
                          };

                          Navigator.pop(ctx);

                          if (isEdit) {
                            if (index != null && index < _artCenters.length) {
                              setState(() => _artCenters[index] = payload);
                            }
                            await sl<ApiService>().updateArtCenter(payload);
                          } else {
                            setState(() {
                              _artCenters.insert(0, payload);
                              _galleries.insert(0, payload);
                            });
                            await sl<ApiService>().createArtCenter(payload);
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // --- Modal Dialog: Create & Edit Gallery ---
  void _showCreateGalleryDialog({Map<String, dynamic>? existing, int? index}) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(
      text: existing?['name'] ?? existing?['title'] ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final coverImageCtrl = TextEditingController(
      text: existing?['image_url'] ?? existing?['cover_url'] ?? '',
    );
    String? selectedEvent = existing?['event_name'];
    bool isVisibleToEveryone = (existing?['is_public'] ?? 1) == 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit gallery' : 'Create gallery',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Title',
                        controller: titleCtrl,
                        hint: 'Gallery title',
                        isFocused: true,
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Description',
                        controller: descCtrl,
                        hint: 'Short description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cover image URL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.upload_file_outlined,
                              size: 14,
                              color: Color(0xFF6A2777),
                            ),
                            label: const Text(
                              'Upload photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6A2777),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed:
                                () => _pickAndUploadImageForField(
                                  coverImageCtrl,
                                  setModalState,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildFormField(
                        label: '',
                        controller: coverImageCtrl,
                        hint: 'https://... or click Upload',
                        onChanged: (_) => setModalState(() {}),
                      ),
                      if (coverImageCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppCachedImage(
                                imageUrl: coverImageCtrl.text.trim(),
                                fit: BoxFit.cover,
                                placeholder: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF6A2777),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: Container(
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(12),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: Color(0xFF94A3B8),
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Image preview not available',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setModalState(() {
                                        coverImageCtrl.clear();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked event (optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: selectedEvent,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                elevation: 4,
                                menuMaxHeight: 280,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF64748B),
                                ),
                                hint: const Text(
                                  'No event',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'No event',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ..._events.map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e.title,
                                      child: Text(
                                        e.title,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setModalState(() => selectedEvent = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Visible to everyone',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Switch(
                              value: isVisibleToEveryone,
                              activeThumbColor: const Color(0xFF6A2777),
                              activeTrackColor: const Color(0xFFD8B4E2),
                              onChanged: (val) {
                                setModalState(() => isVisibleToEveryone = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;

                          final payload = {
                            if (existing?['id'] != null) 'id': existing!['id'],
                            'name': title,
                            'title': title,
                            'description':
                                descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : (selectedEvent != null
                                        ? 'Curated collection for $selectedEvent'
                                        : ''),
                            'image_url': coverImageCtrl.text.trim(),
                            'cover_url': coverImageCtrl.text.trim(),
                            'event_name': selectedEvent ?? '',
                            'is_public': isVisibleToEveryone ? 1 : 0,
                            'is_approved': isVisibleToEveryone ? 1 : 0,
                            'status':
                                isVisibleToEveryone ? 'approved' : 'pending',
                            'category': 'Artist gallery',
                          };

                          Navigator.pop(ctx);

                          if (isEdit) {
                            if (index != null && index < _galleries.length) {
                              setState(() => _galleries[index] = payload);
                            }
                            await sl<ApiService>().updateArtCenter(payload);
                          } else {
                            setState(() {
                              _galleries.insert(0, payload);
                            });
                            await sl<ApiService>().createArtCenter(payload);
                          }
                        },
                        child: Text(
                          isEdit ? 'Save' : 'Create',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isFocused = false,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    final textField = TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly || onTap != null,
      enableInteractiveSelection: onTap == null,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 13.5,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        suffixIcon:
            suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: const Color(0xFF6A2777))
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color:
                isFocused ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
            width: isFocused ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color:
                isFocused ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
            width: isFocused ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        if (onTap != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AbsorbPointer(absorbing: true, child: textField),
            ),
          )
        else
          textField,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildAdminDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 48,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leading: Builder(
          builder:
              (scaffoldContext) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: InkWell(
                    onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A2777).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6A2777).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF6A2777),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Admin Dashboard'.trData(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Artist Dubai · Executive'.trData(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // ── Language Toggle Button ──────────────────────────────────────────
          Builder(
            builder: (context) {
              LocaleProvider? localeProvider;
              try {
                localeProvider = Provider.of<LocaleProvider>(
                  context,
                  listen: true,
                );
              } catch (_) {}
              final isArabic = localeProvider?.isArabic ?? false;
              return Tooltip(
                message: isArabic ? 'Switch to English' : 'التبديل إلى العربية',
                child: InkWell(
                  onTap: () => localeProvider?.toggleLocale(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E227A).withValues(alpha: 0.08),
                      border: Border.all(
                        color: const Color(0xFF5E227A).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language,
                          size: 12.5,
                          color: Color(0xFF5E227A),
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          isArabic ? 'عربي' : 'EN',
                          style: const TextStyle(
                            color: Color(0xFF5E227A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Tooltip(
            message: 'Recycle Bin'.trData(context),
            child: InkWell(
              onTap: () => context.push(RouteNames.adminRecycleBin),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Exit to App'.trData(context),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.home);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        color: const Color(0xFF6A2777),
        backgroundColor: Colors.white,
        strokeWidth: 2.8,
        displacement: 40,
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Multi-row Tab Selector Bar
              _buildTabSelector(),
              const SizedBox(height: 16),

              // 2. Tab Content View
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                count: '${_artists.length}',
                label: 'Artists'.trData(context),
                isSelected: _selectedTab == AdminTab.artists,
                onTap: () => setState(() => _selectedTab = AdminTab.artists),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_outlined,
                count: '${_events.length}',
                label: 'Events'.trData(context),
                isSelected:
                    _selectedTab == AdminTab.events ||
                    _selectedTab == AdminTab.calendar,
                onTap: () => setState(() => _selectedTab = AdminTab.events),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.image_outlined,
                count: '${_galleries.length}',
                label: 'Galleries'.trData(context),
                isSelected: _selectedTab == AdminTab.galleries,
                onTap: () => setState(() => _selectedTab = AdminTab.galleries),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.business_outlined,
                count: '${_artCenters.length}',
                label: 'Art Centers'.trData(context),
                isSelected: _selectedTab == AdminTab.artCenters,
                onTap: () => setState(() => _selectedTab = AdminTab.artCenters),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.account_balance_outlined,
                count: '${_govEntities.length}',
                label: 'Government'.trData(context),
                isSelected: _selectedTab == AdminTab.government,
                onTap: () => setState(() => _selectedTab = AdminTab.government),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.tune_rounded,
                count: '${_categories.length + _experienceLevels.length}',
                label: 'Masters'.trData(context),
                isSelected: _selectedTab == AdminTab.masters,
                onTap: () => setState(() => _selectedTab = AdminTab.masters),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shield_outlined,
                count:
                    '$_activeMenuCount/${MenuPermissionModel.defaultPermissions().length}',
                label: 'Menu Permissions'.trData(context),
                isSelected: _selectedTab == AdminTab.permissions,
                onTap:
                    () => setState(() => _selectedTab = AdminTab.permissions),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.hourglass_empty_rounded,
                count: '$_comingSoonMenuCount',
                label: 'Coming Soon'.trData(context),
                isSelected: _selectedTab == AdminTab.permissions,
                onTap:
                    () => setState(() => _selectedTab = AdminTab.permissions),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.manage_accounts_outlined,
                count: '${_users.length}',
                label: 'All Users & Data'.trData(context),
                isSelected: _selectedTab == AdminTab.users,
                onTap: () => setState(() => _selectedTab = AdminTab.users),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.palette_outlined,
                count:
                    '${_users.where((u) => u['has_artist_profile'] == true || u['role'] == 'artist').length}',
                label: 'Artist Accounts'.trData(context),
                isSelected: _selectedTab == AdminTab.users,
                onTap: () => setState(() => _selectedTab = AdminTab.users),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.info_outline_rounded,
                count: 'Live',
                label: 'About Us Page Content'.trData(context),
                isSelected: _selectedTab == AdminTab.aboutUs,
                onTap: () => setState(() => _selectedTab = AdminTab.aboutUs),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.visibility_outlined,
                count: 'Preview',
                label: 'View About Page'.trData(context),
                isSelected: false,
                onTap: () => context.push(RouteNames.aboutUs),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String count,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6A2777) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? const Color(0x206A2777)
                      : const Color(0x06000000),
              blurRadius: isSelected ? 12 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF6A2777).withValues(alpha: 0.12)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFF6A2777).withValues(alpha: 0.3)
                              : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isSelected
                            ? const Color(0xFF6A2777)
                            : const Color(0xFF475569),
                    size: 19,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A2777),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color:
                    isSelected
                        ? const Color(0xFF6A2777)
                        : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected
                        ? const Color(0xFF6A2777)
                        : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      (AdminTab.overview, 'Overview'.trData(context), Icons.dashboard_outlined),
      (AdminTab.artists, 'Artists'.trData(context), Icons.palette_outlined),
      (AdminTab.events, 'Events'.trData(context), Icons.event_outlined),
      (
        AdminTab.calendar,
        'Calendar'.trData(context),
        Icons.calendar_month_outlined,
      ),
      (
        AdminTab.galleries,
        'Galleries'.trData(context),
        Icons.photo_library_outlined,
      ),
      (
        AdminTab.artCenters,
        'Art Centers'.trData(context),
        Icons.account_balance_outlined,
      ),
      (
        AdminTab.government,
        'Government'.trData(context),
        Icons.assured_workload_outlined,
      ),
      (AdminTab.masters, 'Masters'.trData(context), Icons.stars_outlined),
      (
        AdminTab.permissions,
        'Permissions'.trData(context),
        Icons.security_outlined,
      ),
      (
        AdminTab.aboutUs,
        'About Us'.trData(context),
        Icons.info_outline_rounded,
      ),
      (AdminTab.users, 'Users'.trData(context), Icons.people_alt_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= 900) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children:
                  tabs
                      .map(
                        (t) =>
                            Expanded(child: _buildWideTabButton(t.$1, t.$2, t.$3)),
                      )
                      .toList(),
            ),
          );
        } else {
          // Mobile & compact screens (< 900px): Clean 2-row compact grid, NO horizontal scrolling
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildCompactTabButton(
                      AdminTab.overview,
                      'Overview'.trData(context),
                      Icons.dashboard_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.artists,
                      'Artists'.trData(context),
                      Icons.palette_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.events,
                      'Events'.trData(context),
                      Icons.event_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.calendar,
                      'Calendar'.trData(context),
                      Icons.calendar_month_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.galleries,
                      'Galleries'.trData(context),
                      Icons.photo_library_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _buildCompactTabButton(
                      AdminTab.artCenters,
                      'Centers'.trData(context),
                      Icons.account_balance_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.government,
                      'Gov'.trData(context),
                      Icons.assured_workload_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.masters,
                      'Masters'.trData(context),
                      Icons.stars_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.permissions,
                      'Perms'.trData(context),
                      Icons.security_outlined,
                    ),
                    _buildCompactTabButton(
                      AdminTab.aboutUs,
                      'About Us'.trData(context),
                      Icons.info_outline_rounded,
                    ),
                    _buildCompactTabButton(
                      AdminTab.users,
                      'Users'.trData(context),
                      Icons.people_alt_outlined,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildWideTabButton(AdminTab tab, String title, IconData? icon) {
    final isSelected = _selectedTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6A2777) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isSelected
                    ? const [
                      BoxShadow(
                        color: Color(0x336A2777),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTabButton(AdminTab tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedTab = tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6A2777) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow:
                  isSelected
                      ? const [
                        BoxShadow(
                          color: Color(0x336A2777),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF334155),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AdminTab.overview:
        return _buildMetricsGrid();
      case AdminTab.artists:
        return _buildArtistsTab();
      case AdminTab.events:
        return _buildEventsTab();
      case AdminTab.calendar:
        return _buildCalendarTab();
      case AdminTab.galleries:
        return _buildGalleriesTab();
      case AdminTab.artCenters:
        return _buildArtCentersTab();
      case AdminTab.government:
        return _buildGovernmentTab();
      case AdminTab.masters:
        return _buildMastersTab();
      case AdminTab.permissions:
        return _buildPermissionsTab();
      case AdminTab.aboutUs:
        return _buildAboutUsTab();
      case AdminTab.users:
        return _buildUsersTab();
    }
  }

  // --- 1. Artists Tab ---
  Widget _buildArtistsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_artists.length} artists'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'New artist'.trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              onPressed:
                  () => context.push(
                    RouteNames.artistRegistration,
                    extra: {'fromAdmin': true},
                  ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_artists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No artists registered yet.'.trData(context),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _artists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final artist = _artists[index];
              final isActive = artist.isActive;
              return _buildListItemCard(
                title: artist.name.trData(context),
                subtitle:
                    '${artist.localizedCategory(context)} · ${artist.localizedLocation(context).isNotEmpty ? artist.localizedLocation(context) : 'Dubai, UAE'.trData(context)}',
                badgeText: (isActive ? 'Active' : 'Inactive').trData(context),
                isPurpleBadge: isActive,
                onToggleStatus: () => _toggleArtistStatus(artist, index),
                onEdit: () {
                  context.push(RouteNames.artistDetail, extra: artist);
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Artist Profile'.trData(context),
                    message: 'Are you sure you want to remove ${artist.name}?',
                    onConfirm: () async {
                      setState(() => _artists.removeAt(index));
                      await sl<ApiService>().deleteArtist(artist.id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleArtistStatus(ArtistModel artist, int index) async {
    final newActive = !artist.isActive;
    final newStatus = newActive ? 'active' : 'inactive';
    final updated = artist.copyWith(isActive: newActive, status: newStatus);

    setState(() {
      _artists[index] = updated;
    });

    await sl<ApiService>().updateArtist({
      'id': int.tryParse(artist.id) ?? artist.id,
      'status': newStatus,
      'is_active': newActive ? 1 : 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${artist.name} is now ${newActive ? "Active" : "Inactive"}',
          ),
          backgroundColor:
              newActive ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- 2. Events Tab ---
  Widget _buildEventsTab() {
    final pendingEvents =
        _events.where((e) {
          final st = e.status.toLowerCase().trim();
          return st == 'pending' ||
              st == 'pending_approval' ||
              (!e.isActive && st != 'cancelled' && st != 'inactive');
        }).toList();

    final activeEvents =
        _events.where((e) {
          final st = e.status.toLowerCase().trim();
          return e.isActive &&
              st != 'cancelled' &&
              st != 'inactive' &&
              st != 'pending' &&
              st != 'pending_approval';
        }).toList();

    List<ArtEventModel> displayedEvents;
    if (_eventFilterIndex == 1) {
      displayedEvents = pendingEvents;
    } else if (_eventFilterIndex == 2) {
      displayedEvents = activeEvents;
    } else {
      displayedEvents = _events;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_events.length} events total'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'New event'.trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              onPressed: () async {
                await context.push(
                  RouteNames.createArtEvent,
                  extra: {'fromAdmin': true},
                );
                _loadAllData();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter sub-tabs (All, Pending Review, Active - no horizontal scroll)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildEventFilterChip(
              0,
              '${'All'.trData(context)} (${_events.length})',
            ),
            _buildEventFilterChip(
              1,
              '${'Pending Review'.trData(context)} (${pendingEvents.length})',
              isHighlight: pendingEvents.isNotEmpty,
            ),
            _buildEventFilterChip(
              2,
              '${'Active'.trData(context)} (${activeEvents.length})',
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (displayedEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _eventFilterIndex == 1
                    ? 'No pending event requests.'.trData(context)
                    : (_eventFilterIndex == 2
                        ? 'No active events.'.trData(context)
                        : 'No events created yet.'.trData(context)),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ev = displayedEvents[index];
              final realIndex = _events.indexOf(ev);
              final st = ev.status.toLowerCase().trim();
              final isPending =
                  st == 'pending' ||
                  st == 'pending_approval' ||
                  (!ev.isActive && st != 'cancelled' && st != 'inactive');
              final isActive =
                  ev.isActive &&
                  st != 'cancelled' &&
                  st != 'inactive' &&
                  !isPending;

              final plan = ev.publishingPlan ?? '';
              final amount = ev.publishingAmount ?? '';
              final planInfo =
                  plan.isNotEmpty
                      ? ' · Plan: ${plan.toUpperCase()}${amount.isNotEmpty ? " ($amount)" : ""}'
                      : '';
              final payRef = ev.paymentReference ?? '';
              final payStatus =
                  ev.paymentStatus ?? (isPending ? 'pending' : 'paid');
              final payProof = ev.paymentProofUrl ?? '';

              return _buildListItemCard(
                title: ev.title.trData(context),
                subtitle:
                    '${ev.organizer.isNotEmpty ? "Organizer: ${ev.organizer} · " : ""}${ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime} - ${ev.location}$planInfo'
                        .trData(context),
                badgeText: (isPending
                        ? 'Pending Review'
                        : (isActive ? 'Active' : 'Inactive'))
                    .trData(context),
                isPurpleBadge: isActive,
                isAmberBadge: isPending,
                paymentProofUrl: payProof,
                paymentReference: payRef,
                paymentStatus: isPending ? payStatus : null,
                onViewReceipt:
                    payProof.isNotEmpty
                        ? () => _showReceiptDialog(
                          context,
                          title: ev.title,
                          receiptUrl: payProof,
                          refNumber: payRef,
                          plan: plan,
                          amount: amount,
                          onAccept:
                              isPending
                                  ? () => _approveEvent(ev, realIndex)
                                  : null,
                        )
                        : null,
                onApprove:
                    isPending ? () => _approveEvent(ev, realIndex) : null,
                onToggleStatus: () => _toggleEventStatus(ev, realIndex),
                onEdit: () async {
                  await context.push(
                    RouteNames.createArtEvent,
                    extra: {'event': ev, 'fromAdmin': true},
                  );
                  _loadAllData();
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Event'.trData(context),
                    message: 'Are you sure you want to delete "${ev.title}"?',
                    onConfirm: () async {
                      if (realIndex >= 0) {
                        setState(() => _events.removeAt(realIndex));
                      }
                      await sl<ApiService>().deleteEvent(ev.id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEventFilterChip(
    int index,
    String label, {
    bool isHighlight = false,
  }) {
    final isSelected = _eventFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _eventFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF6A2777)
                  : (isHighlight
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF6A2777)
                    : (isHighlight
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight:
                isSelected || isHighlight ? FontWeight.bold : FontWeight.w500,
            color:
                isSelected
                    ? Colors.white
                    : (isHighlight
                        ? const Color(0xFFD97706)
                        : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Future<void> _approveEvent(ArtEventModel ev, int index) async {
    final updated = ev.copyWith(isActive: true, status: 'active');
    if (index >= 0 && index < _events.length) {
      setState(() {
        _events[index] = updated;
      });
    }
    sl<LiveSyncService>().notifyEventsChanged(_events);

    final success = await sl<ApiService>().updateEvent({
      'id': int.tryParse(ev.id) ?? ev.id,
      'status': 'active',
      'is_active': 1,
    });

    if (!success && mounted) {
      if (index >= 0 && index < _events.length) {
        setState(() {
          _events[index] = ev;
        });
      }
      sl<LiveSyncService>().notifyEventsChanged(_events);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve "${ev.title}". Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${ev.title}" approved and published to public events!',
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleEventStatus(ArtEventModel ev, int index) async {
    if (_togglingEventIds.contains(ev.id)) return;
    _togglingEventIds.add(ev.id);

    final isCurrentlyActive =
        ev.isActive &&
        ev.status.toLowerCase().trim() != 'cancelled' &&
        ev.status.toLowerCase().trim() != 'inactive';
    final newActive = !isCurrentlyActive;
    final newStatus = newActive ? 'active' : 'inactive';
    final updated = ev.copyWith(isActive: newActive, status: newStatus);

    setState(() {
      _events[index] = updated;
    });

    sl<LiveSyncService>().notifyEventsChanged(_events);

    final success = await sl<ApiService>().updateEvent({
      'id': int.tryParse(ev.id) ?? ev.id,
      'status': newStatus,
      'is_active': newActive ? 1 : 0,
    });

    _togglingEventIds.remove(ev.id);

    if (!success && mounted) {
      setState(() {
        _events[index] = ev;
      });
      sl<LiveSyncService>().notifyEventsChanged(_events);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update "${ev.title}". Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${ev.title}" is now ${newActive ? "Active" : "Inactive"}',
          ),
          backgroundColor:
              newActive ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- 3. Calendar Tab ---
  Widget _buildCalendarTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_events.length} calendar events'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'Add to calendar'.trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              onPressed: () async {
                await context.push(
                  RouteNames.createArtEvent,
                  extra: {'isCalendar': true, 'fromAdmin': true},
                );
                _loadAllData();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No upcoming events.'.trData(context),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ev = _events[index];
              final isActive =
                  ev.isActive &&
                  ev.status.toLowerCase().trim() != 'cancelled' &&
                  ev.status.toLowerCase().trim() != 'inactive';
              return _buildListItemCard(
                title: ev.title.trData(context),
                subtitle:
                    '${ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime} - ${ev.locationCity ?? ev.location}'
                        .trData(context),
                badgeText: (isActive ? 'Scheduled' : 'Cancelled').trData(
                  context,
                ),
                isPurpleBadge: isActive,
                isRedBadge: !isActive,
                onToggleStatus: () => _toggleCalendarEventStatus(ev, index),
                onEdit: () async {
                  await context.push(
                    RouteNames.createArtEvent,
                    extra: {'event': ev, 'isCalendar': true, 'fromAdmin': true},
                  );
                  _loadAllData();
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Remove from Calendar'.trData(context),
                    message:
                        'Are you sure you want to remove "${ev.title}" from the calendar?',
                    onConfirm: () async {
                      setState(() {
                        _events.removeAt(index);
                      });
                      await sl<ApiService>().deleteEvent(ev.id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleCalendarEventStatus(ArtEventModel ev, int index) async {
    if (_togglingEventIds.contains(ev.id)) return;
    _togglingEventIds.add(ev.id);

    final isCurrentlyActive =
        ev.isActive &&
        ev.status.toLowerCase().trim() != 'cancelled' &&
        ev.status.toLowerCase().trim() != 'inactive';
    final newActive = !isCurrentlyActive;
    final newStatus = newActive ? 'active' : 'cancelled';
    final updated = ev.copyWith(isActive: newActive, status: newStatus);

    setState(() {
      _events[index] = updated;
    });

    // Notify live streams optimistically so all tabs and screens reflect immediately
    sl<LiveSyncService>().notifyEventsChanged(_events);

    final success = await sl<ApiService>().updateEvent({
      'id': int.tryParse(ev.id) ?? ev.id,
      'status': newStatus,
      'is_active': newActive ? 1 : 0,
    });

    _togglingEventIds.remove(ev.id);

    if (!success && mounted) {
      setState(() {
        _events[index] = ev;
      });
      sl<LiveSyncService>().notifyEventsChanged(_events);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update "${ev.title}". Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${ev.title}" is now ${newActive ? "Scheduled" : "Cancelled"}',
          ),
          backgroundColor:
              newActive ? const Color(0xFF6A2777) : const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isItemPending(Map<String, dynamic> item) {
    final rawStatus = (item['status'] ?? '').toString().trim().toLowerCase();
    if (rawStatus == 'pending' ||
        rawStatus == 'awaiting' ||
        rawStatus == 'in_review' ||
        rawStatus == 'unapproved') {
      return true;
    }
    if (rawStatus == 'approved' ||
        rawStatus == 'active' ||
        rawStatus == 'open') {
      return false;
    }
    final isApproved = item['is_approved'];
    if (isApproved == 0 ||
        isApproved == '0' ||
        isApproved == false ||
        isApproved == 'false') {
      return true;
    }
    final isPublic = item['is_public'];
    if (isPublic == 0 ||
        isPublic == '0' ||
        isPublic == false ||
        isPublic == 'false') {
      return true;
    }
    return false;
  }

  Future<void> _toggleGalleryApproval(
    Map<String, dynamic> item,
    int index,
  ) async {
    final isCurrentlyPending = _isItemPending(item);
    final targetStatus = isCurrentlyPending ? 'approved' : 'pending';
    final targetFlag = isCurrentlyPending ? 1 : 0;
    final name = (item['name'] ?? item['title'] ?? 'Art Space').toString();
    final id = item['id'];

    final updated = Map<String, dynamic>.from(item);
    updated['status'] = targetStatus;
    updated['is_public'] = targetFlag;
    updated['is_approved'] = targetFlag;

    setState(() {
      final gIndex = _galleries.indexWhere((g) => g['id'] == id);
      if (gIndex != -1) _galleries[gIndex] = updated;
      final aIndex = _artCenters.indexWhere((c) => c['id'] == id);
      if (aIndex != -1) _artCenters[aIndex] = updated;
    });

    await sl<ApiService>().updateArtCenter({
      'id': id,
      'status': targetStatus,
      'is_public': targetFlag,
      'is_approved': targetFlag,
    });
    try {
      sl<LiveSyncService>().notifyGalleriesChanged();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyPending
                ? '"$name" activated and published to app!'
                : '"$name" set to pending (hidden from public).',
          ),
          backgroundColor:
              isCurrentlyPending
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- 4. Galleries Tab (Screenshot 6) ---
  Widget _buildGalleriesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              'Public photo galleries'.trData(context),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: Text(
              'New gallery'.trData(context),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            onPressed: _showCreateGalleryDialog,
          ),
        ),
        const SizedBox(height: 12),
        if (_galleries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No galleries registered.'.trData(context),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _galleries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final gal = _galleries[index];
              final name = gal['name'] as String? ?? 'Gallery';
              final id = gal['id'];
              final isPending = _isItemPending(gal);
              final plan = gal['publishing_plan']?.toString() ?? '';
              final amount = gal['publishing_amount']?.toString() ?? '';
              final planInfo =
                  plan.isNotEmpty
                      ? ' · Plan: ${plan.toUpperCase()}${amount.isNotEmpty ? " ($amount)" : ""}'
                      : '';
              final payRef = gal['payment_reference']?.toString() ?? '';
              final payStatus =
                  gal['payment_status']?.toString() ??
                  (isPending ? 'pending' : 'paid');
              final payProof =
                  (gal['payment_proof_url'] ?? gal['receipt_url'])
                      ?.toString() ??
                  '';

              return _buildListItemCard(
                title: name.trData(context),
                subtitle:
                    '${(gal['description'] != null && gal['description'].toString().isNotEmpty ? gal['description'] : (gal['artist_name'] != null && gal['artist_name'].toString().isNotEmpty ? 'Artist: ${gal['artist_name']}' : 'Artist photo collection'))}$planInfo'
                        .trData(context),
                badgeText: (isPending ? 'Pending' : 'Approved').trData(context),
                isPurpleBadge: !isPending,
                isAmberBadge: isPending,
                paymentProofUrl: payProof,
                paymentReference: payRef,
                paymentStatus: isPending ? payStatus : null,
                onViewReceipt:
                    payProof.isNotEmpty
                        ? () => _showReceiptDialog(
                          context,
                          title: name.trData(context),
                          receiptUrl: payProof,
                          refNumber: payRef,
                          plan: plan,
                          amount: amount,
                          onAccept:
                              isPending
                                  ? () => _approveGallery(gal, index)
                                  : null,
                        )
                        : null,
                onApprove: isPending ? () => _approveGallery(gal, index) : null,
                onToggleStatus: () => _toggleGalleryApproval(gal, index),
                onEdit:
                    () => _showCreateGalleryDialog(existing: gal, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Gallery'.trData(context),
                    message: 'Are you sure you want to remove "$name"?',
                    onConfirm: () async {
                      setState(() => _galleries.removeAt(index));
                      await sl<ApiService>().deleteGallery(id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // --- 5. Art Centers Tab (Screenshot 1 & Screenshot 5) ---
  Widget _buildArtCentersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.business_outlined, size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text(
              'Physical art centers shown in the app',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_artCenters.length} centers'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'New center'.trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              onPressed: _showArtCenterDialog,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_artCenters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No art centers yet.'.trData(context),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _artCenters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final center = _artCenters[index];
              final name =
                  (center['name'] ?? center['title'] ?? 'Art Center')
                      .toString();
              final subtitle =
                  (center['category'] ??
                          center['location'] ??
                          center['address'] ??
                          'Dubai, UAE')
                      .toString();
              final isCurrentlyOpen =
                  center['currently_open'] == 1 ||
                  center['currently_open'] == true;
              final isPending = _isItemPending(center);
              return _buildListItemCard(
                title: name.trData(context),
                subtitle: subtitle.trData(context),
                customStatusToggle: _buildOpenClosedToggle(
                  isOpen: isCurrentlyOpen,
                  isPending: isPending,
                  onToggle: () => _toggleArtCenterStatus(center, index),
                ),
                onApprove:
                    isPending ? () => _approveGallery(center, index) : null,
                onEdit:
                    () => _showArtCenterDialog(existing: center, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Art Center'.trData(context),
                    message: 'Are you sure you want to remove "$name"?',
                    onConfirm: () async {
                      setState(() => _artCenters.removeAt(index));
                      await sl<ApiService>().deleteGallery(center['id']);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleArtCenterStatus(
    Map<String, dynamic> center,
    int index,
  ) async {
    final isCurrentlyOpen =
        center['currently_open'] == 1 || center['currently_open'] == true;
    final isPending = _isItemPending(center);
    final newOpen = isPending ? 1 : (isCurrentlyOpen ? 0 : 1);
    final newStatus =
        isPending ? 'approved' : (newOpen == 1 ? 'approved' : 'inactive');

    final updated = Map<String, dynamic>.from(center);
    updated['currently_open'] = newOpen;
    updated['status'] = newStatus;
    updated['is_public'] = 1;
    updated['is_approved'] = 1;

    setState(() {
      _artCenters[index] = updated;
      final gIndex = _galleries.indexWhere((g) => g['id'] == center['id']);
      if (gIndex != -1) _galleries[gIndex] = updated;
    });

    await sl<ApiService>().updateArtCenter({
      'id': center['id'],
      'currently_open': newOpen,
      'status': newStatus,
      'is_public': 1,
      'is_approved': 1,
    });
    try {
      sl<LiveSyncService>().notifyGalleriesChanged();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${center['name'] ?? 'Art Center'} is now ${newOpen == 1 ? "OPEN" : "CLOSED"}!',
          ),
          backgroundColor:
              newOpen == 1 ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _approveGallery(Map<String, dynamic> item, int index) async {
    final name = (item['name'] ?? item['title'] ?? 'Art Space').toString();
    final id = item['id'];
    final updated = Map<String, dynamic>.from(item);
    updated['status'] = 'approved';
    updated['is_public'] = 1;
    updated['is_approved'] = 1;

    setState(() {
      final gIndex = _galleries.indexWhere((g) => g['id'] == id);
      if (gIndex != -1) _galleries[gIndex] = updated;
      final aIndex = _artCenters.indexWhere((c) => c['id'] == id);
      if (aIndex != -1) _artCenters[aIndex] = updated;
    });

    await sl<ApiService>().updateArtCenter({
      'id': id,
      'status': 'approved',
      'is_public': 1,
      'is_approved': 1,
    });
    try {
      sl<LiveSyncService>().notifyGalleriesChanged();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" request accepted and published to app!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- 7. Government Tab (Screenshots 2, 3, 4) ---
  Widget _buildGovernmentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_govEntities.length} entries'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'New entry'.trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _showGovernmentDialog(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_govEntities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No government entries registered.'.trData(context),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _govEntities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final g = _govEntities[index];
              return _buildGovernmentCard(
                entity: g,
                index: index,
                onEdit: () => _showGovernmentDialog(existing: g, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Government Entry'.trData(context),
                    message: 'Are you sure you want to remove "${g.name}"?',
                    onConfirm: () async {
                      setState(() => _govEntities.removeAt(index));
                      await sl<ApiService>().deleteGovernmentEntity(
                        id: g.id,
                        name: g.name,
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleGovernmentOpen(GovernmentEntity entity, int index) async {
    final newIsOpen = !entity.defaultIsOpen;
    final newTiming =
        newIsOpen ? 'Open · Closes at 18:00' : 'Closed · Opens tomorrow';
    final updated = GovernmentEntity(
      id: entity.id,
      name: entity.name,
      defaultIsOpen: newIsOpen,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      category: entity.category,
      location: entity.location,
      defaultTiming: newTiming,
      websiteUrl: entity.websiteUrl,
      directionsUrl: entity.directionsUrl,
      googleMapsReviewsUrl: entity.googleMapsReviewsUrl,
      reviews: entity.reviews,
      openHour: entity.openHour,
      openMinute: entity.openMinute,
      closeHour: entity.closeHour,
      closeMinute: entity.closeMinute,
      closedDays: entity.closedDays,
      seasonalNotice: entity.seasonalNotice,
    );

    setState(() {
      final list = List<GovernmentEntity>.from(_govEntities);
      if (index >= 0 && index < list.length) {
        list[index] = updated;
      }
      _govEntities = list;
    });

    await sl<ApiService>().updateGovernmentEntity({
      if (entity.id != null) 'id': entity.id,
      'name': entity.name,
      'currently_open': newIsOpen ? 1 : 0,
      'status_text': newTiming,
    });
    try {
      sl<LiveSyncService>().notifyGovernmentChanged();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entity.name} is now ${newIsOpen ? "Open" : "Closed"}',
          ),
          backgroundColor:
              newIsOpen ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Sleek segmented Open / Closed toggle matching modern UI standards
  Widget _buildOpenClosedToggle({
    required bool isOpen,
    required VoidCallback onToggle,
    bool isPending = false,
  }) {
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
        ),
        child: Text(
          'Pending'.trData(context),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Open segment
          InkWell(
            key: const Key('admin_toggle_open_btn'),
            borderRadius: BorderRadius.circular(16),
            onTap: isOpen ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isOpen
                        ? const [
                          BoxShadow(
                            color: Color(0x3316A34A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOpen) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'Open'.trData(context),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isOpen ? FontWeight.w700 : FontWeight.w500,
                      color: isOpen ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Closed segment
          InkWell(
            key: const Key('admin_toggle_close_btn'),
            borderRadius: BorderRadius.circular(16),
            onTap: !isOpen ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isOpen ? const Color(0xFFEF4444) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    !isOpen
                        ? const [
                          BoxShadow(
                            color: Color(0x33EF4444),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isOpen) ...[
                    const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'Closed'.trData(context),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: !isOpen ? FontWeight.w700 : FontWeight.w500,
                      color: !isOpen ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Government Card matching Screenshot 2
  Widget _buildGovernmentCard({
    required GovernmentEntity entity,
    required int index,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entity.name.trData(context),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildOpenClosedToggle(
                isOpen: entity.defaultIsOpen,
                onToggle: () => _toggleGovernmentOpen(entity, index),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            entity.category.trData(context),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            entity.localizedLocation(context),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entity.rating} ★ · ${entity.reviewCount} ${'reviews'.trData(context)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Common card container matching screenshots
  Widget _buildListItemCard({
    required String title,
    required String subtitle,
    Widget? customStatusToggle,
    String? badgeText,
    bool isPurpleBadge = false,
    bool isAmberBadge = false,
    bool isGreenBadge = false,
    bool isRedBadge = false,
    VoidCallback? onApprove,
    VoidCallback? onToggleStatus,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? paymentProofUrl,
    String? paymentReference,
    String? paymentStatus,
    VoidCallback? onViewReceipt,
    String? actionButtonText,
    Color? actionButtonColor,
    VoidCallback? onAction,
  }) {
    Color badgeBg;
    Color badgeFg;
    Border? badgeBorder;

    if (isPurpleBadge) {
      badgeBg = const Color(0xFF6A2777);
      badgeFg = Colors.white;
      badgeBorder = null;
    } else if (isAmberBadge) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFD97706);
      badgeBorder = Border.all(color: const Color(0xFFFDE68A), width: 0.8);
    } else if (isGreenBadge) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeFg = const Color(0xFF16A34A);
      badgeBorder = Border.all(color: const Color(0xFFBBF7D0), width: 0.8);
    } else if (isRedBadge) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeFg = const Color(0xFFDC2626);
      badgeBorder = Border.all(color: const Color(0xFFFECACA), width: 0.8);
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF475569);
      badgeBorder = Border.all(color: const Color(0xFFCBD5E1), width: 0.8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isNarrow = cardConstraints.maxWidth < 420;

          final infoColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              if ((paymentReference != null && paymentReference.isNotEmpty) ||
                  (paymentStatus != null && paymentStatus.isNotEmpty)) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (paymentReference != null &&
                        paymentReference.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 10,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Ref: $paymentReference',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (paymentStatus != null && paymentStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              paymentStatus.toLowerCase() == 'paid' ||
                                      paymentStatus.toLowerCase() ==
                                          'approved'
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                paymentStatus.toLowerCase() == 'paid' ||
                                        paymentStatus.toLowerCase() ==
                                            'approved'
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color:
                                paymentStatus.toLowerCase() == 'paid' ||
                                        paymentStatus.toLowerCase() ==
                                            'approved'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );

          final badgeWidget = customStatusToggle ??
              (badgeText != null
                  ? MouseRegion(
                      cursor:
                          onToggleStatus != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                            border: badgeBorder,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onToggleStatus != null &&
                                  (isPurpleBadge || isGreenBadge)) ...[
                                const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: badgeFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null);

          final actionsList = <Widget>[
            if (onViewReceipt != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6A2777),
                  side: const BorderSide(color: Color(0xFF6A2777), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onViewReceipt,
                icon: const Icon(Icons.receipt_long_rounded, size: 12),
                label: const Text(
                  'Receipt',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            if (actionButtonText != null && onAction != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionButtonColor ?? const Color(0xFF6A2777),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(54, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionButtonText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (onApprove != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(58, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onApprove,
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onDelete,
              ),
          ];

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: infoColumn),
                    if (badgeWidget != null) ...[
                      const SizedBox(width: 8),
                      badgeWidget,
                    ],
                  ],
                ),
                if (actionsList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actionsList,
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: infoColumn),
              if (onViewReceipt != null) ...[
                actionsList.first,
                const SizedBox(width: 6),
              ],
              if (badgeWidget != null) ...[
                badgeWidget,
                const SizedBox(width: 8),
              ],
              for (final action in actionsList.where((w) => w != actionsList.first || onViewReceipt == null)) ...[
                action,
                const SizedBox(width: 6),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showReceiptDialog(
    BuildContext context, {
    required String title,
    required String receiptUrl,
    String? refNumber,
    String? plan,
    String? amount,
    VoidCallback? onAccept,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF6A2777),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Proof',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Meta chips
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (plan != null && plan.isNotEmpty)
                          Text(
                            'Plan: ${plan.toUpperCase()}${amount != null && amount.isNotEmpty ? " ($amount)" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                        if (refNumber != null && refNumber.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tag,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 2),
                              SelectableText(
                                refNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Receipt Image preview
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: InteractiveViewer(
                          child: Image.network(
                            receiptUrl,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Receipt image not accessible',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onAccept != null) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onAccept();
                          },
                          icon: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Accept & Publish',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // --- 8. Masters Tab (Manage Categories & Experience Levels) ---
  Widget _buildMastersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-tab switcher: Categories vs Experience Levels vs Locations vs Listing Plans (No horizontal scrolling!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMasterSubTabItem(
                        index: 0,
                        icon: Icons.category_outlined,
                        label:
                            '${'Categories'.trData(context)} (${_categories.length})',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildMasterSubTabItem(
                        index: 1,
                        icon: Icons.stars_outlined,
                        label:
                            '${'Levels'.trData(context)} (${_experienceLevels.length})',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildMasterSubTabItem(
                        index: 2,
                        icon: Icons.location_on_outlined,
                        label:
                            '${'Locations'.trData(context)} (${_locations.length})',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildMasterSubTabItem(
                        index: 3,
                        icon: Icons.list_alt_rounded,
                        label:
                            '${'Listing Plans'.trData(context)} (${_listingPlans.length})',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMasterSubTabItem(
                            index: 0,
                            icon: Icons.category_outlined,
                            label:
                                '${'Categories'.trData(context)} (${_categories.length})',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildMasterSubTabItem(
                            index: 1,
                            icon: Icons.stars_outlined,
                            label:
                                '${'Levels'.trData(context)} (${_experienceLevels.length})',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMasterSubTabItem(
                            index: 2,
                            icon: Icons.location_on_outlined,
                            label:
                                '${'Locations'.trData(context)} (${_locations.length})',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildMasterSubTabItem(
                            index: 3,
                            icon: Icons.list_alt_rounded,
                            label:
                                '${'Listing Plans'.trData(context)} (${_listingPlans.length})',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
        const SizedBox(height: 14),

        // Action header row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            Text(
              _masterSubTab == 0
                  ? '${_categories.length} categories configured'.trData(
                    context,
                  )
                  : _masterSubTab == 1
                  ? '${_experienceLevels.length} experience levels configured'
                      .trData(context)
                  : _masterSubTab == 2
                  ? '${_locations.length} locations configured'.trData(context)
                  : '${_listingPlans.length} listing plans configured'.trData(
                    context,
                  ),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_masterSubTab != 3)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_masterSubTab == 0) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6A2777),
                        side: const BorderSide(
                          color: Color(0xFF6A2777),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: Text(
                        'Seed All 50 Categories'.trData(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await sl<ApiService>().seedDefaultCategories();
                        if (success) {
                          _loadAllData();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('All 50 art categories restored successfully!'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: Text(
                      (_masterSubTab == 0
                              ? 'New Category'
                              : _masterSubTab == 1
                              ? 'New Level'
                              : 'New Location')
                          .trData(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      if (_masterSubTab == 0) {
                        _showCategoryDialog();
                      } else if (_masterSubTab == 1) {
                        _showExperienceLevelDialog();
                      } else {
                        _showLocationDialog();
                      }
                    },
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6A2777),
                  side: const BorderSide(color: Color(0xFF6A2777), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh, size: 14),
                label: Text('Refresh'.trData(context),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                onPressed: () async {
                  final plans = await sl<ApiService>().getListingPlans(forceRefresh: true);
                  if (mounted) {
                    setState(() => _listingPlans = plans);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Listing plans refreshed'.trData(context)),
                      backgroundColor: const Color(0xFF6A2777),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 14),

        // List Content
        if (_masterSubTab == 0)
          _buildCategoriesMasterList()
        else if (_masterSubTab == 1)
          _buildExperienceLevelsMasterList()
        else if (_masterSubTab == 2)
          _buildLocationsMasterList()
        else
          _buildListingPlansMasterList(),
      ],
    );
  }

  Widget _buildMasterSubTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _masterSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _masterSubTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isSelected
                  ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isSelected
                      ? const Color(0xFF6A2777)
                      : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color:
                        isSelected
                            ? const Color(0xFF6A2777)
                            : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTypeFilterChip(String value, String label) {
    final isSelected = _categoryTypeFilter == value;
    return InkWell(
      onTap: () => setState(() => _categoryTypeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label.trData(context),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesMasterList() {
    final filteredCategories = _categories.where((cat) {
      if (_categoryTypeFilter != 'all') {
        if (cat.type.toLowerCase() != _categoryTypeFilter.toLowerCase()) {
          return false;
        }
      }
      if (_categorySearchQuery.trim().isNotEmpty) {
        final q = _categorySearchQuery.trim().toLowerCase();
        final matchesName = cat.name.toLowerCase().contains(q) || cat.name.trData(context).toLowerCase().contains(q);
        final matchesDesc = cat.description.toLowerCase().contains(q);
        return matchesName || matchesDesc;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Filter Header
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _categorySearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search categories by name...'.trData(context),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _categorySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() => _categorySearchQuery = ''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        // Scope Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryTypeFilterChip('all', 'All (${_categories.length})'),
              const SizedBox(width: 6),
              _buildCategoryTypeFilterChip('artist', 'Artists (${_categories.where((c) => c.type == 'artist').length})'),
              const SizedBox(width: 6),
              _buildCategoryTypeFilterChip('event', 'Events (${_categories.where((c) => c.type == 'event').length})'),
              const SizedBox(width: 6),
              _buildCategoryTypeFilterChip('general', 'General (${_categories.where((c) => c.type == 'general' || c.type.isEmpty).length})'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No categories match your search.'.trData(context),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = filteredCategories[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji Badge
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cat.emoji.isNotEmpty ? cat.emoji : '🎨',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Name & Type Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat.name.trData(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            cat.type.trData(context).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Edit Category',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _showCategoryDialog(existing: cat),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        tooltip: 'Delete Category',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          final messenger = ScaffoldMessenger.of(context);
                          _confirmDelete(
                            title: 'Delete Category',
                            message:
                                'Are you sure you want to delete category "${cat.name}"? This action cannot be undone.',
                            onConfirm: () async {
                              final success = await sl<ApiService>().deleteCategory(
                                id: cat.id,
                                name: cat.name,
                              );
                              if (success) {
                                setState(() {
                                  _categories.removeWhere(
                                    (c) =>
                                        c.name == cat.name ||
                                        (cat.id > 0 && c.id == cat.id),
                                  );
                                });
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${cat.name}" category'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (cat.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  cat.description.trData(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.purple.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${cat.artistCount} artists'.trData(context),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 13,
                        color: Colors.indigo.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${cat.eventCount} events'.trData(context),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
      ],
    );
  }

  Widget _buildExperienceLevelsMasterList() {
    if (_experienceLevels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No experience levels configured.'.trData(context),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _experienceLevels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final level = _experienceLevels[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Order Badge
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A2777),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${level.displayOrder > 0 ? level.displayOrder : index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name.trData(context),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (level.yearsRange.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${'Years'.trData(context)}: ${level.yearsRange.trData(context)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    tooltip: 'Edit Experience Level',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _showExperienceLevelDialog(existing: level),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Delete Experience Level',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      _confirmDelete(
                        title: 'Delete Experience Level'.trData(context),
                        message: 'Are you sure you want to delete "${level.name}"?',
                        onConfirm: () async {
                          final success = await sl<ApiService>()
                              .deleteExperienceLevel(id: level.id);
                          if (success) {
                            setState(() {
                              _experienceLevels.removeWhere(
                                (l) => l.id == level.id,
                              );
                            });
                            messenger.showSnackBar(
                              SnackBar(content: Text('Deleted "${level.name}"')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryDialog({CategoryInfo? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '🎨');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String selectedType = existing?.type ?? 'general';

    final presetEmojis = [
      '🎨', '📷', '🗿', '✏️', '💻', '🤖', '🏛️', '🎭',
      '💃', '🎵', '🎬', '📹', '📚', '📜', '🖋️', '📐',
      '👗', '🛋️', '📦', '🧶', '🧵', '🏺', '🖨️', '🖌️',
      '🏙️', '🧱', '🩰', '💡', '🧠', '🔀', '📑', '🎮',
      '🥽', '🎞️', '🗯️', '✍️', '💍', '🪟', '🪵', '⚙️',
      '🎎', '🎼', '🎤', '🧪', '🏞️', '🌿', '👑',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Category' : 'New Category',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Category Name',
                        controller: nameCtrl,
                        isFocused: true,
                        hint: 'e.g. Contemporary Painting',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Emoji Icon',
                        controller: emojiCtrl,
                        hint: 'e.g. 🎨',
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            presetEmojis.map((e) {
                              final isSelected = emojiCtrl.text == e;
                              return InkWell(
                                onTap: () {
                                  setModalState(() => emojiCtrl.text = e);
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(0xFFF3E8FF)
                                            : const Color(0xFFF1F5F9),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? const Color(0xFF6A2777)
                                              : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Scope
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Applicable Scope',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children:
                                ['general', 'artist', 'event'].map((t) {
                                  final isSel = selectedType == t;
                                  return ChoiceChip(
                                    label: Text(
                                      t == 'general'
                                          ? 'All (General)'
                                          : t == 'artist'
                                          ? 'Artists Only'
                                          : 'Events Only',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            isSel
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color:
                                            isSel
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                      ),
                                    ),
                                    selected: isSel,
                                    selectedColor: const Color(0xFF6A2777),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    onSelected: (val) {
                                      if (val) {
                                        setModalState(() => selectedType = t);
                                      }
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Description',
                        controller: descCtrl,
                        hint: 'Brief description of this art category...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A2777),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              Navigator.pop(ctx);
                              if (isEdit) {
                                await sl<ApiService>().updateCategory(
                                  id: existing.id,
                                  name: name,
                                  description: descCtrl.text.trim(),
                                  emoji:
                                      emojiCtrl.text.trim().isNotEmpty
                                          ? emojiCtrl.text.trim()
                                          : '🎨',
                                  type: selectedType,
                                );
                              } else {
                                await sl<ApiService>().createCategory(
                                  name: name,
                                  description: descCtrl.text.trim(),
                                  emoji:
                                      emojiCtrl.text.trim().isNotEmpty
                                          ? emojiCtrl.text.trim()
                                          : '🎨',
                                  type: selectedType,
                                );
                              }
                              _loadAllData();
                            },
                            child: Text(
                              isEdit ? 'Save Changes' : 'Create Category',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showExperienceLevelDialog({ExperienceLevelModel? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final yearsCtrl = TextEditingController(text: existing?.yearsRange ?? '');
    final orderCtrl = TextEditingController(
      text:
          existing != null
              ? '${existing.displayOrder}'
              : '${_experienceLevels.length + 1}',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Experience Level'
                                : 'New Experience Level',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Level Name',
                        controller: nameCtrl,
                        isFocused: true,
                        hint: 'e.g. Intermediate (3-5 years)',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Years Range',
                        controller: yearsCtrl,
                        hint: 'e.g. 3-5 years',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Display Order',
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 1',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A2777),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              final order =
                                  int.tryParse(orderCtrl.text.trim()) ?? 0;
                              Navigator.pop(ctx);
                              if (isEdit) {
                                await sl<ApiService>().updateExperienceLevel(
                                  id: existing.id,
                                  name: name,
                                  yearsRange: yearsCtrl.text.trim(),
                                  displayOrder: order,
                                );
                              } else {
                                await sl<ApiService>().createExperienceLevel(
                                  name: name,
                                  yearsRange: yearsCtrl.text.trim(),
                                  displayOrder: order,
                                );
                              }
                              _loadAllData();
                            },
                            child: Text(
                              isEdit ? 'Save Changes' : 'Create Level',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildLocationsMasterList() {
    if (_locations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No locations configured.'.trData(context),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF6A2777),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.name.trData(context),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${loc.city.trData(context)}, ${loc.country.trData(context)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${'Order'.trData(context)} #${loc.displayOrder > 0 ? loc.displayOrder : index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    tooltip: 'Edit Location',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _showLocationDialog(existing: loc),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Delete Location',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      _confirmDelete(
                        title: 'Delete Location'.trData(context),
                        message:
                            'Are you sure you want to delete location "${loc.name}"?',
                        onConfirm: () async {
                          final success = await sl<ApiService>().deleteLocation(
                            id: loc.id,
                          );
                          if (success) {
                            setState(() {
                              _locations.removeWhere((l) => l.id == loc.id);
                            });
                            messenger.showSnackBar(
                              SnackBar(content: Text('Deleted "${loc.name}"')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationDialog({LocationModel? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Dubai');
    final countryCtrl = TextEditingController(text: existing?.country ?? 'UAE');
    final orderCtrl = TextEditingController(
      text:
          existing != null
              ? '${existing.displayOrder}'
              : '${_locations.length + 1}',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Location' : 'New Location',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Location Name',
                        controller: nameCtrl,
                        isFocused: true,
                        hint: 'e.g. Dubai Design District (d3), Dubai',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'City',
                        controller: cityCtrl,
                        hint: 'e.g. Dubai',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Country',
                        controller: countryCtrl,
                        hint: 'e.g. UAE',
                      ),
                      const SizedBox(height: 12),

                      _buildFormField(
                        label: 'Display Order',
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 1',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A2777),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              final order =
                                  int.tryParse(orderCtrl.text.trim()) ?? 0;
                              Navigator.pop(ctx);
                              if (isEdit) {
                                await sl<ApiService>().updateLocation(
                                  id: existing.id,
                                  name: name,
                                  city:
                                      cityCtrl.text.trim().isNotEmpty
                                          ? cityCtrl.text.trim()
                                          : 'Dubai',
                                  country:
                                      countryCtrl.text.trim().isNotEmpty
                                          ? countryCtrl.text.trim()
                                          : 'UAE',
                                  displayOrder: order,
                                );
                              } else {
                                await sl<ApiService>().createLocation(
                                  name: name,
                                  city:
                                      cityCtrl.text.trim().isNotEmpty
                                          ? cityCtrl.text.trim()
                                          : 'Dubai',
                                  country:
                                      countryCtrl.text.trim().isNotEmpty
                                          ? countryCtrl.text.trim()
                                          : 'UAE',
                                  displayOrder: order,
                                );
                              }
                              _loadAllData();
                            },
                            child: Text(
                              isEdit ? 'Save Changes' : 'Create Location',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // ignore: unused_element
  Widget _buildPublishingPricingMasterList() {
    final pricingList =
        _publishingPricing.isNotEmpty
            ? _publishingPricing
            : const [
              PublishingPricingModel(
                id: 1,
                itemType: 'event',
                itemName: 'Event Publishing',
                weeklyPrice: 'AED 150',
                monthlyPrice: 'AED 500',
                sixMonthPrice: 'AED 2,500',
                yearlyPrice: 'AED 4,500',
                currency: 'AED',
                description:
                    'Standard rate for publishing art events, exhibitions, and symposiums on Artist Dubai.',
              ),
              PublishingPricingModel(
                id: 2,
                itemType: 'gallery',
                itemName: 'Gallery Listing & Showcase',
                weeklyPrice: 'AED 200',
                monthlyPrice: 'AED 750',
                sixMonthPrice: 'AED 3,800',
                yearlyPrice: 'AED 6,500',
                currency: 'AED',
                description:
                    'Premier directory listing, verified status badge, and spotlight showcase for Dubai art galleries.',
              ),
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pricingList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final pricing = pricingList[index];
            final isEvent = pricing.itemType == 'event';

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isEvent
                          ? const Color(0xFFE9D5FF)
                          : const Color(0xFFBAE6FD),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isEvent
                                  ? const Color(0xFFF3E8FF)
                                  : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEvent
                              ? Icons.event_available_rounded
                              : Icons.museum_outlined,
                          color:
                              isEvent
                                  ? const Color(0xFF6A2777)
                                  : const Color(0xFF0284C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    pricing.itemName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 11,
                                        color: Color(0xFF059669),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active in App',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pricing.description ??
                                  (isEvent
                                      ? 'Rates displayed to users & organizers when creating events in the app.'
                                      : 'Rates applied when galleries register for directory listing and showcases.'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Rate Cards Grid (Weekly, Monthly, Yearly)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 500;
                      final cards = [
                        _buildRateBadge(
                          title: '6 Months Rate',
                          duration: '180 Days Exposure',
                          amount: pricing.sixMonthPrice,
                          accentColor: const Color(0xFFE11D48),
                        ),
                        _buildRateBadge(
                          title: 'Yearly Rate',
                          duration: '365 Days Featured',
                          amount: pricing.yearlyPrice,
                          accentColor: const Color(0xFF059669),
                        ),
                      ];

                      if (isCompact) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 10),
                            cards[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currency: ${pricing.currency}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Edit ${isEvent ? 'Event' : 'Gallery'} Rates',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => _showEditPricingDialog(pricing),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static const List<Map<String, dynamic>> _planTypeTabs = [
    {'type': 'all',        'label': 'All Plans',   'colorHex': 0xFF5E227A, 'icon': Icons.layers_outlined},
    {'type': 'event',      'label': 'Events',      'colorHex': 0xFF6A2777, 'icon': Icons.event_available_rounded},
    {'type': 'gallery',    'label': 'Galleries',   'colorHex': 0xFF0284C7, 'icon': Icons.museum_outlined},
    {'type': 'artist',     'label': 'Artists',     'colorHex': 0xFF7C3AED, 'icon': Icons.palette_outlined},
    {'type': 'chat',       'label': 'Chat',        'colorHex': 0xFF059669, 'icon': Icons.forum_rounded},
    {'type': 'art_centre', 'label': 'Art Centres', 'colorHex': 0xFFD97706, 'icon': Icons.account_balance_outlined},
  ];

  bool _planMatchesTypeTab(ListingPlanItem p, String tabType) {
    if (tabType == 'all') return true;
    final t = p.itemType.toLowerCase();
    if (tabType == 'art_centre') return t == 'art_centre' || t == 'center';
    return t == tabType;
  }

  Widget _buildListingPlansMasterList() {
    final currentTabType = _planTypeTabs[_listingPlanTypeTab]['type'] as String;
    final currentColor = Color(_planTypeTabs[_listingPlanTypeTab]['colorHex'] as int);
    final currentLabel = _planTypeTabs[_listingPlanTypeTab]['label'] as String;

    final filteredPlans = _listingPlans
        .where((p) => _planMatchesTypeTab(p, currentTabType))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Duration buckets
    final shortPlans     = filteredPlans.where((p) => p.durationDays <= 45).toList();
    final threeMonthPlans = filteredPlans.where((p) => p.durationDays > 45 && p.durationDays < 150).toList();
    final sixMonthPlans   = filteredPlans.where((p) => p.durationDays >= 150 && p.durationDays < 300).toList();
    final twelveMonthPlans = filteredPlans.where((p) => p.durationDays >= 300 && p.durationDays < 1000).toList();
    final permanentPlans  = filteredPlans.where((p) => p.durationDays >= 1000).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Plan Type Tab Bar ──────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_planTypeTabs.length, (i) {
              final tab = _planTypeTabs[i];
              final tabType = tab['type'] as String;
              final tabLabel = tab['label'] as String;
              final tabColor = Color(tab['colorHex'] as int);
              final tabIcon = tab['icon'] as IconData;
              final isSelected = _listingPlanTypeTab == i;
              final count = _listingPlans.where((p) => _planMatchesTypeTab(p, tabType)).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _listingPlanTypeTab = i),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? tabColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? tabColor : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: tabColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tabIcon, size: 14,
                            color: isSelected ? Colors.white : tabColor),
                        const SizedBox(width: 6),
                        Text(tabLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            )),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // ── Type Summary + New Plan Button ────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: currentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$currentLabel Plans',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(
                      '${filteredPlans.length} plan${filteredPlans.length == 1 ? '' : 's'} configured · Create 3-month, 6-month or 12-month plans',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: Text('New Plan',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                onPressed: () => _showEditListingPlanDialog(null, currentTabType),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Duration-Grouped Plan Cards ───────────────────────
        if (filteredPlans.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium_outlined, size: 44, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No $currentLabel plans yet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text('Tap "New Plan" above to create a 3-month, 6-month or 12-month plan for $currentLabel.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
              ],
            ),
          )
        else ...[
          if (shortPlans.isNotEmpty) ...[
            _buildPlanDurationSection('Monthly / Short-Term Plans', Icons.calendar_today_rounded, currentColor, shortPlans),
            const SizedBox(height: 10),
          ],
          if (threeMonthPlans.isNotEmpty) ...[
            _buildPlanDurationSection('3-Month Plans (90 Days)', Icons.date_range_rounded, currentColor, threeMonthPlans),
            const SizedBox(height: 10),
          ],
          if (sixMonthPlans.isNotEmpty) ...[
            _buildPlanDurationSection('6-Month Plans (180 Days)', Icons.event_note_rounded, currentColor, sixMonthPlans),
            const SizedBox(height: 10),
          ],
          if (twelveMonthPlans.isNotEmpty) ...[
            _buildPlanDurationSection('12-Month Plans (1 Year)', Icons.calendar_month_rounded, currentColor, twelveMonthPlans),
            const SizedBox(height: 10),
          ],
          if (permanentPlans.isNotEmpty) ...[
            _buildPlanDurationSection('Permanent / Lifetime Plans', Icons.all_inclusive_rounded, currentColor, permanentPlans),
          ],
        ],
      ],
    );
  }

  Widget _buildPlanDurationSection(
      String title, IconData icon, Color color, List<ListingPlanItem> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${plans.length} plan${plans.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final plan in plans) ...[
          _buildAdminListingPlanCard(plan, color),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAdminListingPlanCard(ListingPlanItem plan, Color accentColor) {
    final isEvent = plan.itemType.toLowerCase() == 'event';
    final isGallery = plan.itemType.toLowerCase() == 'gallery';
    final isChat = plan.itemType.toLowerCase() == 'chat';
    final isArtist = plan.itemType.toLowerCase() == 'artist';
    final isArtCentre =
        plan.itemType.toLowerCase() == 'art_centre' ||
        plan.itemType.toLowerCase() == 'center';

    final Color cardBorderColor =
        isEvent ? const Color(0xFFE9D5FF)
        : (isGallery ? const Color(0xFFBAE6FD)
        : (isChat ? const Color(0xFFA7F3D0)
        : (isArtist ? const Color(0xFFDDD6FE)
        : const Color(0xFFFDE68A))));
    final Color iconBgColor =
        isEvent ? const Color(0xFFF3E8FF)
        : (isGallery ? const Color(0xFFE0F2FE)
        : (isChat ? const Color(0xFFECFDF5)
        : (isArtist ? const Color(0xFFEDE9FE)
        : const Color(0xFFFEF3C7))));
    final Color iconColor =
        isEvent ? const Color(0xFF6A2777)
        : (isGallery ? const Color(0xFF0284C7)
        : (isChat ? const Color(0xFF059669)
        : (isArtist ? const Color(0xFF7C3AED)
        : const Color(0xFFD97706))));
    final IconData planIcon =
        isEvent ? Icons.event_available_rounded
        : (isGallery ? Icons.museum_outlined
        : (isChat ? Icons.chat_bubble_outline_rounded
        : (isArtist ? Icons.palette_outlined
        : Icons.account_balance_outlined)));
    final String typeLabel =
        isEvent ? 'Event Plan'
        : (isGallery ? 'Gallery Plan'
        : (isChat ? 'Chat Plan'
        : (isArtist ? 'Artist Plan'
        : (isArtCentre ? 'Art Centre' : plan.itemType.toUpperCase()))));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(planIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(plan.title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  height: 1.25)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Text(typeLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: iconColor,
                                  letterSpacing: 0.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(plan.category,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A2777))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: plan.isActive
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plan.isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.visibility_off_outlined,
                                size: 11,
                                color: plan.isActive
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                plan.isActive ? 'Active in App' : 'Hidden',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: plan.isActive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.badge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1EBF7),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(plan.badge,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5E227A))),
                          ),
                        if (plan.duration.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 11, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 3),
                                Text(plan.duration,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D4ED8))),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (plan.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(plan.description,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Price + Features
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Listing Price',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                          Text(plan.price,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Included Features:',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    for (final feat in (plan.features.isNotEmpty ? plan.features : plan.effectiveFeatures))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 14, color: Color(0xFF6A2777)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(feat,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF334155),
                                      height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Listing Price',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(plan.price,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Included Features:',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        for (final feat in (plan.features.isNotEmpty ? plan.features : plan.effectiveFeatures))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_rounded,
                                      size: 14, color: Color(0xFF6A2777)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(feat,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF334155),
                                          height: 1.3)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Action Bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Type: ${plan.itemType}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: plan.isActive
                          ? Colors.redAccent
                          : const Color(0xFF059669),
                      side: BorderSide(
                        color: plan.isActive
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : const Color(0xFFA7F3D0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                        plan.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 14),
                    label: Text(
                        plan.isActive ? 'Hide' : 'Activate',
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      final updated = plan.copyWith(isActive: !plan.isActive);
                      await sl<ApiService>().updateListingPlan(
                        id: updated.id,
                        itemType: updated.itemType,
                        title: updated.title,
                        category: updated.category,
                        badge: updated.badge,
                        price: updated.price,
                        description: updated.description,
                        features: updated.features.isNotEmpty ? updated.features : updated.effectiveFeatures,
                        buttonText: updated.buttonText,
                        isActive: updated.isActive,
                        sortOrder: updated.sortOrder,
                        duration: updated.duration,
                        durationDays: updated.durationDays,
                      );
                      final fresh = await sl<ApiService>().getListingPlans(forceRefresh: true);
                      if (mounted) setState(() => _listingPlans = fresh);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                    label: const Text('Edit Plan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
                    onPressed: () => _showEditListingPlanDialog(plan),
                  ),
                  if (plan.id != null)
                    IconButton(
                      tooltip: 'Delete Plan',
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 17, color: Colors.redAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        padding: const EdgeInsets.all(7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                        ),
                      ),
                      onPressed: () => _confirmDeleteListingPlan(plan),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _confirmDeleteListingPlan(ListingPlanItem plan) {
    if (plan.id == null) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete Listing Plan',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to permanently delete "${plan.title}"? This listing plan will be removed from both the mobile app and admin console.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final success = await sl<ApiService>().deleteListingPlan(
                    plan.id!,
                  );
                  if (success) {
                    final updated = await sl<ApiService>().getListingPlans(
                      forceRefresh: true,
                    );
                    if (mounted) {
                      setState(() => _listingPlans = updated);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '"${plan.title}" deleted successfully.',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete listing plan.'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete Plan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildRateBadge({
    required String title,
    required String duration,
    required String amount,
    required Color accentColor,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              if (badgeText != null && badgeText.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            duration,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  void _showEditPricingDialog(PublishingPricingModel pricing) {
    final sixMonthCtrl = TextEditingController(text: pricing.sixMonthPrice);
    final yearlyCtrl = TextEditingController(text: pricing.yearlyPrice);
    final sixMonthBadgeCtrl = TextEditingController(
      text: pricing.sixMonthBadge,
    );
    final yearlyBadgeCtrl = TextEditingController(text: pricing.yearlyBadge);
    final descCtrl = TextEditingController(text: pricing.description ?? '');

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: Color(0xFF6A2777),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit ${pricing.itemName}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Configure live amounts charged for ${pricing.itemType == 'event' ? 'event publishing' : 'gallery registration'} in the app.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 6 Months Rate Field
                        const Text(
                          '6 Months Rate *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: sixMonthCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. AED 2,500',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: Color(0xFF6B1C9B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B1C9B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 6 Months Badge / Subtitle
                        const Text(
                          '6 Months Badge / Subtitle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: sixMonthBadgeCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 180 days active',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B1C9B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Yearly Rate Field
                        const Text(
                          'Yearly Rate *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: yearlyCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. AED 4,500',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.stars_rounded,
                              size: 18,
                              color: Color(0xFF6B1C9B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B1C9B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Yearly Badge / Subtitle
                        const Text(
                          'Yearly Badge / Subtitle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: yearlyBadgeCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 365 days active',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B1C9B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description Field
                        const Text(
                          'Plan Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Brief summary of what this plan covers',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B1C9B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A2777),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final sixMonth = sixMonthCtrl.text.trim();
                                final yearly = yearlyCtrl.text.trim();

                                if (sixMonth.isEmpty || yearly.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter 6-month and yearly amounts',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);

                                final success = await sl<ApiService>()
                                    .updatePublishingPricing(
                                      itemType: pricing.itemType,
                                      weeklyPrice: pricing.weeklyPrice,
                                      monthlyPrice: pricing.monthlyPrice,
                                      sixMonthPrice: sixMonth,
                                      yearlyPrice: yearly,
                                      sixMonthBadge:
                                          sixMonthBadgeCtrl.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? sixMonthBadgeCtrl.text.trim()
                                              : pricing.sixMonthBadge,
                                      yearlyBadge:
                                          yearlyBadgeCtrl.text.trim().isNotEmpty
                                              ? yearlyBadgeCtrl.text.trim()
                                              : pricing.yearlyBadge,
                                      description:
                                          descCtrl.text.trim().isNotEmpty
                                              ? descCtrl.text.trim()
                                              : null,
                                    );

                                if (success) {
                                  final updatedList = await sl<ApiService>()
                                      .getPublishingPricing(forceRefresh: true);
                                  if (mounted) {
                                    setState(
                                      () => _publishingPricing = updatedList,
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${pricing.itemName} rates updated successfully!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF6A2777,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to update rates. Please check connection.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Save Rates',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  List<String> _getConnectedCategories(String itemType) {
    switch (itemType) {
      case 'event':
        return const [
          'Exhibitions & Openings',
          'Art Exhibition',
          'Gallery Opening',
          'Art Fair',
          'Art Workshop',
          'Artist Talk',
          'Cultural Festival',
          'Sculpture Installation',
          'Photography Exhibition',
          'Art Competition',
          'Community Art Project',
          'Workshops & Classes',
          'Featured Event',
          'Standard Event Listing',
        ];
      case 'artist':
        return const [
          'Featured Profile',
          'Verified Artist Portfolio',
          'Contemporary Artist',
          'Fine Art & Painting',
          'Digital & 3D Artist',
          'Sculptor & Ceramics',
          'Photographer Portfolio',
          'Calligraphy & Traditional',
          'Emerging Artist',
          'Master Artist',
        ];
      case 'gallery':
        return const [
          'Galleries & Spaces',
          'Commercial Art Gallery',
          'Contemporary Art Space',
          'Photography Gallery',
          'Sculpture Park & Studio',
          'Virtual Gallery Showroom',
          'Pop-up Art Space',
          'Exhibition Hall',
        ];
      case 'chat':
        return const [
          'Messaging & Inquiries',
          'Direct Collector Messaging',
          'Buyer Inquiries & Orders',
          'Commission Requests',
          'VIP Art Advisory Chat',
        ];
      case 'art_centre':
        return const [
          'Institutions & Venues',
          'Cultural Centre',
          'Museum & Foundation',
          'Community Art Hub',
          'Art Academy & School',
        ];
      case 'custom':
      default:
        return const [
          'General Listing',
          'Special Edition',
          'Art Supplies & Services',
          'Corporate Art Partnership',
          'Annual All-Access Pass',
        ];
    }
  }

  void _showCategoryPickerSheet({
    required BuildContext context,
    required String itemType,
    required List<String> categories,
    required String currentCategory,
    required ValueChanged<String> onSelected,
  }) {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered =
                categories.where((c) {
                  if (query.isEmpty) return true;
                  return c.toLowerCase().contains(query.toLowerCase());
                }).toList();

            final bool hasExactMatch = categories.any(
              (c) => c.trim().toLowerCase() == query.trim().toLowerCase(),
            );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Category ($itemType)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(sheetCtx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search or type category...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF6A2777),
                        ),
                        suffixIcon:
                            query.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setSheetState(() => query = '');
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF6A2777),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setSheetState(() => query = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (query.isNotEmpty && !hasExactMatch)
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Color(0xFF6A2777),
                              ),
                            ),
                            title: Text(
                              'Use "$query" as custom category',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A2777),
                              ),
                            ),
                            onTap: () {
                              onSelected(query.trim());
                              Navigator.pop(sheetCtx);
                            },
                          ),
                        ...filtered.map((cat) {
                          final isSelected =
                              currentCategory.trim().toLowerCase() ==
                              cat.trim().toLowerCase();
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.category_outlined,
                              size: 18,
                              color:
                                  isSelected
                                      ? const Color(0xFF6A2777)
                                      : const Color(0xFF94A3B8),
                            ),
                            title: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? const Color(0xFF6A2777)
                                        : const Color(0xFF1E293B),
                              ),
                            ),
                            tileColor:
                                isSelected ? const Color(0xFFFAF5FF) : null,
                            onTap: () {
                              onSelected(cat);
                              Navigator.pop(sheetCtx);
                            },
                          );
                        }),
                        if (filtered.isEmpty &&
                            (query.isEmpty || hasExactMatch))
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No categories found',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditListingPlanDialog([ListingPlanItem? plan, String? defaultItemType]) {
    final isEditing = plan != null;
    String selectedItemType = plan?.itemType ??
        (defaultItemType == null || defaultItemType == 'all' ? 'event' : defaultItemType);
    final titleCtrl = TextEditingController(text: plan?.title ?? '');
    final initialCat =
        plan?.category ??
        (selectedItemType == 'artist'
            ? 'Featured Profile'
            : (selectedItemType == 'gallery'
                ? 'Galleries & Spaces'
                : (selectedItemType == 'chat'
                    ? 'Messaging & Inquiries'
                    : (selectedItemType == 'art_centre'
                        ? 'Institutions & Venues'
                        : 'Exhibitions & Openings'))));
    final categoryCtrl = TextEditingController(text: initialCat);
    final badgeCtrl = TextEditingController(
      text: plan?.badge ?? (selectedItemType == 'artist' ? 'Free' : 'One-time'),
    );
    final initialPrice = ListingPlanItem.normalizePrice(
      plan?.price ?? (selectedItemType == 'artist' ? 'Free' : 'AED 199'),
    );
    final priceCtrl = TextEditingController(text: initialPrice);
    if (selectedItemType == 'artist' && priceCtrl.text.toLowerCase() != 'free') {
      priceCtrl.text = 'Free';
      if (badgeCtrl.text == 'One-time') badgeCtrl.text = 'Free';
    }
    final descCtrl = TextEditingController(text: plan?.description ?? '');
    final durationCtrl = TextEditingController(
      text: plan?.duration ??
          (selectedItemType == 'gallery' || selectedItemType == 'art_centre'
              ? '1 Year (365 Days)'
              : (selectedItemType == 'artist'
                  ? 'Permanent Free Profile'
                  : '30 Days')),
    );
    final initialFeatures =
        plan != null
            ? (plan.features.isNotEmpty
                ? plan.features.join('\n')
                : plan.effectiveFeatures.join('\n'))
            : ListingPlanItem.defaultFeaturesForItemType(selectedItemType).join('\n');
    final featuresCtrl = TextEditingController(text: initialFeatures);
    final buttonTextCtrl = TextEditingController(
      text: plan?.buttonText ??
          (selectedItemType == 'artist'
              ? 'Create Free Profile'
              : 'Pay from My Listings'),
    );
    bool isActive = plan?.isActive ?? true;
    final customFeatureInputCtrl = TextEditingController();
    bool showRawFeaturesEditor = false;

    // Quick Templates for 1-Click Professional Pre-Filling
    final quickTemplates = [
      {
        'title': 'Standard Event Listing',
        'category': 'Exhibitions & Openings',
        'badge': 'Popular',
        'price': 'AED 500',
        'duration': '30 Days',
        'itemType': 'event',
        'desc': '30-day verified event showcase across mobile app and website',
        'features': [
          '30-day verified event showcase across mobile app and website',
          'Event calendar & push notification highlight',
          'Direct ticket booking & RSVP link integration',
          'Featured placement in Art Events feed',
          'Analytics & attendee click metrics',
        ].join('\n'),
        'buttonText': 'Pay from My Listings',
      },
      {
        'title': 'Artist Portfolio',
        'category': 'Featured Profile',
        'badge': 'Free',
        'price': 'Free',
        'duration': 'Permanent Free Profile',
        'itemType': 'artist',
        'desc':
            'Free verified artist profile, unlimited artwork uploads & direct collector messaging',
        'features': [
          'Verified Artist Badge on profile',
          'Unlimited portfolio artwork uploads',
          'Featured spot on Artist Discovery grid',
          'Direct WhatsApp & inquiry link to artist',
          'Direct collector messaging & inquiry channel',
        ].join('\n'),
        'buttonText': 'Create Free Profile',
      },
      {
        'title': 'Elite Gallery Showcase',
        'category': 'Galleries & Spaces',
        'badge': 'Premium',
        'price': 'AED 750',
        'duration': '1 Year (365 Days)',
        'itemType': 'gallery',
        'desc':
            'Comprehensive gallery venue listing with exhibitions calendar & collector reach',
        'features': [
          'Full digital gallery showroom & map listing',
          'Unlimited exhibition postings for 12 months',
          'Featured spot on Galleries directory',
          'Direct visitor booking & VIP inquiries',
          'Social media & push broadcast spotlight',
        ].join('\n'),
        'buttonText': 'List Your Gallery',
      },
      {
        'title': 'Starter Plan',
        'category': 'Messaging & Inquiries',
        'badge': 'Default',
        'price': 'Free',
        'duration': 'Monthly Reset',
        'itemType': 'chat',
        'desc': 'Free monthly allowance to connect with artists across Dubai',
        'features': [
          '10 direct messages per month',
          'Direct artist collaboration inquiries',
          'Flyer & artwork attachment support',
          'Allowance auto-resets on the 1st',
        ].join('\n'),
        'buttonText': 'Select Plan',
      },
      {
        'title': 'Pro Artist',
        'category': 'Messaging & Inquiries',
        'badge': 'Most Popular',
        'price': 'AED 49',
        'duration': '30 Days',
        'itemType': 'chat',
        'desc': '50 direct messages per month for active networking',
        'features': [
          '50 direct messages per month',
          'Direct artist outreach & networking',
          'Priority delivery in artist inboxes',
          'High-resolution flyer attachments',
          'Monthly reset on the 1st',
        ].join('\n'),
        'buttonText': 'Select Plan',
      },
      {
        'title': 'Unlimited VIP',
        'category': 'Messaging & Inquiries',
        'badge': 'For Agencies & Curators',
        'price': 'AED 99',
        'duration': 'Monthly Subscription',
        'itemType': 'chat',
        'desc':
            'Unlimited direct artist messages with verified VIP sender badge',
        'features': [
          'Unlimited direct artist messages',
          'Verified VIP sender badge',
          'Ideal for galleries, curators & agencies',
          'Priority instant customer support',
        ].join('\n'),
        'buttonText': 'Select Plan',
      },
      {
        'title': 'Art Center Partner',
        'category': 'Institutions & Venues',
        'badge': 'VIP Partner',
        'price': 'AED 990',
        'duration': '1 Year (365 Days)',
        'itemType': 'art_centre',
        'desc':
            'Official institution hub page, workshop hosting & priority event syndication',
        'features': [
          'Official verified institution partner badge',
          'Unlimited event & workshop listings',
          'Direct ticket booking with instant notifications',
          'Top banner rotation on mobile home screen',
          'Dedicated account manager & support',
        ].join('\n'),
        'buttonText': 'Join Partner Network',
      },
    ];

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              final connectedCategories = _getConnectedCategories(selectedItemType);
              final categoryOptions = <String>{
                ...connectedCategories,
                ..._categories.map((c) => c.name.trim()).where((n) => n.isNotEmpty),
              }.toList();

              final pricePresets = const [
                'Free',
                'AED 49',
                'AED 99',
                'AED 149',
                'AED 199',
                'AED 299',
                'AED 350',
                'AED 500',
                'AED 750',
                'AED 990',
                'AED 1,500',
                'AED 3,000',
              ];

              final badgePresets = const [
                'Free',
                'Popular',
                'Recommended',
                'Best Choice',
                'Featured',
                'VIP Partner',
                'One-time',
                'Limited Offer',
                'Hot',
                'New',
                'None (No Badge)',
              ];

              final buttonPresets = const [
                'Create Free Profile',
                'Pay from My Listings',
                'Subscribe to Pro',
                'List Your Gallery',
                'Subscribe to Chat',
                'Join Partner Network',
                'Choose Plan',
              ];

              const standardFeaturesCatalog = [
                'Verified Artist Badge on profile',
                'Unlimited portfolio artwork uploads',
                'Featured spot on Artist Discovery grid',
                'Direct WhatsApp & inquiry link to artist',
                'Direct collector messaging & inquiry channel',
                '30-day verified event showcase across mobile app and website',
                'Event calendar & push notification highlight',
                'Direct ticket booking & RSVP link integration',
                'Interactive venue map pin & directions',
                'Full digital gallery showroom & map listing',
                'Unlimited exhibition postings for 12 months',
                'High-res flyer & artwork attachments support',
                'Social media & newsletter spotlight',
                'Analytics & attendee / visitor click metrics',
                'Dedicated account manager & support',
              ];

              final activeLines = <String>[];
              final seenFeatures = <String>{};
              for (final raw in featuresCtrl.text.split('\n')) {
                final trimmed = raw.trim();
                if (trimmed.isNotEmpty && seenFeatures.add(trimmed.toLowerCase())) {
                  activeLines.add(trimmed);
                }
              }
              if (featuresCtrl.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).length != activeLines.length) {
                featuresCtrl.text = activeLines.join('\n');
              }
              final customFeatures = activeLines
                  .where((l) => !standardFeaturesCatalog.contains(l))
                  .toList();

              final currentCat = categoryCtrl.text.trim();
              if (currentCat.isEmpty) {
                categoryCtrl.text = connectedCategories.first;
              }

              final currentPrice = ListingPlanItem.normalizePrice(priceCtrl.text);
              final bool isPriceInPresets = pricePresets.contains(currentPrice);
              final String selectedPriceValue = selectedItemType == 'artist'
                  ? 'Free'
                  : (isPriceInPresets
                      ? currentPrice
                      : (currentPrice.isEmpty ? 'AED 199' : '__custom__'));
              if (isPriceInPresets && priceCtrl.text.trim() != currentPrice) {
                priceCtrl.text = currentPrice;
              }
              if (selectedItemType == 'artist' && priceCtrl.text != 'Free') {
                priceCtrl.text = 'Free';
              }

              final currentBadge = badgeCtrl.text.trim();
              final bool isBadgeInPresets = badgePresets.contains(currentBadge) || currentBadge.isEmpty;
              final String selectedBadgeValue = currentBadge.isEmpty
                  ? 'None (No Badge)'
                  : (isBadgeInPresets ? currentBadge : '__custom__');

              final currentBtn = buttonTextCtrl.text.trim();
              final bool isBtnInPresets = buttonPresets.contains(currentBtn);
              final String selectedBtnValue = isBtnInPresets
                  ? currentBtn
                  : (currentBtn.isEmpty
                      ? (selectedItemType == 'artist' ? 'Create Free Profile' : 'Pay from My Listings')
                      : '__custom__');
              if (buttonTextCtrl.text.isEmpty && selectedBtnValue != '__custom__') {
                buttonTextCtrl.text = selectedBtnValue;
              }

              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 580,
                    maxHeight: 750,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6A2777,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFD8B4FE),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.list_alt_rounded,
                                color: Color(0xFF6A2777),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Edit ${plan.title}'
                                        : 'New Listing Plan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEditing
                                        ? 'Update pricing, features and app visibility'
                                        : 'Create & publish listing plan for mobile app',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: Color(0xFF64748B),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Quick Template Pre-Fill Row
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFF6A2777),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Quick Templates (One-Click Pre-fill):',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children:
                                quickTemplates.map((t) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          titleCtrl.text = t['title']!;
                                          categoryCtrl.text = t['category']!;
                                          badgeCtrl.text = t['badge']!;
                                          priceCtrl.text = t['price']!;
                                          selectedItemType = t['itemType']!;
                                          descCtrl.text = t['desc']!;
                                          if (t['duration'] != null) {
                                            durationCtrl.text = t['duration']!;
                                          }
                                          featuresCtrl.text = t['features']!;
                                          buttonTextCtrl.text =
                                              t['buttonText']!;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF5FF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE9D5FF),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              t['itemType'] == 'event'
                                                  ? Icons
                                                      .event_available_rounded
                                                  : (t['itemType'] == 'artist'
                                                      ? Icons.palette_outlined
                                                      : (t['itemType'] ==
                                                              'gallery'
                                                          ? Icons
                                                              .museum_outlined
                                                          : (t['itemType'] ==
                                                                  'chat'
                                                              ? Icons
                                                                  .chat_bubble_outline_rounded
                                                              : Icons
                                                                  .account_balance_outlined))),
                                              size: 13,
                                              color: const Color(0xFF6A2777),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              t['title']!.split(' ').first,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF6A2777),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Item Type Selector Dropdown (Prominently placed at top)
                        _buildFormLabel('Listing Item Type *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(selectedItemType),
                          isExpanded: true,
                          initialValue:
                              [
                                    'event',
                                    'artist',
                                    'gallery',
                                    'chat',
                                    'art_centre',
                                    'custom',
                                  ].contains(selectedItemType)
                                  ? selectedItemType
                                  : 'custom',
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'event',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 17,
                                    color: Color(0xFF6A2777),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Event Listing (event)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'artist',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.palette_outlined,
                                    size: 17,
                                    color: Color(0xFF7E22CE),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          'Artist Portfolio (artist)',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '100% Free',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'gallery',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.museum_outlined,
                                    size: 17,
                                    color: Color(0xFF0284C7),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Gallery Showcase (gallery)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'chat',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 17,
                                    color: Color(0xFF059669),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Chat & Messaging (chat)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'art_centre',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_outlined,
                                    size: 17,
                                    color: Color(0xFFD97706),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Art Center Showcase (art_centre)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 17,
                                    color: Color(0xFF475569),
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Custom Subscription (custom)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedItemType = val;
                              final newConnected = _getConnectedCategories(val);
                              categoryCtrl.text = newConnected.first;
                              if (val == 'artist') {
                                priceCtrl.text = 'Free';
                                badgeCtrl.text = 'Free';
                                buttonTextCtrl.text = 'Create Free Profile';
                              }
                              if (featuresCtrl.text.trim().isEmpty) {
                                featuresCtrl.text =
                                    ListingPlanItem.defaultFeaturesForItemType(
                                      val,
                                    ).join('\n');
                              }
                            });
                          },
                          decoration: _dialogInputDecoration(),
                        ),
                        if (selectedItemType == 'artist') ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Artist Portfolio is 100% Free on Artist Dubai (0 AED).',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Plan Title
                        _buildFormLabel('Plan Title *'),
                        const SizedBox(height: 6),
                        _buildDialogTextField(
                          controller: titleCtrl,
                          hint: 'e.g. Standard Event Listing, Artist Portfolio',
                          icon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Responsive Category & Price Rows
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 440;

                            final categoryWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildFormLabel('Category (Searchable) *'),
                                    InkWell(
                                      onTap: () {
                                        _showCategoryPickerSheet(
                                          context: context,
                                          itemType: selectedItemType,
                                          categories: categoryOptions,
                                          currentCategory: categoryCtrl.text,
                                          onSelected: (chosen) {
                                            setModalState(() {
                                              categoryCtrl.text = chosen;
                                            });
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.manage_search_rounded,
                                              size: 15,
                                              color: Color(0xFF6A2777),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Browse (${categoryOptions.length})',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF6A2777),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: categoryCtrl,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search or enter category...',
                                    hintStyle: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.category_outlined,
                                      size: 18,
                                      color: Color(0xFF6A2777),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (categoryCtrl.text.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 16,
                                            ),
                                            color: const Color(0xFF94A3B8),
                                            tooltip: 'Clear category',
                                            onPressed: () {
                                              setModalState(() {
                                                categoryCtrl.clear();
                                              });
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_drop_down_circle_outlined,
                                            size: 18,
                                          ),
                                          color: const Color(0xFF6A2777),
                                          tooltip:
                                              'Browse categories for $selectedItemType',
                                          onPressed: () {
                                            _showCategoryPickerSheet(
                                              context: context,
                                              itemType: selectedItemType,
                                              categories: categoryOptions,
                                              currentCategory:
                                                  categoryCtrl.text,
                                              onSelected: (chosen) {
                                                setModalState(() {
                                                  categoryCtrl.text = chosen;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6A2777),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children:
                                        connectedCategories.take(6).map((cat) {
                                          final isSelected =
                                              categoryCtrl.text
                                                  .trim()
                                                  .toLowerCase() ==
                                              cat.trim().toLowerCase();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  categoryCtrl.text = cat;
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF6A2777,
                                                          )
                                                          : const Color(
                                                            0xFFF1F5F9,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? const Color(
                                                              0xFF6A2777,
                                                            )
                                                            : const Color(
                                                              0xFFE2E8F0,
                                                            ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  cat,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : const Color(
                                                              0xFF475569,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            );

                            final badgeWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('Badge Tag (Dropdown)'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(selectedBadgeValue),
                                  initialValue: selectedBadgeValue,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  items: [
                                    ...badgePresets.map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: '__custom__',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_note_rounded,
                                            size: 15,
                                            color: Color(0xFF6A2777),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Custom Badge...',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF6A2777),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setModalState(() {
                                      if (val == 'None (No Badge)') {
                                        badgeCtrl.text = '';
                                      } else if (val == '__custom__') {
                                        if (isBadgeInPresets) badgeCtrl.clear();
                                      } else {
                                        badgeCtrl.text = val;
                                      }
                                    });
                                  },
                                  decoration: _dialogInputDecoration(
                                    icon: Icons.bookmark_border_rounded,
                                  ),
                                ),
                                if (selectedBadgeValue == '__custom__') ...[
                                  const SizedBox(height: 6),
                                  _buildDialogTextField(
                                    controller: badgeCtrl,
                                    hint: 'Type custom badge name...',
                                    icon: Icons.bookmark_border_rounded,
                                  ),
                                ],
                              ],
                            );

                            final priceWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('Price (Live Display) *'),
                                const SizedBox(height: 6),
                                if (selectedItemType == 'artist')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF86EFAC),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF16A34A),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Free (0 AED)',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(selectedPriceValue),
                                    initialValue: selectedPriceValue,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                    items: [
                                      ...pricePresets.map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p,
                                            style: TextStyle(
                                              fontWeight:
                                                  p == 'Free'
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                              color:
                                                  p == 'Free'
                                                      ? const Color(0xFF15803D)
                                                      : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const DropdownMenuItem(
                                        value: '__custom__',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_note_rounded,
                                              size: 15,
                                              color: Color(0xFF6A2777),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Custom Price...',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Color(0xFF6A2777),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setModalState(() {
                                        if (val == '__custom__') {
                                          if (isPriceInPresets) priceCtrl.clear();
                                        } else {
                                          priceCtrl.text = val;
                                        }
                                      });
                                    },
                                    decoration: _dialogInputDecoration(
                                      icon: Icons.payments_rounded,
                                    ),
                                  ),
                                  if (selectedPriceValue == '__custom__') ...[
                                    const SizedBox(height: 6),
                                    _buildDialogTextField(
                                      controller: priceCtrl,
                                      hint: 'e.g. AED 1,200',
                                      icon: Icons.payments_rounded,
                                      isBold: true,
                                    ),
                                  ],
                                ],
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  categoryWidget,
                                  const SizedBox(height: 12),
                                  priceWidget,
                                  const SizedBox(height: 12),
                                  badgeWidget,
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: categoryWidget),
                                    const SizedBox(width: 12),
                                    Expanded(child: badgeWidget),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                priceWidget,
                              ],
                            );
                          },
                        ),
                        // Duration Presets (1-Click Selector for 3, 6, 12 Months)
                        Row(
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 15,
                              color: Color(0xFF6A2777),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Quick Duration Presets:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              {
                                'label': '1 Month (30d)',
                                'val': '30 Days',
                                'badge': 'Standard',
                                'titleSuffix': '(1 Month)',
                              },
                              {
                                'label': '3 Months (90d)',
                                'val': '90 Days (3 Months)',
                                'badge': 'Special Offer',
                                'titleSuffix': '(3 Months)',
                              },
                              {
                                'label': '6 Months (180d)',
                                'val': '180 Days (6 Months)',
                                'badge': 'Save 25%',
                                'titleSuffix': '(6 Months)',
                              },
                              {
                                'label': '12 Months (1 Year)',
                                'val': '1 Year (365 Days)',
                                'badge': 'Best Value',
                                'titleSuffix': '(12 Months)',
                              },
                              if (selectedItemType == 'artist')
                                {
                                  'label': 'Permanent Free',
                                  'val': 'Permanent Free Profile',
                                  'badge': 'Free',
                                  'titleSuffix': '',
                                },
                            ].map((preset) {
                              final isSel = durationCtrl.text.trim().toLowerCase() ==
                                      preset['val']!.toLowerCase() ||
                                  (preset['val'] == '90 Days (3 Months)' &&
                                      durationCtrl.text.contains('90')) ||
                                  (preset['val'] == '180 Days (6 Months)' &&
                                      durationCtrl.text.contains('180')) ||
                                  (preset['val'] == '1 Year (365 Days)' &&
                                      (durationCtrl.text.contains('365') ||
                                          durationCtrl.text.contains('1 Year')));
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      durationCtrl.text = preset['val']!;
                                      badgeCtrl.text = preset['badge']!;
                                      if (titleCtrl.text.isEmpty ||
                                          titleCtrl.text.contains('(')) {
                                        final base = selectedItemType == 'event'
                                            ? 'Event Showcase'
                                            : (selectedItemType == 'gallery'
                                                ? 'Gallery Showcase'
                                                : (selectedItemType == 'chat'
                                                    ? 'Pro Artist Chat'
                                                    : (selectedItemType == 'art_centre'
                                                        ? 'Art Centre Partner'
                                                        : 'Artist Portfolio')));
                                        final suffix = preset['titleSuffix']!;
                                        titleCtrl.text = suffix.isNotEmpty
                                            ? '$base $suffix'
                                            : base;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? const Color(0xFF6A2777)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel
                                            ? const Color(0xFF6A2777)
                                            : const Color(0xFFCBD5E1),
                                        width: isSel ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      preset['label']!,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSel
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Duration / Validity Configuration
                        _buildFormLabel('Duration / Validity Period *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(durationCtrl.text),
                          isExpanded: true,
                          initialValue: [
                            '30 Days',
                            '60 Days',
                            '90 Days (3 Months)',
                            '180 Days (6 Months)',
                            '1 Year (365 Days)',
                            'Permanent Free Profile',
                            'Permanent / Lifetime',
                          ].contains(durationCtrl.text.trim())
                              ? durationCtrl.text.trim()
                              : '__custom__',
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '30 Days',
                              child: Text('30 Days (Standard Event / Listing)'),
                            ),
                            DropdownMenuItem(
                              value: '60 Days',
                              child: Text('60 Days (2 Months)'),
                            ),
                            DropdownMenuItem(
                              value: '90 Days (3 Months)',
                              child: Text('90 Days (Quarterly Pass)'),
                            ),
                            DropdownMenuItem(
                              value: '180 Days (6 Months)',
                              child: Text('180 Days (Bi-Annual)'),
                            ),
                            DropdownMenuItem(
                              value: '1 Year (365 Days)',
                              child: Text('1 Year / 365 Days (Gallery / Institution)'),
                            ),
                            DropdownMenuItem(
                              value: 'Permanent Free Profile',
                              child: Text('Permanent Free Profile (Artists)'),
                            ),
                            DropdownMenuItem(
                              value: 'Permanent / Lifetime',
                              child: Text('Permanent / Lifetime Access'),
                            ),
                            DropdownMenuItem(
                              value: '__custom__',
                              child: Text(
                                'Custom Duration...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF6A2777),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              if (val != '__custom__') {
                                durationCtrl.text = val;
                              }
                            });
                          },
                          decoration: _dialogInputDecoration(
                            icon: Icons.timer_outlined,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDialogTextField(
                          controller: durationCtrl,
                          hint: 'e.g. 1 Year (365 Days), 30 Days, Permanent',
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Description Field
                        _buildFormLabel('Description'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _dialogInputDecoration(
                            icon: Icons.description_outlined,
                            hint:
                                'e.g. Free verified artist profile, artwork showcase & direct collector inquiries',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Features Checklist with Interactive Checkboxes & Raw Text toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFormLabel('Features Checklist *'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activeLines.length} Selected',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6A2777),
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  showRawFeaturesEditor = !showRawFeaturesEditor;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    showRawFeaturesEditor
                                        ? Icons.checklist_rounded
                                        : Icons.edit_note_rounded,
                                    size: 15,
                                    color: const Color(0xFF6A2777),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    showRawFeaturesEditor
                                        ? 'Checkboxes View'
                                        : 'Raw Text View',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6A2777),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toggle checkboxes to include features, or add custom bullets below.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (showRawFeaturesEditor) ...[
                          TextField(
                            controller: featuresCtrl,
                            maxLines: 5,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (_) => setModalState(() {}),
                            decoration: _dialogInputDecoration(
                              hint:
                                  'Verified Artist Badge\nUnlimited portfolio uploads\nDirect WhatsApp link',
                            ),
                          ),
                        ] else ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Standard features scrollable checklist with Checkboxes
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: standardFeaturesCatalog.length,
                                      itemBuilder: (context, idx) {
                                        final feat = standardFeaturesCatalog[idx];
                                        final isChecked = activeLines.contains(feat);
                                        return InkWell(
                                          onTap: () {
                                            final lines = List<String>.from(activeLines);
                                            if (isChecked) {
                                              lines.remove(feat);
                                            } else {
                                              lines.add(feat);
                                            }
                                            featuresCtrl.text = lines.join('\n');
                                            setModalState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3.5,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: Checkbox(
                                                    value: isChecked,
                                                    activeColor: const Color(
                                                      0xFF6A2777,
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                    onChanged: (val) {
                                                      final lines =
                                                          List<String>.from(
                                                            activeLines,
                                                          );
                                                      if (val == true) {
                                                        if (!lines.contains(
                                                          feat,
                                                        )) {
                                                          lines.add(feat);
                                                        }
                                                      } else {
                                                        lines.remove(feat);
                                                      }
                                                      featuresCtrl.text = lines
                                                          .join('\n');
                                                      setModalState(() {});
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    feat,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          isChecked
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                      color:
                                                          isChecked
                                                              ? const Color(
                                                                0xFF0F172A,
                                                              )
                                                              : const Color(
                                                                0xFF475569,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (customFeatures.isNotEmpty) ...[
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(10, 6, 10, 2),
                                    child: Text(
                                      'Custom Features Added:',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  ...customFeatures.map(
                                    (cFeat) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 14,
                                            color: Color(0xFF16A34A),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              cFeat,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: Color(0xFFEF4444),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Remove',
                                            onPressed: () {
                                              final lines = List<String>.from(
                                                activeLines,
                                              )..removeWhere(
                                                   (l) =>
                                                       l.toLowerCase() ==
                                                       cFeat.toLowerCase(),
                                                 );
                                              featuresCtrl.text = lines.join(
                                                '\n',
                                              );
                                              setModalState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: customFeatureInputCtrl,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: InputDecoration(
                                            hintText:
                                                '+ Add custom feature bullet point...',
                                            hintStyle: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 7,
                                                ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                          ),
                                          onSubmitted: (val) {
                                            final trimmed = val.trim();
                                            if (trimmed.isNotEmpty) {
                                              final lines = List<String>.from(
                                                activeLines,
                                              );
                                              if (!lines.any((l) => l.toLowerCase() == trimmed.toLowerCase())) {
                                                lines.add(trimmed);
                                              }
                                              featuresCtrl.text = lines.join(
                                                '\n',
                                              );
                                              customFeatureInputCtrl.clear();
                                              setModalState(() {});
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF6A2777,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        onPressed: () {
                                          final trimmed =
                                              customFeatureInputCtrl.text.trim();
                                          if (trimmed.isNotEmpty) {
                                            final lines = List<String>.from(
                                              activeLines,
                                            );
                                            if (!lines.any((l) => l.toLowerCase() == trimmed.toLowerCase())) {
                                              lines.add(trimmed);
                                            }
                                            featuresCtrl.text = lines.join(
                                              '\n',
                                            );
                                            customFeatureInputCtrl.clear();
                                            setModalState(() {});
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Quick-append feature chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildQuickFeatureChip(
                                '+ 30-Day Highlight',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickFeatureChip(
                                '+ Verified Gold Badge',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickFeatureChip(
                                '+ Direct WhatsApp Link',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickFeatureChip(
                                '+ Push Notification Broadcast',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickFeatureChip(
                                '+ Unlimited Messages',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickFeatureChip(
                                '+ Direct Collector Inquiries',
                                featuresCtrl,
                                () => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action Button Text (Dropdown + Custom)
                        _buildFormLabel('Action Button Text (Dropdown)'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(selectedBtnValue),
                          initialValue: selectedBtnValue,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: [
                            ...buttonPresets.map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              ),
                            ),
                            const DropdownMenuItem(
                              value: '__custom__',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 15,
                                    color: Color(0xFF6A2777),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Custom Button Text...',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF6A2777),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              if (val == '__custom__') {
                                if (isBtnInPresets) buttonTextCtrl.clear();
                              } else {
                                buttonTextCtrl.text = val;
                              }
                            });
                          },
                          decoration: _dialogInputDecoration(
                            icon: Icons.touch_app_outlined,
                          ),
                        ),
                        if (selectedBtnValue == '__custom__') ...[
                          const SizedBox(height: 6),
                          _buildDialogTextField(
                            controller: buttonTextCtrl,
                            hint: 'e.g. Join Artist Network',
                            icon: Icons.touch_app_outlined,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildButtonPresetChip(
                              'Create Free Profile',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                            _buildButtonPresetChip(
                              'Pay from My Listings',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                            _buildButtonPresetChip(
                              'Subscribe to Pro',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                            _buildButtonPresetChip(
                              'List Your Gallery',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                            _buildButtonPresetChip(
                              'Subscribe to Chat',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                            _buildButtonPresetChip(
                              'Choose Plan',
                              buttonTextCtrl,
                              () => setModalState(() {}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Active Switch Card Container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isActive
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_outlined,
                                      color:
                                          isActive
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 2,
                                            children: [
                                              const Text(
                                                'Active in App',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isActive
                                                          ? const Color(
                                                            0xFFDCFCE7,
                                                          )
                                                          : const Color(
                                                            0xFFE2E8F0,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isActive
                                                      ? 'VISIBLE'
                                                      : 'HIDDEN',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        isActive
                                                            ? const Color(
                                                              0xFF15803D,
                                                            )
                                                            : const Color(
                                                              0xFF64748B,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Visible to users on listing plans screen',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: isActive,
                                activeThumbColor: const Color(0xFF16A34A),
                                activeTrackColor: const Color(0xFFBBF7D0),
                                onChanged:
                                    (val) =>
                                        setModalState(() => isActive = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Dialog Actions
                        Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A2777),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                isEditing ? 'Save Changes' : 'Create Plan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () async {
                                final title = titleCtrl.text.trim();
                                final category = categoryCtrl.text.trim();
                                final price = ListingPlanItem.normalizePrice(
                                  priceCtrl.text,
                                );
                                final itemType = selectedItemType.trim();

                                if (title.isEmpty ||
                                    category.isEmpty ||
                                    price.isEmpty ||
                                    itemType.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Title, Category, Price, and Item Type are required.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                final lines = <String>[];
                                final seenLines = <String>{};
                                for (final raw in featuresCtrl.text.split('\n')) {
                                  final trimmed = raw.trim();
                                  if (trimmed.isNotEmpty &&
                                      seenLines.add(trimmed.toLowerCase())) {
                                    lines.add(trimmed);
                                  }
                                }

                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);

                                final durStr = durationCtrl.text.trim().isNotEmpty
                                    ? durationCtrl.text.trim()
                                    : (itemType == 'gallery' || itemType == 'art_centre'
                                        ? '1 Year (365 Days)'
                                        : (itemType == 'artist' ? 'Permanent Free Profile' : '30 Days'));
                                int durDays = 30;
                                final dLower = durStr.toLowerCase();
                                if (dLower.contains('year') || dLower.contains('365')) {
                                  durDays = 365;
                                } else if (dLower.contains('180') || dLower.contains('6 month')) {
                                  durDays = 180;
                                } else if (dLower.contains('90') || dLower.contains('3 month') || dLower.contains('quarter')) {
                                  durDays = 90;
                                } else if (dLower.contains('60')) {
                                  durDays = 60;
                                } else if (dLower.contains('permanent') || dLower.contains('lifetime')) {
                                  durDays = 3650;
                                } else {
                                  final m = RegExp(r'(\d+)').firstMatch(durStr);
                                  if (m != null) {
                                    durDays = int.tryParse(m.group(1)!) ?? 30;
                                  }
                                }

                                bool success;
                                if (isEditing) {
                                  success = await sl<ApiService>()
                                      .updateListingPlan(
                                        id: plan.id,
                                        itemType: itemType,
                                        title: title,
                                        category: category,
                                        badge: badgeCtrl.text.trim(),
                                        price: price,
                                        description: descCtrl.text.trim(),
                                        features: lines,
                                        buttonText: buttonTextCtrl.text.trim(),
                                        isActive: isActive,
                                        sortOrder: plan.sortOrder,
                                        duration: durStr,
                                        durationDays: durDays,
                                      );
                                } else {
                                  success = await sl<ApiService>()
                                      .createListingPlan(
                                        itemType: itemType,
                                        title: title,
                                        category: category,
                                        badge: badgeCtrl.text.trim(),
                                        price: price,
                                        description: descCtrl.text.trim(),
                                        features: lines,
                                        buttonText: buttonTextCtrl.text.trim(),
                                        isActive: isActive,
                                        sortOrder: _listingPlans.length + 1,
                                        duration: durStr,
                                        durationDays: durDays,
                                      );
                                }

                                if (success) {
                                  final updatedList = await sl<ApiService>()
                                      .getListingPlans(forceRefresh: true);
                                  if (mounted) {
                                    setState(() => _listingPlans = updatedList);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$title saved and synced live successfully!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF6A2777,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to save listing plan. Please check connection.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  InputDecoration _dialogInputDecoration({IconData? icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon:
          icon != null
              ? Icon(icon, size: 18, color: const Color(0xFF6A2777))
              : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isBold = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6A2777)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildQuickFeatureChip(
    String text,
    TextEditingController controller,
    VoidCallback onUpdate,
  ) {
    final cleanText = text.replaceFirst('+ ', '').trim();
    final currentLines = controller.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final isSelected = currentLines.any(
      (l) => l.toLowerCase() == cleanText.toLowerCase(),
    );

    return InkWell(
      onTap: () {
        final lines = controller.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (isSelected) {
          lines.removeWhere((l) => l.toLowerCase() == cleanText.toLowerCase());
        } else {
          lines.add(cleanText);
        }
        controller.text = lines.join('\n');
        onUpdate();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFFAF5FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_rounded,
              size: 13,
              color:
                  isSelected
                      ? const Color(0xFF6A2777)
                      : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              cleanText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color:
                    isSelected
                        ? const Color(0xFF6A2777)
                        : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonPresetChip(
    String text,
    TextEditingController controller,
    VoidCallback onUpdate,
  ) {
    return InkWell(
      onTap: () {
        controller.text = text;
        onUpdate();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A2777),
          ),
        ),
      ),
    );
  }

  // --- 8. Menu Permissions & Coming Soon Controls Tab ---
  Widget _buildPermissionsTab() {
    final permissionsList = MenuPermissionModel.defaultPermissions();
    final totalCount = permissionsList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Action Bar: Quick Controls
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              '$totalCount menu items'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6A2777),
                    side: const BorderSide(color: Color(0xFFD8B4E2)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: Text(
                    'Enable All'.trData(context),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _toggleAllPermissions(true),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    'Reset Defaults'.trData(context),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _resetPermissionsToDefaults(),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3. List of Menu Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: permissionsList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = permissionsList[index];
            final isEnabled = _menuPermissions[item.routeName] ?? true;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isEnabled
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFED7AA),
                  width: isEnabled ? 1.0 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isEnabled
                            ? const Color(0x06000000)
                            : const Color(0x10EA580C),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  final isCompactCard = cardConstraints.maxWidth < 400;

                  final thumbnailWidget = Container(
                    width: isCompactCard ? 40 : 46,
                    height: isCompactCard ? 40 : 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF28208C),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.image,
                            color: Colors.white,
                            size: isCompactCard ? 19 : 22,
                          ),
                    ),
                  );

                  final titleRow = Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: isCompactCard ? 13.0 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (item.subtitle != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.subtitle!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                    ],
                  );

                  final statusBadge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isEnabled
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isEnabled
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFDE68A),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_empty_rounded,
                          size: 11,
                          color:
                              isEnabled
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEnabled
                              ? 'Normal Access'.trData(context)
                              : 'Coming Soon'.trData(context),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isEnabled
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  );

                  final previewButton = IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    tooltip:
                        isEnabled
                            ? 'Test Normal View'
                            : 'Test Coming Soon View',
                    onPressed: () {
                      if (isEnabled) {
                        context.push(item.routeName);
                      } else {
                        context.push(
                          RouteNames.comingSoon,
                          extra: {
                            'featureName': item.getLocalizedTitle(context),
                          },
                        );
                      }
                    },
                  );

                  final switchWidget = Transform.scale(
                    scale: isCompactCard ? 0.78 : 0.82,
                    child: Switch(
                      value: isEnabled,
                      activeThumbColor: const Color(0xFF6A2777),
                      activeTrackColor: const Color(0xFFD8B4E2),
                      inactiveThumbColor: const Color(0xFFCBD5E1),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      onChanged:
                          (newVal) => _toggleMenuPermission(item, newVal),
                    ),
                  );

                  if (isCompactCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            thumbnailWidget,
                            const SizedBox(width: 10),
                            Expanded(child: titleRow),
                            switchWidget,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    item.routeName,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF94A3B8),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  statusBadge,
                                ],
                              ),
                            ),
                            previewButton,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      thumbnailWidget,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleRow,
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  item.routeName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                statusBadge,
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      previewButton,
                      switchWidget,
                    ],
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _toggleMenuPermission(
    MenuPermissionModel item,
    bool isEnabled,
  ) async {
    setState(() {
      _menuPermissions[item.routeName] = isEnabled;
      if (item.routeName == '/events') {
        _menuPermissions['/events-competition'] = isEnabled;
      }
    });

    try {
      await sl<ApiService>().updateMenuPermission(
        routeName: item.routeName,
        isEnabled: isEnabled,
        key: item.key,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled
                ? '${item.title}: Permission enabled (Opens Normal)'.trData(
                  context,
                )
                : '${item.title}: Permission turned OFF (Opens Coming Soon)'
                    .trData(context),
          ),
          backgroundColor:
              isEnabled ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAllPermissions(bool isEnabled) async {
    final updated = <String, bool>{};
    for (final item in MenuPermissionModel.defaultPermissions()) {
      updated[item.routeName] = isEnabled;
      if (item.routeName == '/events') {
        updated['/events-competition'] = isEnabled;
      }
    }
    setState(() => _menuPermissions = updated);
    await sl<ApiService>().updateAllMenuPermissions(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled
                ? 'All menu permissions enabled (Normal Access)'.trData(context)
                : 'All menu permissions turned off (Coming Soon)'.trData(
                  context,
                ),
          ),
          backgroundColor: const Color(0xFF6A2777),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetPermissionsToDefaults() async {
    final updated = <String, bool>{};
    for (final item in MenuPermissionModel.defaultPermissions()) {
      updated[item.routeName] = true;
      if (item.routeName == '/events') {
        updated['/events-competition'] = true;
      }
    }
    setState(() => _menuPermissions = updated);
    await sl<ApiService>().updateAllMenuPermissions(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu permissions reset to defaults (All Enabled)'.trData(context),
          ),
          backgroundColor: const Color(0xFF6A2777),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- 9. Users & Data Tab ---
  Widget _buildUsersTab() {
    final filteredUsers =
        _users.where((user) {
          final name = (user['full_name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final role = (user['role'] ?? '').toString().toLowerCase();
          final query = _userSearchQuery.toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              name.contains(query) ||
              email.contains(query) ||
              role.contains(query);

          final matchesRole =
              _userRoleFilter == 'all' ||
              role == _userRoleFilter.toLowerCase() ||
              (_userRoleFilter == 'artist' &&
                  user['has_artist_profile'] == true);

          return matchesSearch && matchesRole;
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with count & refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_users.length} registered users'.trData(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_users.where((u) => u['is_admin'] == true).length} admins · ${_users.where((u) => u['has_artist_profile'] == true || u['role'] == 'artist').length} artists'
                      .trData(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            IconButton(
              icon:
                  _isLoadingUsers
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6A2777),
                        ),
                      )
                      : const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF6A2777),
                      ),
              tooltip: 'Refresh Users'.trData(context),
              onPressed: _refreshUsers,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _userSearchQuery = val),
            decoration: InputDecoration(
              icon: const Icon(
                Icons.search,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              hintText: 'Search user by name, email, or role...'.trData(
                context,
              ),
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Role Filter Chips (Wrap naturally without horizontal scrolling)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildUserRoleChip(
              'all',
              'All Users'.trData(context),
              _users.length,
            ),
            _buildUserRoleChip(
              'admin',
              'Admins'.trData(context),
              _users.where((u) => u['is_admin'] == true).length,
            ),
            _buildUserRoleChip(
              'artist',
              'Artists'.trData(context),
              _users
                  .where(
                    (u) =>
                        u['has_artist_profile'] == true ||
                        u['role'] == 'artist',
                  )
                  .length,
            ),
            _buildUserRoleChip(
              'user',
              'Standard Users'.trData(context),
              _users
                  .where(
                    (u) =>
                        u['role'] == 'user' &&
                        u['has_artist_profile'] != true,
                  )
                  .length,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // User Cards List
        if (filteredUsers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 48,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 8),
                Text(
                  'No users match your filter'.trData(context),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _buildUserCard(filteredUsers[i]),
          ),
      ],
    );
  }

  Widget _buildUserRoleChip(String roleKey, String label, int count) {
    final isSelected = _userRoleFilter == roleKey;
    return InkWell(
      onTap: () => setState(() => _userRoleFilter = roleKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A2777) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6A2777) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final id = user['id'] ?? 0;
    final name = (user['full_name'] ?? 'Unnamed User').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'user').toString().toLowerCase();
    final isAdmin =
        user['is_admin'] == true ||
        role == 'admin' ||
        role == 'superadmin' ||
        email.toLowerCase().startsWith('admin@');
    final hasArtist = user['has_artist_profile'] == true || role == 'artist';
    final artistName = user['artist_name']?.toString() ?? '';
    final artistCategory = user['artist_category']?.toString() ?? '';
    final avatarUrl = user['avatar_url']?.toString() ?? '';
    final totalBookings = user['total_bookings'] ?? 0;
    final totalFavorites = user['total_favorites'] ?? 0;
    final totalArtworks = user['total_artworks'] ?? 0;
    final chatPlan = user['chat_plan']?.toString() ?? 'Basic (Free)';
    final createdAt = user['created_at']?.toString() ?? '';

    final String displayRole =
        isAdmin
            ? 'ADMIN'
            : (role == 'artist' || hasArtist
                ? 'ARTIST'
                : (role.isNotEmpty ? role.toUpperCase() : 'USER'));

    Color roleBadgeBg;
    Color roleBadgeBorder;
    Color roleBadgeText;
    if (isAdmin) {
      roleBadgeBg = const Color(0xFFFEF2F2);
      roleBadgeBorder = const Color(0xFFFCA5A5);
      roleBadgeText = const Color(0xFFDC2626);
    } else if (hasArtist || role == 'artist') {
      roleBadgeBg = const Color(0xFFFAF5FF);
      roleBadgeBorder = const Color(0xFFD8B4FE);
      roleBadgeText = const Color(0xFF7E22CE);
    } else {
      roleBadgeBg = const Color(0xFFF1F5F9);
      roleBadgeBorder = const Color(0xFFCBD5E1);
      roleBadgeText = const Color(0xFF334155);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Name/Email, Role Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(
                  0xFF6A2777,
                ).withValues(alpha: 0.12),
                backgroundImage:
                    (avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                child:
                    (avatarUrl.isEmpty)
                        ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A2777),
                            fontSize: 16,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 10),
              // Name and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Role Badge & Edit Role Button
              PopupMenuButton<String>(
                tooltip: 'Manage Role'.trData(context),
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (newRole) => _updateUserRole(id, newRole),
                itemBuilder:
                    (ctx) => [
                      PopupMenuItem(
                        value: 'user',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Set as User'.trData(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'artist',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.palette_outlined,
                              size: 16,
                              color: Color(0xFF7E22CE),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Set as Artist'.trData(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Promote to Admin'.trData(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: roleBadgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleBadgeBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayRole,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: roleBadgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: roleBadgeText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Row 2: User Activity Stats & Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildUserDataBadge(
                Icons.bookmark_border_rounded,
                '$totalBookings Bookings'.trData(context),
              ),
              _buildUserDataBadge(
                Icons.favorite_border_rounded,
                '$totalFavorites Favorites'.trData(context),
              ),
              if (hasArtist || totalArtworks > 0)
                _buildUserDataBadge(
                  Icons.palette_outlined,
                  '$totalArtworks Artworks'.trData(context),
                ),
              _buildUserDataBadge(Icons.chat_bubble_outline_rounded, chatPlan),
            ],
          ),

          // Row 2.5: Purchased Plans & Due Dates Section
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final rawPlans = user['purchased_plans'];
              final List<Map<String, dynamic>> plansList = [];
              if (rawPlans is List) {
                for (final item in rawPlans) {
                  if (item is Map) {
                    plansList.add(Map<String, dynamic>.from(item));
                  }
                }
              }

              final userEmailLower = email.toLowerCase().trim();
              if (plansList.isEmpty) {
                // Check if user published events with plans
                for (final ev in _events) {
                  final orgEmail =
                      (ev.organizerEmail ?? '').toLowerCase().trim();
                  if (orgEmail == userEmailLower &&
                      ev.publishingPlan != null &&
                      ev.publishingPlan!.isNotEmpty) {
                    final pName =
                        '${ev.publishingPlan![0].toUpperCase()}${ev.publishingPlan!.substring(1)} Plan';
                    plansList.add({
                      'plan_name': pName,
                      'plan_type': 'Event Publishing',
                      'price':
                          (ev.publishingAmount != null &&
                                  ev.publishingAmount!.isNotEmpty)
                              ? ev.publishingAmount!
                              : (ev.price.isNotEmpty ? ev.price : 'Free'),
                      'due_date':
                          ev.dateTime.isNotEmpty
                              ? ev.dateTime.split(' ').first
                              : 'Active',
                      'status':
                          (ev.paymentStatus != null &&
                                  ev.paymentStatus!.isNotEmpty)
                              ? ev.paymentStatus!
                              : 'Active',
                    });
                  }
                }
                // Check if user published galleries with plans
                for (final g in _galleries) {
                  final gEmail =
                      (g['user_email'] ?? g['email'] ?? '')
                          .toString()
                          .toLowerCase()
                          .trim();
                  final pubPlan = g['publishing_plan']?.toString() ?? '';
                  if (gEmail == userEmailLower && pubPlan.isNotEmpty) {
                    plansList.add({
                      'plan_name':
                          '${pubPlan[0].toUpperCase()}${pubPlan.substring(1)} Plan',
                      'plan_type': 'Gallery Publishing',
                      'price':
                          (g['publishing_amount'] != null &&
                                  g['publishing_amount'].toString().isNotEmpty)
                              ? g['publishing_amount'].toString()
                              : (g['price'] != null &&
                                      g['price'].toString().isNotEmpty
                                  ? g['price'].toString()
                                  : 'Free'),
                      'due_date':
                          (g['created_at'] != null)
                              ? g['created_at'].toString().split(' ').first
                              : 'Active',
                      'status': (g['payment_status'] ?? 'Active').toString(),
                    });
                  }
                }
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF6A2777),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Purchased Plans & Due Dates'.trData(context),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                plansList.isNotEmpty
                                    ? const Color(
                                      0xFF6A2777,
                                    ).withValues(alpha: 0.1)
                                    : const Color(
                                      0xFF64748B,
                                    ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            plansList.isNotEmpty
                                ? '${plansList.length} Plan(s)'.trData(context)
                                : 'No Active Plans'.trData(context),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  plansList.isNotEmpty
                                      ? const Color(0xFF6A2777)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (plansList.isEmpty) ...[
                      Text(
                        'User has no active purchased plans or subscriptions.'
                            .trData(context),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      for (int pIdx = 0; pIdx < plansList.length; pIdx++) ...[
                        if (pIdx > 0) const SizedBox(height: 6),
                        _buildPlanRow(
                          context,
                          planName:
                              (plansList[pIdx]['plan_name'] ??
                                      plansList[pIdx]['plan_type'] ??
                                      'Plan')
                                  .toString(),
                          price:
                              (plansList[pIdx]['price'] ?? 'Free').toString(),
                          dueDate:
                              (plansList[pIdx]['due_date'] ??
                                      plansList[pIdx]['expires_at'] ??
                                      'Active')
                                  .toString(),
                          status:
                              (plansList[pIdx]['status'] ?? 'Active')
                                  .toString(),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),

          // Row 3: If Artist, show Artist Details
          if (hasArtist && artistName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF7E22CE),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Linked Artist: $artistName ${artistCategory.isNotEmpty ? '· $artistCategory' : ''}'
                          .trData(context),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B21A8),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Row 4: Account Actions & Registration Date
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (createdAt.isNotEmpty)
                Text(
                  'Registered: ${createdAt.split(' ').first}'.trData(context),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const SizedBox.shrink(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A2777),
                      side: const BorderSide(color: Color(0xFFD8B4E2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.card_membership_rounded, size: 14),
                    label: Text(
                      'Assign / Edit Plan'.trData(context),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _showAssignPlanDialog(user),
                  ),
                  IconButton(
                    tooltip: 'Delete User'.trData(context),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: Colors.redAccent,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.all(6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                      ),
                    ),
                    onPressed: () => _confirmDeleteUser(user),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRow(
    BuildContext context, {
    required String planName,
    required String price,
    required String dueDate,
    required String status,
  }) {
    final isExpired = status.toLowerCase().contains('expired');
    final isFree = price.toLowerCase().contains('free') || price == '0';

    Color statusBg = const Color(0xFFDCFCE7);
    Color statusText = const Color(0xFF15803D);
    if (isExpired) {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFB91C1C);
    } else if (status.toLowerCase().contains('pending')) {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        planName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: statusText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 10.5,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Due / Expires: '.trData(context) + dueDate,
                        style: TextStyle(
                          fontSize: 10.5,
                          color:
                              isExpired
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                          fontWeight:
                              isExpired ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isFree ? const Color(0xFFF0FDF4) : const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isFree ? const Color(0xFFBBF7D0) : const Color(0xFFE9D5FF),
              ),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color:
                    isFree ? const Color(0xFF16A34A) : const Color(0xFF6A2777),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDataBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final fresh = await sl<ApiService>().getUsers();
      if (mounted) {
        setState(() {
          _users = fresh;
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _updateUserRole(dynamic userId, String newRole) async {
    final int id = int.tryParse(userId.toString()) ?? 0;
    if (id <= 0) return;

    final success = await sl<ApiService>().updateUserRole(
      userId: id,
      role: newRole,
    );
    if (success && mounted) {
      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          _users[idx]['role'] = newRole;
          _users[idx]['is_admin'] = newRole == 'admin';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User role updated to $newRole successfully'.trData(context),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _showAssignPlanDialog(Map<String, dynamic> user) async {
    final int userId = int.tryParse(user['id'].toString()) ?? 0;
    final String email = (user['email'] ?? '').toString();
    final String userName = (user['full_name'] ?? 'User').toString();
    final String currentPlan = (user['chat_plan'] ?? 'Basic (Free)').toString();

    // 1. Build catalog of all pre-configured plans from Admin Masters (_listingPlans) merged with baseline plans
    final allListingPlans = List<ListingPlanItem>.from(_listingPlans);
    for (final bp in ListingPlanItem.defaultBaselinePlans) {
      if (!allListingPlans.any((p) => p.title.toLowerCase().trim() == bp.title.toLowerCase().trim())) {
        allListingPlans.add(bp);
      }
    }

    String resolvePlanTypeFromItem(ListingPlanItem item) {
      final t = item.itemType.toLowerCase().trim();
      if (t == 'event') return 'Event Publishing';
      if (t == 'gallery') return 'Gallery Publishing';
      if (t == 'art_centre' || t == 'center') return 'Art Center Showcase';
      if (t == 'chat') return 'Chat & Messaging';
      if (t == 'artist') return 'Membership Plan';
      return 'Custom Subscription';
    }

    String resolveFilterKeyFromPlanType(String planType) {
      final pt = planType.toLowerCase().trim();
      if (pt.contains('event')) return 'event';
      if (pt.contains('gallery')) return 'gallery';
      if (pt.contains('art center') || pt.contains('art centre') || pt.contains('center')) return 'art_centre';
      if (pt.contains('chat') || pt.contains('messaging')) return 'chat';
      if (pt.contains('membership') || pt.contains('artist')) return 'artist';
      return 'all';
    }

    IconData resolveIconForType(String typeKey) {
      final tk = typeKey.toLowerCase().trim();
      if (tk.contains('event')) return Icons.event_available_rounded;
      if (tk.contains('artist') || tk.contains('membership')) return Icons.palette_outlined;
      if (tk.contains('gallery')) return Icons.museum_outlined;
      if (tk.contains('art center') || tk.contains('art centre') || tk.contains('center') || tk.contains('art_centre')) return Icons.account_balance_outlined;
      if (tk.contains('chat') || tk.contains('messaging')) return Icons.chat_bubble_outline_rounded;
      return Icons.stars_rounded;
    }

    int countForFilter(String key) {
      if (key == 'all') return allListingPlans.length;
      if (key == 'art_centre') {
        return allListingPlans.where((p) => p.itemType.toLowerCase() == 'art_centre' || p.itemType.toLowerCase() == 'center').length;
      }
      return allListingPlans.where((p) => p.itemType.toLowerCase() == key).length;
    }

    List<ListingPlanItem> getFilteredPlans(String filterKey) {
      if (filterKey == 'all') return allListingPlans;
      if (filterKey == 'art_centre') {
        return allListingPlans.where((p) => p.itemType.toLowerCase() == 'art_centre' || p.itemType.toLowerCase() == 'center').toList();
      }
      return allListingPlans.where((p) => p.itemType.toLowerCase() == filterKey).toList();
    }

    // 2. Check if user already purchased a plan
    final rawPurchased = user['purchased_plans'];
    Map<String, dynamic>? latestPurchased;
    if (rawPurchased is List && rawPurchased.isNotEmpty) {
      for (final p in rawPurchased) {
        if (p is Map) {
          latestPurchased = Map<String, dynamic>.from(p);
          break;
        }
      }
    }

    // Initial Category filter & template
    String selectedCategoryFilter = 'all';
    String selectedTemplate = 'custom';
    String selectedPlanType = 'Event Publishing';

    if (latestPurchased != null && (latestPurchased['plan_name']?.toString().isNotEmpty ?? false)) {
      selectedTemplate = 'user_purchased';
      final pType = (latestPurchased['plan_type'] ?? 'Event Publishing').toString();
      selectedPlanType = pType;
      final fKey = resolveFilterKeyFromPlanType(pType);
      if (fKey != 'all') selectedCategoryFilter = fKey;
    } else {
      final matching = allListingPlans.where((p) => p.title.toLowerCase().trim() == currentPlan.toLowerCase().trim()).toList();
      if (matching.isNotEmpty) {
        selectedTemplate = matching.first.title;
        selectedPlanType = resolvePlanTypeFromItem(matching.first);
        final itemKey = matching.first.itemType.toLowerCase() == 'center' ? 'art_centre' : matching.first.itemType.toLowerCase();
        selectedCategoryFilter = itemKey;
      }
    }

    final initialPrice = latestPurchased != null
        ? (latestPurchased['price']?.toString() ?? 'Free')
        : (allListingPlans.any((p) => p.title == selectedTemplate)
            ? allListingPlans.firstWhere((p) => p.title == selectedTemplate).price
            : (currentPlan.contains('Basic') ? 'Free' : (currentPlan.contains('Pro') ? 'AED 99' : 'AED 199')));

    final planController = TextEditingController(
      text: latestPurchased != null
          ? (latestPurchased['plan_name']?.toString() ?? currentPlan)
          : (selectedTemplate != 'custom' ? selectedTemplate : currentPlan),
    );
    final priceController = TextEditingController(text: initialPrice);

    // Expiration date (defaults to +30 days or existing due date)
    final existingDue = latestPurchased != null
        ? (latestPurchased['due_date'] ?? latestPurchased['expires_at'])?.toString()
        : null;
    String initialDueStr = '';
    if (existingDue != null && existingDue.isNotEmpty && existingDue.length >= 10) {
      initialDueStr = existingDue.substring(0, 10);
    } else {
      final defaultDue = DateTime.now().add(const Duration(days: 30));
      initialDueStr =
          '${defaultDue.year}-${defaultDue.month.toString().padLeft(2, '0')}-${defaultDue.day.toString().padLeft(2, '0')}';
    }
    final dueDateController = TextEditingController(text: initialDueStr);
    String selectedStatus = latestPurchased != null ? (latestPurchased['status']?.toString() ?? 'Active') : 'Active';

    final categoryFilterTabs = [
      {'key': 'all', 'label': 'All Plans', 'icon': Icons.apps_rounded},
      {'key': 'event', 'label': 'Events', 'icon': Icons.event_available_rounded},
      {'key': 'artist', 'label': 'Artists', 'icon': Icons.palette_outlined},
      {'key': 'gallery', 'label': 'Galleries', 'icon': Icons.museum_outlined},
      {'key': 'chat', 'label': 'Chat & Messaging', 'icon': Icons.chat_bubble_outline_rounded},
      {'key': 'art_centre', 'label': 'Art Centres', 'icon': Icons.account_balance_outlined},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentFilteredPlans = getFilteredPlans(selectedCategoryFilter);
          final hasSelectedInCurrent = currentFilteredPlans.any((p) => p.title == selectedTemplate);

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 820),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Icon, User Details, Close Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A2777), Color(0xFF8B2C9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6A2777).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.card_membership_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign Plan to User'.trData(context),
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6A2777),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '($email)',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  'Current: $currentPlan',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // User Purchased Plan Banner with Auto-Fill Action
                    if (latestPurchased != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 17, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User Purchased Plan'.trData(context),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  Text(
                                    '${latestPurchased['plan_name']} · ${latestPurchased['price'] ?? 'Active'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  final pName = (latestPurchased?['plan_name'] ?? currentPlan).toString();
                                  final pPrice = (latestPurchased?['price'] ?? 'Free').toString();
                                  final pDue = (latestPurchased?['due_date'] ?? latestPurchased?['expires_at'] ?? '').toString();
                                  final pType = (latestPurchased?['plan_type'] ?? 'Event Publishing').toString();

                                  planController.text = pName;
                                  priceController.text = pPrice;
                                  if (pDue.isNotEmpty && pDue.length >= 10) {
                                    dueDateController.text = pDue.substring(0, 10);
                                  }
                                  selectedPlanType = pType;
                                  selectedCategoryFilter = resolveFilterKeyFromPlanType(pType);
                                  selectedStatus = 'Active';
                                  selectedTemplate = 'user_purchased';
                                });
                              },
                              child: Text(
                                'Auto-Fill'.trData(context),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Category Filter Selector Chips (Connected with Admin Listing Plans)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFormLabel('Filter Category'.trData(context)),
                        Text(
                          '${currentFilteredPlans.length} plans available'.trData(context),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: categoryFilterTabs.map((cat) {
                          final key = cat['key'] as String;
                          final label = cat['label'] as String;
                          final icon = cat['icon'] as IconData;
                          final count = countForFilter(key);
                          final isSelected = selectedCategoryFilter == key;

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedCategoryFilter = key;
                                  final filtered = getFilteredPlans(key);
                                  if (filtered.isNotEmpty && selectedTemplate != 'user_purchased') {
                                    final first = filtered.first;
                                    selectedTemplate = first.title;
                                    planController.text = first.title;
                                    priceController.text = first.price;
                                    selectedPlanType = resolvePlanTypeFromItem(first);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 13,
                                      color: isSelected ? Colors.white : const Color(0xFF6A2777),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$label ($count)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Auto Plan Selector Dropdown (Populated directly from Admin Created Plans)
                    _buildFormLabel('Auto-Select From Created Plans'.trData(context)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('$selectedCategoryFilter-$selectedTemplate'),
                      initialValue: (selectedTemplate == 'user_purchased' ||
                              selectedTemplate == 'custom' ||
                              hasSelectedInCurrent)
                          ? selectedTemplate
                          : (currentFilteredPlans.isNotEmpty ? currentFilteredPlans.first.title : 'custom'),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      items: [
                        if (latestPurchased != null)
                          DropdownMenuItem(
                            value: 'user_purchased',
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'User Purchased: ${latestPurchased['plan_name']} · ${latestPurchased['price'] ?? 'Active'}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...currentFilteredPlans.map(
                          (p) => DropdownMenuItem(
                            value: p.title,
                            child: Row(
                              children: [
                                Icon(
                                  resolveIconForType(p.itemType),
                                  size: 16,
                                  color: const Color(0xFF6A2777),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${p.title} — ${p.price} (${p.badge.isNotEmpty ? p.badge : p.category})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 8),
                              Text(
                                'Custom / Manual Entry',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() {
                          selectedTemplate = val;
                          if (val == 'user_purchased' && latestPurchased != null) {
                            planController.text = (latestPurchased['plan_name'] ?? currentPlan).toString();
                            priceController.text = (latestPurchased['price'] ?? 'Free').toString();
                            final pDue = (latestPurchased['due_date'] ?? latestPurchased['expires_at'] ?? '').toString();
                            if (pDue.isNotEmpty && pDue.length >= 10) {
                              dueDateController.text = pDue.substring(0, 10);
                            }
                            final pType = (latestPurchased['plan_type'] ?? 'Event Publishing').toString();
                            selectedPlanType = pType;
                            selectedCategoryFilter = resolveFilterKeyFromPlanType(pType);
                            selectedStatus = 'Active';
                          } else if (val != 'custom') {
                            final found = allListingPlans.firstWhere(
                              (p) => p.title == val,
                              orElse: () => allListingPlans.first,
                            );
                            planController.text = found.title;
                            priceController.text = found.price;
                            selectedPlanType = resolvePlanTypeFromItem(found);
                            final itemKey = found.itemType.toLowerCase() == 'center' ? 'art_centre' : found.itemType.toLowerCase();
                            selectedCategoryFilter = itemKey;
                            final nextDue = DateTime.now().add(const Duration(days: 30));
                            dueDateController.text =
                                '${nextDue.year}-${nextDue.month.toString().padLeft(2, '0')}-${nextDue.day.toString().padLeft(2, '0')}';
                            selectedStatus = 'Active';
                          }
                        });
                      },
                      decoration: _dialogInputDecoration(icon: Icons.auto_awesome_rounded),
                    ),
                    const SizedBox(height: 14),

                    // 2. Plan Name / Tier Textfield
                    _buildFormLabel('Plan Name / Tier *'.trData(context)),
                    const SizedBox(height: 6),
                    _buildDialogTextField(
                      controller: planController,
                      hint: 'e.g. Event Listing, Pro Artist, Gallery Listing, Chat Pro',
                      icon: Icons.card_membership_rounded,
                    ),
                    const SizedBox(height: 14),

                    // 3. Price Textfield & Quick Preset Chips
                    _buildFormLabel('Price *'.trData(context)),
                    const SizedBox(height: 6),
                    _buildDialogTextField(
                      controller: priceController,
                      hint: 'e.g. Free, AED 49, AED 99, AED 149, AED 199, AED 299',
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          'Free',
                          'AED 49',
                          'AED 99',
                          'AED 149',
                          'AED 199',
                          'AED 299',
                          'AED 500',
                        ].map((p) {
                          final isSelected = priceController.text.trim().toLowerCase() == p.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  priceController.text = p;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Due / Expiration Date with Picker & Quick Preset Buttons
                    _buildFormLabel('Due / Expiration Date (YYYY-MM-DD) *'.trData(context)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final currentText = dueDateController.text.trim();
                        DateTime initDate = DateTime.now().add(const Duration(days: 30));
                        if (currentText.length >= 10) {
                          final parsed = DateTime.tryParse(currentText);
                          if (parsed != null) initDate = parsed;
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dueDateController.text =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: IgnorePointer(
                        child: TextField(
                          controller: dueDateController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: _dialogInputDecoration(
                            icon: Icons.calendar_month_rounded,
                            hint: 'YYYY-MM-DD',
                          ).copyWith(
                            suffixIcon: const Icon(
                              Icons.event_available_rounded,
                              size: 19,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildDurationQuickChip(
                            '+30 Days',
                            30,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                          const SizedBox(width: 6),
                          _buildDurationQuickChip(
                            '+60 Days',
                            60,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                          const SizedBox(width: 6),
                          _buildDurationQuickChip(
                            '+90 Days',
                            90,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                          const SizedBox(width: 6),
                          _buildDurationQuickChip(
                            '+6 Months',
                            180,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                          const SizedBox(width: 6),
                          _buildDurationQuickChip(
                            '+1 Year',
                            365,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                          const SizedBox(width: 6),
                          _buildDurationQuickChip(
                            'Lifetime (5 Yrs)',
                            1825,
                            dueDateController,
                            () => setDialogState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Plan Type Dropdown (Fully connected with Admin Plan Types)
                    _buildFormLabel('Plan Type *'.trData(context)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedPlanType),
                      initialValue: selectedPlanType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Event Publishing',
                          child: Row(
                            children: [
                              Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Event Listing / Publishing', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Membership Plan',
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Artist Portfolio / Membership', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Gallery Publishing',
                          child: Row(
                            children: [
                              Icon(Icons.museum_outlined, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Gallery Showcase / Listing', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Art Center Showcase',
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Art Center Showcase', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Chat & Messaging',
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Chat & Messaging Pro', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Custom Subscription',
                          child: Row(
                            children: [
                              Icon(Icons.stars_rounded, size: 16, color: Color(0xFF6A2777)),
                              SizedBox(width: 8),
                              Text('Custom Subscription', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedPlanType = val;
                            final newFilter = resolveFilterKeyFromPlanType(val);
                            if (newFilter != 'all') {
                              selectedCategoryFilter = newFilter;
                              final filtered = getFilteredPlans(newFilter);
                              if (filtered.isNotEmpty && selectedTemplate != 'user_purchased') {
                                final first = filtered.first;
                                selectedTemplate = first.title;
                                planController.text = first.title;
                                priceController.text = first.price;
                              }
                            }
                          });
                        }
                      },
                      decoration: _dialogInputDecoration(icon: Icons.category_outlined),
                    ),
                    const SizedBox(height: 14),

                    // 6. Status Dropdown
                    _buildFormLabel('Subscription Status *'.trData(context)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                              SizedBox(width: 8),
                              Text(
                                'Active (Full Access)',
                                style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Row(
                            children: [
                              Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text(
                                'Pending (Awaiting Confirmation)',
                                style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Expired',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text(
                                'Expired (Access Suspended)',
                                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                      decoration: _dialogInputDecoration(
                        icon: selectedStatus == 'Active'
                            ? Icons.check_circle_rounded
                            : (selectedStatus == 'Pending'
                                ? Icons.pending_actions_rounded
                                : Icons.cancel_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Actions: Cancel & Save Plan
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel'.trData(context),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A2777),
                              foregroundColor: Colors.white,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                            label: Text(
                              'Save Plan'.trData(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              final pName = planController.text.trim();
                              final pPrice = priceController.text.trim();
                              final pDue = dueDateController.text.trim();
                              final messenger = ScaffoldMessenger.of(context);
                              final successMsg = 'Plan updated successfully for $userName'.trData(context);
                              final failMsg = 'Failed to update user plan. Please check connection.'.trData(context);
                              Navigator.pop(ctx);

                              final success = await sl<ApiService>().assignUserPlan(
                                userId: userId,
                                email: email,
                                planName: pName.isNotEmpty ? pName : 'Basic (Free)',
                                planType: selectedPlanType,
                                price: pPrice.isNotEmpty ? pPrice : 'Free',
                                dueDate: pDue,
                                status: selectedStatus,
                              );

                              if (success) {
                                await _refreshUsers();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(successMsg),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } else if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(failMsg),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildDurationQuickChip(
    String label,
    int days,
    TextEditingController controller,
    VoidCallback onSet,
  ) {
    final target = DateTime.now().add(Duration(days: days));
    final targetStr =
        '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    final isSelected = controller.text.trim() == targetStr;

    return InkWell(
      onTap: () {
        controller.text = targetStr;
        onSet();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF6A2777) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

    Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final int userId = int.tryParse(user['id'].toString()) ?? 0;
    final String email = (user['email'] ?? '').toString();
    final String userName = (user['full_name'] ?? 'User').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete User?'.trData(context),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "$userName" ($email)? This will permanently remove their profile, plans, and activity.'
                  .trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel'.trData(context),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete Permanently'.trData(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await sl<ApiService>().adminDeleteUser(
        userId: userId,
        email: email,
      );
      if (success) {
        setState(() {
          _users.removeWhere((u) => u['id'] == userId || u['email'] == email);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User "$userName" deleted successfully'.trData(context),
              ),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete user. Please check server connection.'.trData(
                context,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // --- 10. About Us Page Content Management Tab ---
  // ---------------------------------------------------------------------------
  List<({TextEditingController en, TextEditingController ar, String fieldName})>
      get _aboutUsFieldPairs => [
        (en: _aboutTitleEnCtrl, ar: _aboutTitleArCtrl, fieldName: 'Main Page Title'),
        (
          en: _aboutWhatMeansTitleEnCtrl,
          ar: _aboutWhatMeansTitleArCtrl,
          fieldName: 'Section 1 Title',
        ),
        (
          en: _aboutWhatMeansBodyEnCtrl,
          ar: _aboutWhatMeansBodyArCtrl,
          fieldName: 'Section 1 Body',
        ),
        (en: _aboutQuoteTextEnCtrl, ar: _aboutQuoteTextArCtrl, fieldName: 'Featured Quote'),
        (en: _aboutConnectBodyEnCtrl, ar: _aboutConnectBodyArCtrl, fieldName: 'Connect Body'),
        (
          en: _aboutOpportunitiesBodyEnCtrl,
          ar: _aboutOpportunitiesBodyArCtrl,
          fieldName: 'Opportunities Body',
        ),
        (en: _aboutFusionBodyEnCtrl, ar: _aboutFusionBodyArCtrl, fieldName: 'Fusion Body'),
        (
          en: _aboutDubaiVisionBodyEnCtrl,
          ar: _aboutDubaiVisionBodyArCtrl,
          fieldName: 'Dubai Vision Body',
        ),
        (
          en: _aboutOurVisionBodyEnCtrl,
          ar: _aboutOurVisionBodyArCtrl,
          fieldName: 'Our Vision Body',
        ),
        (
          en: _aboutClosingBordersEnCtrl,
          ar: _aboutClosingBordersArCtrl,
          fieldName: 'Closing Borders',
        ),
        (
          en: _aboutClosingImpossibleEnCtrl,
          ar: _aboutClosingImpossibleArCtrl,
          fieldName: 'Closing Impossible',
        ),
      ];

  void _initAboutUsAutoSync() {
    for (final pair in _aboutUsFieldPairs) {
      _lastSyncedValues[pair.en] = pair.en.text;
      _lastSyncedValues[pair.ar] = pair.ar.text;
      pair.en.addListener(() => _handleAboutFieldChanged(pair.en, pair.ar, toArabic: true));
      pair.ar.addListener(() => _handleAboutFieldChanged(pair.ar, pair.en, toArabic: false));
    }
  }

  void _handleAboutFieldChanged(
    TextEditingController source,
    TextEditingController target, {
    required bool toArabic,
  }) {
    if (!_aboutAutoSyncEnabled || _isAutoSyncingAboutUs) return;
    // Guard: Only process edits triggered on the currently active tab
    // 0 = English tab (edits sync to Arabic)
    // 1 = Arabic tab (edits sync to English)
    if (toArabic && _aboutLanguageSubTab != 0) return;
    if (!toArabic && _aboutLanguageSubTab != 1) return;

    final currentText = source.text.trim();
    if (currentText == _lastSyncedValues[source]?.trim()) return;

    _aboutSyncDebounceTimer?.cancel();
    _aboutSyncDebounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted || !_aboutAutoSyncEnabled || _isAutoSyncingAboutUs) return;
      final textToTranslate = source.text;
      if (textToTranslate.trim().isEmpty) {
        _isAutoSyncingAboutUs = true;
        target.text = '';
        _lastSyncedValues[source] = '';
        _lastSyncedValues[target] = '';
        _isAutoSyncingAboutUs = false;
        return;
      }

      setState(() => _syncingFieldsCount++);
      try {
        final translated = await DataTranslator.translateAsync(
          textToTranslate,
          toArabic: toArabic,
        );
        if (mounted && source.text == textToTranslate) {
          _isAutoSyncingAboutUs = true;
          target.text = translated;
          _lastSyncedValues[source] = textToTranslate;
          _lastSyncedValues[target] = translated;
          _isAutoSyncingAboutUs = false;
        }
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() {
            if (_syncingFieldsCount > 0) _syncingFieldsCount--;
          });
        }
      }
    });
  }

  Future<void> _syncAllAboutFields({
    required bool fromEnglish,
    bool showToast = false,
  }) async {
    if (_isSyncingAllAboutFields) return;
    setState(() => _isSyncingAllAboutFields = true);
    int translatedCount = 0;
    try {
      _isAutoSyncingAboutUs = true;
      for (final pair in _aboutUsFieldPairs) {
        final source = fromEnglish ? pair.en : pair.ar;
        final target = fromEnglish ? pair.ar : pair.en;
        final sourceText = source.text;
        if (sourceText.trim().isNotEmpty) {
          final translated = await DataTranslator.translateAsync(
            sourceText,
            toArabic: fromEnglish,
          );
          if (translated.isNotEmpty) {
            target.text = translated;
            _lastSyncedValues[source] = sourceText;
            _lastSyncedValues[target] = translated;
            translatedCount++;
          }
        } else {
          target.text = '';
          _lastSyncedValues[source] = '';
          _lastSyncedValues[target] = '';
        }
      }
    } catch (_) {
    } finally {
      _isAutoSyncingAboutUs = false;
      if (mounted) {
        setState(() => _isSyncingAllAboutFields = false);
        if (showToast) {
          final msg = fromEnglish
              ? 'Synced $translatedCount fields to Arabic successfully'
              : 'تمت مزامنة $translatedCount حقلاً إلى الإنجليزية بنجاح';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(msg.trData(context))),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadAboutUsData() async {
    setState(() => _isLoadingAboutUs = true);
    try {
      final data = await sl<ApiService>().getAboutData();
      if (mounted) {
        _populateAboutUsFields(data);
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isLoadingAboutUs = false);
      }
    }
  }

  void _populateAboutUsFields(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _isAutoSyncingAboutUs = true;
    _aboutTitleEnCtrl.text = data['title']?.toString() ?? 'ABOUT US';
    _aboutTitleArCtrl.text = data['title_ar']?.toString() ?? 'من نحن';
    _aboutWhatMeansTitleEnCtrl.text =
        data['what_means_title']?.toString() ?? 'What does it mean to be an artist?';
    _aboutWhatMeansTitleArCtrl.text =
        data['what_means_title_ar']?.toString() ?? 'ماذا يعني أن تكون فناناً؟';
    _aboutWhatMeansBodyEnCtrl.text =
        data['what_means_body']?.toString() ??
        "The word artist has a long history. It is rooted in the idea of art and originally described people with exceptional knowledge, skills and abilities. Today, an artist is someone who creates, interprets and gives expression to ideas, emotions and visions.\n\nBut we believe art can be more.";
    _aboutWhatMeansBodyArCtrl.text =
        data['what_means_body_ar']?.toString() ??
        "إن كلمة فنان لها تاريخ طويل، وجذورها متأصلة في فكرة الفن، وكانت في الأصل تصف الأشخاص ذوي المعرفة والمهارات والقدرات الاستثنائية. اليوم، الفنان هو شخص يبدع ويفسر ويعبر عن الأفكار والمشاعر والرؤى.\n\nلكننا نؤمن بأن الفن يمكن أن يكون أكثر من ذلك.";
    _aboutQuoteTextEnCtrl.text =
        data['quote_text']?.toString() ??
        '“Art does not reproduce the visible; rather, it makes visible.”';
    _aboutQuoteTextArCtrl.text =
        data['quote_text_ar']?.toString() ??
        '«الفن لا يعيد إنتاج المرئي، بل يجعله مرئياً.»';
    _aboutConnectBodyEnCtrl.text =
        data['connect_body']?.toString() ??
        'Our platform was created to connect artists across disciplines, cultures, languages and levels of experience. From photography, painting and music to sculpture, digital art and many other creative forms, our platform gives artists a place to discover, share, connect and collaborate.';
    _aboutConnectBodyArCtrl.text =
        data['connect_body_ar']?.toString() ??
        'تم إنشاء منصتنا لربط الفنانين عبر مختلف التخصصات والثقافات واللغات ومستويات الخبرة. من التصوير الفوتوغرافي والرسم والموسيقى إلى النحت والفن الرقمي والعديد من الأشكال الإبداعية الأخرى، تمنح منصتنا الفنانين مساحة للاكتشاف والمشاركة والتواصل والتعاون.';
    _aboutOpportunitiesBodyEnCtrl.text =
        data['opportunities_body']?.toString() ??
        'Artists can explore different forms of art, discover galleries and art associations, connect directly with them, showcase their work and take part in events, competitions and creative challenges. Most importantly, the platform creates opportunities for meaningful exchange, inspiration and collaboration.';
    _aboutOpportunitiesBodyArCtrl.text =
        data['opportunities_body_ar']?.toString() ??
        'يمكن للفنانين استكشاف أشكال مختلفة من الفن، واكتشاف صالات العرض والجمعيات الفنية، والتواصل معها مباشرة، وعرض أعمالهم والمشاركة في الفعاليات والمسابقات والتحديات الإبداعية. والأهم من ذلك، تخلق المنصة فرصاً للتبادل الهادف والإلهام والتعاون.';
    _aboutFusionBodyEnCtrl.text =
        data['fusion_body']?.toString() ??
        "Because when different artists, cultures and creative perspectives come together, something new can emerge.\n\nPerhaps even a form of art that has never existed before.";
    _aboutFusionBodyArCtrl.text =
        data['fusion_body_ar']?.toString() ??
        "لأنه عندما يلتقي فنانون وثقافات ورؤى إبداعية مختلفة، يمكن أن يولد شيء جديد تماماً.\n\nوربما حتى شكل فني لم يكن موجوداً من قبل.";
    _aboutDubaiVisionBodyEnCtrl.text =
        data['dubai_vision_body']?.toString() ??
        "Dubai is a unique place for this vision. With people from more than 180 nationalities, countless cultures, languages and perspectives meet here. Art has the power to connect these differences and create something that belongs to everyone.\n\nOur digital world allows us to bring these creative forces together beyond borders and distances.";
    _aboutDubaiVisionBodyArCtrl.text =
        data['dubai_vision_body_ar']?.toString() ??
        "دبي هي المكان الأمثل لتحقيق هذه الرؤية. مع وجود أشخاص من أكثر من 180 جنسية، تلتقي هنا ثقافات ولغات ورؤى لا حصر لها. يمتلك الفن القدرة على الجمع بين هذه الاختلافات وخلق شيء ينتمي للجميع.\n\nعالمنا الرقمي يتيح لنا جمع هذه الطاقات الإبداعية متجاوزين كل الحدود والمسافات.";
    _aboutOurVisionBodyEnCtrl.text =
        data['our_vision_body']?.toString() ??
        "Our vision is more than simply creating a platform for artists.\n\nWe want to create a space where encounters become inspiration, inspiration becomes collaboration, and collaboration becomes new art.";
    _aboutOurVisionBodyArCtrl.text =
        data['our_vision_body_ar']?.toString() ??
        "رؤيتنا تتجاوز مجرد إنشاء منصة للفنانين.\n\nنريد خلق مساحة يتحول فيها اللقاء إلى إلهام، والإلهام إلى تعاون، والتعاون إلى فن جديد.";
    _aboutClosingBordersEnCtrl.text =
        data['closing_borders']?.toString() ?? 'Because art has no borders.';
    _aboutClosingBordersArCtrl.text =
        data['closing_borders_ar']?.toString() ?? 'لأن الفن لا يعرف حدوداً.';
    _aboutClosingImpossibleEnCtrl.text =
        data['closing_impossible']?.toString() ??
        'And when people, ideas and talents come together, artists have the power to make the impossible possible.';
    _aboutClosingImpossibleArCtrl.text =
        data['closing_impossible_ar']?.toString() ??
        'وعندما تجتمع العقول والأفكار والمواهب، يمتلك الفنانون القدرة على جعل المستحيل ممكناً.';
    for (final pair in _aboutUsFieldPairs) {
      _lastSyncedValues[pair.en] = pair.en.text;
      _lastSyncedValues[pair.ar] = pair.ar.text;
    }
    _isAutoSyncingAboutUs = false;
  }

  Future<void> _saveAboutUsData() async {
    setState(() => _isSavingAboutUs = true);
    final payload = {
      'title': _aboutTitleEnCtrl.text.trim(),
      'title_ar': _aboutTitleArCtrl.text.trim(),
      'what_means_title': _aboutWhatMeansTitleEnCtrl.text.trim(),
      'what_means_title_ar': _aboutWhatMeansTitleArCtrl.text.trim(),
      'what_means_body': _aboutWhatMeansBodyEnCtrl.text.trim(),
      'what_means_body_ar': _aboutWhatMeansBodyArCtrl.text.trim(),
      'quote_text': _aboutQuoteTextEnCtrl.text.trim(),
      'quote_text_ar': _aboutQuoteTextArCtrl.text.trim(),
      'connect_body': _aboutConnectBodyEnCtrl.text.trim(),
      'connect_body_ar': _aboutConnectBodyArCtrl.text.trim(),
      'opportunities_body': _aboutOpportunitiesBodyEnCtrl.text.trim(),
      'opportunities_body_ar': _aboutOpportunitiesBodyArCtrl.text.trim(),
      'fusion_body': _aboutFusionBodyEnCtrl.text.trim(),
      'fusion_body_ar': _aboutFusionBodyArCtrl.text.trim(),
      'dubai_vision_body': _aboutDubaiVisionBodyEnCtrl.text.trim(),
      'dubai_vision_body_ar': _aboutDubaiVisionBodyArCtrl.text.trim(),
      'our_vision_body': _aboutOurVisionBodyEnCtrl.text.trim(),
      'our_vision_body_ar': _aboutOurVisionBodyArCtrl.text.trim(),
      'closing_borders': _aboutClosingBordersEnCtrl.text.trim(),
      'closing_borders_ar': _aboutClosingBordersArCtrl.text.trim(),
      'closing_impossible': _aboutClosingImpossibleEnCtrl.text.trim(),
      'closing_impossible_ar': _aboutClosingImpossibleArCtrl.text.trim(),
    };

    final ok = await sl<ApiService>().updateAboutData(payload);
    if (mounted) {
      setState(() => _isSavingAboutUs = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('About Us page updated successfully!'.trData(context)),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update About Us page. Check admin connection.'
                  .trData(context),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetAboutUsDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.restore_rounded,
                  color: Color(0xFF6A2777),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Restore Default Content?'.trData(context),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'This will reset all English and Arabic texts back to the official default content. You can still make edits before saving.'
                  .trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel'.trData(context),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A2777),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Restore Defaults'.trData(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      _isAutoSyncingAboutUs = true;
      _aboutTitleEnCtrl.text = 'ABOUT US';
      _aboutTitleArCtrl.text = 'من نحن';
      _aboutWhatMeansTitleEnCtrl.text = 'What does it mean to be an artist?';
      _aboutWhatMeansTitleArCtrl.text = 'ماذا يعني أن تكون فناناً؟';
      _aboutWhatMeansBodyEnCtrl.text =
          "The word artist has a long history. It is rooted in the idea of art and originally described people with exceptional knowledge, skills and abilities. Today, an artist is someone who creates, interprets and gives expression to ideas, emotions and visions.\n\nBut we believe art can be more.";
      _aboutWhatMeansBodyArCtrl.text =
          "إن كلمة فنان لها تاريخ طويل، وجذورها متأصلة في فكرة الفن، وكانت في الأصل تصف الأشخاص ذوي المعرفة والمهارات والقدرات الاستثنائية. اليوم، الفنان هو شخص يبدع ويفسر ويعبر عن الأفكار والمشاعر والرؤى.\n\nلكننا نؤمن بأن الفن يمكن أن يكون أكثر من ذلك.";
      _aboutQuoteTextEnCtrl.text =
          '“Art does not reproduce the visible; rather, it makes visible.”';
      _aboutQuoteTextArCtrl.text =
          '«الفن لا يعيد إنتاج المرئي، بل يجعله مرئياً.»';
      _aboutConnectBodyEnCtrl.text =
          'Our platform was created to connect artists across disciplines, cultures, languages and levels of experience. From photography, painting and music to sculpture, digital art and many other creative forms, our platform gives artists a place to discover, share, connect and collaborate.';
      _aboutConnectBodyArCtrl.text =
          'تم إنشاء منصتنا لربط الفنانين عبر مختلف التخصصات والثقافات واللغات ومستويات الخبرة. من التصوير الفوتوغرافي والرسم والموسيقى إلى النحت والفن الرقمي والعديد من الأشكال الإبداعية الأخرى، تمنح منصتنا الفنانين مساحة للاكتشاف والمشاركة والتواصل والتعاون.';
      _aboutOpportunitiesBodyEnCtrl.text =
          'Artists can explore different forms of art, discover galleries and art associations, connect directly with them, showcase their work and take part in events, competitions and creative challenges. Most importantly, the platform creates opportunities for meaningful exchange, inspiration and collaboration.';
      _aboutOpportunitiesBodyArCtrl.text =
          'يمكن للفنانين استكشاف أشكال مختلفة من الفن، واكتشاف صالات العرض والجمعيات الفنية، والتواصل معها مباشرة، وعرض أعمالهم والمشاركة في الفعاليات والمسابقات والتحديات الإبداعية. والأهم من ذلك، تخلق المنصة فرصاً للتبادل الهادف والإلهام والتعاون.';
      _aboutFusionBodyEnCtrl.text =
          "Because when different artists, cultures and creative perspectives come together, something new can emerge.\n\nPerhaps even a form of art that has never existed before.";
      _aboutFusionBodyArCtrl.text =
          "لأنه عندما يلتقي فنانون وثقافات ورؤى إبداعية مختلفة، يمكن أن يولد شيء جديد تماماً.\n\nوربما حتى شكل فني لم يكن موجوداً من قبل.";
      _aboutDubaiVisionBodyEnCtrl.text =
          "Dubai is a unique place for this vision. With people from more than 180 nationalities, countless cultures, languages and perspectives meet here. Art has the power to connect these differences and create something that belongs to everyone.\n\nOur digital world allows us to bring these creative forces together beyond borders and distances.";
      _aboutDubaiVisionBodyArCtrl.text =
          "دبي هي المكان الأمثل لتحقيق هذه الرؤية. مع وجود أشخاص من أكثر من 180 جنسية، تلتقي هنا ثقافات ولغات ورؤى لا حصر لها. يمتلك الفن القدرة على الجمع بين هذه الاختلافات وخلق شيء ينتمي للجميع.\n\nعالمنا الرقمي يتيح لنا جمع هذه الطاقات الإبداعية متجاوزين كل الحدود والمسافات.";
      _aboutOurVisionBodyEnCtrl.text =
          "Our vision is more than simply creating a platform for artists.\n\nWe want to create a space where encounters become inspiration, inspiration becomes collaboration, and collaboration becomes new art.";
      _aboutOurVisionBodyArCtrl.text =
          "رؤيتنا تتجاوز مجرد إنشاء منصة للفنانين.\n\nنريد خلق مساحة يتحول فيها اللقاء إلى إلهام، والإلهام إلى تعاون، والتعاون إلى فن جديد.";
      _aboutClosingBordersEnCtrl.text = 'Because art has no borders.';
      _aboutClosingBordersArCtrl.text = 'لأن الفن لا يعرف حدوداً.';
      _aboutClosingImpossibleEnCtrl.text =
          'And when people, ideas and talents come together, artists have the power to make the impossible possible.';
      _aboutClosingImpossibleArCtrl.text =
          'وعندما تجتمع العقول والأفكار والمواهب، يمتلك الفنانون القدرة على جعل المستحيل ممكناً.';
      for (final pair in _aboutUsFieldPairs) {
        _lastSyncedValues[pair.en] = pair.en.text;
        _lastSyncedValues[pair.ar] = pair.ar.text;
      }
      _isAutoSyncingAboutUs = false;
      setState(() {});
      await _saveAboutUsData();
    }
  }

  Widget _buildAboutTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
    bool isArabic = false,
  }) {
    return Column(
      crossAxisAlignment:
          isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isArabic
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!isArabic)
              Expanded(
                child: Text(
                  label.trData(context),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            if (_aboutAutoSyncEnabled)
              Container(
                margin: EdgeInsets.only(
                  left: isArabic ? 0 : 6,
                  right: isArabic ? 6 : 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isArabic
                      ? const Color(0xFFFAF5FF)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isArabic
                        ? const Color(0xFFE9D5FF)
                        : const Color(0xFFFDE68A),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 11,
                      color: isArabic
                          ? const Color(0xFF6A2777)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isArabic ? 'مزامنة إلى EN' : 'Syncs to AR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isArabic
                            ? const Color(0xFF6A2777)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            if (isArabic)
              Expanded(
                child: Text(
                  label.trData(context),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor:
                isArabic ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF6A2777),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF6A2777)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.trData(context),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAboutUsTab() {
    final isArabic = _aboutLanguageSubTab == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingAboutUs)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(
              color: Color(0xFF6A2777),
              backgroundColor: Color(0x336A2777),
            ),
          ),
        // ── Top Header Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A2777), Color(0xFF3B1E78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x266A2777),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Us Content Editor'.trData(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Modify live text, quotes, and vision sections for the public page'
                              .trData(context),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSavingAboutUs ? null : _saveAboutUsData,
                    icon: _isSavingAboutUs
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6A2777),
                          ),
                        )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                      _isSavingAboutUs
                          ? 'Saving...'.trData(context)
                          : 'Save Changes'.trData(context),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A2777),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.aboutUs),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Preview Page'.trData(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetAboutUsDefaults,
                    icon: const Icon(
                      Icons.restore_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Reset Defaults'.trData(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Auto-Sync Status & Action Banner ──
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _aboutAutoSyncEnabled
                ? const Color(0xFFFAF5FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _aboutAutoSyncEnabled
                  ? const Color(0xFFE9D5FF)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _aboutAutoSyncEnabled
                      ? const Color(0xFF6A2777).withValues(alpha: 0.12)
                      : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 18,
                  color: _aboutAutoSyncEnabled
                      ? const Color(0xFF6A2777)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Bidirectional Auto-Sync'.trData(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (_isSyncingAllAboutFields || _syncingFieldsCount > 0) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Translating...'.trData(context),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6A2777),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Changes in EN automatically update AR & vice versa'
                          .trData(context),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (_aboutAutoSyncEnabled)
                TextButton.icon(
                  onPressed: _isSyncingAllAboutFields
                      ? null
                      : () => _syncAllAboutFields(
                            fromEnglish: _aboutLanguageSubTab == 0,
                            showToast: true,
                          ),
                  icon: const Icon(Icons.bolt_rounded, size: 15),
                  label: Text(
                    _aboutLanguageSubTab == 0
                        ? 'Sync to AR'.trData(context)
                        : 'Sync to EN'.trData(context),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6A2777),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _aboutAutoSyncEnabled,
                  activeThumbColor: const Color(0xFF6A2777),
                  onChanged: (val) {
                    setState(() => _aboutAutoSyncEnabled = val);
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Language Selector Segmented Control ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_aboutLanguageSubTab != 0) {
                      if (_aboutAutoSyncEnabled) {
                        _syncAllAboutFields(fromEnglish: false);
                      }
                      setState(() => _aboutLanguageSubTab = 0);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !isArabic ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !isArabic
                          ? const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇬🇧', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'English (EN)'.trData(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !isArabic
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !isArabic
                                  ? const Color(0xFF6A2777)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_aboutLanguageSubTab != 1) {
                      if (_aboutAutoSyncEnabled) {
                        _syncAllAboutFields(fromEnglish: true);
                      }
                      setState(() => _aboutLanguageSubTab = 1);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isArabic ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isArabic
                          ? const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇦🇪', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'العربية (AR)'.trData(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isArabic
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isArabic
                                  ? const Color(0xFF6A2777)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 1. Header & Main Title ──
        _buildAboutSectionCard(
          title: 'Main Page Title',
          icon: Icons.title_rounded,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'عنوان الصفحة الرئيسي (بالعربية)' : 'Main Page Title (English)',
              controller: isArabic ? _aboutTitleArCtrl : _aboutTitleEnCtrl,
              hint: isArabic ? 'من نحن' : 'ABOUT US',
              isArabic: isArabic,
            ),
          ],
        ),

        // ── 2. Section 1: "What does it mean to be an artist?" ──
        _buildAboutSectionCard(
          title: 'Section 1: What Does It Mean To Be An Artist?',
          icon: Icons.brush_outlined,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'عنوان الفقرة الأولى' : 'Section 1 Title',
              controller:
                  isArabic
                      ? _aboutWhatMeansTitleArCtrl
                      : _aboutWhatMeansTitleEnCtrl,
              hint:
                  isArabic
                      ? 'ماذا يعني أن تكون فناناً؟'
                      : 'What does it mean to be an artist?',
              isArabic: isArabic,
            ),
            const SizedBox(height: 12),
            _buildAboutTextField(
              label: isArabic ? 'نص الفقرة الأولى' : 'Section 1 Body Text',
              controller:
                  isArabic
                      ? _aboutWhatMeansBodyArCtrl
                      : _aboutWhatMeansBodyEnCtrl,
              maxLines: 4,
              hint: isArabic ? 'نص التاريخ والمعنى...' : 'Historical meaning and creative expression...',
              isArabic: isArabic,
            ),
          ],
        ),

        // ── 3. Quote Callout Box ──
        _buildAboutSectionCard(
          title: 'Featured Quote Callout Box',
          icon: Icons.format_quote_rounded,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'نص الاقتباس البارز' : 'Featured Quote Text',
              controller:
                  isArabic ? _aboutQuoteTextArCtrl : _aboutQuoteTextEnCtrl,
              maxLines: 2,
              hint:
                  isArabic
                      ? '«الفن لا يعيد إنتاج المرئي، بل يجعله مرئياً.»'
                      : '“Art does not reproduce the visible; rather, it makes visible.”',
              isArabic: isArabic,
            ),
          ],
        ),

        // ── 4. Platform Connect & Opportunities ──
        _buildAboutSectionCard(
          title: 'Platform Purpose & Collaboration',
          icon: Icons.handshake_outlined,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'هدف المنصة والتواصل' : 'Connect & Collaborate Body Text',
              controller:
                  isArabic ? _aboutConnectBodyArCtrl : _aboutConnectBodyEnCtrl,
              maxLines: 4,
              hint: isArabic ? 'تم إنشاء منصتنا لربط الفنانين...' : 'Our platform was created to connect artists...',
              isArabic: isArabic,
            ),
            const SizedBox(height: 12),
            _buildAboutTextField(
              label: isArabic ? 'الفرص والاستكشاف' : 'Exploration & Opportunities Body Text',
              controller:
                  isArabic
                      ? _aboutOpportunitiesBodyArCtrl
                      : _aboutOpportunitiesBodyEnCtrl,
              maxLines: 4,
              hint: isArabic ? 'يمكن للفنانين استكشاف أشكال مختلفة...' : 'Artists can explore different forms of art...',
              isArabic: isArabic,
            ),
          ],
        ),

        // ── 5. Creative Fusion & Dubai Context ──
        _buildAboutSectionCard(
          title: 'Cultural Fusion & Dubai Context',
          icon: Icons.location_city_rounded,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'تلاقي الثقافات وتوليد الفن' : 'Fusion of Perspectives Body Text',
              controller:
                  isArabic ? _aboutFusionBodyArCtrl : _aboutFusionBodyEnCtrl,
              maxLines: 3,
              hint: isArabic ? 'لأنه عندما يلتقي فنانون وثقافات...' : 'Because when different artists come together...',
              isArabic: isArabic,
            ),
            const SizedBox(height: 12),
            _buildAboutTextField(
              label: isArabic ? 'رؤية دبي والبيئة متعددة الثقافات' : 'Dubai Vision & Cultural Context',
              controller:
                  isArabic
                      ? _aboutDubaiVisionBodyArCtrl
                      : _aboutDubaiVisionBodyEnCtrl,
              maxLines: 4,
              hint: isArabic ? 'دبي هي المكان الأمثل لتحقيق هذه الرؤية...' : 'Dubai is a unique place for this vision...',
              isArabic: isArabic,
            ),
          ],
        ),

        // ── 6. Vision & Closing Creed ──
        _buildAboutSectionCard(
          title: 'Vision & Closing Creed',
          icon: Icons.auto_awesome_rounded,
          children: [
            _buildAboutTextField(
              label: isArabic ? 'رؤيتنا المستقبلية' : 'Our Vision Body Text',
              controller:
                  isArabic ? _aboutOurVisionBodyArCtrl : _aboutOurVisionBodyEnCtrl,
              maxLines: 3,
              hint: isArabic ? 'رؤيتنا تتجاوز مجرد إنشاء منصة...' : 'Our vision is more than simply creating a platform...',
              isArabic: isArabic,
            ),
            const SizedBox(height: 12),
            _buildAboutTextField(
              label: isArabic ? 'شعار النهاية (الفن بلا حدود)' : 'Closing Tagline',
              controller:
                  isArabic
                      ? _aboutClosingBordersArCtrl
                      : _aboutClosingBordersEnCtrl,
              hint: isArabic ? 'لأن الفن لا يعرف حدوداً.' : 'Because art has no borders.',
              isArabic: isArabic,
            ),
            const SizedBox(height: 12),
            _buildAboutTextField(
              label: isArabic ? 'الخاتمة: صنع المستحيل' : 'Closing Impossible Statement',
              controller:
                  isArabic
                      ? _aboutClosingImpossibleArCtrl
                      : _aboutClosingImpossibleEnCtrl,
              maxLines: 3,
              hint: isArabic ? 'وعندما تجتمع العقول والأفكار والمواهب...' : 'And when people, ideas and talents come together...',
              isArabic: isArabic,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Bottom Save Action Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Changes are stored in MySQL and live broadcast to all devices instantly.'
                      .trData(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSavingAboutUs ? null : _saveAboutUsData,
                icon: _isSavingAboutUs
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(
                  _isSavingAboutUs
                      ? 'Saving...'.trData(context)
                      : 'Save Changes'.trData(context),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A2777),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    final storage = sl<StorageService>();
    final adminName = storage.getString('user_name') ?? 'Super Admin';
    final adminEmail =
        storage.getString('user_email') ?? 'admin@artistdubai.com';
    final adminRole =
        (storage.getString('user_role') ?? 'Administrator').toUpperCase();

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3B0744),
                    Color(0xFF6A2777),
                    Color(0xFF8B2C9E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Artist Dubai'.trData(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'Executive Console'.trData(context),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Admin User Profile Info Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            adminName.isNotEmpty
                                ? adminName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adminName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                adminEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                adminRole,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation Drawer Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: [
                  _buildDrawerSectionLabel(context, 'MANAGEMENT & CATALOG'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard Overview'.trData(context),
                    count: 'KPIs',
                    isSelected: _selectedTab == AdminTab.overview,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.overview);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_alt_rounded,
                    title: 'Artists Management'.trData(context),
                    count: '${_artists.length}',
                    isSelected: _selectedTab == AdminTab.artists,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.artists);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.event_available_rounded,
                    title: 'Events & Competitions'.trData(context),
                    count: '${_events.length}',
                    isSelected: _selectedTab == AdminTab.events,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.events);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.calendar_month_rounded,
                    title: 'Events Calendar'.trData(context),
                    count: 'View',
                    isSelected: _selectedTab == AdminTab.calendar,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.calendar);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.photo_library_rounded,
                    title: 'Galleries'.trData(context),
                    count: '${_galleries.length}',
                    isSelected: _selectedTab == AdminTab.galleries,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.galleries);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.museum_rounded,
                    title: 'Art Centers'.trData(context),
                    count: '${_artCenters.length}',
                    isSelected: _selectedTab == AdminTab.artCenters,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.artCenters);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_rounded,
                    title: 'Government & Hubs'.trData(context),
                    count: '${_govEntities.length}',
                    isSelected: _selectedTab == AdminTab.government,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.government);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),

                  _buildDrawerSectionLabel(context, 'PLATFORM & USERS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.tune_rounded,
                    title: 'Masters & Categories'.trData(context),
                    count: '${_categories.length + _experienceLevels.length}',
                    isSelected: _selectedTab == AdminTab.masters,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.masters);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Menu Permissions'.trData(context),
                    count: '$_activeMenuCount Active',
                    isSelected: _selectedTab == AdminTab.permissions,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.permissions);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_accounts_rounded,
                    title: 'Users & Purchased Plans'.trData(context),
                    count: '${_users.length}',
                    isSelected: _selectedTab == AdminTab.users,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.users);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About Us Content'.trData(context),
                    count: 'Live',
                    isSelected: _selectedTab == AdminTab.aboutUs,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedTab = AdminTab.aboutUs);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.delete_outline_rounded,
                    title: 'Recycle Bin'.trData(context),
                    count: 'Bin',
                    iconColor: const Color(0xFFDC2626),
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(RouteNames.adminRecycleBin);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),

                  _buildDrawerSectionLabel(context, 'SHORTCUTS & PORTAL'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Back to Home App'.trData(context),
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.home);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Art Guide'.trData(context),
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(RouteNames.ai);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Platform Settings'.trData(context),
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(RouteNames.settings);
                    },
                  ),
                ],
              ),
            ),

            // ── Drawer Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF6A2777),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Artist Dubai v2.4.0'.trData(context),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.home);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A2777).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6A2777).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.exit_to_app_rounded,
                            size: 13,
                            color: Color(0xFF6A2777),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Exit'.trData(context),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(
        label.trData(context),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? count,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color:
            isSelected
                ? const Color(0xFF6A2777).withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:
                  isSelected
                      ? Border.all(
                        color: const Color(0xFF6A2777).withValues(alpha: 0.25),
                        width: 1.2,
                      )
                      : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color:
                      isSelected
                          ? const Color(0xFF6A2777)
                          : (iconColor ?? const Color(0xFF64748B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isSelected
                              ? const Color(0xFF6A2777)
                              : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (count != null && count.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF6A2777)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
