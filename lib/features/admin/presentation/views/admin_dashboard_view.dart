import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
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
        final galleries = results[2] as List<Map<String, dynamic>>;
        setState(() {
          _artists = results[0] as List<ArtistModel>;
          _events = results[1] as List<ArtEventModel>;
          _galleries = galleries;
          _artCenters = galleries;
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
                        'name': name,
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
                          name: name,
                          defaultIsOpen: isCurrentlyOpen,
                          rating: double.tryParse(ratingCtrl.text.trim()) ?? 4.5,
                          reviewCount: int.tryParse(reviewsCtrl.text.trim()) ?? 100,
                          category: typeCtrl.text.trim(),
                          location: addressCtrl.text.trim(),
                          defaultTiming: statusTextCtrl.text.trim(),
                          websiteUrl: websiteCtrl.text.trim(),
                          directionsUrl: existing.directionsUrl,
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

                  _buildFormField(label: 'Opening hours', controller: hoursCtrl, hint: 'Sat–Thu 10:00–20:00'),
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
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                            hint: const Text(
                              'No event',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No event', style: TextStyle(fontSize: 13.5, color: Color(0xFF1E293B))),
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
                        'description': descCtrl.text.trim(),
                        'image_url': coverImageCtrl.text.trim(),
                        'cover_url': coverImageCtrl.text.trim(),
                        'event_name': selectedEvent ?? '',
                        'is_public': isVisibleToEveryone ? 1 : 0,
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
  }) {
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
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        ),
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
      bottomNavigationBar: const AppBottomNavBar(),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_outlined,
                count: '${_events.length}',
                label: 'Events',
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.confirmation_number_outlined,
                count: '${_bookings.length}',
                label: 'Bookings',
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A2777), size: 22),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
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
    if (_artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No artists registered yet.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _artists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _buildListItemCard(
          title: artist.name,
          subtitle: artist.location.isNotEmpty ? artist.location : 'Dubai, UAE',
          badgeText: artist.category,
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
    );
  }

  // --- 2. Events Tab ---
  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push(RouteNames.createArtEvent),
            child: const Text('New event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
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
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate} - ${ev.location}',
                badgeText: 'active',
                isStatusBadge: true,
                onEdit: () {
                  context.push(RouteNames.createArtEvent, extra: ev);
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

  // --- 3. Calendar Tab ---
  Widget _buildCalendarTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push(RouteNames.createArtEvent),
            child: const Text('Add to calendar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 24),
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
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime} - ${ev.locationCity ?? ev.location}',
                badgeText: 'Scheduled',
                isStatusBadge: true,
                onEdit: () => context.push(RouteNames.createArtEvent, extra: ev),
                onDelete: () {
                  _confirmDelete(
                    title: 'Remove from Calendar',
                    message: 'Are you sure you want to delete "${ev.title}" from the database calendar?',
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
                subtitle: (gal['category'] ?? gal['location'] ?? 'Artist gallery').toString(),
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
    if (_bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No bookings visible.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = _bookings[index];
        final eventTitle = b['event_title'] as String? ?? '';
        final userName = b['full_name'] as String? ?? b['artist_name'] as String? ?? '';
        final status = b['status'] as String? ?? 'Confirmed';
        final date = b['event_date'] as String? ?? b['created_at'] as String? ?? '';

        final title = eventTitle.isNotEmpty
            ? eventTitle
            : (userName.isNotEmpty ? userName : 'Booking #${b['id'] ?? (index + 1)}');
        final subtitle = userName.isNotEmpty && eventTitle.isNotEmpty
            ? '$userName • $date'
            : date;

        return _buildListItemCard(
          title: title,
          subtitle: subtitle,
          badgeText: status,
          isStatusBadge: true,
        );
      },
    );
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
                badgeText: isPending ? 'Pending' : (isCurrentlyOpen ? 'Open' : 'Active'),
                isPurpleBadge: !isPending,
                isAmberBadge: isPending,
                onApprove: isPending ? () => _approveGallery(center, index) : null,
                onToggleStatus: () => _toggleGalleryApproval(center, index),
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
                onEdit: () => _showGovernmentDialog(existing: g, index: index),
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Government Entry',
                    message: 'Are you sure you want to remove "${g.name}"?',
                    onConfirm: () async {
                      setState(() => _govEntities.removeAt(index));
                      await sl<ApiService>().deleteGovernmentEntity(name: g.name);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // Government Card matching Screenshot 2
  Widget _buildGovernmentCard({
    required GovernmentEntity entity,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: entity.defaultIsOpen ? const Color(0xFF6A2777) : const Color(0xFF94A3B8),
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
    bool isStatusBadge = false,
    bool isPurpleBadge = false,
    bool isAmberBadge = false,
    VoidCallback? onApprove,
    VoidCallback? onToggleStatus,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
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
            InkWell(
              onTap: onToggleStatus,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAmberBadge
                      ? const Color(0xFFFEF3C7)
                      : (isPurpleBadge
                          ? const Color(0xFF6A2777)
                          : (isStatusBadge ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC))),
                  borderRadius: BorderRadius.circular(12),
                  border: isPurpleBadge
                      ? null
                      : Border.all(
                          color: isAmberBadge ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isAmberBadge
                        ? const Color(0xFFD97706)
                        : (isPurpleBadge ? Colors.white : const Color(0xFF334155)),
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
