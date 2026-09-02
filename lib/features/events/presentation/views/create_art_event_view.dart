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
import '../../../../core/widgets/app_cached_image.dart';

import '../../domain/models/art_event_model.dart';

class CreateArtEventView extends StatefulWidget {
  final ArtEventModel? event;

  const CreateArtEventView({super.key, this.event});

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
  bool _isSubmitting = false;

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
      _uploadedImageUrl = ev.imageUrl;
      if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
        _categories.insert(0, _selectedCategory!);
      }
    } else {
      _eventTitleController = TextEditingController();
      _descriptionController = TextEditingController();
      _eventDateController = TextEditingController();
      _endDateController = TextEditingController();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF6A2777)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF6A2777)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
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

    final hour = pickedTime?.hour ?? 18;
    final minute = pickedTime?.minute ?? 0;
    final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, hour, minute);

    final formatted =
        '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

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
      final parsedCapacity = int.tryParse(_maxTicketsController.text.trim()) ?? 100;
      bool success = false;

      if (isEdit) {
        success = await sl<ApiService>().updateEvent({
          'id': widget.event!.id,
          'title': title,
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          'event_date': eventDate,
          'end_date': _endDateController.text.trim(),
          'location': _locationController.text.trim().isEmpty ? 'Dubai, UAE' : _locationController.text.trim(),
          'venue': _venueController.text.trim(),
          'price': 'Free Entry',
          'max_attendees': parsedCapacity,
          'tags': _tagsController.text.trim(),
          if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) 'image_url': _uploadedImageUrl!,
        });
      } else {
        success = await sl<ApiService>().createEvent(
          title: title,
          description: _descriptionController.text.trim(),
          category: _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          eventDate: eventDate,
          endDate: _endDateController.text.trim(),
          location: _locationController.text.trim().isEmpty ? 'Dubai, UAE' : _locationController.text.trim(),
          venue: _venueController.text.trim(),
          isFree: true,
          price: 'Free Entry',
          maxAttendees: parsedCapacity,
          organizerName: _organizerNameController.text.trim(),
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          tags: _tagsController.text.trim(),
          imageUrl: _uploadedImageUrl,
        );
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          sl<LiveSyncService>().notifyEventsChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Art Event updated successfully in database!'
                    : 'Art Event saved dynamically to database!',
              ),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.myEvents);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save art event. Please check inputs.'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppTopBar(backgroundColor: Colors.white),
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
                          color: const Color(0xFFF1E6F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2D1E8)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A2777).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_note,
                                color: Color(0xFF6A2777),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit ? 'EDIT ART EVENT' : 'CREATE ART EVENT',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEdit
                                        ? 'Update details, tickets, and photos for this event.'
                                        : 'Publish a new exhibition, workshop, or cultural gathering.',
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
                              maxLines: 3,
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
                            _buildTextField(
                              controller: _locationController,
                              hintText: 'UAE',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pricing & Capacity Card
                      _buildCardSection(
                        title: 'Pricing & Capacity',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: true,
                                    activeColor: const Color(0xFF2563EB),
                                    onChanged: (val) {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'This is a free event',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Max Attendees (Optional)'),
                            _buildTextField(
                              controller: _maxTicketsController,
                              hintText: 'Leave empty for unlimited',
                              keyboardType: TextInputType.number,
                            ),
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

                      // Action Row: Cancel & Update Event
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.pop(),
                            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E227A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isSubmitting ? null : _submitEvent,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    isEdit ? 'Update Event' : 'Create Event',
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
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
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: onTap != null,
      onTap: onTap,
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
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
                : null,
        suffixIcon:
            suffixIcon != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Icon(suffixIcon, size: 18, color: const Color(0xFF64748B)),
                  )
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
    final uniqueItems = items.toSet().toList();
    final validValue = (value != null && uniqueItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
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
}
