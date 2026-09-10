import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
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

  bool _isSubmitting = false;
  bool _isSubmitted = false;

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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final publishingAmount = _galleryPricing?.getPriceForPlan(_selectedPublishingPlan) ??
          (_selectedPublishingPlan == 'monthly' ? 'AED 750' : (_selectedPublishingPlan == 'yearly' ? 'AED 6,500' : 'AED 200'));

      final success = await sl<ApiService>().registerGallery({
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
        'status': 'pending',
        'is_public': 0,
        'is_approved': 0,
        'publishing_plan': _selectedPublishingPlan,
        'publishing_amount': publishingAmount,
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
        if (success) {
          sl<LiveSyncService>().notifyGalleriesChanged();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    }
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
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5E227A)),
                          )
                        : const Text(
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
}
