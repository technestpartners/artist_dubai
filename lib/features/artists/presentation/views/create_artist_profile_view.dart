import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class CreateArtistProfileView extends StatefulWidget {
  const CreateArtistProfileView({super.key});

  @override
  State<CreateArtistProfileView> createState() =>
      _CreateArtistProfileViewState();
}

class ProfileArtworkItem {
  final XFile file;
  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController mediumController;
  final TextEditingController dimensionsController;
  final TextEditingController yearController;
  bool isFeatured;

  ProfileArtworkItem({
    required this.file,
    String? initialTitle,
    String? initialMedium,
    String? initialPrice,
    String? initialDimensions,
    String? initialYear,
    this.isFeatured = false,
  })  : titleController = TextEditingController(text: initialTitle ?? ''),
        priceController = TextEditingController(text: initialPrice ?? '\$3,200'),
        mediumController = TextEditingController(text: initialMedium ?? 'Oil on Canvas'),
        dimensionsController = TextEditingController(text: initialDimensions ?? '150 x 100 cm'),
        yearController = TextEditingController(text: initialYear ?? DateTime.now().year.toString());

  void dispose() {
    titleController.dispose();
    priceController.dispose();
    mediumController.dispose();
    dimensionsController.dispose();
    yearController.dispose();
  }
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
  final List<ProfileArtworkItem> _portfolioArtworks = [];

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            String baseTitle = img.name.split('.').first.replaceAll('_', ' ').replaceAll('-', ' ');
            if (baseTitle.isEmpty || baseTitle.startsWith('image_picker')) {
              baseTitle = 'Artwork Piece #${_portfolioArtworks.length + 1}';
            }
            _portfolioArtworks.add(ProfileArtworkItem(
              file: img,
              initialTitle: baseTitle,
              initialMedium: _selectedCategory ?? 'Mixed Media',
            ));
          }
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
          _portfolioArtworks.add(ProfileArtworkItem(
            file: image,
            initialTitle: 'Artwork Piece #${_portfolioArtworks.length + 1}',
            initialMedium: _selectedCategory ?? 'Mixed Media',
          ));
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
      _portfolioArtworks[index].dispose();
      _portfolioArtworks.removeAt(index);
    });
  }

  List<String> _categories = [
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
    String prefilledName = '';
    String prefilledEmail = '';
    try {
      final storage = sl<StorageService>();
      prefilledName = storage.getString('user_name') ?? '';
      prefilledEmail = storage.getString('user_email') ?? '';
    } catch (_) {}

    _fullNameController = TextEditingController(text: prefilledName);
    _emailController = TextEditingController(text: prefilledEmail);
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

    _loadDynamicData();
  }

  Future<void> _loadDynamicData() async {
    try {
      final catInfos = await sl<ApiService>().getCategories(type: 'artist');
      if (catInfos.isNotEmpty && mounted) {
        setState(() {
          _categories = catInfos.map((c) => c.name).toList();
        });
      }
    } catch (_) {}
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

    for (final art in _portfolioArtworks) {
      art.dispose();
    }
    super.dispose();
  }

  Future<void> _pickYear(TextEditingController controller) async {
    final now = DateTime.now();
    final parsedYear = int.tryParse(controller.text.trim()) ?? now.year;
    final initialDate = DateTime(parsedYear);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
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
    if (picked != null) {
      setState(() {
        controller.text = picked.year.toString();
      });
    }
  }

  void _submitProfile() async {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name or stage name.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      String? uploadedAvatar;
      String? uploadedBanner;

      // Upload artworks to server and collect their URLs & metadata
      final List<Map<String, dynamic>> uploadedArtworksData = [];

      if (_portfolioArtworks.isNotEmpty) {
        for (int i = 0; i < _portfolioArtworks.length; i++) {
          try {
            final artItem = _portfolioArtworks[i];
            final bytes = await artItem.file.readAsBytes();
            final nameParts = artItem.file.name.split('.');
            final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
            final url = await sl<ApiService>().uploadImageBytes(
              bytes,
              ext: ext.isNotEmpty ? ext : 'jpg',
            );
            if (url != null && url.isNotEmpty) {
              if (i == 0) uploadedAvatar = url;
              if (i == 1) uploadedBanner = url;
              uploadedArtworksData.add({
                'title': artItem.titleController.text.trim().isNotEmpty
                    ? artItem.titleController.text.trim()
                    : 'Artwork Piece #${i + 1}',
                'medium': artItem.mediumController.text.trim().isNotEmpty
                    ? artItem.mediumController.text.trim()
                    : 'Oil on Canvas',
                'price': artItem.priceController.text.trim().isNotEmpty
                    ? artItem.priceController.text.trim()
                    : '\$3,200',
                'dimensions': artItem.dimensionsController.text.trim().isNotEmpty
                    ? artItem.dimensionsController.text.trim()
                    : '150 x 100 cm',
                'year': artItem.yearController.text.trim().isNotEmpty
                    ? artItem.yearController.text.trim()
                    : DateTime.now().year.toString(),
                'is_featured': artItem.isFeatured,
                'image_url': url,
              });
            }
          } catch (_) {}
        }
      }

      final profileRes = await sl<ApiService>().createArtistProfile(
        name: name,
        category: _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Visual Arts'),
        location: _locationController.text.trim().isEmpty ? 'Dubai, UAE' : _locationController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        instagram: _instagramController.text.trim(),
        experienceLevel: _selectedExperienceLevel,
        avatarUrl: uploadedAvatar,
        bannerUrl: uploadedBanner,
      );

      if (profileRes != null) {
        final artistId = profileRes['artist_id']?.toString();

        // Insert artworks into MySQL artworks table
        for (final artData in uploadedArtworksData) {
          await sl<ApiService>().createArtwork(
            title: artData['title'].toString(),
            artistId: artistId,
            artistName: name,
            year: artData['year'].toString(),
            medium: artData['medium'].toString(),
            dimensions: artData['dimensions'].toString(),
            price: artData['price'].toString(),
            imageUrl: artData['image_url'].toString(),
            isFeatured: artData['is_featured'] == true,
          );
        }
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (profileRes != null) {
          sl<LiveSyncService>().notifyArtistsChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artist Profile & ${uploadedArtworksData.length} Artworks created successfully!'),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(RouteNames.artists);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile. Please check your inputs.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
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
                      if (_portfolioArtworks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Portfolio Artworks (${_portfolioArtworks.length}):',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pickImagesFromGallery,
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: Color(0xFF6A2777)),
                              label: const Text(
                                'Add More',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A2777),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _portfolioArtworks.length,
                          itemBuilder: (context, index) {
                            final artItem = _portfolioArtworks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Artwork Preview Image
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.network(
                                                artItem.file.path,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(artItem.file.path),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '#${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Editable Artwork Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: artItem.titleController,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                decoration: const InputDecoration(
                                                  hintText: 'Artwork Title',
                                                  hintStyle: TextStyle(
                                                    fontSize: 12.5,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  isDense: true,
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFF6A2777), width: 1.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Color(0xFFDC2626),
                                              ),
                                              onPressed: () => _removeImage(index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: artItem.mediumController,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: Color(0xFF334155),
                                                ),
                                                decoration: const InputDecoration(
                                                  hintText: 'Medium (e.g. Oil on Canvas)',
                                                  hintStyle: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  isDense: true,
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFF6A2777), width: 1.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: artItem.yearController,
                                                readOnly: true,
                                                onTap: () => _pickYear(artItem.yearController),
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: Color(0xFF334155),
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Year (e.g. 2026)',
                                                  hintStyle: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  suffixIcon: GestureDetector(
                                                    onTap: () => _pickYear(artItem.yearController),
                                                    child: const Icon(
                                                      Icons.calendar_today_outlined,
                                                      size: 14,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  isDense: true,
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                                    borderSide: BorderSide(color: Color(0xFF6A2777), width: 1.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: artItem.dimensionsController,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF334155),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Dimensions (e.g. 150 x 100 cm)',
                                            hintStyle: TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(6)),
                                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(6)),
                                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(6)),
                                              borderSide: BorderSide(color: Color(0xFF6A2777), width: 1.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              artItem.isFeatured = !artItem.isFeatured;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  artItem.isFeatured ? Icons.check_box : Icons.check_box_outline_blank,
                                                  size: 18,
                                                  color: artItem.isFeatured ? const Color(0xFF6A2777) : const Color(0xFF94A3B8),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Mark as Featured Artwork (show "Featured" badge)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF334155),
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
                            );
                          },
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
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5E227A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
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
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
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
  }
}
