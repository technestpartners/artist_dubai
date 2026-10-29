import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/share_helper.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class GalleriesView extends StatefulWidget {
  final String? initialGalleryId;
  const GalleriesView({super.key, this.initialGalleryId});

  @override
  State<GalleriesView> createState() => _GalleriesViewState();
}

class _GalleriesViewState extends State<GalleriesView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _registeredGalleries = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _currentFilter = 'all'; // 'all' or 'mine'
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;

  static const Color _screenBg = Color(0xFF6B1C9B);
  static const Color _cardBg = Color(0xFF551478);

  @override
  void initState() {
    super.initState();
    _loadGalleries();
    _galleriesSub = sl<LiveSyncService>().galleriesStream.listen((galleries) {
      if (mounted) {
        setState(() {
          _registeredGalleries = galleries;
        });
      }
    });
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _searchController.dispose();
    _galleriesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadGalleries() async {
    setState(() => _isLoading = true);
    try {
      final list = await sl<ApiService>().getGalleries();
      if (widget.initialGalleryId != null &&
          widget.initialGalleryId!.isNotEmpty) {
        final targetId = widget.initialGalleryId!.trim();
        list.sort((a, b) {
          final aMatch = a['id']?.toString() == targetId;
          final bMatch = b['id']?.toString() == targetId;
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return 0;
        });
      }
      if (mounted) {
        setState(() {
          _registeredGalleries = list;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    await ShareHelper.openUrl(url);
  }

  bool _isMyGallery(Map<String, dynamic> gallery) {
    try {
      final storage = sl<StorageService>();

      // 1. Check persistent locally registered gallery IDs (created by this device/user)
      final galId = (gallery['id'] ?? '').toString().trim();
      final myIds = storage.getStringList('my_gallery_ids') ?? [];
      if (galId.isNotEmpty && myIds.contains(galId)) {
        return true;
      }

      // 2. Check logged-in user's email vs gallery's creator email
      final currentEmail =
          (storage.getString('user_email') ?? '').trim().toLowerCase();
      final galEmail = (gallery['email'] ?? '').toString().trim().toLowerCase();
      if (currentEmail.isNotEmpty &&
          galEmail.isNotEmpty &&
          currentEmail == galEmail) {
        return true;
      }

      // 3. Check logged-in user's ID vs gallery's user_id / creator_id
      final currentUserId = (storage.getString('user_id') ?? '').trim();
      final galUserId =
          (gallery['user_id'] ??
                  gallery['creator_id'] ??
                  gallery['created_by'] ??
                  '')
              .toString()
              .trim();
      if (currentUserId.isNotEmpty &&
          galUserId.isNotEmpty &&
          currentUserId == galUserId) {
        return true;
      }

      // 4. Check persistent locally registered gallery emails
      final myEmails =
          (storage.getStringList('my_gallery_emails') ?? [])
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList();
      if (galEmail.isNotEmpty && myEmails.contains(galEmail)) {
        return true;
      }

      // 5. Check persistent locally registered gallery names created on this device
      final galName =
          (gallery['name'] ?? gallery['title'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      final myNames =
          (storage.getStringList('my_gallery_names') ?? [])
              .map((n) => n.trim().toLowerCase())
              .where((n) => n.isNotEmpty)
              .toList();
      if (galName.isNotEmpty && myNames.contains(galName)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  List<Map<String, dynamic>> _getFilteredGalleries() {
    var baseList = _registeredGalleries;
    if (_currentFilter == 'mine') {
      baseList = baseList.where(_isMyGallery).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return baseList;
    return baseList.where((g) {
      final name = (g['name'] ?? g['title'] ?? '').toString().toLowerCase();
      final about =
          (g['about'] ?? g['description'] ?? g['subtitle'] ?? '')
              .toString()
              .toLowerCase();
      final location =
          (g['location'] ?? g['address'] ?? g['city'] ?? '')
              .toString()
              .toLowerCase();
      final category =
          (g['category'] ?? g['type'] ?? '').toString().toLowerCase();
      final artistName = (g['artist_name'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          about.contains(query) ||
          location.contains(query) ||
          category.contains(query) ||
          artistName.contains(query);
    }).toList();
  }

  Future<void> _showEditGalleryModal(Map<String, dynamic> gallery) async {
    final nameController = TextEditingController(
      text: (gallery['name'] ?? gallery['title'] ?? '').toString(),
    );
    final categoryController = TextEditingController(
      text:
          (gallery['category'] ?? gallery['type'] ?? 'Art Gallery').toString(),
    );
    final locationController = TextEditingController(
      text:
          (gallery['location'] ?? gallery['address'] ?? 'Dubai, UAE')
              .toString(),
    );
    final timingController = TextEditingController(
      text: (gallery['timing'] ?? '').toString(),
    );
    final websiteController = TextEditingController(
      text: (gallery['website'] ?? '').toString(),
    );
    final aboutController = TextEditingController(
      text:
          (gallery['about'] ??
                  gallery['description'] ??
                  gallery['subtitle'] ??
                  '')
              .toString(),
    );

    String? uploadedImageUrl =
        (gallery['image_url'] ?? gallery['image'] ?? '').toString();
    if (uploadedImageUrl.isEmpty) uploadedImageUrl = null;
    bool isUploadingImage = false;
    bool isSaving = false;
    String? errorMessage;

    final categories = [
      'Art Gallery',
      'Art Center',
      'Exhibition Space',
      'Museum',
      'Design Studio',
      'Cultural Center',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;

            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  imageQuality: 85,
                );
                if (picked != null) {
                  setModalState(() {
                    isUploadingImage = true;
                    errorMessage = null;
                  });
                  final bytes = await picked.readAsBytes();
                  final nameParts = picked.name.split('.');
                  final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
                  final url = await sl<ApiService>().uploadImageBytes(
                    bytes,
                    ext: ext,
                  );
                  setModalState(() {
                    isUploadingImage = false;
                    if (url != null && url.isNotEmpty) {
                      uploadedImageUrl = url;
                    }
                  });
                }
              } catch (_) {
                setModalState(() {
                  isUploadingImage = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF6B1C9B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit Venue'.trData(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Image Section
                            Text(
                              'Venue Photo'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (uploadedImageUrl != null &&
                                      uploadedImageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: AppCachedImage(
                                        imageUrl: uploadedImageUrl!,
                                        width: double.infinity,
                                        height: 130,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 36,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'No photo selected'.trData(context),
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isUploadingImage)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF6B1C9B,
                                            ),
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed:
                                              isUploadingImage
                                                  ? null
                                                  : () => pickImage(
                                                    ImageSource.gallery,
                                                  ),
                                          icon: const Icon(
                                            Icons.photo_library,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Gallery'.trData(context),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF6B1C9B,
                                            ),
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed:
                                              isUploadingImage
                                                  ? null
                                                  : () => pickImage(
                                                    ImageSource.camera,
                                                  ),
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Camera'.trData(context),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Venue Name
                            Text(
                              'Venue Name *'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter venue name'.trData(context),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Category
                            Text(
                              'Category / Type *'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: categoryController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Art Gallery'.trData(context),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  categories.map((cat) {
                                    final isSelected =
                                        categoryController.text
                                            .trim()
                                            .toLowerCase() ==
                                        cat.toLowerCase();
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          categoryController.text = cat;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? const Color(0xFF6B1C9B)
                                                  : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? const Color(0xFF6B1C9B)
                                                    : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          cat.trData(context),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Location
                            Text(
                              'Location / Address *'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: locationController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'e.g. Alserkal Avenue, Al Quoz 1, Dubai'
                                        .trData(context),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Opening Hours / Timing
                            Text(
                              'Opening Hours / Timing (Optional)'.trData(
                                context,
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: timingController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Sat–Thu 10:00–20:00'.trData(
                                  context,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Website
                            Text(
                              'Website (Optional)'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: websiteController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'https://...',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // About
                            Text(
                              'About Venue'.trData(context),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: aboutController,
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Describe this art space, focus, collections...'
                                        .trData(context),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                    ),
                                    onPressed:
                                        isSaving
                                            ? null
                                            : () => Navigator.of(ctx).pop(),
                                    child: Text(
                                      'Cancel'.trData(context),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B1C9B),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed:
                                        isSaving
                                            ? null
                                            : () async {
                                              final updatedName =
                                                  nameController.text.trim();
                                              final updatedCategory =
                                                  categoryController.text
                                                      .trim();
                                              final updatedLocation =
                                                  locationController.text
                                                      .trim();
                                              final updatedWebsite =
                                                  websiteController.text.trim();
                                              final updatedAbout =
                                                  aboutController.text.trim();

                                              if (updatedName.isEmpty) {
                                                setModalState(() {
                                                  errorMessage =
                                                      'Venue name cannot be empty'
                                                          .trData(context);
                                                });
                                                return;
                                              }

                                              setModalState(() {
                                                isSaving = true;
                                                errorMessage = null;
                                              });

                                              final id = gallery['id'];
                                              final success = await sl<
                                                    ApiService
                                                  >()
                                                  .updateGallery(
                                                    id: id,
                                                    name: updatedName,
                                                    title: updatedName,
                                                    category:
                                                        updatedCategory
                                                                .isNotEmpty
                                                            ? updatedCategory
                                                            : 'Art Gallery',
                                                    location:
                                                        updatedLocation
                                                                .isNotEmpty
                                                            ? updatedLocation
                                                            : 'Dubai, UAE',
                                                    address:
                                                        updatedLocation
                                                                .isNotEmpty
                                                            ? updatedLocation
                                                            : 'Dubai, UAE',
                                                    timing:
                                                        timingController.text
                                                            .trim(),
                                                    website: updatedWebsite,
                                                    about: updatedAbout,
                                                    description: updatedAbout,
                                                    imageUrl:
                                                        uploadedImageUrl ?? '',
                                                    userEmail:
                                                        gallery['email']
                                                            ?.toString() ??
                                                        sl<StorageService>()
                                                            .getString(
                                                              'user_email',
                                                            ),
                                                  );

                                              if (!mounted) return;
                                              if (success) {
                                                setState(() {
                                                  final idx = _registeredGalleries
                                                      .indexWhere(
                                                        (g) =>
                                                            g['id']
                                                                ?.toString() ==
                                                            id?.toString(),
                                                      );
                                                  if (idx != -1) {
                                                    final updated = Map<
                                                      String,
                                                      dynamic
                                                    >.from(
                                                      _registeredGalleries[idx],
                                                    );
                                                    updated['name'] =
                                                        updatedName;
                                                    updated['title'] =
                                                        updatedName;
                                                    updated['category'] =
                                                        updatedCategory
                                                                .isNotEmpty
                                                            ? updatedCategory
                                                            : 'Art Gallery';
                                                    updated['type'] =
                                                        updatedCategory
                                                                .isNotEmpty
                                                            ? updatedCategory
                                                            : 'Art Gallery';
                                                    updated['location'] =
                                                        updatedLocation
                                                                .isNotEmpty
                                                            ? updatedLocation
                                                            : 'Dubai, UAE';
                                                    updated['address'] =
                                                        updatedLocation
                                                                .isNotEmpty
                                                            ? updatedLocation
                                                            : 'Dubai, UAE';
                                                    updated['timing'] =
                                                        timingController.text
                                                            .trim();
                                                    updated['website'] =
                                                        updatedWebsite;
                                                    updated['about'] =
                                                        updatedAbout;
                                                    updated['description'] =
                                                        updatedAbout;
                                                    updated['subtitle'] =
                                                        updatedAbout;
                                                    updated['image_url'] =
                                                        uploadedImageUrl ?? '';
                                                    updated['image'] =
                                                        uploadedImageUrl ?? '';
                                                    _registeredGalleries[idx] =
                                                        updated;
                                                  }
                                                });
                                                try {
                                                  final storage =
                                                      sl<StorageService>();
                                                  final myNames = List<
                                                    String
                                                  >.from(
                                                    storage.getStringList(
                                                          'my_gallery_names',
                                                        ) ??
                                                        [],
                                                  );
                                                  final oldName =
                                                      (gallery['name'] ??
                                                              gallery['title'] ??
                                                              '')
                                                          .toString()
                                                          .trim();
                                                  if (oldName.isNotEmpty) {
                                                    myNames.remove(oldName);
                                                  }
                                                  if (!myNames.contains(
                                                    updatedName,
                                                  )) {
                                                    myNames.add(updatedName);
                                                  }
                                                  storage.setStringList(
                                                    'my_gallery_names',
                                                    myNames,
                                                  );
                                                } catch (_) {}
                                                if (ctx.mounted) {
                                                  Navigator.of(ctx).pop();
                                                }
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Venue "$updatedName" updated successfully!'
                                                          .trData(context),
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFF6B1C9B),
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                  ),
                                                );
                                              } else {
                                                setModalState(() {
                                                  isSaving = false;
                                                  errorMessage =
                                                      'Failed to update venue. Please try again.'
                                                          .trData(context);
                                                });
                                              }
                                            },
                                    child:
                                        isSaving
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              'Save Changes'.trData(context),
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteGallery(Map<String, dynamic> gallery) {
    final name = (gallery['name'] ?? gallery['title'] ?? 'Venue').toString();
    final id = gallery['id'];

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
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Venue'.trData(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "$name"? This action will remove the venue from the Dubai directory and cannot be undone.'
                  .trData(context),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel'.trData(context),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await sl<ApiService>().deleteGallery(
                    id,
                    userEmail:
                        gallery['email']?.toString() ??
                        sl<StorageService>().getString('user_email'),
                  );
                  if (!mounted) return;
                  if (success) {
                    setState(() {
                      _registeredGalleries.removeWhere(
                        (g) => g['id']?.toString() == id?.toString(),
                      );
                    });
                    try {
                      final storage = sl<StorageService>();
                      final myIds = List<String>.from(
                        storage.getStringList('my_gallery_ids') ?? [],
                      );
                      myIds.remove(id?.toString());
                      storage.setStringList('my_gallery_ids', myIds);
                      final myNames = List<String>.from(
                        storage.getStringList('my_gallery_names') ?? [],
                      );
                      myNames.remove(name.trim());
                      storage.setStringList('my_gallery_names', myNames);
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Venue "$name" deleted successfully'.trData(context),
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete venue. Please try again.'.trData(
                            context,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  'Delete'.trData(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterChips() {
    final totalCount = _registeredGalleries.length;
    final myCount = _registeredGalleries.where(_isMyGallery).length;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = 'all';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    _currentFilter == 'all'
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _currentFilter == 'all'
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: _currentFilter == 'all' ? _screenBg : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Venues ($totalCount)'.trData(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _currentFilter == 'all' ? _screenBg : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = 'mine';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    _currentFilter == 'mine'
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _currentFilter == 'mine'
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_pin_rounded,
                    size: 16,
                    color: _currentFilter == 'mine' ? _screenBg : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'My Venues ($myCount)'.trData(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          _currentFilter == 'mine' ? _screenBg : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: _screenBg,
        decoration: InputDecoration(
          hintText: 'Search Galleries & Art Centers'.trData(context),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14.5),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF64748B),
            size: 22,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF6A2777),
          backgroundColor: Colors.white,
          onRefresh: _loadGalleries,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    rh.horizontalPadding,
                    24,
                    rh.horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 0. Top Navigation & Action Bar (Home / Back & Register Button)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(RouteNames.home);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    context.canPop()
                                        ? Icons.arrow_back
                                        : Icons.home_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.canPop() ? l10n.back : l10n.home,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6B1C9B),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  context.push(RouteNames.galleryRegistration);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Color(0xFF6B1C9B),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        l10n.galleryRegistration,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B1C9B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 1. Header Title & Subtitle
                      Text(
                        l10n.galleriesArtCenter,
                        style: TextStyle(
                          fontSize: rh.adaptiveFont(24),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.galleriesSubtitle,
                        style: TextStyle(
                          fontSize: rh.adaptiveFont(14.5),
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Field (Matching Events page style)
                      _buildSearchBar(),
                      const SizedBox(height: 14),

                      // Filter tabs: All Venues vs My Venues
                      _buildFilterChips(),
                      const SizedBox(height: 18),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (_hasError && _registeredGalleries.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 46,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load galleries'.trData(context),
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your connection and try again.'
                                    .trData(context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _loadGalleries,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text('Retry'.trData(context)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _screenBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_registeredGalleries.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.apartment_outlined,
                                size: 46,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No art centers listed yet'.trData(context),
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Registered galleries and art centers will be shown here.'
                                    .trData(context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else if (_getFilteredGalleries().isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentFilter == 'mine'
                                    ? Icons.storefront_outlined
                                    : Icons.search_off_rounded,
                                size: 46,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                (_currentFilter == 'mine'
                                        ? 'No venues registered by you yet'
                                        : 'No galleries or art centers found matching your search.')
                                    .trData(context),
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              if (_currentFilter == 'mine') ...[
                                Text(
                                  'Register your gallery or art space to showcase it across Dubai.'
                                      .trData(context),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => context.push(
                                        RouteNames.galleryRegistration,
                                      ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(
                                    'Register Art Venue'.trData(context),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _screenBg,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: Text('Clear Search'.trData(context)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _screenBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 600;
                            final crossAxisCount =
                                constraints.maxWidth >= 900 ? 3 : 2;
                            final displayGalleries = _getFilteredGalleries();

                            Widget buildGalleryCard(
                              Map<String, dynamic> gallery,
                            ) {
                              final isMyVenue = _isMyGallery(gallery);
                              final name =
                                  (gallery['name'] ??
                                          gallery['title'] ??
                                          'Art Gallery')
                                      .toString();
                              final category =
                                  (gallery['category'] ?? gallery['type'] ?? '')
                                      .toString();
                              final location =
                                  (gallery['location'] ??
                                          gallery['address'] ??
                                          'Dubai, UAE')
                                      .toString();
                              final imageUrl =
                                  (gallery['image_url'] ??
                                          gallery['image'] ??
                                          '')
                                      .toString();

                              return Container(
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(18),
                                            ),
                                        child: AppCachedImage(
                                          imageUrl: imageUrl,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Top Row: Title + My Venue Tag + Open Badge
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        name.trData(context),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    if (isMyVenue) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient:
                                                              const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xFFE11D48,
                                                                  ),
                                                                  Color(
                                                                    0xFFC026D3,
                                                                  ),
                                                                ],
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.verified,
                                                              size: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'My Venue'.trData(
                                                                context,
                                                              ),
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  Localizations.localeOf(
                                                            context,
                                                          ).languageCode ==
                                                          'ar'
                                                      ? 'مفتوح'
                                                      : 'Open',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Subtitle: Category / Type
                                          Text(
                                            (category.isNotEmpty
                                                    ? category
                                                    : 'Art Space')
                                                .trData(context),
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),

                                          // Location Pin & Address
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  location.trData(context),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    color: Colors.white70,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((gallery['timing'] ?? '')
                                              .toString()
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 15,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    (gallery['timing'] ?? '')
                                                        .toString()
                                                        .trim()
                                                        .trData(context),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 16),

                                          // Directions and Share Actions
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 44,
                                                  child: ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors
                                                          .white
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        () => _launchUrl(
                                                          'https://maps.google.com/?q=${Uri.encodeComponent('$name $location')}',
                                                        ),
                                                    icon: const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                    label: Text(
                                                      l10n.directions,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () {
                                                  ShareHelper.shareGallery(
                                                    context: context,
                                                    galleryId:
                                                        gallery['id']
                                                            ?.toString() ??
                                                        '',
                                                    title: name,
                                                    location: location,
                                                    imageUrl: imageUrl,
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.share_outlined,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Edit and Delete Actions for My Created Venue
                                          if (isMyVenue) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 38,
                                                      child: ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF6366F1,
                                                              ),
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _showEditGalleryModal(
                                                                  gallery,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                        label: Text(
                                                          'Edit'.trData(
                                                            context,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 38,
                                                      child: ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFDC2626,
                                                              ),
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _confirmDeleteGallery(
                                                                  gallery,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                        label: Text(
                                                          'Delete'.trData(
                                                            context,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (isWide) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayGalleries.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.65,
                                    ),
                                itemBuilder:
                                    (context, index) => buildGalleryCard(
                                      displayGalleries[index],
                                    ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayGalleries.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 16),
                              itemBuilder:
                                  (context, index) =>
                                      buildGalleryCard(displayGalleries[index]),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }
}
