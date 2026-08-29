import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class CreateArtEventView extends StatefulWidget {
  const CreateArtEventView({super.key});

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

  String? _selectedCategory;
  bool _isFreeEvent = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Exhibition & Gallery Showcase',
    'Art Competition & Contest',
    'Workshop & Masterclass',
    'Art Fair & Festival',
    'Gallery Opening',
    'Live Performance & Painting',
    'Other Art Event',
  ];

  @override
  void initState() {
    super.initState();
    _eventTitleController = TextEditingController();
    _descriptionController = TextEditingController();
    _eventDateController = TextEditingController();
    _endDateController = TextEditingController();
    _locationController = TextEditingController(text: 'Dubai, UAE');
    _venueController = TextEditingController();
    _organizerNameController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _notesController = TextEditingController();
    _tagsController = TextEditingController();
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
    super.dispose();
  }

  void _submitEvent() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post(
        ApiEndpoints.events,
        data: {
          'title':
              _eventTitleController.text.trim().isEmpty
                  ? 'New Art Event'
                  : _eventTitleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory ?? 'Exhibition & Gallery Showcase',
          'event_date': _eventDateController.text.trim(),
          'end_date': _endDateController.text.trim(),
          'location':
              _locationController.text.trim().isEmpty
                  ? 'Dubai, UAE'
                  : _locationController.text.trim(),
          'venue': _venueController.text.trim(),
          'is_free': _isFreeEvent ? 1 : 0,
          'organizer_name': _organizerNameController.text.trim(),
          'contact_email': _contactEmailController.text.trim(),
          'contact_phone': _contactPhoneController.text.trim(),
          'tags': _tagsController.text.trim(),
        },
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Art Event saved dynamically to database!'),
            backgroundColor: Color(0xFF5E227A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(RouteNames.eventsCompetition);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: ${e.toString()}'),
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
                          children: const [
                            Text(
                              'Create Art Event',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E227A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Organize and promote your art event in Dubai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('End Date & Time (Optional)'),
                      _buildTextField(
                        controller: _endDateController,
                        hintText: 'dd-mm-yyyy --:--',
                        suffixIcon: Icons.calendar_today_outlined,
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

                      // SECTION 3: Ticketing
                      _buildSectionTitle(
                        icon: Icons.attach_money,
                        title: 'Ticketing',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          value: _isFreeEvent,
                          activeColor: const Color(0xFF5E227A),
                          title: const Text(
                            'Free Event',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          subtitle: const Text(
                            'This event is free to attend',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _isFreeEvent = val;
                            });
                          },
                        ),
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
                                        : const Text(
                                          'Create Event',
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
            const AppBottomNavBar(currentIndex: 2),
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
    IconData? prefixIcon,
    IconData? suffixIcon,
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
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
                : null,
        suffixIcon:
            suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: const Color(0xFF64748B))
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
