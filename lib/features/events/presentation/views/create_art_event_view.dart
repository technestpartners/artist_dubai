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

import '../../../../core/widgets/app_cached_image.dart';

import '../../../admin/domain/models/publishing_pricing_model.dart';
import '../../domain/models/art_event_model.dart';

class CreateArtEventView extends StatefulWidget {
  final ArtEventModel? event;
  final bool isCalendar;
  final bool fromAdmin;
  final bool showBottomBar;

  const CreateArtEventView({
    super.key,
    this.event,
    this.isCalendar = false,
    this.fromAdmin = false,
    this.showBottomBar = true,
  });

  @override
  State<CreateArtEventView> createState() => _CreateArtEventViewState();
}

class _CreateArtEventViewState extends State<CreateArtEventView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _eventTitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _locationController;
  late final TextEditingController _venueController;
  late final TextEditingController _organizerNameController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  late final TextEditingController _maxTicketsController;

  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  String? _selectedCategory;
  String? _selectedLocation = 'Dubai, UAE';
  bool _isSubmitting = false;

  String _selectedPublishingPlan = 'weekly';
  PublishingPricingModel? _eventPricing;

  List<String> _categories = [
    'Art Exhibition',
    'Gallery Opening',
    'Art Workshop',
    'Artist Talk',
    'Art Fair',
    'Sculpture Installation',
    'Photography Exhibition',
    'Cultural Festival',
    'Art Competition',
    'Community Art Project',
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

  @override
  void initState() {
    super.initState();
    String prefilledOrganizer = 'Artist Dubai';
    String prefilledEmail = '';
    try {
      final storage = sl<StorageService>();
      final uName = storage.getString('user_name');
      final uEmail = storage.getString('user_email');
      if (uName != null && uName.isNotEmpty) prefilledOrganizer = uName;
      if (uEmail != null && uEmail.isNotEmpty) prefilledEmail = uEmail;
    } catch (_) {}

    final ev = widget.event;
    if (ev != null) {
      _eventTitleController = TextEditingController(text: ev.title);
      _descriptionController = TextEditingController(text: ev.description);
      _eventDateController = TextEditingController(
        text: ev.dateTime.isNotEmpty ? ev.dateTime : ev.formattedDate,
      );
      _endDateController = TextEditingController();
      _locationController = TextEditingController(text: ev.location);
      _venueController = TextEditingController(text: ev.locationCity ?? '');
      _organizerNameController = TextEditingController(
        text: ev.organizer.isNotEmpty ? ev.organizer : prefilledOrganizer,
      );
      _contactEmailController = TextEditingController(
        text: ev.organizerEmail != null && ev.organizerEmail!.isNotEmpty
            ? ev.organizerEmail!
            : prefilledEmail,
      );
      _contactPhoneController = TextEditingController();
      _notesController = TextEditingController(text: ev.requirements);
      _tagsController = TextEditingController(text: ev.tags.join(', '));
      _maxTicketsController = TextEditingController(
        text: ev.maxAttendees.toString(),
      );
      _selectedCategory = ev.category.isNotEmpty ? ev.category : null;
      _selectedLocation = ev.location.isNotEmpty ? ev.location : 'Dubai, UAE';
      if (_selectedLocation != null && !_locations.contains(_selectedLocation)) {
        _locations.insert(0, _selectedLocation!);
      }
      _uploadedImageUrl = ev.imageUrl;
      if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
        _categories.insert(0, _selectedCategory!);
      }
      if (ev.publishingPlan != null && ev.publishingPlan!.isNotEmpty) {
        _selectedPublishingPlan = ev.publishingPlan!;
      }
    } else {
      _eventTitleController = TextEditingController();
      _descriptionController = TextEditingController();
      _eventDateController = TextEditingController();
      _endDateController = TextEditingController();
      _selectedLocation = 'Dubai, UAE';
      _locationController = TextEditingController(text: 'Dubai, UAE');
      _venueController = TextEditingController();
      _organizerNameController = TextEditingController(text: prefilledOrganizer);
      _contactEmailController = TextEditingController(text: prefilledEmail);
      _contactPhoneController = TextEditingController();
      _notesController = TextEditingController();
      _tagsController = TextEditingController();
      _maxTicketsController = TextEditingController(text: '100');
    }
    _loadDynamicCategories();
    _loadDynamicLocations();
    _loadPublishingPricing();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
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
                content: Text('Event image uploaded successfully!'),
                backgroundColor: Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
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
              // Drag Handle
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

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Featured Image',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option 1: Choose from Gallery
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                              'Select a banner or photo from your device',
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

              // Option 2: Take a Photo
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                              'Use your camera to capture an event image',
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

  Future<void> _loadDynamicCategories() async {
    try {
      final fetched = await sl<ApiService>().getEventCategories();
      final filtered = fetched.where((c) => c != 'All Categories' && c != 'All').toList();
      if (mounted && filtered.isNotEmpty) {
        setState(() {
          final combined = <String>{..._categories, ...filtered}.toList();
          _categories = combined;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDynamicLocations() async {
    try {
      final fetched = await sl<ApiService>().getLocations();
      final names = fetched.map((l) => l.name).where((n) => n.trim().isNotEmpty).toList();
      if (mounted && names.isNotEmpty) {
        setState(() {
          _locations = <String>{..._locations, ...names}.toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPublishingPricing() async {
    try {
      final pricingList = await sl<ApiService>().getPublishingPricing();
      final evPricing = pricingList.firstWhere(
        (p) => p.itemType == 'event',
        orElse: () => const PublishingPricingModel(
          id: 1,
          itemType: 'event',
          itemName: 'Event Publishing',
          weeklyPrice: 'AED 150',
          monthlyPrice: 'AED 500',
          yearlyPrice: 'AED 4,500',
          currency: 'AED',
        ),
      );
      if (mounted) {
        setState(() {
          _eventPricing = evPricing;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
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

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
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
        '${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}';
    final formatted = pickedTime != null
        ? '$datePart ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'
        : datePart;

    setState(() {
      controller.text = formatted;
    });
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    _organizerNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _maxTicketsController.dispose();
    super.dispose();
  }

  void _submitEvent() async {
    final title = _eventTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the event title.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eventDate = _eventDateController.text.trim();
    if (eventDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the event date.'),
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
      final isEdit = widget.event != null;
      bool isAdmin = widget.fromAdmin;
      try {
        final storage = sl<StorageService>();
        if (!isAdmin) {
          isAdmin = storage.getBool('is_admin') ?? false;
        }
      } catch (_) {}

      final parsedCapacity = int.tryParse(_maxTicketsController.text.trim()) ?? 100;
      final selectedLoc = (_selectedLocation != null && _selectedLocation!.trim().isNotEmpty)
          ? _selectedLocation!.trim()
          : (_locationController.text.trim().isEmpty ? 'Dubai, UAE' : _locationController.text.trim());
      final publishingAmount = _eventPricing?.getPriceForPlan(_selectedPublishingPlan) ??
          (_selectedPublishingPlan == 'monthly' ? 'AED 500' : (_selectedPublishingPlan == 'yearly' ? 'AED 4,500' : 'AED 150'));
      bool success = false;

      if (isEdit) {
        success = await sl<ApiService>().updateEvent({
          'id': widget.event!.id,
          'title': title,
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          'event_date': eventDate,
          'end_date': _endDateController.text.trim(),
          'location': selectedLoc,
          'venue': _venueController.text.trim(),
          'price': 'Free Entry',
          'max_attendees': parsedCapacity,
          'tags': _tagsController.text.trim(),
          'publishing_plan': _selectedPublishingPlan,
          'publishing_amount': publishingAmount,
          if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) 'image_url': _uploadedImageUrl!,
        });
      } else {
        success = await sl<ApiService>().createEvent(
          title: title,
          description: _descriptionController.text.trim(),
          category: _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          eventDate: eventDate,
          endDate: _endDateController.text.trim(),
          location: selectedLoc,
          venue: _venueController.text.trim(),
          isFree: true,
          price: 'Free Entry',
          maxAttendees: parsedCapacity,
          organizerName: _organizerNameController.text.trim(),
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          tags: _tagsController.text.trim(),
          imageUrl: _uploadedImageUrl,
          status: isAdmin ? 'active' : 'pending',
          isActive: isAdmin,
          fromAdmin: isAdmin,
          publishingPlan: _selectedPublishingPlan,
          publishingAmount: publishingAmount,
        );
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          sl<LiveSyncService>().notifyEventsChanged();

          if (isEdit || isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isCalendar
                      ? (isEdit ? 'Calendar event updated successfully!' : 'Event scheduled on calendar successfully!')
                      : (isEdit ? 'Event updated successfully!' : 'Event created and published successfully!'),
                ),
                backgroundColor: const Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.fromAdmin ? RouteNames.adminDashboard : RouteNames.myEvents);
            }
          } else {
            // User submitted event request to admin
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: const [
                    Icon(Icons.mark_email_read_outlined, color: Color(0xFF6A2777), size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Request Sent to Admin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your event "$title" has been successfully submitted for administrative review.',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Once approved by the admin, it will be published in the public directory.',
                              style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.myEvents);
                      }
                    },
                    child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go(RouteNames.myEvents);
                    },
                    child: const Text('View My Events', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save event. Please check inputs.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;

    final appBarTitle = widget.isCalendar
        ? (isEdit ? 'Edit Calendar Event' : 'Add to Calendar')
        : (isEdit ? 'Edit Event' : 'Create Event');

    final headerTitle = widget.isCalendar
        ? (isEdit ? 'EDIT CALENDAR EVENT' : 'SCHEDULE CALENDAR EVENT')
        : (isEdit ? 'EDIT ART EVENT' : 'CREATE ART EVENT');

    final headerSubtitle = widget.isCalendar
        ? (isEdit ? 'Update scheduled exhibition or calendar date.' : 'Schedule an upcoming exhibition, showcase, or cultural date on the calendar.')
        : (isEdit ? 'Update details, tickets, and photos for this event.' : 'Publish a new exhibition, workshop, or cultural gathering.');

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B1C9B),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.fromAdmin ? RouteNames.adminDashboard : RouteNames.events);
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B1C9B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isCalendar ? Icons.calendar_month_rounded : Icons.event_note,
                                color: const Color(0xFF6B1C9B),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    headerSubtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Featured Image Card
                      _buildCardSection(
                        title: 'Featured Image',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isUploadingImage) ...[
                              Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Color(0xFF6A2777)),
                                      SizedBox(height: 8),
                                      Text('Uploading image to server...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_selectedImage != null || (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)) ...[
                              Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _selectedImage != null
                                          ? (kIsWeb
                                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                                          : AppCachedImage(imageUrl: _uploadedImageUrl!, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                            _uploadedImageUrl = null;
                                          });
                                        },
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
                                      foregroundColor: const Color(0xFF6A2777),
                                      side: const BorderSide(color: Color(0xFF6A2777)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Change Image', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    onPressed: () => _showImageSourceActionSheet(context),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('Uploaded', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1E293B),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.upload_outlined, size: 16),
                                    label: const Text('Upload Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    onPressed: () => _showImageSourceActionSheet(context),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Select banner from device gallery or take a photo (JPG, PNG, WebP).',
                                      style: TextStyle(fontSize: 11, color: const Color(0xFF64748B).withValues(alpha: 0.8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Event Information Card
                      _buildCardSection(
                        title: 'Event Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Event Title'),
                            _buildTextField(
                              controller: _eventTitleController,
                              hintText: 'Enter event title',
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Category'),
                            _buildDropdownField(
                              value: _selectedCategory,
                              hintText: 'Select category',
                              items: _categories,
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategory = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Description'),
                            _buildTextField(
                              controller: _descriptionController,
                              hintText: 'Describe your event..',
                              maxLines: 4,
                              maxLength: 2000,
                              showCounter: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date & Time Card
                      _buildCardSection(
                        title: 'Date & Time',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Start Date & Time'),
                            _buildTextField(
                              controller: _eventDateController,
                              hintText: 'dd-mm-yyyy --:--',
                              suffixIcon: Icons.calendar_today_outlined,
                              onTap: () => _pickDateTime(_eventDateController),
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('End Date & Time (Optional)'),
                            _buildTextField(
                              controller: _endDateController,
                              hintText: 'dd-mm-yyyy --:--',
                              suffixIcon: Icons.calendar_today_outlined,
                              onTap: () => _pickDateTime(_endDateController),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location Card
                      _buildCardSection(
                        title: 'Location',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Venue Name (Optional)'),
                            _buildTextField(
                              controller: _venueController,
                              hintText: 'e.g., Dubai Opera',
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Address/Location'),
                            _buildSearchableLocationField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),


                      // Additional Details Card
                      _buildCardSection(
                        title: 'Additional Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Phone Number (Optional)'),
                            _buildTextField(
                              controller: _contactPhoneController,
                              hintText: '+971 50 123 4567',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Requirements (Optional)'),
                            _buildTextField(
                              controller: _notesController,
                              hintText: 'Any special requirements or instructions for attendees..',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Tags (Optional)'),
                            _buildTextField(
                              controller: _tagsController,
                              hintText: 'Add tags (press Enter to add)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Event Publishing Notice (Paid Service)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B1C9B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PAID PUBLISHING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Choose Publishing Plan',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Publishing events is a paid service on Artist Dubai. Select your preferred promotion duration. Once reviewed and approved by the admin, your event will be broadcasted to art enthusiasts across Dubai.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 460;
                                final weeklyPrice = _eventPricing?.weeklyPrice ?? 'AED 150';
                                final monthlyPrice = _eventPricing?.monthlyPrice ?? 'AED 500';
                                final yearlyPrice = _eventPricing?.yearlyPrice ?? 'AED 4,500';

                                final cards = [
                                  _buildPricingPlanCard(
                                    id: 'weekly',
                                    title: 'Weekly',
                                    price: weeklyPrice,
                                    period: '/ week',
                                    subtitle: '7 days active',
                                    tag: null,
                                  ),
                                  _buildPricingPlanCard(
                                    id: 'monthly',
                                    title: 'Monthly',
                                    price: monthlyPrice,
                                    period: '/ month',
                                    subtitle: '30 days active',
                                    tag: 'POPULAR',
                                  ),
                                  _buildPricingPlanCard(
                                    id: 'yearly',
                                    title: 'Yearly',
                                    price: yearlyPrice,
                                    period: '/ year',
                                    subtitle: '365 days active',
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
                      const SizedBox(height: 20),

                      // Action Row: Cancel & Update Event
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(widget.fromAdmin ? RouteNames.adminDashboard : RouteNames.events);
                              }
                            },
                            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6B1C9B),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isSubmitting ? null : _submitEvent,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Color(0xFF6B1C9B), strokeWidth: 2),
                                  )
                                : Text(
                                    isEdit
                                        ? (widget.isCalendar ? 'Update Calendar Event' : 'Update Event')
                                        : (widget.isCalendar ? 'Schedule on Calendar' : 'Create Event'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
      bottomNavigationBar: (!widget.fromAdmin && !widget.isCalendar && widget.showBottomBar)
          ? const AppBottomNavBar(currentIndex: 2)
          : null,
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
    IconData? prefixIcon,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
    VoidCallback? onTap,
  }) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: onTap != null,
      enableInteractiveSelection: onTap == null,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: showCounter ? null : '',
        counterStyle: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.normal,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
                : null,
        suffixIcon:
            suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: const Color(0xFF6A2777))
                : null,
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
          borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
        ),
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: true,
            child: field,
          ),
        ),
      );
    }
    return field;
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = items.toSet().toList();
    final validValue = (value != null && uniqueItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
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
      items: uniqueItems.map((item) {
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

  Widget _buildSearchableLocationField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _locations;
            }
            return _locations.where((loc) =>
                loc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          initialValue: TextEditingValue(text: _selectedLocation ?? 'Dubai, UAE'),
          onSelected: (String selection) {
            setState(() {
              _selectedLocation = selection;
              _locationController.text = selection;
            });
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
                fontSize: 14.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search or select location (e.g. Dubai, UAE)',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.normal,
                ),
                suffixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6A2777),
                  size: 20,
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
                  borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
                ),
              ),
              onChanged: (val) {
                _selectedLocation = val;
                _locationController.text = val;
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
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      final isSelected = option == _selectedLocation;
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF5EBF7)
                                : Colors.transparent,
                            border: index < options.length - 1
                                ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                      width: 1,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF6A2777)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isSelected
                                        ? const Color(0xFF6A2777)
                                        : const Color(0xFF1E293B),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF6A2777),
                                ),
                            ],
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
      },
    );
  }

  Widget _buildPricingPlanCard({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B1C9B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B1C9B).withValues(alpha: 0.12),
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
                        color: isSelected ? const Color(0xFF6B1C9B) : const Color(0xFF334155),
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected ? const Color(0xFF6B1C9B) : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (tag != null)
              Positioned(
                top: -6,
                right: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: tag == 'POPULAR' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 8,
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
