import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

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

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);
  static const Color _formCardBg = Color(0xFF5A1684);

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
                const SizedBox(height: 20),

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
}
