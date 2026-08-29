import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.bookings);
      if (response is Map<String, dynamic> && response['data'] is List) {
        if (mounted) {
          setState(() {
            _bookings = response['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            // "My Bookings" Sub-Header with Back Arrow & Home Action
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'My Bookings',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage your event bookings',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
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

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF5E227A)),
                    )
                  : _bookings.isEmpty
                      ? _buildEmptyState()
                      : _buildBookingsList(),
            ),

            const AppBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final name = booking['full_name'] ?? 'Guest Booking';
        final artist = booking['artist_name'] ?? 'Artist Request';
        final type = booking['booking_type'] ?? 'Custom Request';
        final status = booking['status'] ?? 'Pending';
        final budget = booking['budget_range'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A2777),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Artist: ${artist.toString()} • Type: ${type.toString()}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                if (budget.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ${budget.toString()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Color(0xFF4A5568),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Bookings Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You haven\'t booked any events yet. Start exploring events to make your first booking!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E227A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  context.push(RouteNames.eventsCompetition);
                },
                child: const Text(
                  'Browse Events',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
