import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

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
      _selectedCategory = ev.category;
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

  Future<void> _loadDynamicCategories() async {
    try {
      final fetched = await sl<ApiService>().getEventCategories();
      final filtered = fetched.where((c) => c != 'All Categories' && c != 'All').toList();
      if (mounted && filtered.isNotEmpty) {
        setState(() {
          _categories = filtered;
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
          'event_date': _eventDateController.text.trim().isEmpty ? '15 Oct 2026' : _eventDateController.text.trim(),
          'end_date': _endDateController.text.trim(),
          'location': _locationController.text.trim().isEmpty ? 'Dubai, UAE' : _locationController.text.trim(),
          'venue': _venueController.text.trim(),
          'price': 'Free Entry',
          'max_attendees': parsedCapacity,
          'tags': _tagsController.text.trim(),
        });
      } else {
        success = await sl<ApiService>().createEvent(
          title: title,
          description: _descriptionController.text.trim(),
          category: _selectedCategory ?? (_categories.isNotEmpty ? _categories.first : 'Art Exhibition'),
          eventDate: _eventDateController.text.trim().isEmpty ? '15 Oct 2026' : _eventDateController.text.trim(),
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Arrow & Top Icon Header (Matching Screenshot media_1787728280911.png)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black87,
                            ),
                            onPressed: () => context.pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Spacer(),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF5E227A),
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 24),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title & Subtitle
                      Center(
                        child: Column(
                          children: [
                            Text(
                              isEdit ? 'Edit Art Event' : 'Create Art Event',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E227A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isEdit
                                  ? 'Update and manage your art event in Dubai'
                                  : 'Organize and promote your art event in Dubai',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SECTION 1: Event Details
                      _buildSectionTitle(
                        icon: Icons.calendar_today_outlined,
                        title: 'Event Details',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Event Title'),
                      _buildTextField(
                        controller: _eventTitleController,
                        hintText: 'Enter event title',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Description'),
                      _buildTextField(
                        controller: _descriptionController,
                        hintText: 'Describe your event..',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Event Category'),
                      _buildDropdownField(
                        value: _selectedCategory,
                        hintText: 'Select event category',
                        items: _categories,
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                       _buildLabel('Event Date & Time'),
                       _buildTextField(
                         controller: _eventDateController,
                         hintText: 'dd-mm-yyyy --:--',
                         suffixIcon: Icons.calendar_today_outlined,
                         onTap: () => _pickDateTime(_eventDateController),
                       ),
                       const SizedBox(height: 14),
                       _buildLabel('End Date & Time (Optional)'),
                       _buildTextField(
                         controller: _endDateController,
                         hintText: 'dd-mm-yyyy --:--',
                         suffixIcon: Icons.calendar_today_outlined,
                         onTap: () => _pickDateTime(_endDateController),
                       ),
                      const SizedBox(height: 28),

                      // SECTION 2: Location
                      _buildSectionTitle(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Location'),
                      _buildTextField(
                        controller: _locationController,
                        hintText: 'Dubai, UAE',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Venue (Optional)'),
                      _buildTextField(
                        controller: _venueController,
                        hintText: 'Gallery name or address',
                      ),
                      const SizedBox(height: 28),

                      // SECTION 3: Capacity & Attendance
                      _buildSectionTitle(
                        icon: Icons.people_outline,
                        title: 'Attendance & Capacity',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Maximum Capacity (Total RSVP Limit)'),
                      _buildTextField(
                        controller: _maxTicketsController,
                        hintText: 'e.g. 100',
                        prefixIcon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 28),

                      // SECTION 4: Organizer Information
                      _buildSectionTitle(
                        icon: Icons.people_outline,
                        title: 'Organizer Information',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Organizer Name'),
                      _buildTextField(
                        controller: _organizerNameController,
                        hintText: 'Your name or organization',
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Contact Email'),
                      _buildTextField(
                        controller: _contactEmailController,
                        hintText: 'your@email.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Contact Phone (Optional)'),
                      _buildTextField(
                        controller: _contactPhoneController,
                        hintText: '+971 50 XXX XXXX',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Requirements or Notes'),
                      _buildTextField(
                        controller: _notesController,
                        hintText:
                            'Any special requirements, dress code, or additional information..',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Tags (comma-separated)'),
                      _buildTextField(
                        controller: _tagsController,
                        hintText: 'art, exhibition, gallery, painting',
                      ),
                      const SizedBox(height: 28),

                      // Action Row: Cancel & Create Event
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
                                  backgroundColor: const Color(0xFF5E227A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : _submitEvent,
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
                                        : Text(
                                           isEdit ? 'Update Event' : 'Create Event',
                                           style: const TextStyle(
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
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
    return DropdownButtonFormField<String>(
      value: value,
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
