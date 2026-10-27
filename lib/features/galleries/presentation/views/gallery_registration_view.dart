import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../admin/domain/models/publishing_pricing_model.dart';
import '../../../chat/domain/models/listing_plan_model.dart';

class GalleryRegistrationView extends StatefulWidget {
  const GalleryRegistrationView({super.key});

  @override
  State<GalleryRegistrationView> createState() =>
      _GalleryRegistrationViewState();
}

class _GalleryRegistrationViewState extends State<GalleryRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();

  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  bool _hasValidated = false;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _activeGalleryPlan;
  Locale? _lastLocale;

  String _selectedPublishingPlan = '';
  PublishingPricingModel? _galleryPricing;
  StreamSubscription<List<PublishingPricingModel>>? _pricingSub;
  List<ListingPlanItem> _galleryListingPlans = (sl<ApiService>().cachedListingPlans ?? [])
      .where((p) =>
          p.isActive &&
          (p.itemType.toLowerCase() == 'gallery' ||
              (p.itemType.toLowerCase() != 'art_centre' &&
                  p.itemType.toLowerCase() != 'event' &&
                  p.category.toLowerCase().contains('gallery'))))
      .toList();
  StreamSubscription<List<ListingPlanItem>>? _listingPlansSub;

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);

  @override
  void initState() {
    super.initState();
    if (_galleryListingPlans.isNotEmpty) {
      _selectedPublishingPlan =
          _galleryListingPlans.first.id?.toString() ??
              _galleryListingPlans.first.title;
    }
    _loadPublishingPricing();
    _loadGalleryListingPlans();
    _loadUserActiveGalleryPlan();

    try {
      _pricingSub = sl<LiveSyncService>().publishingPricingStream.listen((
        pricingList,
      ) {
        if (!mounted || pricingList.isEmpty) return;
        final galPricing = pricingList.where((p) => p.itemType == 'gallery').firstOrNull;
        if (galPricing != null) {
          setState(() {
            _galleryPricing = galPricing;
          });
        }
      });
    } catch (_) {}

    try {
      _listingPlansSub = sl<LiveSyncService>().listingPlansStream.listen((plans) {
        if (!mounted) return;
        final galPlans = plans
            .where((p) =>
                p.isActive &&
                (p.itemType.toLowerCase() == 'gallery' ||
                    (p.itemType.toLowerCase() != 'art_centre' &&
                        p.itemType.toLowerCase() != 'event' &&
                        p.category.toLowerCase().contains('gallery'))))
            .toList();
        setState(() {
          _galleryListingPlans = galPlans;
          if (_galleryListingPlans.isNotEmpty &&
              !_galleryListingPlans.any((p) =>
                  p.id?.toString() == _selectedPublishingPlan ||
                  p.title == _selectedPublishingPlan)) {
            _selectedPublishingPlan =
                _galleryListingPlans.first.id?.toString() ??
                    _galleryListingPlans.first.title;
          }
        });
      });
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale != null &&
        _lastLocale?.languageCode != currentLocale.languageCode) {
      if (_hasValidated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasValidated) {
            _formKey.currentState?.validate();
          }
        });
      }
    }
    _lastLocale = currentLocale;
  }

  Future<void> _loadPublishingPricing() async {
    try {
      final pricingList = await sl<ApiService>().getPublishingPricing(
        forceRefresh: true,
      );
      final galPricing =
          pricingList.where((p) => p.itemType == 'gallery').firstOrNull;
      if (mounted && galPricing != null) {
        setState(() {
          _galleryPricing = galPricing;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGalleryListingPlans() async {
    try {
      final plans = await sl<ApiService>().getListingPlans();
      if (!mounted) return;
      final galPlans = plans
          .where((p) =>
              p.isActive &&
              (p.itemType.toLowerCase() == 'gallery' ||
                  (p.itemType.toLowerCase() != 'art_centre' &&
                      p.itemType.toLowerCase() != 'event' &&
                      p.category.toLowerCase().contains('gallery'))))
          .toList();
      setState(() {
        _galleryListingPlans = galPlans;
        if (_galleryListingPlans.isNotEmpty &&
            !_galleryListingPlans.any((p) =>
                p.id?.toString() == _selectedPublishingPlan ||
                p.title == _selectedPublishingPlan)) {
          _selectedPublishingPlan =
              _galleryListingPlans.first.id?.toString() ??
                  _galleryListingPlans.first.title;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadUserActiveGalleryPlan() async {
    try {
      final active = await sl<ApiService>().getActivePlanForType('gallery');
      if (mounted && active != null) {
        setState(() {
          _activeGalleryPlan = active;
          final planName = active['plan_name']?.toString();
          if (planName != null && planName.isNotEmpty) {
            _selectedPublishingPlan = planName;
          }
        });
        return;
      }
      final storage = sl<StorageService>();
      final local = storage.getString('active_plan_gallery');
      if (mounted && local != null && local.isNotEmpty) {
        setState(() {
          _activeGalleryPlan = {'plan_name': local, 'status': 'active'};
          _selectedPublishingPlan = local;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _pricingSub?.cancel();
    _listingPlansSub?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
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
                content: Text(l10n.galleryPhotoUploadedSuccess),
                backgroundColor: const Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isUploadingImage = false);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Image Source'.trData(context),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                              color: const Color(0xFFEDE9FE),
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
                                  'Select a photo from your device library'
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
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                                  'Use your camera to capture space photo'
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

  void _submitForm() async {
    setState(() => _hasValidated = true);
    if (!_formKey.currentState!.validate()) return;

    String publishingAmount = 'Free';
    String resolvedPlanName = 'Standard Gallery Registration';
    if (_galleryListingPlans.isNotEmpty) {
      final matchingPlan = _galleryListingPlans.firstWhere(
        (p) =>
            p.id?.toString() == _selectedPublishingPlan ||
            p.title == _selectedPublishingPlan,
        orElse: () => _galleryListingPlans.first,
      );
      publishingAmount = matchingPlan.price;
      resolvedPlanName = matchingPlan.title;
    }

    final hasActiveGalleryPlan = _activeGalleryPlan != null;
    final isPaidPlan = _galleryListingPlans.isNotEmpty &&
        publishingAmount.toLowerCase() != 'free' &&
        publishingAmount != '0 AED';

    if (hasActiveGalleryPlan || !isPaidPlan) {
      setState(() => _isSubmitting = true);
      final payload = {
        'name': _nameController.text.trim(),
        'category':
            _typeController.text.trim().isNotEmpty
                ? _typeController.text.trim()
                : 'Art Gallery',
        'type': _typeController.text.trim(),
        'address': _addressController.text.trim(),
        'location':
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : 'Dubai, UAE',
        'website': _websiteController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'about': _aboutController.text.trim(),
        'image_url': _uploadedImageUrl ?? '',
        'publishing_plan':
            hasActiveGalleryPlan
                ? (_activeGalleryPlan!['plan_name'] ?? resolvedPlanName)
                : resolvedPlanName,
        'payment_status': 'paid',
        'payment_method': hasActiveGalleryPlan ? 'active_plan' : 'standard_registration',
      };

      final success = await sl<ApiService>().registerGallery(payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          try {
            sl<LiveSyncService>().notifyGalleriesChanged();
          } catch (_) {}
          setState(() => _isSubmitted = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration failed. Please try again.'.trData(context),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    context.push(
      RouteNames.planPayment,
      extra: {
        'itemType': 'gallery',
        'title': _nameController.text.trim(),
        'subtitle':
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : 'Dubai, UAE',
        'planId': _selectedPublishingPlan,
        'planName': resolvedPlanName,
        'planAmount': publishingAmount,
        'formData': {
          'name': _nameController.text.trim(),
          'category':
              _typeController.text.trim().isNotEmpty
                  ? _typeController.text.trim()
                  : 'Art Gallery',
          'type': _typeController.text.trim(),
          'address': _addressController.text.trim(),
          'location':
              _addressController.text.trim().isNotEmpty
                  ? _addressController.text.trim()
                  : 'Dubai, UAE',
          'website': _websiteController.text.trim(),
          'contact_person': _contactPersonController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'about': _aboutController.text.trim(),
          'image_url': _uploadedImageUrl ?? '',
        },
      },
    );
  }

  InputDecoration _whiteInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5E227A), width: 1.8),
      ),
      errorStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // "Art Venue" Sub-Header with Back Arrow & Home Action
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rh.horizontalPadding,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.home);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.artVenue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: rh.isCompact ? 15 : 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go(RouteNames.home),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.home,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    rh.horizontalPadding,
                    20,
                    rh.horizontalPadding,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                      child: _isSubmitted ? _buildSubmittedView() : _buildFormView(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildFormView() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Title & Subtitle
          Text(
            l10n.artVenue,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.artVenueSubtitle,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // 2. Form Container Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field 1: Gallery / center name *
                Text(
                  '${l10n.galleryCenterName} *',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _whiteInputDecoration(),
                  validator: (v) {
                    final isAr =
                        Localizations.localeOf(context).languageCode == 'ar';
                    if (v == null || v.trim().isEmpty) {
                      return isAr
                          ? 'الرجاء إدخال اسم المعرض'
                          : 'Please enter gallery name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 2: Type
                Text(
                  l10n.venueType,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _whiteInputDecoration(
                    hintText: l10n.venueTypeHint,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 3: Address
                Text(
                  l10n.address,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 4: Website
                Text(
                  l10n.website,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _websiteController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.url,
                  decoration: _whiteInputDecoration(hintText: 'https://...'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 5: Contact person
                Text(
                  l10n.contactPerson,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contactPersonController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 6: Email *
                Text(
                  '${l10n.emailLabel} *',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _whiteInputDecoration(),
                  validator: (v) {
                    final isAr =
                        Localizations.localeOf(context).languageCode == 'ar';
                    if (v == null || v.trim().isEmpty) {
                      return isAr
                          ? 'الرجاء إدخال البريد الإلكتروني'
                          : 'Please enter email';
                    }
                    if (!v.contains('@')) {
                      return isAr
                          ? 'الرجاء إدخال بريد إلكتروني صالح'
                          : 'Please enter valid email';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 7: Phone
                Text(
                  l10n.phone,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\+\s\-\(\)]'),
                    ),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 8: About the space
                Text(
                  l10n.aboutTheSpace,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _aboutController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 4,
                  decoration: _whiteInputDecoration(),
                ),
                const SizedBox(height: 14),

                // Field 9: Gallery / Space Photo
                Text(
                  l10n.gallerySpacePhotoOptional,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isUploadingImage) ...[
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.uploadingImage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_uploadedImageUrl != null &&
                          _uploadedImageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                _uploadedImageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      height: 120,
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap:
                                      () => setState(() {
                                        _uploadedImageUrl = null;
                                      }),
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Change Photo'.trData(context),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed:
                                  () => _showImageSourceActionSheet(context),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4ADE80),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uploaded'.trData(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4ADE80),
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
                            final isNarrow = boxConstraints.maxWidth < 360;
                            final btn = OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Upload Photo'.trData(context),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed:
                                  () => _showImageSourceActionSheet(context),
                            );

                            final promptText = Text(
                              'Select showcase photo of the gallery/space (JPG, PNG, WebP).'
                                  .trData(context),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),

                // Paid Publishing Service Notice (hidden if user already has an active plan)
                if (_activeGalleryPlan == null) ...[
                  Container(
                    width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B1C9B), Color(0xFF551478)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B1C9B).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          Text(
                            'Art Venue Listing'.trData(
                              context,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'Choose Your Plan'.trData(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _galleryPricing?.description != null &&
                                _galleryPricing!.description!.trim().isNotEmpty &&
                                !_galleryPricing!.description!
                                    .toLowerCase()
                                    .contains('feature your gallery on curated maps')
                            ? DataTranslator.tr(
                              context,
                              _galleryPricing!.description!.trim(),
                            )
                            : 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!'
                                .trData(context),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Exclusive Benefits:'.trData(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: 'Enjoy your first 3 months free.'.trData(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (_galleryListingPlans.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No paid gallery plans currently configured by administrator. Standard registration applies.'
                                          .trData(context),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final cards = _galleryListingPlans.map((plan) {
                            final planId =
                                plan.id?.toString() ?? plan.title;
                            final subtitle = (plan.features.isNotEmpty &&
                                    plan.features.first.trim().isNotEmpty)
                                ? plan.features.first.trim()
                                : (plan.description.trim().isNotEmpty
                                    ? plan.description.trim()
                                    : (plan.duration.isNotEmpty
                                        ? plan.duration
                                        : 'Gallery Showcase'));
                            final rawTitle = plan.title.trData(context);
                            final cardTitle = (plan.duration.contains('3 Month') || plan.duration.contains('90') || rawTitle.contains('3 Month'))
                                ? '3 Months'.trData(context)
                                : ((plan.duration.contains('6 Month') || plan.duration.contains('180') || rawTitle.contains('6 Month'))
                                    ? '6 Months'.trData(context)
                                    : ((plan.duration.contains('12 Month') || plan.duration.contains('365') || plan.duration.contains('1 Year') || rawTitle.contains('12 Month'))
                                        ? '12 Months'.trData(context)
                                        : rawTitle));
                            final periodStr = (cardTitle == '3 Months' || cardTitle == '6 Months' || cardTitle == '12 Months')
                                ? ''
                                : (plan.duration.isNotEmpty ? ' · ${plan.duration}' : '');
                            return _buildGalleryPricingCard(
                              id: planId,
                              title: cardTitle,
                              price: plan.price,
                              period: periodStr,
                              subtitle: subtitle,
                              tag:
                                  plan.badge.isNotEmpty ? plan.badge : null,
                            );
                          }).toList();

                          return Column(
                            children: [
                              for (int i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                cards[i],
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildPaymentNoticeCard(),
                const SizedBox(height: 18),

                // Field 9: Submit registration button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5E227A),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.add_business_rounded,
                            size: 18,
                            color: Color(0xFF5E227A),
                          ),
                    label: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFF5E227A),
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            _activeGalleryPlan != null
                                ? 'Register Venue (Covered by Active Plan)'
                                    .trData(context)
                                : l10n.registerVenue,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5E227A),
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubmittedView() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Title & Subtitle
        Text(
          l10n.artVenue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Registration'.trData(context),
          style: const TextStyle(
            fontSize: 14.5,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        // 2. Center Registration Received Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
                child: const Icon(Icons.check, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                'Registration received'.trData(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Thank you. Our team will review your gallery or art center and get in touch by email.'
                    .trData(context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.go(RouteNames.home),
                child: Text(
                  'Back to home'.trData(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGalleryPricingCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? tag,
  }) {
    final isSelected = _selectedPublishingPlan == id ||
        _selectedPublishingPlan.toLowerCase() == title.toLowerCase() ||
        (_selectedPublishingPlan.contains('3') && (title.contains('3') || id.contains('3') || id == 'three_month')) ||
        (_selectedPublishingPlan.contains('6') && (title.contains('6') || id.contains('6') || id == 'six_month')) ||
        ((_selectedPublishingPlan.contains('12') || _selectedPublishingPlan.contains('year')) && (title.contains('12') || id.contains('12') || id == 'yearly'));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPublishingPlan = id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF9333EA)
                  : Colors.white.withValues(alpha: 0.20),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5E227A).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, cardConstraints) {
              final isCompactCard = cardConstraints.maxWidth < 280;

              final radioCheck = AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
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
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 1.8,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9333EA)
                                .withValues(alpha: 0.40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              );

              final tagBadge = (tag != null && tag.isNotEmpty)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6B1C9B),
                                  Color(0xFF9333EA),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.12),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF9333EA)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFE9D5FF),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              tag.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFE9D5FF),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null;

              final priceWidget = Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price.trData(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? const Color(0xFF5E227A)
                          : Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (period.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      period.trData(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF64748B)
                            : Colors.white70,
                      ),
                    ),
                  ],
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompactCard) ...[
                    // Standard Row: Title + Tag on start, Price + Radio on end
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                title.trData(context),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? const Color(0xFF1E1B4B)
                                      : Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (tagBadge != null) tagBadge,
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        priceWidget,
                        const SizedBox(width: 10),
                        radioCheck,
                      ],
                    ),
                  ] else ...[
                    // Compact Row for ultra-narrow devices (300px)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                title.trData(context),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? const Color(0xFF1E1B4B)
                                      : Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (tagBadge != null) tagBadge,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        radioCheck,
                      ],
                    ),
                    const SizedBox(height: 6),
                    priceWidget,
                  ],
                  const SizedBox(height: 10),

                  // Subtle Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: isSelected
                        ? const Color(0xFFF1E8FB)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 9),

                  // Subtitle / Key Benefit Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(
                            alpha: isSelected ? 0.15 : 0.25,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          subtitle.trData(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF475569)
                                : Colors.white.withValues(alpha: 0.90),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentNoticeCard() {
    if (_activeGalleryPlan != null) {
      final planName =
          _activeGalleryPlan!['plan_name']?.toString() ?? 'Gallery Plan';
      final rawDays = _activeGalleryPlan!['days_left'];
      final int? daysNum = rawDays != null ? int.tryParse(rawDays.toString()) : null;
      final durLabel = _activeGalleryPlan!['duration_label']?.toString() ??
          _activeGalleryPlan!['duration']?.toString() ??
          (daysNum != null && daysNum > 0
              ? (daysNum >= 330 ? '$daysNum days (~1 year) remaining' : '$daysNum days remaining')
              : '1 Year (365 Days)');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Color(0xFF059669), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Plan Applied: $planName'.trData(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your active subscription covers this venue listing at 0 AED ($durLabel).'
                        .trData(context),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String planAmount = '';
    String resolvedPlanName = _selectedPublishingPlan;
    if (_galleryListingPlans.isNotEmpty) {
      final matching = _galleryListingPlans.firstWhere(
        (p) =>
            p.id?.toString() == _selectedPublishingPlan ||
            p.title.toLowerCase() == _selectedPublishingPlan.toLowerCase() ||
            (_selectedPublishingPlan.contains('3') && p.title.contains('3')) ||
            (_selectedPublishingPlan.contains('6') && p.title.contains('6')) ||
            ((_selectedPublishingPlan.contains('12') || _selectedPublishingPlan.contains('year')) &&
                (p.title.contains('12') || p.title.toLowerCase().contains('year'))),
        orElse: () => _galleryListingPlans.first,
      );
      planAmount = matching.price;
      resolvedPlanName = matching.title;
    } else {
      planAmount = _galleryPricing?.getPriceForPlan(_selectedPublishingPlan) ?? '';
      resolvedPlanName = 'Gallery Showcase';
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _proceedToStripeCheckout(planAmount, resolvedPlanName),
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFF635BFF).withValues(alpha: 0.35),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF635BFF).withValues(alpha: 0.32),
                const Color(0xFF4F46E5).withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF9384FF).withValues(alpha: 0.55),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF635BFF).withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stripe / Card Icon badge
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF635BFF), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF635BFF).withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          'Pay with Stripe: '.trData(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            planAmount.trData(context),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct secure checkout with Credit Card, Apple Pay & Google Pay'
                          .trData(context),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Powered by Stripe • Tap to proceed'.trData(context),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToStripeCheckout(String planAmount, String planName) {
    if (_activeGalleryPlan != null) {
      _submitForm();
      return;
    }

    setState(() => _hasValidated = true);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete the required venue details above to proceed to Stripe checkout.'
                .trData(context),
          ),
          backgroundColor: const Color(0xFF635BFF),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    _submitForm();
  }
}
