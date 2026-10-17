import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

import '../../../../core/widgets/app_cached_image.dart';

import '../../../admin/domain/models/publishing_pricing_model.dart';
import '../../../chat/domain/models/listing_plan_model.dart';
import '../../domain/models/art_event_model.dart';
import '../../../../core/services/event_draft_service.dart';

class CreateArtEventView extends StatefulWidget {
  final ArtEventModel? event;
  final bool isCalendar;
  final bool fromAdmin;
  final bool showBottomBar;
  final Map<String, dynamic>? initialDraft;

  const CreateArtEventView({
    super.key,
    this.event,
    this.isCalendar = false,
    this.fromAdmin = false,
    this.showBottomBar = true,
    this.initialDraft,
  });

  @override
  State<CreateArtEventView> createState() => _CreateArtEventViewState();
}

class _CreateArtEventViewState extends State<CreateArtEventView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _eventTitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _locationController;
  late final TextEditingController _venueController;
  late final TextEditingController _organizerNameController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  late final TextEditingController _maxTicketsController;

  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  String? _selectedCategory;
  String? _selectedLocation = 'Dubai, UAE';
  bool _isSubmitting = false;

  String _selectedPublishingPlan = 'six_month';
  PublishingPricingModel? _eventPricing;
  StreamSubscription<List<PublishingPricingModel>>? _pricingSub;
  List<ListingPlanItem> _eventListingPlans = [];
  StreamSubscription<List<ListingPlanItem>>? _listingPlansSub;
  Map<String, dynamic>? _activeEventPlan;

  final _titleKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _dateKey = GlobalKey();
  final _endDateKey = GlobalKey();
  final _phoneKey = GlobalKey();

  final _titleFocusNode = FocusNode();
  final _dateFocusNode = FocusNode();
  final _endDateFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  String? _titleError;
  String? _categoryError;
  String? _dateError;
  String? _endDateError;
  String? _phoneError;

  final _transactionIdController = TextEditingController();
  String? _receiptUrl;

  List<String> _categories = [
    'Art Exhibition',
    'Gallery Opening',
    'Art Workshop',
    'Artist Talk',
    'Art Fair',
    'Sculpture Installation',
    'Photography Exhibition',
    'Cultural Festival',
    'Art Competition',
    'Community Art Project',
  ];

  List<String> _locations = [
    'Dubai, UAE',
    'Dubai Design District (d3), Dubai',
    'Alserkal Avenue, Al Quoz, Dubai',
    'Downtown Dubai, UAE',
    'DIFC, Dubai',
    'Al Shindagha Historic District, Dubai',
    'Jaddaf Waterfront, Dubai',
    'Madinat Jumeirah, Dubai',
    'Dubai Marina, UAE',
    'Palm Jumeirah, Dubai',
    'Jumeirah, Dubai',
    'Business Bay, Dubai',
    'Abu Dhabi, UAE',
    'Sharjah, UAE',
    'Ajman, UAE',
    'Ras Al Khaimah, UAE',
    'Fujairah, UAE',
    'Umm Al Quwain, UAE',
  ];

  String _normalizeDateTimeString(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final ddmmyyyy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    if (ddmmyyyy.hasMatch(trimmed)) {
      return '$trimmed 06:00 PM';
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    String prefilledOrganizer = 'Artist Dubai';
    String prefilledEmail = '';
    try {
      final storage = sl<StorageService>();
      final uName = storage.getString('user_name');
      final uEmail = storage.getString('user_email');
      if (uName != null && uName.isNotEmpty) prefilledOrganizer = uName;
      if (uEmail != null && uEmail.isNotEmpty) prefilledEmail = uEmail;
    } catch (_) {}

    final ev = widget.event;
    final draft = widget.initialDraft ??
        (ev == null ? EventDraftService.getDraft()?.rawFormData : null);

    if (draft != null && ev == null) {
      _eventTitleController =
          TextEditingController(text: draft['title']?.toString() ?? '');
      _descriptionController =
          TextEditingController(text: draft['description']?.toString() ?? '');
      _eventDateController = TextEditingController(
        text: _normalizeDateTimeString(draft['event_date']?.toString() ?? ''),
      );
      _endDateController = TextEditingController(
        text: _normalizeDateTimeString(draft['end_date']?.toString() ?? ''),
      );
      _selectedLocation =
          draft['location']?.toString() ?? 'Dubai, UAE';
      _locationController = TextEditingController(text: _selectedLocation);
      _venueController =
          TextEditingController(text: draft['venue']?.toString() ?? '');
      _organizerNameController = TextEditingController(
        text: draft['organizer_name']?.toString() ?? prefilledOrganizer,
      );
      _contactEmailController = TextEditingController(
        text: draft['contact_email']?.toString() ?? prefilledEmail,
      );
      _contactPhoneController =
          TextEditingController(text: draft['contact_phone']?.toString() ?? '');
      _notesController = TextEditingController();
      _tagsController =
          TextEditingController(text: draft['tags']?.toString() ?? '');
      _maxTicketsController = TextEditingController(
        text: draft['max_attendees']?.toString() ?? '100',
      );
      _selectedCategory = draft['category']?.toString();
      _uploadedImageUrl = draft['image_url']?.toString();
      if (_selectedLocation != null &&
          !_locations.contains(_selectedLocation)) {
        _locations.insert(0, _selectedLocation!);
      }
      if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory)) {
        _categories.insert(0, _selectedCategory!);
      }
      if (draft['planId'] != null && draft['planId'].toString().isNotEmpty) {
        _selectedPublishingPlan = draft['planId'].toString();
      }
    } else if (ev != null) {
      _eventTitleController = TextEditingController(text: ev.title);
      _descriptionController = TextEditingController(text: ev.description);
      _eventDateController = TextEditingController(
        text: _normalizeDateTimeString(
          ev.dateTime.isNotEmpty ? ev.dateTime : ev.formattedDate,
        ),
      );
      _endDateController = TextEditingController();
      _locationController = TextEditingController(text: ev.location);
      _venueController = TextEditingController(text: ev.locationCity ?? '');
      _organizerNameController = TextEditingController(
        text: ev.organizer.isNotEmpty ? ev.organizer : prefilledOrganizer,
      );
      _contactEmailController = TextEditingController(
        text:
            ev.organizerEmail != null && ev.organizerEmail!.isNotEmpty
                ? ev.organizerEmail!
                : prefilledEmail,
      );
      _contactPhoneController = TextEditingController();
      _notesController = TextEditingController(text: ev.requirements);
      _tagsController = TextEditingController(text: ev.tags.join(', '));
      _maxTicketsController = TextEditingController(
        text: ev.maxAttendees.toString(),
      );
      _selectedCategory = ev.category.isNotEmpty ? ev.category : null;
      _selectedLocation = ev.location.isNotEmpty ? ev.location : 'Dubai, UAE';
      if (_selectedLocation != null &&
          !_locations.contains(_selectedLocation)) {
        _locations.insert(0, _selectedLocation!);
      }
      _uploadedImageUrl = ev.imageUrl;
      if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory)) {
        _categories.insert(0, _selectedCategory!);
      }
      if (ev.publishingPlan != null && ev.publishingPlan!.isNotEmpty) {
        _selectedPublishingPlan = ev.publishingPlan!;
      }
      if (ev.paymentProofUrl != null && ev.paymentProofUrl!.isNotEmpty) {
        _receiptUrl = ev.paymentProofUrl;
      }
      if (ev.paymentReference != null && ev.paymentReference!.isNotEmpty) {
        _transactionIdController.text = ev.paymentReference!;
      }
    } else {
      _eventTitleController = TextEditingController();
      _descriptionController = TextEditingController();
      _eventDateController = TextEditingController();
      _endDateController = TextEditingController();
      _selectedLocation = 'Dubai, UAE';
      _locationController = TextEditingController(text: 'Dubai, UAE');
      _venueController = TextEditingController();
      _organizerNameController = TextEditingController(
        text: prefilledOrganizer,
      );
      _contactEmailController = TextEditingController(text: prefilledEmail);
      _contactPhoneController = TextEditingController();
      _notesController = TextEditingController();
      _tagsController = TextEditingController();
      _maxTicketsController = TextEditingController(text: '100');
    }
    _loadDynamicCategories();
    _loadDynamicLocations();
    _loadPublishingPricing();
    _loadEventListingPlans();
    _loadUserActiveEventPlan();

    try {
      _pricingSub = sl<LiveSyncService>().publishingPricingStream.listen((
        pricingList,
      ) {
        if (!mounted || pricingList.isEmpty) return;
        final evPricing = pricingList.firstWhere(
          (p) => p.itemType == 'event',
          orElse:
              () =>
                  _eventPricing ??
                  const PublishingPricingModel(
                    id: 1,
                    itemType: 'event',
                    itemName: 'Event Publishing',
                    weeklyPrice: 'AED 150',
                    monthlyPrice: 'AED 500',
                    sixMonthPrice: 'AED 2,500',
                    yearlyPrice: 'AED 4,500',
                    sixMonthBadge: '180 days active',
                    yearlyBadge: '365 days active',
                    description:
                        'Publishing events is a paid service on Artist Dubai. Select your preferred promotion duration. Once reviewed and approved by the admin, your event will be broadcasted to art enthusiasts across Dubai.',
                    currency: 'AED',
                  ),
        );
        setState(() {
          _eventPricing = evPricing;
        });
      });
    } catch (_) {}

    try {
      _listingPlansSub = sl<LiveSyncService>().listingPlansStream.listen((plans) {
        if (!mounted) return;
        final eventPlans = plans
            .where((p) =>
                p.isActive &&
                (p.itemType.toLowerCase() == 'event' ||
                    p.category.toLowerCase().contains('event') ||
                    p.title.toLowerCase().contains('event')))
            .toList();
        setState(() {
          _eventListingPlans = eventPlans;
          if (_eventListingPlans.isNotEmpty &&
              !_eventListingPlans.any((p) =>
                  p.id?.toString() == _selectedPublishingPlan ||
                  p.title == _selectedPublishingPlan)) {
            _selectedPublishingPlan =
                _eventListingPlans.first.id?.toString() ??
                    _eventListingPlans.first.title;
          }
        });
      });
    } catch (_) {}

    _eventTitleController.addListener(() {
      if (_titleError != null && _eventTitleController.text.trim().isNotEmpty) {
        setState(() => _titleError = null);
      }
    });
    _eventDateController.addListener(() {
      if (_dateError != null && _eventDateController.text.trim().isNotEmpty) {
        setState(() => _dateError = null);
      }
    });
    _endDateController.addListener(() {
      if (_endDateError != null) {
        setState(() => _endDateError = null);
      }
    });
    _contactPhoneController.addListener(() {
      if (_phoneError != null) {
        setState(() => _phoneError = _validatePhone(_contactPhoneController.text));
      }
    });
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      return isArabic
          ? 'رقم الهاتف لا يمكن أن يحتوي على أحرف'
          : 'Phone number cannot contain letters';
    }

    if (digitsOnly.length < 7) {
      return isArabic
          ? 'رقم الهاتف يجب أن يتكون من 7 أرقام على الأقل'
          : 'Phone number must be at least 7 digits';
    }
    if (digitsOnly.length > 15) {
      return isArabic
          ? 'رقم الهاتف لا يمكن أن يتجاوز 15 رقماً'
          : 'Phone number cannot exceed 15 digits';
    }
    return null;
  }

  void _scrollToField(GlobalKey key, {FocusNode? focusNode}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.15,
        );
      }
      if (focusNode != null) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            focusNode.requestFocus();
          }
        });
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _isUploadingImage = true;
        });

        final bytes = await picked.readAsBytes();
        final nameParts = picked.name.split('.');
        final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
        final url = await sl<ApiService>().uploadImageBytes(bytes, ext: ext);
        if (mounted) {
          setState(() {
            _uploadedImageUrl = url;
            _isUploadingImage = false;
          });
          if (url != null) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.eventImageUploadedSuccess),
                backgroundColor: const Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload Featured Image'.trData(context),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Choose from Gallery
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: Color(0xFF6A2777),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose from Gallery'.trData(context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select a banner or photo from your device'
                                      .trData(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Take a Photo
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF6A2777),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Take a Photo'.trData(context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Use your camera to capture an event image'
                                      .trData(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _loadDynamicCategories() async {
    try {
      final fetched = await sl<ApiService>().getEventCategories();
      final filtered =
          fetched.where((c) => c != 'All Categories' && c != 'All').toList();
      if (mounted && filtered.isNotEmpty) {
        setState(() {
          final combined = <String>{..._categories, ...filtered}.toList();
          _categories = combined;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDynamicLocations() async {
    try {
      final fetched = await sl<ApiService>().getLocations();
      final names =
          fetched.map((l) => l.name).where((n) => n.trim().isNotEmpty).toList();
      if (mounted && names.isNotEmpty) {
        setState(() {
          _locations = <String>{..._locations, ...names}.toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPublishingPricing() async {
    try {
      final pricingList = await sl<ApiService>().getPublishingPricing(
        forceRefresh: true,
      );
      final evPricing = pricingList.firstWhere(
        (p) => p.itemType == 'event',
        orElse:
            () => const PublishingPricingModel(
              id: 1,
              itemType: 'event',
              itemName: 'Event Publishing',
              weeklyPrice: 'AED 150',
              monthlyPrice: 'AED 500',
              sixMonthPrice: 'AED 2,500',
              yearlyPrice: 'AED 4,500',
              sixMonthBadge: '180 days active',
              yearlyBadge: '365 days active',
              description:
                  'Publishing events is a paid service on Artist Dubai. Select your preferred promotion duration. Once reviewed and approved by the admin, your event will be broadcasted to art enthusiasts across Dubai.',
              currency: 'AED',
            ),
      );
      if (mounted) {
        setState(() {
          _eventPricing = evPricing;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEventListingPlans() async {
    try {
      final plans = await sl<ApiService>().getListingPlans();
      if (!mounted) return;
      final eventPlans = plans
          .where((p) =>
              p.isActive &&
              (p.itemType.toLowerCase() == 'event' ||
                  p.category.toLowerCase().contains('event') ||
                  p.title.toLowerCase().contains('event')))
          .toList();
      setState(() {
        _eventListingPlans = eventPlans;
        if (_eventListingPlans.isNotEmpty &&
            !_eventListingPlans.any((p) =>
                p.id?.toString() == _selectedPublishingPlan ||
                p.title == _selectedPublishingPlan)) {
          _selectedPublishingPlan =
              _eventListingPlans.first.id?.toString() ??
                  _eventListingPlans.first.title;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadUserActiveEventPlan() async {
    try {
      final active = await sl<ApiService>().getActivePlanForType('event');
      if (mounted && active != null) {
        setState(() {
          _activeEventPlan = active;
          final planName = active['plan_name']?.toString();
          if (planName != null && planName.isNotEmpty) {
            _selectedPublishingPlan = planName;
          }
        });
        return;
      }
      final storage = sl<StorageService>();
      final local = storage.getString('active_plan_event');
      if (mounted && local != null && local.isNotEmpty) {
        setState(() {
          _activeEventPlan = {'plan_name': local, 'status': 'active'};
          _selectedPublishingPlan = local;
        });
      }
    } catch (_) {}
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hourOfPeriod = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$day-$month-$year $hour:$minute $period';
  }

  DateTime? _parseDateTimeString(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parts = trimmed.split(RegExp(r'\s+'));
      final dateParts = parts[0].split('-');
      if (dateParts.length == 3) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        int hour = 18;
        int minute = 0;
        if (parts.length > 1) {
          final timeParts = parts[1].split(':');
          if (timeParts.length >= 2) {
            hour = int.parse(timeParts[0]);
            minute = int.parse(timeParts[1]);
            if (parts.length > 2) {
              final ampm = parts[2].toUpperCase();
              if (ampm == 'PM' && hour < 12) hour += 12;
              if (ampm == 'AM' && hour == 12) hour = 0;
            }
          }
        }
        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime firstDate = now.subtract(const Duration(days: 1));
    DateTime initialDate = now;
    final isEndDate = controller == _endDateController;
    DateTime? startDate;

    TimeOfDay initialTime = const TimeOfDay(hour: 18, minute: 0);

    // Extract initial date and time from current controller text if available
    if (controller.text.trim().isNotEmpty) {
      final parsed = _parseDateTimeString(controller.text);
      if (parsed != null) {
        initialDate = parsed;
        initialTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    }

    if (isEndDate) {
      startDate = _parseDateTimeString(_eventDateController.text);
      if (startDate != null) {
        firstDate = DateTime(startDate.year, startDate.month, startDate.day);
        final currentEndDate = _parseDateTimeString(_endDateController.text);
        if (currentEndDate != null && !currentEndDate.isBefore(firstDate)) {
          initialDate = currentEndDate;
          initialTime = TimeOfDay(
            hour: currentEndDate.hour,
            minute: currentEndDate.minute,
          );
        } else {
          initialDate = firstDate;
          initialTime = TimeOfDay(
            hour: startDate.hour,
            minute: startDate.minute,
          );
        }
      }
    } else {
      final currentStartDate = _parseDateTimeString(_eventDateController.text);
      if (currentStartDate != null && !currentStartDate.isBefore(firstDate)) {
        initialDate = currentStartDate;
        initialTime = TimeOfDay(
          hour: currentStartDate.hour,
          minute: currentStartDate.minute,
        );
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A2777),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    if (isEndDate &&
        startDate != null &&
        pickedDate.year == startDate.year &&
        pickedDate.month == startDate.month &&
        pickedDate.day == startDate.day) {
      initialTime = TimeOfDay(hour: startDate.hour, minute: startDate.minute);
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A2777),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    // Guarantee that both Date AND Time are always populated (fallback to initialTime if time dialog dismissed)
    final effectiveTime = pickedTime ?? initialTime;
    final formatted = _formatDateTime(pickedDate, effectiveTime);

    setState(() {
      controller.text = formatted;
      if (!isEndDate) {
        _dateError = null;
      } else {
        _endDateError = null;
      }
      // If start date changed and is now after existing end date, sync end date to match start date
      if (!isEndDate && _endDateController.text.isNotEmpty) {
        final newStart = _parseDateTimeString(formatted);
        final currentEnd = _parseDateTimeString(_endDateController.text);
        if (newStart != null &&
            currentEnd != null &&
            currentEnd.isBefore(newStart)) {
          _endDateController.text = formatted;
        }
      }
      // If end date was picked and is earlier than start date/time, adjust and inform user
      if (isEndDate && _eventDateController.text.isNotEmpty) {
        final currentStart = _parseDateTimeString(_eventDateController.text);
        final newEnd = _parseDateTimeString(formatted);
        if (currentStart != null &&
            newEnd != null &&
            newEnd.isBefore(currentStart)) {
          controller.text = _eventDateController.text;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تاريخ ووقت الانتهاء يجب أن يكون في أو بعد تاريخ البدء'
                    : 'End date and time must be on or after the start date and time',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    _organizerNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _maxTicketsController.dispose();
    _transactionIdController.dispose();
    _titleFocusNode.dispose();
    _dateFocusNode.dispose();
    _endDateFocusNode.dispose();
    _phoneFocusNode.dispose();
    _pricingSub?.cancel();
    _listingPlansSub?.cancel();
    super.dispose();
  }

  void _submitEvent() async {
    final l10n = AppLocalizations.of(context);
    final title = _eventTitleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = l10n.enterEventTitle;
      });
      _scrollToField(_titleKey, focusNode: _titleFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterEventTitle),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      setState(() {
        _categoryError = l10n.selectCategory;
      });
      _scrollToField(_categoryKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCategory),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eventDate = _eventDateController.text.trim();
    if (eventDate.isEmpty) {
      setState(() {
        _dateError = l10n.selectEventDate;
      });
      _scrollToField(_dateKey, focusNode: _dateFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectEventDate),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final startDt = _parseDateTimeString(eventDate);
    final endDt = _parseDateTimeString(_endDateController.text.trim());
    if (startDt != null && endDt != null && endDt.isBefore(startDt)) {
      final msg =
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'تاريخ ووقت الانتهاء يجب أن يكون في أو بعد تاريخ البدء'
              : 'End date and time must be on or after the start date and time';
      setState(() {
        _endDateError = msg;
      });
      _scrollToField(_endDateKey, focusNode: _endDateFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phoneVal = _contactPhoneController.text.trim();
    final phoneErr = _validatePhone(phoneVal);
    if (phoneErr != null) {
      setState(() {
        _phoneError = phoneErr;
      });
      _scrollToField(_phoneKey, focusNode: _phoneFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneErr),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _titleError = null;
      _categoryError = null;
      _dateError = null;
      _endDateError = null;
      _phoneError = null;
      _isSubmitting = true;
    });

    try {
      final isEdit = widget.event != null;
      bool isAdmin = widget.fromAdmin;
      try {
        final storage = sl<StorageService>();
        if (!isAdmin) {
          isAdmin = storage.getBool('is_admin') ?? false;
        }
      } catch (_) {}

      final parsedCapacity =
          int.tryParse(_maxTicketsController.text.trim()) ?? 100;
      final selectedLoc =
          (_selectedLocation != null && _selectedLocation!.trim().isNotEmpty)
              ? _selectedLocation!.trim()
              : (_locationController.text.trim().isEmpty
                  ? 'Dubai, UAE'
                  : _locationController.text.trim());
      // Resolve dynamic plan selection from admin listing plans or baseline pricing
      String publishingAmount = 'AED 2,500';
      String resolvedPlanName = 'Event Publishing';

      if (_eventListingPlans.isNotEmpty) {
        final matchingPlan = _eventListingPlans.firstWhere(
          (p) =>
              p.id?.toString() == _selectedPublishingPlan ||
              p.title.toLowerCase() == _selectedPublishingPlan.toLowerCase(),
          orElse: () => _eventListingPlans.first,
        );
        publishingAmount = matchingPlan.price;
        resolvedPlanName = matchingPlan.title;
      } else {
        publishingAmount =
            _eventPricing?.getPriceForPlan(_selectedPublishingPlan) ??
            (_selectedPublishingPlan == 'monthly'
                ? 'AED 500'
                : (_selectedPublishingPlan == 'yearly'
                    ? 'AED 4,500'
                    : 'AED 2,500'));
        resolvedPlanName = _selectedPublishingPlan == 'yearly'
            ? (_eventPricing?.yearlyBadge.trim().isNotEmpty == true
                ? '${l10n.yearly} (${_eventPricing!.yearlyBadge.trim()})'
                : 'Yearly Plan (365 Days)')
            : (_eventPricing?.sixMonthBadge.trim().isNotEmpty == true
                ? '${l10n.sixMonths} (${_eventPricing!.sixMonthBadge.trim()})'
                : '6 Months Plan (180 Days)');
      }
      final txnRef = _transactionIdController.text.trim();
      final hasPaymentProof =
          (_receiptUrl != null && _receiptUrl!.isNotEmpty) || txnRef.isNotEmpty;

      final hasActiveEventPlan = _activeEventPlan != null;
      final effectivePaymentStatus = (isAdmin || hasActiveEventPlan)
          ? 'paid'
          : (hasPaymentProof ? 'submitted' : 'unpaid');
      final effectivePublishingPlan = hasActiveEventPlan
          ? (_activeEventPlan!['plan_name']?.toString() ?? resolvedPlanName)
          : resolvedPlanName;
      final effectivePublishingAmount = hasActiveEventPlan
          ? '0 AED (Included with ${_activeEventPlan!['plan_name'] ?? 'Active Plan'})'
          : publishingAmount;

      if (!isEdit && !isAdmin && !hasActiveEventPlan) {
        setState(() => _isSubmitting = false);

        final eventFormData = <String, dynamic>{
          'title': title,
          'description': _descriptionController.text.trim(),
          'category':
              _selectedCategory ??
              (_categories.isNotEmpty
                  ? _categories.first
                  : 'Art Exhibition'),
          'event_date': eventDate,
          'end_date': _endDateController.text.trim(),
          'location': selectedLoc,
          'venue': _venueController.text.trim(),
          'is_free': true,
          'price': 'Free Entry',
          'max_attendees': parsedCapacity,
          'organizer_name': _organizerNameController.text.trim(),
          'contact_email': _contactEmailController.text.trim(),
          'contact_phone': _contactPhoneController.text.trim(),
          'tags': _tagsController.text.trim(),
          'image_url': _uploadedImageUrl,
          'is_calendar': widget.isCalendar,
        };

        // Persist draft so user can resume anytime if they back out or close at payment
        await EventDraftService.saveDraft(
          title: title,
          subtitle: '${_selectedCategory ?? 'Art Exhibition'} • $selectedLoc',
          planId: _selectedPublishingPlan,
          planName: resolvedPlanName,
          planAmount: publishingAmount,
          formData: eventFormData,
          userEmail: _contactEmailController.text.trim(),
        );

        if (!mounted) return;
        context.push(
          RouteNames.planPayment,
          extra: {
            'itemType': 'event',
            'title': title,
            'subtitle':
                '${_selectedCategory ?? 'Art Exhibition'} • $selectedLoc',
            'planId': _selectedPublishingPlan,
            'planName': resolvedPlanName,
            'planAmount': publishingAmount,
            'formData': eventFormData,
          },
        );
        return;
      }

      bool success = false;

      if (isEdit) {
        success = await sl<ApiService>().updateEvent({
          'id': widget.event!.id,
          'title': title,
          'description': _descriptionController.text.trim(),
          'category':
              _selectedCategory ??
              (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          'event_date': eventDate,
          'end_date': _endDateController.text.trim(),
          'location': selectedLoc,
          'venue': _venueController.text.trim(),
          'price': 'Free Entry',
          'max_attendees': parsedCapacity,
          'tags': _tagsController.text.trim(),
          'publishing_plan': effectivePublishingPlan,
          'publishing_amount': effectivePublishingAmount,
          'payment_status': effectivePaymentStatus,
          if (_receiptUrl != null && _receiptUrl!.isNotEmpty)
            'payment_proof_url': _receiptUrl!,
          if (txnRef.isNotEmpty) 'payment_reference': txnRef,
          if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
            'image_url': _uploadedImageUrl!,
        });
      } else {
        success = await sl<ApiService>().createEvent(
          title: title,
          description: _descriptionController.text.trim(),
          category:
              _selectedCategory ??
              (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          eventDate: eventDate,
          endDate: _endDateController.text.trim(),
          location: selectedLoc,
          venue: _venueController.text.trim(),
          isFree: true,
          price: 'Free Entry',
          maxAttendees: parsedCapacity,
          organizerName: _organizerNameController.text.trim(),
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          tags: _tagsController.text.trim(),
          imageUrl: _uploadedImageUrl,
          status: isAdmin || hasActiveEventPlan ? 'active' : 'pending',
          isActive: isAdmin || hasActiveEventPlan,
          fromAdmin: isAdmin,
          publishingPlan: effectivePublishingPlan,
          publishingAmount: effectivePublishingAmount,
          paymentStatus: effectivePaymentStatus,
          paymentProofUrl: _receiptUrl,
          paymentReference: txnRef.isNotEmpty ? txnRef : null,
        );
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          sl<LiveSyncService>().notifyEventsChanged();

          if (isEdit || isAdmin) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isCalendar
                      ? (isEdit
                          ? l10n.calendarEventUpdatedSuccess
                          : l10n.eventScheduledSuccess)
                      : (isEdit
                          ? l10n.eventUpdatedSuccess
                          : l10n.eventCreatedSuccess),
                ),
                backgroundColor: const Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                widget.fromAdmin
                    ? RouteNames.adminDashboard
                    : RouteNames.myEvents,
              );
            }
          } else {
            // User submitted event request to admin
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFF6A2777),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Request Sent to Admin'.trData(context),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your event "$title" has been successfully submitted for administrative review.'
                              .trData(context),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Once approved by the admin, it will be published in the public directory.'
                                      .trData(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.myEvents);
                          }
                        },
                        child: Text(
                          'Close'.trData(context),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.go(RouteNames.myEvents);
                        },
                        child: Text(
                          'View My Events'.trData(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
            );
          }
        } else {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToSaveEvent),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.event != null;

    final appBarTitle =
        widget.isCalendar
            ? (isEdit ? l10n.editCalendarEvent : l10n.addToCalendar)
            : (isEdit ? l10n.editEvent : l10n.createEvent);

    final headerTitle =
        widget.isCalendar
            ? (isEdit
                ? l10n.headerEditCalendarEvent
                : l10n.headerScheduleCalendarEvent)
            : (isEdit ? l10n.headerEditArtEvent : l10n.headerCreateArtEvent);

    final headerSubtitle =
        widget.isCalendar
            ? (isEdit
                ? l10n.headerSubtitleCalendarEdit
                : l10n.headerSubtitleCalendarCreate)
            : (isEdit
                ? l10n.headerSubtitleEventEdit
                : l10n.headerSubtitleEventCreate);

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B1C9B),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                widget.fromAdmin
                    ? RouteNames.adminDashboard
                    : RouteNames.events,
              );
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          appBarTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: rh.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: rh.horizontalPadding,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6B1C9B,
                                    ).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.isCalendar
                                        ? Icons.calendar_month_rounded
                                        : Icons.event_note,
                                    color: const Color(0xFF6B1C9B),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        headerTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        headerSubtitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Featured Image Card
                          _buildCardSection(
                            title: l10n.featuredImage,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isUploadingImage) ...[
                                  Container(
                                    width: double.infinity,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Color(0xFF6A2777),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.uploadingImage,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else if (_selectedImage != null ||
                                    (_uploadedImageUrl != null &&
                                        _uploadedImageUrl!.isNotEmpty)) ...[
                                  Container(
                                    width: double.infinity,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child:
                                              _selectedImage != null
                                                  ? (kIsWeb
                                                      ? Image.network(
                                                        _selectedImage!.path,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Image.file(
                                                        File(
                                                          _selectedImage!.path,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ))
                                                  : AppCachedImage(
                                                    imageUrl:
                                                        _uploadedImageUrl!,
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImage = null;
                                                _uploadedImageUrl = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF6A2777,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF6A2777),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l10n.changeImage,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed:
                                            () => _showImageSourceActionSheet(
                                              context,
                                            ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.uploaded,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  LayoutBuilder(
                                    builder: (context, boxConstraints) {
                                      final isNarrow =
                                          boxConstraints.maxWidth < 360;
                                      final btn = OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF1E293B,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 20,
                                          color: Color(0xFF6A2777),
                                        ),
                                        label: Text(
                                          l10n.uploadImage,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed:
                                            () => _showImageSourceActionSheet(
                                              context,
                                            ),
                                      );

                                      final promptText = Text(
                                        l10n.uploadImagePrompt,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(
                                            0xFF64748B,
                                          ).withValues(alpha: 0.8),
                                        ),
                                      );

                                      if (isNarrow) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            btn,
                                            const SizedBox(height: 8),
                                            promptText,
                                          ],
                                        );
                                      }

                                      return Row(
                                        children: [
                                          btn,
                                          const SizedBox(width: 12),
                                          Expanded(child: promptText),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Event Information Card
                          _buildCardSection(
                            title: l10n.eventInformation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  l10n.eventTitle,
                                  isRequired: true,
                                  hasError: _titleError != null,
                                ),
                                _buildTextField(
                                  fieldKey: _titleKey,
                                  controller: _eventTitleController,
                                  focusNode: _titleFocusNode,
                                  errorText: _titleError,
                                  hintText: l10n.enterEventTitle,
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(
                                  l10n.categoryLabel,
                                  isRequired: true,
                                  hasError: _categoryError != null,
                                ),
                                _buildDropdownField(
                                  fieldKey: _categoryKey,
                                  value: _selectedCategory,
                                  hintText: l10n.selectCategory,
                                  items: _categories,
                                  errorText: _categoryError,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCategory = val;
                                      _categoryError = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(l10n.descriptionLabel),
                                _buildTextField(
                                  controller: _descriptionController,
                                  hintText: l10n.describeYourEvent,
                                  maxLines: 4,
                                  maxLength: 2000,
                                  showCounter: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Date & Time Card
                          _buildCardSection(
                            title: l10n.dateTime,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  l10n.startDateTime,
                                  isRequired: true,
                                  hasError: _dateError != null,
                                ),
                                _buildTextField(
                                  fieldKey: _dateKey,
                                  controller: _eventDateController,
                                  focusNode: _dateFocusNode,
                                  errorText: _dateError,
                                  hintText: 'dd-mm-yyyy hh:mm AM/PM',
                                  suffixIcon: Icons.calendar_today_outlined,
                                  onTap:
                                      () => _pickDateTime(_eventDateController),
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(
                                  l10n.endDateTimeOptional,
                                  hasError: _endDateError != null,
                                ),
                                _buildTextField(
                                  fieldKey: _endDateKey,
                                  controller: _endDateController,
                                  focusNode: _endDateFocusNode,
                                  errorText: _endDateError,
                                  hintText: 'dd-mm-yyyy hh:mm AM/PM',
                                  suffixIcon: Icons.calendar_today_outlined,
                                  onTap:
                                      () => _pickDateTime(_endDateController),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Location Card
                          _buildCardSection(
                            title: l10n.locationLabel,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(l10n.venueNameOptional),
                                _buildTextField(
                                  controller: _venueController,
                                  hintText: l10n.venueNameHint,
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(l10n.addressLocation),
                                _buildSearchableLocationField(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Additional Details Card
                          _buildCardSection(
                            title: l10n.additionalDetails,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(l10n.phoneOptional),
                                _buildTextField(
                                  fieldKey: _phoneKey,
                                  focusNode: _phoneFocusNode,
                                  controller: _contactPhoneController,
                                  hintText: '+971 50 123 4567',
                                  keyboardType: TextInputType.phone,
                                  errorText: _phoneError,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  validator: _validatePhone,
                                  onChanged: (val) {
                                    if (_phoneError != null) {
                                      setState(() => _phoneError = _validatePhone(val));
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(l10n.requirementsOptional),
                                _buildTextField(
                                  controller: _notesController,
                                  hintText: l10n.requirementsHint,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                _buildLabel(l10n.tagsOptional),
                                _buildTextField(
                                  controller: _tagsController,
                                  hintText: l10n.tagsHint,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Event Publishing Notice (Paid Service)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6B1C9B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.paidPublishing,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.choosePublishingPlan,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_activeEventPlan != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF10B981),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.verified,
                                              color: Color(0xFF059669),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Active Plan Applied: ${_activeEventPlan!['plan_name'] ?? 'Event Plan'}'
                                                    .trData(context),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF065F46),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '0 AED EXTRA'.trData(context),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your active subscription covers this event listing. No additional payment required.'
                                              .trData(context),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF047857),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.timer_outlined,
                                              size: 12,
                                              color: Color(0xFF047857),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _activeEventPlan!['duration_label'] != null
                                                  ? _activeEventPlan!['duration_label'].toString().trData(context)
                                                  : (_activeEventPlan!['days_left'] != null
                                                      ? '${_activeEventPlan!['days_left']} days remaining on this plan'.trData(context)
                                                      : (_activeEventPlan!['duration'] != null
                                                          ? _activeEventPlan!['duration'].toString().trData(context)
                                                          : 'Active Event Pass'.trData(context))),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_activeEventPlan == null) ...[
                                  const SizedBox(height: 8),
                                Text(
                                  _eventPricing?.description != null &&
                                          _eventPricing!.description!
                                              .trim()
                                              .isNotEmpty
                                      ? DataTranslator.tr(
                                        context,
                                        _eventPricing!.description!.trim(),
                                      )
                                      : l10n.paidPublishingDesc,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmall = constraints.maxWidth < 460;

                                    List<Widget> cards = [];
                                    if (_eventListingPlans.isNotEmpty) {
                                      cards = _eventListingPlans.map((plan) {
                                        final planId =
                                            plan.id?.toString() ?? plan.title;
                                        final subtitle = (plan.features.isNotEmpty &&
                                                plan.features.first.trim().isNotEmpty)
                                            ? plan.features.first.trim()
                                            : (plan.description.trim().isNotEmpty
                                                ? plan.description.trim()
                                                : (plan.category.trim().isNotEmpty
                                                    ? plan.category.trim()
                                                    : 'Verified Event Showcase'));
                                        return _buildPricingPlanCard(
                                          id: planId,
                                          title: plan.title,
                                          price: plan.price,
                                          period: '',
                                          subtitle: subtitle,
                                          tag:
                                              plan.badge.isNotEmpty
                                                  ? plan.badge
                                                  : null,
                                        );
                                      }).toList();
                                    } else {
                                      final sixMonthPrice =
                                          _eventPricing?.sixMonthPrice ??
                                          'AED 2,500';
                                      final yearlyPrice =
                                          _eventPricing?.yearlyPrice ??
                                          'AED 4,500';
                                      final sixMonthSubtitle =
                                          _eventPricing?.sixMonthBadge
                                                      .trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? DataTranslator.tr(
                                                context,
                                                _eventPricing!.sixMonthBadge
                                                    .trim(),
                                              )
                                              : l10n.daysActive180;
                                      final yearlySubtitle =
                                          _eventPricing?.yearlyBadge
                                                      .trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? DataTranslator.tr(
                                                context,
                                                _eventPricing!.yearlyBadge.trim(),
                                              )
                                              : l10n.daysActive365;

                                      cards = [
                                        _buildPricingPlanCard(
                                          id: 'six_month',
                                          title: l10n.sixMonths,
                                          price: sixMonthPrice,
                                          period: '/ 6 mo',
                                          subtitle: sixMonthSubtitle,
                                        ),
                                        _buildPricingPlanCard(
                                          id: 'yearly',
                                          title: l10n.yearly,
                                          price: yearlyPrice,
                                          period: '/ year',
                                          subtitle: yearlySubtitle,
                                        ),
                                      ];
                                    }

                                    if (isSmall || cards.length != 2) {
                                      return Column(
                                        children: [
                                          for (int i = 0;
                                              i < cards.length;
                                              i++) ...[
                                            if (i > 0)
                                              const SizedBox(height: 10),
                                            cards[i],
                                          ],
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
                              ],
                            ],
                          ),
                        ),
                          if (!widget.fromAdmin && !isEdit) ...[
                            _buildPaymentNoticeCard(),
                          ],
                          const SizedBox(height: 20),

                          // Action Row: Cancel & Update Event
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(
                                      widget.fromAdmin
                                          ? RouteNames.adminDashboard
                                          : RouteNames.events,
                                    );
                                  }
                                },
                                child: Text(
                                  l10n.cancel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6B1C9B),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : _submitEvent,
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF6B1C9B),
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                isEdit
                                                    ? (widget.isCalendar
                                                        ? l10n.updateCalendarEvent
                                                        : l10n.updateEvent)
                                                    : (widget.fromAdmin
                                                        ? (widget.isCalendar
                                                            ? l10n
                                                                .scheduleCalendarEvent
                                                            : l10n.createEvent)
                                                        : (_activeEventPlan != null
                                                            ? 'Publish Event (Covered by Plan)'
                                                                .trData(context)
                                                            : l10n
                                                                .proceedToPayment)),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isEdit &&
                                                !widget.fromAdmin) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 16,
                                                color: Color(0xFF6B1C9B),
                                              ),
                                            ],
                                          ],
                                        ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (!widget.fromAdmin && !widget.isCalendar && widget.showBottomBar)
              ? const AppBottomNavBar(currentIndex: 2)
              : null,
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentNoticeCard() {
    final l10n = AppLocalizations.of(context);
    String planAmount = 'AED 2,500';
    if (_eventListingPlans.isNotEmpty) {
      final matching = _eventListingPlans.firstWhere(
        (p) =>
            p.id?.toString() == _selectedPublishingPlan ||
            p.title.toLowerCase() == _selectedPublishingPlan.toLowerCase(),
        orElse: () => _eventListingPlans.first,
      );
      planAmount = matching.price;
    } else {
      planAmount =
          _eventPricing?.getPriceForPlan(_selectedPublishingPlan) ??
          (_selectedPublishingPlan == 'monthly'
              ? 'AED 500'
              : (_selectedPublishingPlan == 'six_month'
                  ? 'AED 2,500'
                  : (_selectedPublishingPlan == 'yearly'
                      ? 'AED 4,500'
                      : 'AED 150')));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment_rounded,
              color: Colors.amberAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: l10n.paymentOnNextStep,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: planAmount,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.paymentDetailsNotice,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
    String label, {
    bool isRequired = false,
    bool hasError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: hasError ? const Color(0xFFDC2626) : const Color(0xFF1E1E1E),
          ),
          children:
              isRequired
                  ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Key? fieldKey,
    FocusNode? focusNode,
    String? errorText,
    ValueChanged<String>? onChanged,
    IconData? prefixIcon,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
    VoidCallback? onTap,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: autovalidateMode,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: onTap != null,
      enableInteractiveSelection: onTap == null,
      onTap: onTap,
      onChanged: onChanged,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      style: const TextStyle(
        fontSize: 14.5,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        counterText: showCounter ? null : '',
        counterStyle: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.normal,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(
                  prefixIcon,
                  size: 18,
                  color:
                      hasError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                )
                : null,
        suffixIcon:
            suffixIcon != null
                ? Icon(
                  suffixIcon,
                  size: 18,
                  color:
                      hasError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6A2777),
                )
                : null,
        filled: true,
        fillColor: hasError ? const Color(0xFFFEF2F2) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            width: hasError ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFF6A2777),
            width: hasError ? 2 : 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
    );

    Widget content = field;
    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AbsorbPointer(absorbing: true, child: field),
        ),
      );
    }

    return AnimatedContainer(
      key: fieldKey,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            hasError
                ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: content,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Key? fieldKey,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final uniqueItems = items.toSet().toList();
    final validValue =
        (value != null && uniqueItems.contains(value)) ? value : null;

    final dropdown = DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 320,
      elevation: 4,
      hint: Text(
        hintText,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.normal,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF334155)),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1E293B),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: hasError ? const Color(0xFFFEF2F2) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            width: hasError ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFF5E227A),
            width: hasError ? 2 : 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
      selectedItemBuilder: (context) {
        return uniqueItems.map((item) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              DataTranslator.tr(context, item),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items:
          uniqueItems.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                DataTranslator.tr(context, item),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
    );

    return AnimatedContainer(
      key: fieldKey,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            hasError
                ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: dropdown,
    );
  }

  Widget _buildSearchableLocationField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l10n = AppLocalizations.of(context);
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _locations;
            }
            return _locations.where(
              (loc) =>
                  loc.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ) ||
                  DataTranslator.tr(
                    context,
                    loc,
                  ).toLowerCase().contains(textEditingValue.text.toLowerCase()),
            );
          },
          initialValue: TextEditingValue(
            text: DataTranslator.tr(context, _selectedLocation ?? 'Dubai, UAE'),
          ),
          onSelected: (String selection) {
            setState(() {
              _selectedLocation = selection;
              _locationController.text = selection;
            });
          },
          optionsMaxHeight: 250,
          optionsViewOpenDirection: OptionsViewOpenDirection.down,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchLocationHint,
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.normal,
                ),
                suffixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6A2777),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6A2777),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) {
                _selectedLocation = val;
                _locationController.text = val;
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      final isSelected = option == _selectedLocation;
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFF5EBF7)
                                    : Colors.transparent,
                            border:
                                index < options.length - 1
                                    ? const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFF1F5F9),
                                        width: 1,
                                      ),
                                    )
                                    : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color:
                                    isSelected
                                        ? const Color(0xFF6A2777)
                                        : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DataTranslator.tr(context, option),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color:
                                        isSelected
                                            ? const Color(0xFF6A2777)
                                            : const Color(0xFF1E293B),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF6A2777),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPricingPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? tag,
  }) {
    final isSelected = _selectedPublishingPlan == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPublishingPlan = id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6B1C9B) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B1C9B).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title.trData(context),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFF6B1C9B)
                            : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tag != null && tag.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF3E8FF)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD8B4FE)
                              : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tag.trData(context),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF6B1C9B)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF6B1C9B), Color(0xFF9333EA)],
                            )
                          : null,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.6,
                            ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price.trData(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (period.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      period.trData(context),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subtitle.trData(context),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
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
      ),
    );
  }
}
