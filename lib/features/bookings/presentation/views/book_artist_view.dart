import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class BookArtistView extends StatefulWidget {
  const BookArtistView({super.key, this.artistName});

  final String? artistName;

  @override
  State<BookArtistView> createState() => _BookArtistViewState();
}

class _BookArtistViewState extends State<BookArtistView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _artistNameController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requirementsController;

  String? _selectedBookingType;
  String? _selectedBudgetRange;
  bool _isSubmitting = false;

  final List<String> _bookingTypes = [
    'Commission Artwork',
    'Live Performance / Painting',
    'Exhibition & Display',
    'Workshop & Masterclass',
    'Art Consultation',
    'Other Custom Request',
  ];

  final List<String> _budgetRanges = [
    'Under AED 1,000',
    'AED 1,000 - 5,000',
    'AED 5,000 - 15,000',
    'AED 15,000 - 50,000',
    'AED 50,000+',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _artistNameController = TextEditingController(
      text: widget.artistName ?? '',
    );
    _eventDateController = TextEditingController();
    _endDateController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _requirementsController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _artistNameController.dispose();
    _eventDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
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
              primary: Color(0xFF5E227A),
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
              primary: Color(0xFF5E227A),
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

  void _submitBooking() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await sl<ApiService>().createBooking({
        'full_name': _fullNameController.text.trim().isEmpty
            ? 'Valued Art Collector'
            : _fullNameController.text.trim(),
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'artist_name': _artistNameController.text.trim(),
        'booking_type': _selectedBookingType ?? 'Commission Artwork',
        'budget_range': _selectedBudgetRange ?? 'AED 5,000 - 15,000',
        'event_date': _eventDateController.text.trim().isNotEmpty
            ? _eventDateController.text.trim()
            : 'Flexible Date',
        'end_date': _endDateController.text.trim(),
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'Dubai, UAE',
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'total_price': _selectedBudgetRange ?? 'AED 1500+',
        'status': 'Confirmed',
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          sl<LiveSyncService>().notifyBookingsChanged();
          try {
            sl<NotificationService>().addNotification(
              title: 'Booking Request Sent!',
              body:
                  'Your booking request for ${_artistNameController.text.trim()} was successfully submitted.',
              icon: Icons.calendar_month_outlined,
              route: RouteNames.bookings,
            );
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request submitted and saved to database!'),
              backgroundColor: Color(0xFF5E227A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(RouteNames.bookings);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your inputs and try again.'),
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
            content: Text('Failed to submit booking: ${e.toString()}'),
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
                      // Sub-Header Back Button & Circular Palette Badge (Matching Screenshot media_1787732959782.png)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF1E1E1E),
                              size: 20,
                            ),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(RouteNames.home);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.palette_outlined,
                              color: Color(0xFF6A2777),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title & Subtitle Header
                      Center(
                        child: Column(
                          children: const [
                            Text(
                              'Book an Artist',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A2777),
                              ),
                            ),
                            SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Connect with talented artists for your project or event',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main White Form Container Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SECTION 1: Your Information
                            _buildSectionTitle(
                              icon: Icons.person_outline,
                              title: 'Your Information',
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Full Name'),
                            _buildTextField(
                              controller: _fullNameController,
                              hintText: 'Enter your full name',
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Email'),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'your@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Phone'),
                            _buildTextField(
                              controller: _phoneController,
                              hintText: '+971 50 XXX XXXX',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 28),

                            // SECTION 2: Artist & Booking Details
                            _buildSectionTitle(
                              icon: Icons.palette_outlined,
                              title: 'Artist & Booking Details',
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Artist Name'),
                            _buildTextField(
                              controller: _artistNameController,
                              hintText:
                                  'Enter artist name or leave empty if booking any artist',
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Booking Type'),
                            _buildDropdownField(
                              value: _selectedBookingType,
                              hintText: 'Select booking type',
                              items: _bookingTypes,
                              onChanged: (val) {
                                setState(() {
                                  _selectedBookingType = val;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Budget Range (Optional)'),
                            _buildDropdownField(
                              value: _selectedBudgetRange,
                              hintText: 'Select budget range',
                              items: _budgetRanges,
                              onChanged: (val) {
                                setState(() {
                                  _selectedBudgetRange = val;
                                });
                              },
                            ),
                            const SizedBox(height: 28),

                            // SECTION 3: Event Details
                            _buildSectionTitle(
                              icon: Icons.calendar_today_outlined,
                              title: 'Event Details',
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
                            const SizedBox(height: 14),
                            _buildLabel('Location'),
                            _buildTextField(
                              controller: _locationController,
                              hintText: 'Dubai, UAE or specific venue',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Project Description'),
                            _buildTextField(
                              controller: _descriptionController,
                              hintText:
                                  'Describe your project, event, or commission in detail. Include style preferences, themes, and any specific requirements..',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Specific Requirements (Optional)'),
                            _buildTextField(
                              controller: _requirementsController,
                              hintText:
                                  'Any special materials, techniques, timeline constraints, or other requirements..',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),

                            // Note Callout Box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    height: 1.45,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Note: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'This is a booking request. The artist will review your request and contact you directly to discuss details, pricing, and availability. Response time is typically within 24-48 hours.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Row: Cancel & Submit Booking Request
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF333333),
                                          width: 1.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go(RouteNames.home);
                                        }
                                      },
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
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6A2777,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          _isSubmitting ? null : _submitBooking,
                                      child:
                                          _isSubmitting
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : const Text(
                                                'Submit Booking Request',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
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
