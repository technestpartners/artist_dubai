import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/artist_model.dart';

class CreateArtistProfileView extends StatefulWidget {
  final bool fromAdmin;
  final bool isEditing;
  final ArtistModel? artist;
  final String? artistId;

  const CreateArtistProfileView({
    super.key,
    this.fromAdmin = false,
    this.isEditing = false,
    this.artist,
    this.artistId,
  });

  @override
  State<CreateArtistProfileView> createState() =>
      _CreateArtistProfileViewState();
}

class ProfileArtworkItem {
  final XFile? file;
  final String? existingImageUrl;
  final String? existingId;
  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController mediumController;
  final TextEditingController dimensionsController;
  final TextEditingController yearController;
  bool isFeatured;

  ProfileArtworkItem({
    this.file,
    this.existingImageUrl,
    this.existingId,
    String? initialTitle,
    String? initialMedium,
    String? initialPrice,
    String? initialDimensions,
    String? initialYear,
    this.isFeatured = false,
  })  : titleController = TextEditingController(text: initialTitle ?? ''),
        priceController = TextEditingController(text: initialPrice ?? ''),
        mediumController = TextEditingController(text: initialMedium ?? ''),
        dimensionsController = TextEditingController(text: initialDimensions ?? ''),
        yearController = TextEditingController(text: initialYear ?? DateTime.now().year.toString());

  bool get isExisting => existingId != null || (existingImageUrl != null && existingImageUrl!.isNotEmpty);

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
  String? _selectedLocation = 'Dubai, UAE';
  String _selectedCountryCode = kDefaultCountryCode.code;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  bool _isEditMode = false;
  String? _editingArtistId;
  String? _existingAvatarUrl;

  static const int kMaxArtworks = 6;

  bool get _isAllCriteriaMet {
    final hasName = _fullNameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final hasLocation = _selectedLocation != null && _selectedLocation!.trim().isNotEmpty;
    final hasTerms = _agreedToTerms;
    return hasName && hasEmail && hasLocation && hasTerms;
  }

  void _onFormCriteriaChanged() {
    if (mounted) setState(() {});
  }

  final ImagePicker _picker = ImagePicker();
  final List<ProfileArtworkItem> _portfolioArtworks = [];
  XFile? _profilePhotoFile;
  Uint8List? _profilePhotoBytes;

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profilePhotoFile = image;
          _profilePhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting profile picture: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final currentCount = _portfolioArtworks.length;
    if (currentCount >= kMaxArtworks) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 6 artwork uploads allowed.'),
            backgroundColor: Color(0xFF6A2777),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        final remainingSlots = kMaxArtworks - currentCount;
        final imagesToAdd = images.take(remainingSlots).toList();
        setState(() {
          for (final img in imagesToAdd) {
            _portfolioArtworks.add(ProfileArtworkItem(
              file: img,
              initialTitle: '',
              initialMedium: _selectedCategory ?? 'Mixed Media',
            ));
          }
        });
        if (images.length > remainingSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 6 artworks allowed. Added $remainingSlots artwork(s).'),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
    if (_portfolioArtworks.length >= kMaxArtworks) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 6 artwork uploads allowed.'),
            backgroundColor: Color(0xFF6A2777),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _portfolioArtworks.add(ProfileArtworkItem(
            file: image,
            initialTitle: '',
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

  final List<String> _deletedArtworkIds = [];

  void _removeImage(int index) {
    setState(() {
      final item = _portfolioArtworks[index];
      if (item.existingId != null && item.existingId!.isNotEmpty) {
        _deletedArtworkIds.add(item.existingId!);
      }
      item.dispose();
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

  List<String> _experienceLevels = [
    'Beginner (1-2 years)',
    'Intermediate (3-5 years)',
    'Advanced (5-10 years)',
    'Professional (10+ years)',
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

  StreamSubscription<List<CategoryInfo>>? _catSub;
  StreamSubscription<List<ExperienceLevelModel>>? _expSub;
  StreamSubscription<List<LocationModel>>? _locSub;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEditing || widget.artist != null || (widget.artistId != null && widget.artistId!.isNotEmpty);
    _editingArtistId = widget.artist?.id ?? widget.artistId;
    if (widget.artist != null && widget.artist!.avatarUrl.isNotEmpty) {
      _existingAvatarUrl = widget.artist!.avatarUrl;
    } else {
      try {
        final savedAvatar = sl<StorageService>().getString('artist_avatar_url');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          _existingAvatarUrl = savedAvatar;
        }
      } catch (_) {}
    }

    String prefilledName = widget.artist?.name ?? '';
    String prefilledEmail = widget.artist?.email ?? '';
    String prefilledPhone = widget.artist?.phone ?? '';
    String prefilledBio = widget.artist?.bio ?? '';
    String prefilledWebsite = widget.artist?.website ?? '';
    String prefilledInstagram = widget.artist?.instagram ?? '';

    try {
      final storage = sl<StorageService>();
      final currentEmail = (storage.getString('user_email') ?? '').trim();
      final currentName = (storage.getString('user_name') ?? '').trim();
      if (!widget.fromAdmin && (prefilledEmail.isEmpty || prefilledEmail.toLowerCase() != currentEmail.toLowerCase())) {
        if (currentName.isNotEmpty) prefilledName = currentName;
        if (currentEmail.isNotEmpty) prefilledEmail = currentEmail;
      }
    } catch (_) {}

    _fullNameController = TextEditingController(text: prefilledName);
    _emailController = TextEditingController(text: prefilledEmail);
    _phoneController = TextEditingController(text: prefilledPhone);
    _bioController = TextEditingController(text: prefilledBio);

    _fullNameController.addListener(_onFormCriteriaChanged);
    _emailController.addListener(_onFormCriteriaChanged);
    _bioController.addListener(_onFormCriteriaChanged);

    _websiteController = TextEditingController(text: prefilledWebsite);
    _instagramController = TextEditingController(text: prefilledInstagram);
    _facebookController = TextEditingController();
    _twitterController = TextEditingController();
    _linkedinController = TextEditingController();
    _tiktokController = TextEditingController();
    _youtubeController = TextEditingController();

    if (widget.artist != null) {
      _selectedCategory = widget.artist!.category;
      _selectedLocation = widget.artist!.location;
      if (widget.artist!.experienceLevel.isNotEmpty) {
        _selectedExperienceLevel = widget.artist!.experienceLevel;
      }
      _agreedToTerms = true;
    }

    _loadDynamicData();
    _initEditProfile();
  }

  void _populateFromArtist(ArtistModel artist) {
    if (!mounted) return;
    final storage = sl<StorageService>();
    final currentEmail = (storage.getString('user_email') ?? '').trim().toLowerCase();
    final currentName = (storage.getString('user_name') ?? '').trim().toLowerCase();

    final artistEmail = artist.email.trim().toLowerCase();
    final artistName = artist.name.trim().toLowerCase();
    final isOwner = currentEmail.isEmpty ||
        (artistEmail.isNotEmpty && artistEmail == currentEmail) ||
        (artistEmail.isEmpty && artistName == currentName);

    // Safety check: unless in admin mode, do not populate another user's artist profile
    if (!widget.fromAdmin && !isOwner) {
      setState(() {
        _isEditMode = false;
        _editingArtistId = null;
        _existingAvatarUrl = null;
        final currentName = storage.getString('user_name') ?? '';
        if (currentName.isNotEmpty) _fullNameController.text = currentName;
        if (currentEmail.isNotEmpty) _emailController.text = currentEmail;
      });
      return;
    }

    setState(() {
      _isEditMode = true;
      _editingArtistId = artist.id;
      _fullNameController.text = artist.name;
      _emailController.text = artist.email;
      _phoneController.text = artist.phone;
      _bioController.text = artist.bio;
      _websiteController.text = artist.website;
      _instagramController.text = artist.instagram;
      _selectedCategory = artist.category;
      _selectedLocation = artist.location;
      if (artist.experienceLevel.isNotEmpty) {
        _selectedExperienceLevel = artist.experienceLevel;
      }
      if (artist.avatarUrl.isNotEmpty) {
        _existingAvatarUrl = artist.avatarUrl;
        try {
          storage.setString('artist_avatar_url', artist.avatarUrl);
        } catch (_) {}
      }
      _agreedToTerms = true;
    });

    _loadArtworksForArtist(artist.id, artist.name);
  }

  Future<void> _loadArtworksForArtist(String artistId, [String? artistName]) async {
    try {
      final artworks = await sl<ApiService>().getArtworks(
        artistId: artistId,
        artistName: artistName,
      );
      if (artworks.isNotEmpty && mounted) {
        setState(() {
          for (final art in artworks) {
            final artId = art['id']?.toString();
            final imgUrl = (art['image_url'] ?? art['image'] ?? '').toString();
            if (imgUrl.isNotEmpty && !_portfolioArtworks.any((p) => p.existingId == artId)) {
              if (_portfolioArtworks.length >= kMaxArtworks) break;
              _portfolioArtworks.add(ProfileArtworkItem(
                existingImageUrl: imgUrl,
                existingId: artId,
                initialTitle: (art['title'] ?? '').toString(),
                initialMedium: (art['medium'] ?? '').toString(),
                initialPrice: (art['price'] ?? '').toString(),
                initialDimensions: (art['dimensions'] ?? '').toString(),
                isFeatured: art['is_featured'] == 1 ||
                    art['is_featured'] == true ||
                    art['is_featured']?.toString() == '1' ||
                    art['is_featured']?.toString() == 'true',
              ));
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _initEditProfile() async {
    final storage = sl<StorageService>();
    final currentEmail = (storage.getString('user_email') ?? '').trim().toLowerCase();
    final currentName = (storage.getString('user_name') ?? '').trim().toLowerCase();

    bool checkOwner(ArtistModel a) {
      if (widget.fromAdmin || currentEmail.isEmpty) return true;
      final aEmail = a.email.trim().toLowerCase();
      final aName = a.name.trim().toLowerCase();
      return (aEmail.isNotEmpty && aEmail == currentEmail) ||
          (aEmail.isEmpty && aName == currentName);
    }

    if (widget.artist != null) {
      if (checkOwner(widget.artist!)) {
        _populateFromArtist(widget.artist!);
        // Ensure latest server version is loaded in background
        if (widget.artist!.id.isNotEmpty && widget.artist!.id != '0') {
          try {
            final freshArtist = await sl<ApiService>().getArtistDetails(widget.artist!.id, forceRefresh: true);
            if (mounted && checkOwner(freshArtist)) {
              _populateFromArtist(freshArtist);
            }
          } catch (_) {}
        }
        return;
      }
    }
    if (widget.artistId != null && widget.artistId!.isNotEmpty) {
      try {
        final artist = await sl<ApiService>().getArtistDetails(widget.artistId!, forceRefresh: true);
        if (checkOwner(artist)) {
          _populateFromArtist(artist);
          return;
        }
      } catch (_) {}
    }

    // Auto-detect if logged-in user already has an artist profile
    try {
      final myArtist = await sl<ApiService>().getMyArtistProfile(forceRefresh: true);
      if (myArtist != null && mounted) {
        _populateFromArtist(myArtist);
        return;
      }
    } catch (_) {}

    // Fallback: If user has no artist profile, ensure clean creation state
    if (mounted && !widget.fromAdmin) {
      setState(() {
        _isEditMode = false;
        _editingArtistId = null;
        _existingAvatarUrl = null;
        final currentName = storage.getString('user_name') ?? '';
        final currentEmail = storage.getString('user_email') ?? '';
        if (currentName.isNotEmpty && _fullNameController.text.isEmpty) {
          _fullNameController.text = currentName;
        }
        if (currentEmail.isNotEmpty && _emailController.text.isEmpty) {
          _emailController.text = currentEmail;
        }
      });
    }
  }

  Future<void> _loadDynamicData() async {
    try {
      final results = await Future.wait([
        sl<ApiService>().getCategories(type: 'artist'),
        sl<ApiService>().getExperienceLevels(),
        sl<ApiService>().getLocations(),
      ]);
      final catInfos = results[0] as List<CategoryInfo>;
      final expLevels = results[1] as List<ExperienceLevelModel>;
      final locModels = results[2] as List<LocationModel>;
      if (mounted) {
        setState(() {
          if (catInfos.isNotEmpty) {
            _categories = catInfos.map((c) => c.name).toList();
          }
          if (expLevels.isNotEmpty) {
            _experienceLevels = expLevels.map((e) => e.name).toSet().toList();
          }
          if (locModels.isNotEmpty) {
            _locations = locModels.map((l) => l.name).toList();
            if (_selectedLocation != null && !_locations.contains(_selectedLocation)) {
              _locations.insert(0, _selectedLocation!);
            }
          }
        });
      }
    } catch (_) {}

    final liveSync = sl<LiveSyncService>();
    _catSub = liveSync.categoriesStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() {
          _categories = list.map((c) => c.name).toList();
        });
      }
    });
    _expSub = liveSync.experienceLevelsStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() {
          _experienceLevels = list.map((e) => e.name).toSet().toList();
        });
      }
    });
    _locSub = liveSync.locationsStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() {
          _locations = list.map((l) => l.name).toList();
          if (_selectedLocation != null && !_locations.contains(_selectedLocation)) {
            _locations.insert(0, _selectedLocation!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _expSub?.cancel();
    _locSub?.cancel();
    _fullNameController.removeListener(_onFormCriteriaChanged);
    _emailController.removeListener(_onFormCriteriaChanged);
    _bioController.removeListener(_onFormCriteriaChanged);

    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    _catSub?.cancel();
    _expSub?.cancel();
    super.dispose();
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

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final effectiveCategory = _selectedCategory?.trim().isNotEmpty == true
        ? _selectedCategory!
        : (_categories.isNotEmpty ? _categories.first : 'Visual Arts');
    final effectiveExperience = _selectedExperienceLevel?.trim().isNotEmpty == true
        ? _selectedExperienceLevel!
        : 'Professional (5+ years)';

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

      // 1. Upload dedicated profile photo if selected
      if (_profilePhotoFile != null) {
        try {
          final bytes = _profilePhotoBytes ?? await _profilePhotoFile!.readAsBytes();
          final nameParts = _profilePhotoFile!.name.split('.');
          final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
          final url = await sl<ApiService>().uploadImageBytes(
            bytes,
            ext: ext.isNotEmpty ? ext : 'jpg',
          );
          if (url != null && url.isNotEmpty) {
            uploadedAvatar = url;
          }
        } catch (_) {}
      }

      // 2. Upload artworks to server and collect their URLs & metadata
      final List<Map<String, dynamic>> uploadedArtworksData = [];

      if (_portfolioArtworks.isNotEmpty) {
        for (int i = 0; i < _portfolioArtworks.length; i++) {
          try {
            final artItem = _portfolioArtworks[i];
            if (artItem.isExisting || artItem.file == null) {
              continue;
            }
            final bytes = await artItem.file!.readAsBytes();
            final nameParts = artItem.file!.name.split('.');
            final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
            final url = await sl<ApiService>().uploadImageBytes(
              bytes,
              ext: ext.isNotEmpty ? ext : 'jpg',
            );
            if (url != null && url.isNotEmpty) {
              if (i == 0 && (uploadedBanner == null || uploadedBanner.isEmpty)) {
                uploadedBanner = url;
              }
              uploadedArtworksData.add({
                'title': artItem.titleController.text.trim().isNotEmpty
                    ? artItem.titleController.text.trim()
                    : 'Artwork Piece #${i + 1}',
                'medium': artItem.mediumController.text.trim().isNotEmpty
                    ? artItem.mediumController.text.trim()
                    : (_selectedCategory ?? 'Mixed Media'),
                'price': artItem.priceController.text.trim().isNotEmpty
                    ? artItem.priceController.text.trim()
                    : '',
                'dimensions': artItem.dimensionsController.text.trim().isNotEmpty
                    ? artItem.dimensionsController.text.trim()
                    : '',
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

      if (_isEditMode && _editingArtistId != null) {
        final updateData = <String, dynamic>{
          'id': _editingArtistId,
          'name': name,
          'category': effectiveCategory,
          'location': _selectedLocation?.isNotEmpty == true ? _selectedLocation! : 'Dubai, UAE',
          'bio': _bioController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? ''
              : (_phoneController.text.trim().startsWith('+')
                  ? _phoneController.text.trim()
                  : '$_selectedCountryCode ${_phoneController.text.trim()}'),
          'website': _websiteController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'experience_level': effectiveExperience,
          if (uploadedAvatar != null) 'avatar_url': uploadedAvatar,
          if (uploadedBanner != null) 'banner_url': uploadedBanner,
        };

        final updated = await sl<ApiService>().updateArtist(updateData);

        // Delete any artworks that were removed by the user
        for (final delId in _deletedArtworkIds) {
          try {
            await sl<ApiService>().deleteArtwork(delId);
          } catch (_) {}
        }

        // Update title and featured flag for existing artworks still in the list
        for (int i = 0; i < _portfolioArtworks.length; i++) {
          final artItem = _portfolioArtworks[i];
          if (artItem.isExisting && artItem.existingId != null) {
            try {
              await sl<ApiService>().updateArtwork({
                'id': artItem.existingId,
                'title': artItem.titleController.text.trim().isNotEmpty
                    ? artItem.titleController.text.trim()
                    : 'Artwork Piece #${i + 1}',
                'is_featured': artItem.isFeatured ? 1 : 0,
              });
            } catch (_) {}
          }
        }

        // Upload any newly selected artworks
        for (final artData in uploadedArtworksData) {
          await sl<ApiService>().createArtwork(
            title: artData['title'].toString(),
            artistId: _editingArtistId,
            artistName: name,
            year: artData['year'].toString(),
            medium: artData['medium'].toString(),
            dimensions: artData['dimensions'].toString(),
            price: artData['price'].toString(),
            imageUrl: artData['image_url'].toString(),
            isFeatured: artData['is_featured'] == true,
          );
        }

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          if (updated) {
            final storage = sl<StorageService>();
            await storage.setBool('has_artist_profile', true);
            await storage.setString('artist_profile_id', _editingArtistId!);
            await storage.setString('artist_profile_name', name);
            sl<LiveSyncService>().notifyArtistsChanged();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Artist Profile updated successfully!'),
                backgroundColor: Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go(RouteNames.artists);
            }
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile. Please check your inputs.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      }

      final profileRes = await sl<ApiService>().createArtistProfile(
        name: name,
        category: effectiveCategory,
        location: _selectedLocation?.isNotEmpty == true ? _selectedLocation! : 'Dubai, UAE',
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? ''
            : (_phoneController.text.trim().startsWith('+')
                ? _phoneController.text.trim()
                : '$_selectedCountryCode ${_phoneController.text.trim()}'),
        website: _websiteController.text.trim(),
        instagram: _instagramController.text.trim(),
        experienceLevel: effectiveExperience,
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
          final artistId = profileRes['artist_id']?.toString();
          final storage = sl<StorageService>();
          await storage.setBool('has_artist_profile', true);
          if (artistId != null) {
            await storage.setString('artist_profile_id', artistId);
          }
          await storage.setString('artist_profile_name', name);
          sl<LiveSyncService>().notifyArtistsChanged();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artist Profile & ${uploadedArtworksData.length} Artworks created successfully!'),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(RouteNames.artists);
        } else {
          if (!mounted) return;
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
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // "Create Artist Profile" Sub-Header with Back Arrow & Home Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Edit Artist Profile' : 'Create Artist Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                        children: const [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Home',
                            style: TextStyle(
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

            // Form Body Content
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
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
                          child: Icon(
                            _isEditMode ? Icons.edit_outlined : Icons.person_outline,
                            color: const Color(0xFF6B1C9B),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title & Subtitle
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _isEditMode ? 'Edit Your Artist Profile' : 'Create Your Artist Profile',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isEditMode
                                  ? 'Update your artist profile and showcase your portfolio'
                                  : 'Join Dubai\'s Artist Community and Showcase Your Portfolio',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE2D6F5),
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
                      const SizedBox(height: 16),

                      // Dedicated Artist Profile Photo (Avatar) Picker
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipOval(
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    color: const Color(0xFFF3E8FF),
                                    child: _profilePhotoBytes != null
                                        ? Image.memory(
                                            _profilePhotoBytes!,
                                            width: 92,
                                            height: 92,
                                            fit: BoxFit.cover,
                                          )
                                        : (_existingAvatarUrl != null &&
                                                _existingAvatarUrl!.isNotEmpty
                                            ? AppCachedImage(
                                                imageUrl: _existingAvatarUrl!,
                                                width: 92,
                                                height: 92,
                                                fit: BoxFit.cover,
                                                placeholder: const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF6A2777),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: const Icon(
                                                  Icons.person,
                                                  size: 46,
                                                  color: Color(0xFF6A2777),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 46,
                                                color: Color(0xFF6A2777),
                                              )),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickProfilePhoto,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6A2777),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _pickProfilePhoto,
                              icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: Colors.white),
                              label: Text(
                                _profilePhotoFile != null
                                    ? 'Change Profile Picture'
                                    : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty
                                        ? 'Change Profile Picture'
                                        : 'Upload Artist Photo (Optional)'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      _buildLabel('Phone Number (Optional)'),
                      _buildPhoneField(),
                      const SizedBox(height: 14),
                      _buildLabel('Location *'),
                      _buildSearchableLocationField(),
                      const SizedBox(height: 28),

                      // SECTION 2: Artist Information
                      _buildSectionTitle(
                        icon: Icons.palette_outlined,
                        title: 'Artist Information',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Art Category'),
                      _buildDropdownField(
                        value: _categories.contains(_selectedCategory)
                            ? _selectedCategory
                            : null,
                        hintText: 'Select your primary art form',
                        items: _categories,
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                          _onFormCriteriaChanged();
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Experience Level'),
                      _buildDropdownField(
                        value: _experienceLevels.contains(_selectedExperienceLevel)
                            ? _selectedExperienceLevel
                            : null,
                        hintText: 'Select your experience level',
                        items: _experienceLevels,
                        onChanged: (val) {
                          setState(() {
                            _selectedExperienceLevel = val;
                          });
                          _onFormCriteriaChanged();
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Artist Bio'),
                      _buildTextField(
                        controller: _bioController,
                        hintText:
                            'Tell us about your artistic journey, style, and inspiration...',
                        maxLines: 5,
                        maxLength: 5000,
                        showCounter: true,
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

                      // SECTION 4: Artwork Portfolio (Max 6)
                      _buildSectionTitle(
                        icon: Icons.upload_file_outlined,
                        title: 'Artwork Portfolio (${_portfolioArtworks.length}/$kMaxArtworks)',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload your artwork images (Max 6). You can crop, remove backgrounds, and manage your portfolio.',
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
                                spacing: 8,
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
                                        horizontal: 10,
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
                                        horizontal: 10,
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
                              Text(
                                _portfolioArtworks.length >= kMaxArtworks
                                    ? 'Maximum 6 artworks reached'
                                    : 'Max 6 uploads • Max 5MB per file',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _portfolioArtworks.length >= kMaxArtworks
                                      ? const Color(0xFF6A2777)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: _portfolioArtworks.length >= kMaxArtworks
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                              'Portfolio Artworks (${_portfolioArtworks.length}/$kMaxArtworks):',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            if (_portfolioArtworks.length < kMaxArtworks)
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
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF5E227A), width: 0.8),
                                ),
                                child: const Text(
                                  'Max 6 reached',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5E227A),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: List.generate(_portfolioArtworks.length, (index) {
                            final artItem = _portfolioArtworks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Artwork Preview Image
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: artItem.file != null
                                                ? (kIsWeb
                                                    ? Image.network(
                                                        artItem.file!.path,
                                                        width: 72,
                                                        height: 72,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(artItem.file!.path),
                                                        width: 72,
                                                        height: 72,
                                                        fit: BoxFit.cover,
                                                      ))
                                                : (artItem.existingImageUrl != null && artItem.existingImageUrl!.isNotEmpty
                                                    ? AppCachedImage(
                                                        imageUrl: artItem.existingImageUrl!,
                                                        width: 72,
                                                        height: 72,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        width: 72,
                                                        height: 72,
                                                        color: const Color(0xFFE2E8F0),
                                                        child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                                                      )),
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
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),

                                      // Artwork Title & Delete button beside image
                                      Expanded(
                                        child: Row(
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
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                                size: 22,
                                                color: Color(0xFFDC2626),
                                              ),
                                              onPressed: () => _removeImage(index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Featured checkbox across full width
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        artItem.isFeatured = !artItem.isFeatured;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            artItem.isFeatured ? Icons.check_box : Icons.check_box_outline_blank,
                                            size: 20,
                                            color: artItem.isFeatured ? const Color(0xFF6A2777) : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Mark as Featured Artwork',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Terms Agreement Checkbox Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      activeColor: const Color(0xFF5E227A),
                                      checkColor: Colors.white,
                                      fillColor:
                                          WidgetStateProperty.resolveWith(
                                        (states) {
                                          if (states.contains(
                                              WidgetState.selected)) {
                                            return const Color(0xFF5E227A);
                                          }
                                          return Colors.white;
                                        },
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF5E227A),
                                        width: 1.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (val) {
                                        setState(() {
                                          _agreedToTerms = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1.0),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '* I agree to the ',
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                setState(() {
                                                  _agreedToTerms =
                                                      !_agreedToTerms;
                                                });
                                              },
                                          ),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                              color: Color(0xFF6B1C9B),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Color(0xFF6B1C9B),
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                context.push(
                                                    RouteNames.privacyPolicy);
                                              },
                                          ),
                                          TextSpan(
                                            text: ' and ',
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                setState(() {
                                                  _agreedToTerms =
                                                      !_agreedToTerms;
                                                });
                                              },
                                          ),
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: const TextStyle(
                                              color: Color(0xFF6B1C9B),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Color(0xFF6B1C9B),
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                context.push(RouteNames
                                                    .termsConditions);
                                              },
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
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => context.pop(),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAllCriteriaMet
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.20),
                                  foregroundColor: _isAllCriteriaMet
                                      ? const Color(0xFF6B1C9B)
                                      : Colors.white.withValues(alpha: 0.45),
                                  elevation: _isAllCriteriaMet ? 3 : 0,
                                  shadowColor: Colors.black38,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: _isAllCriteriaMet
                                        ? BorderSide.none
                                        : BorderSide(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 1.0,
                                          ),
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : _submitProfile,
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF6B1C9B),
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _isEditMode ? 'Save Changes' : 'Create Profile',
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                            ),
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
      bottomNavigationBar: widget.fromAdmin ? null : const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFE2D6F5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: showCounter ? null : '',
        counterStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
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

  Widget _buildPhoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 340,
              menuWidth: 290,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF334155),
                size: 18,
              ),
              selectedItemBuilder: (BuildContext context) {
                return kCountryCodes.map((item) {
                  return Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.flag,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.code,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              items: kCountryCodes.map((item) {
                final isDubai = item.code == '+971';
                return DropdownMenuItem<String>(
                  value: item.code,
                  child: Row(
                    children: [
                      Text(item.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.country,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                isDubai ? FontWeight.bold : FontWeight.w500,
                            color: isDubai
                                ? const Color(0xFF5E227A)
                                : const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${item.code})',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDubai
                              ? const Color(0xFF5E227A)
                              : const Color(0xFF64748B),
                          fontWeight:
                              isDubai ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isDubai) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5E227A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCountryCode = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '50 XXX XXXX',
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
                borderSide:
                    const BorderSide(color: Color(0xFFCBD5E1), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFCBD5E1), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF5E227A), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableLocationField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _locations;
        }
        return _locations.where((location) =>
            location.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      initialValue: TextEditingValue(text: _selectedLocation ?? ''),
      onSelected: (String selection) {
        setState(() {
          _selectedLocation = selection;
        });
        _onFormCriteriaChanged();
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
            fontSize: 14,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search or select your location',
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.normal,
            ),
            suffixIcon: const Icon(Icons.search, color: Color(0xFF334155), size: 20),
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
          onChanged: (val) {
            // Allow freeform text as well
            _selectedLocation = val;
            _onFormCriteriaChanged();
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
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: index < options.length - 1
                            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))
                            : null,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          color: option == _selectedLocation
                              ? const Color(0xFF5E227A)
                              : const Color(0xFF1E293B),
                          fontWeight: option == _selectedLocation
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
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
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
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
