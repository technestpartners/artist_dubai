import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../admin/domain/models/publishing_pricing_model.dart';

class GalleryRegistrationView extends StatefulWidget {
  const GalleryRegistrationView({super.key});

  @override
  State<GalleryRegistrationView> createState() => _GalleryRegistrationViewState();
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

  final bool _isSubmitted = false;

  String _selectedPublishingPlan = 'weekly';
  PublishingPricingModel? _galleryPricing;

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);
  static const Color _formCardBg = Color(0xFF5A1684);

  @override
  void initState() {
    super.initState();
    _loadPublishingPricing();
  }

  Future<void> _loadPublishingPricing() async {
    try {
      final pricingList = await sl<ApiService>().getPublishingPricing();
      final galPricing = pricingList.firstWhere(
        (p) => p.itemType == 'gallery',
        orElse: () => const PublishingPricingModel(
          id: 2,
          itemType: 'gallery',
          itemName: 'Gallery Showcase',
          weeklyPrice: 'AED 200',
          monthlyPrice: 'AED 750',
          yearlyPrice: 'AED 6,500',
          currency: 'AED',
        ),
      );
      if (mounted) {
        setState(() {
          _galleryPricing = galPricing;
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery photo uploaded successfully!'),
                backgroundColor: Color(0xFF6A2777),
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
      builder: (ctx) => SafeArea(
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
                  const Text(
                    'Select Image Source',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select a photo from your device library',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take a Photo',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Use your camera to capture space photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final publishingAmount = _galleryPricing?.getPriceForPlan(_selectedPublishingPlan) ??
        (_selectedPublishingPlan == 'monthly' ? 'AED 750' : (_selectedPublishingPlan == 'yearly' ? 'AED 6,500' : 'AED 200'));

    context.push(
      RouteNames.planPayment,
      extra: {
        'itemType': 'gallery',
        'title': _nameController.text.trim(),
        'subtitle': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Dubai, UAE',
        'planId': _selectedPublishingPlan,
        'planAmount': publishingAmount,
        'formData': {
          'name': _nameController.text.trim(),
          'category': _typeController.text.trim().isNotEmpty ? _typeController.text.trim() : 'Art Gallery',
          'type': _typeController.text.trim(),
          'address': _addressController.text.trim(),
          'location': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Dubai, UAE',
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
      errorStyle: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: _isSubmitted ? _buildSubmittedView() : _buildFormView(),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Title & Subtitle (Exact match to media_1788343870170.png)
          const Text(
            'GALLERIES | ART CENTERS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Register your gallery or art center to be listed in the app',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // 2. Form Container Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _formCardBg.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field 1: Gallery / center name *
                const Text(
                  'Gallery / center name *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  decoration: _whiteInputDecoration(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter gallery name' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 2: Type
                const Text(
                  'Type',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  decoration: _whiteInputDecoration(hintText: 'Gallery · Exhibition space · Studio'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 3: Address
                const Text(
                  'Address',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 4: Website
                const Text(
                  'Website',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _websiteController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  keyboardType: TextInputType.url,
                  decoration: _whiteInputDecoration(hintText: 'https://...'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 5: Contact person
                const Text(
                  'Contact person',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contactPersonController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 6: Email *
                const Text(
                  'Email *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _whiteInputDecoration(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter email';
                    if (!v.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 7: Phone
                const Text(
                  'Phone',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  keyboardType: TextInputType.phone,
                  decoration: _whiteInputDecoration(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Field 8: About the space
                const Text(
                  'About the space',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _aboutController,
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14),
                  maxLines: 4,
                  decoration: _whiteInputDecoration(),
                ),
                const SizedBox(height: 14),

                // Field 9: Gallery / Space Photo
                const Text(
                  'Gallery / Space Photo (Optional)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isUploadingImage) ...[
                        Row(
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Uploading image to server...',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ] else if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                _uploadedImageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 120,
                                  color: Colors.black26,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white54, size: 36),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _uploadedImageUrl = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Change Photo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              onPressed: () => _showImageSourceActionSheet(context),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
                            const SizedBox(width: 4),
                            const Text('Uploaded', style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.upload_outlined, size: 16),
                              label: const Text('Upload Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              onPressed: () => _showImageSourceActionSheet(context),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Select showcase photo of the gallery/space (JPG, PNG, WebP).',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Paid Publishing Service Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Paid Gallery Publishing • Choose Plan',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Publishing your gallery on Artist Dubai is a premium feature. Select your preferred showcase plan. Once verified by the admin, your gallery will be featured prominently to art lovers across the UAE.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmall = constraints.maxWidth < 460;
                          final weeklyPrice = _galleryPricing?.weeklyPrice ?? 'AED 200';
                          final monthlyPrice = _galleryPricing?.monthlyPrice ?? 'AED 750';
                          final yearlyPrice = _galleryPricing?.yearlyPrice ?? 'AED 6,500';

                          final cards = [
                            _buildGalleryPricingCard(
                              id: 'weekly',
                              title: 'Weekly',
                              price: weeklyPrice,
                              period: '/ week',
                              subtitle: '7 days showcase',
                              tag: null,
                            ),
                            _buildGalleryPricingCard(
                              id: 'monthly',
                              title: 'Monthly',
                              price: monthlyPrice,
                              period: '/ month',
                              subtitle: '30 days showcase',
                              tag: 'POPULAR',
                            ),
                            _buildGalleryPricingCard(
                              id: 'yearly',
                              title: 'Yearly',
                              price: yearlyPrice,
                              period: '/ year',
                              subtitle: '365 days showcase',
                              tag: 'BEST VALUE',
                            ),
                          ];

                          if (isSmall) {
                            return Column(
                              children: cards
                                  .map((c) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: c,
                                      ))
                                  .toList(),
                            );
                          }

                          return Row(
                            children: cards
                                .map((c) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: c,
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentNoticeCard(),
                const SizedBox(height: 16),

                // Field 9: Submit registration button (Exact match to screenshot)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E1E1E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      'Submit registration',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Footer Attribution
          const Center(
            child: Text(
              'Hosted by Nizar Fahem',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Title & Subtitle (Exact match to media_1788343894492.png)
        const Text(
          'GALLERIES | ART CENTERS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Registration',
          style: TextStyle(
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
                child: const Icon(
                  Icons.check,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Registration received',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Thank you. Our team will review your gallery or art center and get in touch by email.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.go(RouteNames.home),
                child: const Text(
                  'Back to home',
                  style: TextStyle(
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

        // 3. Footer
        const Center(
          child: Text(
            'Hosted by Nizar Fahem',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
    final isSelected = _selectedPublishingPlan == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPublishingPlan = id;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amberAccent : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF5A1684) : Colors.white,
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected ? const Color(0xFF5A1684) : Colors.white60,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isSelected ? const Color(0xFF64748B) : Colors.white70,
                  ),
                ),
              ],
            ),
            if (tag != null)
              Positioned(
                top: -6,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tag == 'POPULAR' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentNoticeCard() {
    final planAmount = _galleryPricing?.getPriceForPlan(_selectedPublishingPlan) ??
        (_selectedPublishingPlan == 'monthly' ? 'AED 750' : (_selectedPublishingPlan == 'yearly' ? 'AED 6,500' : 'AED 200'));

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
            child: const Icon(Icons.payment_rounded, color: Colors.amberAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Payment on Next Step: ',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    children: [
                      TextSpan(
                        text: planAmount,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.amberAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Admin Payment QR code & bank transfer details on checkout page.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white70),
        ],
      ),
    );
  }
}
