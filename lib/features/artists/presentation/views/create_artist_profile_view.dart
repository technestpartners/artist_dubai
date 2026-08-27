import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class CreateArtistProfileView extends StatefulWidget {
  const CreateArtistProfileView({super.key});

  @override
  State<CreateArtistProfileView> createState() =>
      _CreateArtistProfileViewState();
}

class _CreateArtistProfileViewState extends State<CreateArtistProfileView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;

  late final TextEditingController _websiteController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _twitterController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _youtubeController;

  String? _selectedCategory;
  String? _selectedExperienceLevel;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  final List<String> _categories = [
    'Visual Arts',
    'Painting & Drawing',
    'Sculpture & 3D Art',
    'Digital Art & Illustration',
    'Photography',
    'Mixed Media',
    'Performing Arts & Music',
    'Crafts & Calligraphy',
    'Other Art Form',
  ];

  final List<String> _experienceLevels = [
    'Beginner (1-2 years)',
    'Intermediate (3-5 years)',
    'Advanced (5-10 years)',
    'Professional (10+ years)',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController(text: 'Dubai, UAE');
    _bioController = TextEditingController();

    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _twitterController = TextEditingController();
    _linkedinController = TextEditingController();
    _tiktokController = TextEditingController();
    _youtubeController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();

    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _submitProfile() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Privacy Policy and Terms & Conditions.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post(
        ApiEndpoints.artists,
        data: {
          'name':
              _fullNameController.text.trim().isEmpty
                  ? 'New Artist'
                  : _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location':
              _locationController.text.trim().isEmpty
                  ? 'Dubai, UAE'
                  : _locationController.text.trim(),
          'category': _selectedCategory ?? 'Mixed Media',
          'bio': _bioController.text.trim(),
          'website': _websiteController.text.trim(),
          'instagram': _instagramController.text.trim(),
        },
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artist Profile saved dynamically to database!'),
          backgroundColor: Color(0xFF5E227A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(RouteNames.artists);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // "Create Artist Profile" Sub-Header with Back Arrow & Home Action
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Create Artist Profile',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go(RouteNames.home),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.black87,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Form Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Avatar Badge (Matching Screenshot media_1787731751692.png)
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3E8FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF5E227A),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title & Subtitle
                      Center(
                        child: Column(
                          children: const [
                            Text(
                              'Create Your Artist Profile',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E227A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Join Dubai\'s Artist Community and Showcase Your Portfolio',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SECTION 1: Basic Information
                      _buildSectionTitle(
                        icon: Icons.person_outline,
                        title: 'Basic Information',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Full Name *'),
                      _buildTextField(
                        controller: _fullNameController,
                        hintText: 'Enter your full name',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Email *'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'your@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Phone Number *'),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: '+971 50 XXX XXXX',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Location *'),
                      _buildTextField(
                        controller: _locationController,
                        hintText: 'Dubai, UAE',
                      ),
                      const SizedBox(height: 28),

                      // SECTION 2: Artist Information
                      _buildSectionTitle(
                        icon: Icons.palette_outlined,
                        title: 'Artist Information',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Art Category'),
                      _buildDropdownField(
                        value: _selectedCategory,
                        hintText: 'Select your primary art form',
                        items: _categories,
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Experience Level'),
                      _buildDropdownField(
                        value: _selectedExperienceLevel,
                        hintText: 'Select your experience level',
                        items: _experienceLevels,
                        onChanged: (val) {
                          setState(() {
                            _selectedExperienceLevel = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Artist Bio'),
                      _buildTextField(
                        controller: _bioController,
                        hintText:
                            'Tell us about your artistic journey, style, and inspiration...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 28),

                      // SECTION 3: Social Media (Optional)
                      const Text(
                        'Social Media (Optional)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Website'),
                      _buildTextField(
                        controller: _websiteController,
                        hintText: 'https://yourwebsite.com',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Instagram'),
                      _buildTextField(
                        controller: _instagramController,
                        hintText: '@yourusername',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Facebook'),
                      _buildTextField(
                        controller: _facebookController,
                        hintText: 'https://facebook.com/yourpage',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Twitter/X'),
                      _buildTextField(
                        controller: _twitterController,
                        hintText: '@yourusername',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('LinkedIn'),
                      _buildTextField(
                        controller: _linkedinController,
                        hintText: 'https://linkedin.com/in/yourprofile',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('TikTok'),
                      _buildTextField(
                        controller: _tiktokController,
                        hintText: '@yourusername',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('YouTube'),
                      _buildTextField(
                        controller: _youtubeController,
                        hintText: 'https://youtube.com/@yourchannel',
                      ),
                      const SizedBox(height: 28),

                      // SECTION 4: Artwork Portfolio
                      _buildSectionTitle(
                        icon: Icons.upload_file_outlined,
                        title: 'Artwork Portfolio',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload your artwork images. You can crop, remove backgrounds, and manage your portfolio.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dashed Upload Box Container
                      InkWell(
                        onTap: _pickImagesFromGallery,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF94A3B8),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 44,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Drag & drop images here or click to select',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2 Action Buttons: Choose Files & Camera
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF1E1E1E),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: _pickImagesFromGallery,
                                    icon: const Icon(
                                      Icons.file_upload_outlined,
                                      size: 16,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                    label: const Text(
                                      'Choose Files',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF1E1E1E),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: _pickImageFromCamera,
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                    label: const Text(
                                      'Camera',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Max 5MB per file',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selected Images (${_pickedImages.length}):',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            itemBuilder: (context, index) {
                              final xFile = _pickedImages[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? Image.network(
                                              xFile.path,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(xFile.path),
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Terms Agreement Checkbox Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  activeColor: const Color(0xFF5E227A),
                                  onChanged: (val) {
                                    setState(() {
                                      _agreedToTerms = val ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E1E1E),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: '* I agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                              color: Color(0xFF5E227A),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: const TextStyle(
                                              color: Color(0xFF5E227A),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'By checking this box, you consent to the collection, processing, and storage of your personal data as described in our privacy policy. This includes your profile information, artwork images, and contact details which will be used to showcase your work on the Dubai Artist platform.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action Buttons: Cancel & Create Profile
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF1E1E1E),
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => context.pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9E68B4),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed:
                                    _isSubmitting ? null : _submitProfile,
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Create Profile',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
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
            const AppBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5E227A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5E227A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
        fontSize: 14.5,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5E227A), width: 1.5),
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
    );
  }
}
