import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../government/domain/models/government_entity.dart';

enum AdminTab {
  artists,
  events,
  calendar,
  galleries,
  bookings,
  artCenters,
  government,
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  AdminTab _selectedTab = AdminTab.artists;

  List<ArtistModel> _artists = [];
  List<ArtEventModel> _events = [];
  List<Map<String, dynamic>> _galleries = [];
  List<Map<String, dynamic>> _artCenters = [];
  List<Map<String, dynamic>> _bookings = [];
  List<GovernmentEntity> _govEntities = [];

  StreamSubscription<List<ArtistModel>>? _artistsSub;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSub;
  StreamSubscription<List<GovernmentEntity>>? _govSub;

  Future<void> _pickAndUploadImageForField(TextEditingController controller, StateSetter setModalState) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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
    _loadAllData();
    _subscribeLiveStreams();
  }

  void _subscribeLiveStreams() {
    final liveSync = sl<LiveSyncService>();
    _artistsSub = liveSync.artistsStream.listen((list) {
      if (mounted) {
        setState(() => _artists = list);
      }
    });
    _eventsSub = liveSync.eventsStream.listen((list) {
      if (mounted) {
        setState(() => _events = list);
      }
    });
    _bookingsSub = liveSync.bookingsStream.listen((list) {
      if (mounted) {
        setState(() => _bookings = list);
      }
    });
    _govSub = liveSync.governmentStream.listen((list) {
      if (mounted) {
        setState(() => _govEntities = list);
      }
    });
  }

  @override
  void dispose() {
    _artistsSub?.cancel();
    _eventsSub?.cancel();
    _bookingsSub?.cancel();
    _govSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        sl<ApiService>().getArtists(forceRefresh: true).catchError((_) => <ArtistModel>[]),
        sl<ApiService>().getEvents(forceRefresh: true).catchError((_) => <ArtEventModel>[]),
        sl<ApiService>().getGalleries(forceRefresh: true, isAdmin: true).catchError((_) => <Map<String, dynamic>>[]),
        sl<ApiService>().getBookings(forceRefresh: true).catchError((_) => <Map<String, dynamic>>[]),
        sl<ApiService>().getGovernmentEntities(forceRefresh: true).catchError((_) => <GovernmentEntity>[]),
      ]);

      if (mounted) {
        final allItems = results[2] as List<Map<String, dynamic>>;

        // 1. Separate Photo Galleries (created by artists or event albums)
        final photoGalleries = allItems.where((item) {
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
              (images != null && images.toString().isNotEmpty && images.toString() != '[]');
        }).toList();

        // 2. Separate Physical Art Centers & Venues
        final artCenters = allItems.where((item) {
          final cat = (item['category'] ?? '').toString().toLowerCase();
          final artistId = (item['artist_id'] ?? '').toString();
          final artistName = (item['artist_name'] ?? '').toString();
          final eventName = (item['event_name'] ?? '').toString();
          final images = item['images_json'] ?? item['images'];
          final isPhoto = cat.contains('photo') ||
              cat.contains('artist') ||
              cat.contains('album') ||
              artistId.isNotEmpty ||
              artistName.isNotEmpty ||
              eventName.isNotEmpty ||
              (images != null && images.toString().isNotEmpty && images.toString() != '[]');
          return !isPhoto;
        }).toList();

        final finalPhotoGalleries = photoGalleries.isNotEmpty
            ? photoGalleries
            : [
                {
                  'id': 101,
                  'name': 'ART Water - Brand',
                  'title': 'ART Water - Brand',
                  'description': 'ART Water - Brand photo collection',
                  'category': 'Artist gallery',
                  'artist_name': 'Renish Artistry',
                  'image_url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=800&q=80',
                  'photo_count': 1,
                  'status': 'approved',
                  'is_public': 1,
                  'is_approved': 1,
                },
              ];

        setState(() {
          _artists = results[0] as List<ArtistModel>;
          _events = results[1] as List<ArtEventModel>;
          _galleries = finalPhotoGalleries;
          _artCenters = artCenters;
          _bookings = results[3] as List<Map<String, dynamic>>;
          _govEntities = results[4] as List<GovernmentEntity>;
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3B1E78), // Royal purple dialog background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }



  // --- Modal Dialog: New Government Entry & Edit Entry (Screenshots 3 & 4) ---
  void _showGovernmentDialog({GovernmentEntity? existing, int? index}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final typeCtrl = TextEditingController(text: existing?.category ?? 'Government · Cultural Authority');
    final addressCtrl = TextEditingController(text: existing?.location ?? '');
    final websiteCtrl = TextEditingController(text: existing?.websiteUrl ?? '');
    final ratingCtrl = TextEditingController(text: existing != null ? '${existing.rating}' : '0');
    final reviewsCtrl = TextEditingController(text: existing != null ? '${existing.reviewCount}' : '0');
    final orderCtrl = TextEditingController(text: index != null ? '${index + 1}' : '0');
    final statusTextCtrl = TextEditingController(text: existing?.defaultTiming ?? 'Open · Closes at 15:00');
    bool isCurrentlyOpen = existing?.defaultIsOpen ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(label: 'Name', controller: nameCtrl, isFocused: true),
                  const SizedBox(height: 12),

                  _buildFormField(
                    label: 'Type',
                    controller: typeCtrl,
                    hint: 'Government · Cultural Authority',
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Address', controller: addressCtrl, hint: 'Al Shindagha, Dubai'),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Website', controller: websiteCtrl, hint: 'https://...'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Rating',
                          controller: ratingCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          activeColor: const Color(0xFF6A2777),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        'rating': double.tryParse(ratingCtrl.text.trim()) ?? 4.5,
                        'reviews': int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                        'status_text': statusTextCtrl.text.trim(),
                        'currently_open': isCurrentlyOpen ? 1 : 0,
                      };

                      Navigator.pop(ctx);

                      if (isEdit) {
                        final updated = GovernmentEntity(
                          id: existing.id,
                          name: name,
                          defaultIsOpen: isCurrentlyOpen,
                          rating: double.tryParse(ratingCtrl.text.trim()) ?? 4.5,
                          reviewCount: int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                          category: typeCtrl.text.trim(),
                          location: addressCtrl.text.trim(),
                          defaultTiming: statusTextCtrl.text.trim(),
                          websiteUrl: websiteCtrl.text.trim(),
                          directionsUrl: existing.directionsUrl,
                          googleMapsReviewsUrl: existing.googleMapsReviewsUrl,
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
                        await sl<ApiService>().updateGovernmentEntity(payload);
                      } else {
                        final newEntity = GovernmentEntity(
                          name: name,
                          defaultIsOpen: isCurrentlyOpen,
                          rating: double.tryParse(ratingCtrl.text.trim()) ?? 4.5,
                          reviewCount: int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                          category: typeCtrl.text.trim(),
                          location: addressCtrl.text.trim(),
                          defaultTiming: statusTextCtrl.text.trim(),
                          websiteUrl: websiteCtrl.text.trim(),
                          directionsUrl: 'https://www.google.com/maps/search/?api=1&query=$name+Dubai',
                        );
                        setState(() => _govEntities.insert(0, newEntity));
                        await sl<ApiService>().createGovernmentEntity(payload);
                      }
                      try {
                        sl<LiveSyncService>().notifyGovernmentChanged();
                      } catch (_) {}
                    },
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
    final typeCtrl = TextEditingController(text: existing?['category'] ?? 'Gallery · Exhibition space');
    final addressCtrl = TextEditingController(text: existing?['location'] ?? '');
    final hoursCtrl = TextEditingController(text: existing?['timing'] ?? 'Sat–Thu 10:00–20:00');
    final websiteCtrl = TextEditingController(text: existing?['website'] ?? '');
    final imageCtrl = TextEditingController(text: existing?['image_url'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final orderCtrl = TextEditingController(text: '${existing?['display_order'] ?? 0}');
    bool isCurrentlyOpen = (existing?['currently_open'] == 1 || existing?['currently_open'] == true);
    bool isApproved = (existing?['status'] ?? 'approved').toString().toLowerCase() != 'pending' &&
                      existing?['is_approved'] != 0 &&
                      existing?['is_approved'] != '0' &&
                      existing?['is_public'] != 0 &&
                      existing?['is_public'] != '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(label: 'Name', controller: nameCtrl, isFocused: true),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Type', controller: typeCtrl, hint: 'Gallery · Exhibition space'),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Address', controller: addressCtrl),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Website', controller: websiteCtrl, hint: 'https://...'),
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
                        icon: const Icon(Icons.upload_file_outlined, size: 14, color: Color(0xFF6A2777)),
                        label: const Text('Upload photo', style: TextStyle(fontSize: 12, color: Color(0xFF6A2777), fontWeight: FontWeight.bold)),
                        onPressed: () => _pickAndUploadImageForField(imageCtrl, setModalState),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildFormField(label: '', controller: imageCtrl, hint: 'https://... or click Upload'),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Description', controller: descCtrl, maxLines: 3),
                  const SizedBox(height: 12),

                  _buildFormField(label: 'Display order', controller: orderCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          activeColor: const Color(0xFF6A2777),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              isApproved ? 'Visible in public app' : 'Pending admin review',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Switch(
                          value: isApproved,
                          activeColor: const Color(0xFF16A34A),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
    final titleCtrl = TextEditingController(text: existing?['name'] ?? existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final coverImageCtrl = TextEditingController(text: existing?['image_url'] ?? existing?['cover_url'] ?? '');
    String? selectedEvent = existing?['event_name'];
    bool isVisibleToEveryone = (existing?['is_public'] ?? 1) == 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
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
                        icon: const Icon(Icons.upload_file_outlined, size: 14, color: Color(0xFF6A2777)),
                        label: const Text('Upload photo', style: TextStyle(fontSize: 12, color: Color(0xFF6A2777), fontWeight: FontWeight.bold)),
                        onPressed: () => _pickAndUploadImageForField(coverImageCtrl, setModalState),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildFormField(
                    label: '',
                    controller: coverImageCtrl,
                    hint: 'https://... or click Upload',
                  ),
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
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedEvent,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            elevation: 4,
                            menuMaxHeight: 280,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                            hint: const Text(
                              'No event',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No event', style: TextStyle(fontSize: 13.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                              ),
                              ..._events.map((e) => DropdownMenuItem<String?>(
                                    value: e.title,
                                    child: Text(
                                      e.title,
                                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          activeColor: const Color(0xFF6A2777),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;

                      final payload = {
                        if (existing?['id'] != null) 'id': existing!['id'],
                        'name': title,
                        'title': title,
                        'description': descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : (selectedEvent != null ? 'Curated collection for $selectedEvent' : ''),
                        'image_url': coverImageCtrl.text.trim(),
                        'cover_url': coverImageCtrl.text.trim(),
                        'event_name': selectedEvent ?? '',
                        'is_public': isVisibleToEveryone ? 1 : 0,
                        'is_approved': isVisibleToEveryone ? 1 : 0,
                        'status': isVisibleToEveryone ? 'approved' : 'pending',
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
                    child: Text(isEdit ? 'Save' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
  }) {
    final textField = TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly || onTap != null,
      enableInteractiveSelection: onTap == null,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: const Color(0xFF6A2777))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
            width: isFocused ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
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
              child: AbsorbPointer(
                absorbing: true,
                child: textField,
              ),
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Artist Dubai management',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6A2777),
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI Summary Cards (2x2 Grid matching screenshots)
              _buildMetricsGrid(),
              const SizedBox(height: 16),

              // 2. Multi-row Tab Selector Bar matching screenshots
              _buildTabSelector(),
              const SizedBox(height: 16),

              // 3. Tab Content View
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                count: '${_artists.length}',
                label: 'Artists',
                isSelected: _selectedTab == AdminTab.artists,
                onTap: () => setState(() => _selectedTab = AdminTab.artists),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_outlined,
                count: '${_events.length}',
                label: 'Events',
                isSelected: _selectedTab == AdminTab.events || _selectedTab == AdminTab.calendar,
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
                label: 'Galleries',
                isSelected: _selectedTab == AdminTab.galleries,
                onTap: () => setState(() => _selectedTab = AdminTab.galleries),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.confirmation_number_outlined,
                count: '${_bookings.length}',
                label: 'Bookings',
                isSelected: _selectedTab == AdminTab.bookings,
                onTap: () => setState(() => _selectedTab = AdminTab.bookings),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x186A2777) : const Color(0x08000000),
              blurRadius: isSelected ? 8 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF6A2777),
                  size: 22,
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6A2777),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF6A2777) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              _buildTabButton(AdminTab.artists, 'Artists'),
              _buildTabButton(AdminTab.events, 'Events'),
              _buildTabButton(AdminTab.calendar, 'Calendar'),
              _buildTabButton(AdminTab.galleries, 'Galleries'),
              _buildTabButton(AdminTab.bookings, 'Bookings'),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(AdminTab.artCenters, 'Art Centers'),
              _buildTabButton(AdminTab.government, 'Government'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(AdminTab tab, String title) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AdminTab.artists:
        return _buildArtistsTab();
      case AdminTab.events:
        return _buildEventsTab();
      case AdminTab.calendar:
        return _buildCalendarTab();
      case AdminTab.galleries:
        return _buildGalleriesTab();
      case AdminTab.bookings:
        return _buildBookingsTab();
      case AdminTab.artCenters:
        return _buildArtCentersTab();
      case AdminTab.government:
        return _buildGovernmentTab();
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
              '${_artists.length} artists',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('New artist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
              onPressed: () => context.push(
                RouteNames.artistRegistration,
                extra: {'fromAdmin': true},
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_artists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No artists registered yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                title: artist.name,
                subtitle: '${artist.category} · ${artist.location.isNotEmpty ? artist.location : 'Dubai, UAE'}',
                badgeText: isActive ? 'Active' : 'Inactive',
                isPurpleBadge: isActive,
                onToggleStatus: () => _toggleArtistStatus(artist, index),
                onEdit: () {
                  context.push(RouteNames.artistDetail, extra: artist);
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Artist Profile',
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
          content: Text('${artist.name} is now ${newActive ? "Active" : "Inactive"}'),
          backgroundColor: newActive ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- 2. Events Tab ---
  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_events.length} events',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('New event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
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
        if (_events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No events created yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
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
              final isActive = ev.isActive;
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime} - ${ev.location}',
                badgeText: isActive ? 'Active' : 'Inactive',
                isPurpleBadge: isActive,
                onToggleStatus: () => _toggleEventStatus(ev, index),
                onEdit: () async {
                  await context.push(
                    RouteNames.createArtEvent,
                    extra: {'event': ev, 'fromAdmin': true},
                  );
                  _loadAllData();
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Event',
                    message: 'Are you sure you want to delete "${ev.title}"?',
                    onConfirm: () async {
                      setState(() => _events.removeAt(index));
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

  Future<void> _toggleEventStatus(ArtEventModel ev, int index) async {
    final newActive = !ev.isActive;
    final newStatus = newActive ? 'active' : 'inactive';
    final updated = ev.copyWith(isActive: newActive, status: newStatus);

    setState(() {
      _events[index] = updated;
    });

    await sl<ApiService>().updateEvent({
      'id': int.tryParse(ev.id) ?? ev.id,
      'status': newStatus,
      'is_active': newActive ? 1 : 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${ev.title}" is now ${newActive ? "Active" : "Inactive"}'),
          backgroundColor: newActive ? const Color(0xFF6A2777) : const Color(0xFF64748B),
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
              '${_events.length} calendar events',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Add to calendar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No upcoming events.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
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
              final isActive = ev.isActive;
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime} - ${ev.locationCity ?? ev.location}',
                badgeText: isActive ? 'Scheduled' : 'Cancelled',
                isPurpleBadge: isActive,
                isRedBadge: !isActive,
                onToggleStatus: () => _toggleCalendarEventStatus(ev, index),
                onEdit: () async {
                  await context.push(
                    RouteNames.createArtEvent,
                    extra: {
                      'event': ev,
                      'isCalendar': true,
                      'fromAdmin': true,
                    },
                  );
                  _loadAllData();
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Remove from Calendar',
                    message: 'Are you sure you want to remove "${ev.title}" from the calendar?',
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
    final newActive = !ev.isActive;
    final newStatus = newActive ? 'active' : 'cancelled';
    final updated = ev.copyWith(isActive: newActive, status: newStatus);

    setState(() {
      _events[index] = updated;
    });

    await sl<ApiService>().updateEvent({
      'id': int.tryParse(ev.id) ?? ev.id,
      'status': newStatus,
      'is_active': newActive ? 1 : 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${ev.title}" is now ${newActive ? "Scheduled" : "Cancelled"}'),
          backgroundColor: newActive ? const Color(0xFF6A2777) : const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isItemPending(Map<String, dynamic> item) {
    final rawStatus = (item['status'] ?? '').toString().trim().toLowerCase();
    if (rawStatus == 'pending' || rawStatus == 'awaiting' || rawStatus == 'in_review' || rawStatus == 'unapproved') {
      return true;
    }
    if (rawStatus == 'approved' || rawStatus == 'active' || rawStatus == 'open') {
      return false;
    }
    final isApproved = item['is_approved'];
    if (isApproved == 0 || isApproved == '0' || isApproved == false || isApproved == 'false') {
      return true;
    }
    final isPublic = item['is_public'];
    if (isPublic == 0 || isPublic == '0' || isPublic == false || isPublic == 'false') {
      return true;
    }
    return false;
  }

  Future<void> _toggleGalleryApproval(Map<String, dynamic> item, int index) async {
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
          content: Text(isCurrentlyPending
              ? '"$name" activated and published to app!'
              : '"$name" set to pending (hidden from public).'),
          backgroundColor: isCurrentlyPending ? const Color(0xFF16A34A) : const Color(0xFFD97706),
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
          children: const [
            Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text(
              'Public photo galleries',
              style: TextStyle(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text('New gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
            onPressed: _showCreateGalleryDialog,
          ),
        ),
        const SizedBox(height: 12),
        if (_galleries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No galleries registered.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
              return _buildListItemCard(
                title: name,
                subtitle: (gal['description'] != null && gal['description'].toString().isNotEmpty
                    ? gal['description']
                    : (gal['artist_name'] != null && gal['artist_name'].toString().isNotEmpty
                        ? 'Artist: ${gal['artist_name']}'
                        : 'Artist photo collection')).toString(),
                badgeText: isPending ? 'Pending' : 'Approved',
                isPurpleBadge: !isPending,
                isAmberBadge: isPending,
                onApprove: isPending ? () => _approveGallery(gal, index) : null,
                onToggleStatus: () => _toggleGalleryApproval(gal, index),
                onEdit: () => _showCreateGalleryDialog(existing: gal, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Gallery',
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

  // --- 5. Bookings Tab ---
  Widget _buildBookingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_bookings.length} bookings',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('New booking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
              onPressed: _showCreateBookingDialog,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_bookings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No bookings registered yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = _bookings[index];
              final eventTitle = (b['event_title'] ?? '').toString();
              final userName = (b['full_name'] ?? b['artist_name'] ?? '').toString();
              final status = (b['status'] ?? 'Confirmed').toString().trim();
              final date = (b['event_date'] ?? b['created_at'] ?? '').toString();

              final isPending = status.toLowerCase() == 'pending';
              final isConfirmed = status.toLowerCase() == 'confirmed';
              final isCompleted = status.toLowerCase() == 'completed';
              final isCancelled = status.toLowerCase() == 'cancelled';

              final title = eventTitle.isNotEmpty
                  ? eventTitle
                  : (userName.isNotEmpty ? userName : 'Booking #${b['id'] ?? (index + 1)}');
              final subtitle = userName.isNotEmpty && eventTitle.isNotEmpty
                  ? '$userName • $date'
                  : (date.isNotEmpty ? date : 'Dubai, UAE');

              return _buildListItemCard(
                title: title,
                subtitle: subtitle,
                badgeText: status,
                isPurpleBadge: isConfirmed,
                isAmberBadge: isPending,
                isGreenBadge: isCompleted,
                isRedBadge: isCancelled,
                onApprove: isPending ? () => _acceptBooking(b, index) : null,
                onToggleStatus: () => _toggleBookingStatus(b, index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Booking',
                    message: 'Are you sure you want to delete this booking?',
                    onConfirm: () async {
                      final id = b['id'];
                      setState(() => _bookings.removeAt(index));
                      if (id != null) {
                        await sl<ApiService>().deleteBooking(id);
                      }
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickBookingDateTime(
    BuildContext ctx,
    TextEditingController controller,
    StateSetter setModalState,
  ) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: ctx,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
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

    if (pickedDate == null) return;
    if (!ctx.mounted) return;

    final pickedTime = await showTimePicker(
      context: ctx,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
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

    final datePart =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    final formatted = pickedTime != null
        ? '$datePart ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'
        : datePart;

    setModalState(() {
      controller.text = formatted;
    });
  }

  void _showCreateBookingDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final eventTitleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    String selectedStatus = 'Confirmed';

    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New booking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(label: 'Guest / Artist Name', controller: nameCtrl, isFocused: true),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Email', controller: emailCtrl, keyboardType: TextInputType.emailAddress, hint: 'guest@example.com'),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Phone', controller: phoneCtrl, keyboardType: TextInputType.phone, hint: '+971 50 123 4567'),
                  const SizedBox(height: 12),
                  _buildFormField(label: 'Event / Booking Title', controller: eventTitleCtrl, hint: 'Exhibition entry / Art workshop'),
                  const SizedBox(height: 12),
                  _buildFormField(
                    label: 'Date & Time',
                    controller: dateCtrl,
                    hint: 'Select event date & time',
                    readOnly: true,
                    suffixIcon: Icons.calendar_today_outlined,
                    onTap: () => _pickBookingDateTime(ctx, dateCtrl, setModalState),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedStatus,
                        underline: const SizedBox(),
                        items: ['Confirmed', 'Pending', 'Completed', 'Cancelled']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => selectedStatus = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final payload = {
                        'full_name': name,
                        'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : 'admin@technestpartners.com',
                        'phone': phoneCtrl.text.trim(),
                        'event_title': eventTitleCtrl.text.trim().isNotEmpty ? eventTitleCtrl.text.trim() : 'Art Event Booking',
                        'event_date': dateCtrl.text.trim(),
                        'status': selectedStatus,
                      };
                      Navigator.pop(ctx);
                      setState(() {
                        _bookings.insert(0, payload);
                      });
                      await sl<ApiService>().createBooking(payload);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Booking for "$name" created successfully!'),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Save booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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

  Future<void> _toggleBookingStatus(Map<String, dynamic> b, int index) async {
    final currentStatus = (b['status'] ?? 'pending').toString().toLowerCase();
    String newStatus;
    if (currentStatus == 'pending') {
      newStatus = 'confirmed';
    } else if (currentStatus == 'confirmed') {
      newStatus = 'completed';
    } else if (currentStatus == 'completed') {
      newStatus = 'cancelled';
    } else {
      newStatus = 'confirmed';
    }

    final id = b['id'];
    final updated = Map<String, dynamic>.from(b);
    updated['status'] = newStatus[0].toUpperCase() + newStatus.substring(1);

    setState(() {
      _bookings[index] = updated;
    });

    if (id != null) {
      await sl<ApiService>().updateBookingStatus(bookingId: id, status: newStatus);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to ${updated['status']}'),
          backgroundColor: const Color(0xFF6A2777),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await _refreshBookings();
  }

  Future<void> _acceptBooking(Map<String, dynamic> b, int index) async {
    final id = b['id'];
    final updated = Map<String, dynamic>.from(b);
    updated['status'] = 'Confirmed';

    setState(() {
      _bookings[index] = updated;
    });

    if (id != null) {
      await sl<ApiService>().updateBookingStatus(bookingId: id, status: 'confirmed');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking accepted and confirmed!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await _refreshBookings();
  }

  /// Force-refresh all bookings from MySQL (admin: no email filter)
  Future<void> _refreshBookings() async {
    try {
      final fresh = await sl<ApiService>().getBookings(forceRefresh: true);
      if (mounted) {
        setState(() => _bookings = fresh);
      }
    } catch (_) {}
  }

  // --- 6. Art Centers Tab (Screenshot 1 & Screenshot 5) ---
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
              '${_artCenters.length} centers',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('New center', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
              onPressed: _showArtCenterDialog,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_artCenters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No art centers yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
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
              final name = (center['name'] ?? center['title'] ?? 'Art Center').toString();
              final subtitle = (center['category'] ?? center['location'] ?? center['address'] ?? 'Dubai, UAE').toString();
              final isCurrentlyOpen = center['currently_open'] == 1 || center['currently_open'] == true;
              final isPending = _isItemPending(center);
              return _buildListItemCard(
                title: name,
                subtitle: subtitle,
                badgeText: isPending ? 'Pending' : (isCurrentlyOpen ? 'Open' : 'Closed'),
                isPurpleBadge: !isPending && isCurrentlyOpen,
                isAmberBadge: isPending,
                isRedBadge: !isPending && !isCurrentlyOpen,
                onApprove: isPending ? () => _approveGallery(center, index) : null,
                onToggleStatus: () => _toggleArtCenterStatus(center, index),
                onEdit: () => _showArtCenterDialog(existing: center, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Art Center',
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

  Future<void> _toggleArtCenterStatus(Map<String, dynamic> center, int index) async {
    final isCurrentlyOpen = center['currently_open'] == 1 || center['currently_open'] == true;
    final isPending = _isItemPending(center);
    final newOpen = isPending ? 1 : (isCurrentlyOpen ? 0 : 1);
    final newStatus = isPending ? 'approved' : (newOpen == 1 ? 'approved' : 'inactive');

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
          content: Text('${center['name'] ?? 'Art Center'} is now ${newOpen == 1 ? "OPEN" : "CLOSED"}!'),
          backgroundColor: newOpen == 1 ? const Color(0xFF6A2777) : const Color(0xFF64748B),
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
              '${_govEntities.length} entries',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('New entry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
              onPressed: () => _showGovernmentDialog(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_govEntities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No government entries registered.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                    title: 'Delete Government Entry',
                    message: 'Are you sure you want to remove "${g.name}"?',
                    onConfirm: () async {
                      setState(() => _govEntities.removeAt(index));
                      await sl<ApiService>().deleteGovernmentEntity(id: g.id, name: g.name);
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
    final newTiming = newIsOpen ? 'Open · Closes at 18:00' : 'Closed · Opens tomorrow';
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
      _govEntities[index] = updated;
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
          content: Text('${entity.name} is now ${newIsOpen ? "Open" : "Closed"}'),
          backgroundColor: newIsOpen ? const Color(0xFF6A2777) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  entity.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleGovernmentOpen(entity, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: entity.defaultIsOpen ? const Color(0xFF6A2777) : const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entity.defaultIsOpen ? 'Open' : 'Closed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            entity.category,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            entity.location,
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
                '${entity.rating} ★ · ${entity.reviewCount} reviews',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1E293B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
    String? badgeText,
    bool isPurpleBadge = false,
    bool isAmberBadge = false,
    bool isGreenBadge = false,
    bool isRedBadge = false,
    VoidCallback? onApprove,
    VoidCallback? onToggleStatus,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
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
              ],
            ),
          ),
          if (badgeText != null) ...[
            MouseRegion(
              cursor: onToggleStatus != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: badgeBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleStatus != null && (isPurpleBadge || isGreenBadge)) ...[
                        const Icon(Icons.check, size: 11, color: Colors.white),
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
            ),
            const SizedBox(width: 8),
          ],
          if (onApprove != null) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(58, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onApprove,
              child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
