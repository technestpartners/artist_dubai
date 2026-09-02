import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../domain/models/art_event_model.dart';

class EventsCompetitionView extends StatefulWidget {
  const EventsCompetitionView({super.key});

  @override
  State<EventsCompetitionView> createState() => _EventsCompetitionViewState();
}

class _EventsCompetitionViewState extends State<EventsCompetitionView> {
  List<Map<String, dynamic>> _competitions = [];
  StreamSubscription<List<ArtEventModel>>? _compSub;
  bool _isLoading = true;

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);
  static const Color _openBadge = Color(0xFF22C55E);
  static const Color _closedBadge = Color(0xFFEF4444);
  static const Color _upcomingBadge = Color(0xFFF59E0B);
  static const Color _purpleLight = Color(0xFF7B3FA0);

  @override
  void initState() {
    super.initState();
    final cached = sl<ApiService>().cachedCompetitions;
    if (cached != null && cached.isNotEmpty) {
      _competitions = List.from(cached);
      _isLoading = false;
    }
    _fetchCompetitions();
    _compSub = sl<LiveSyncService>().eventsStream.listen((_) {
      _fetchCompetitions(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _compSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchCompetitions({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_competitions.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await sl<ApiService>().getCompetitions(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _competitions = data.isNotEmpty ? data : ApiService.mockCompetitions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_competitions.isEmpty) {
            _competitions = ApiService.mockCompetitions;
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF651B8A),
          backgroundColor: Colors.white,
          onRefresh: () => _fetchCompetitions(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Title & Subtitle
                const Text(
                  'EVENTS COMPETITION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Open calls and art competitions in Dubai',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 18),

                // Mode Switcher: Art Events | Competitions & Open Calls
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.events);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                'Art Events',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Competitions & Open Calls',
                              style: TextStyle(
                                color: Color(0xFF651B8A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Loading State OR Empty State OR Main Announcement List
                if (_isLoading && _competitions.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ] else if (_competitions.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          color: Colors.white,
                          size: 46,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No competitions announced yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'New competitions will appear here as soon as they are published.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      'Hosted by Nizar Fahem',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  ..._competitions.map((c) => _buildCard(c)),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Hosted by Nizar Fahem',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
  );
}



  Widget _buildCard(Map<String, dynamic> c) {
    final status = c['status']?.toString() ?? 'open';
    final entriesCount = (c['entries_count'] is num)
        ? (c['entries_count'] as num).toInt()
        : int.tryParse(c['entries_count']?.toString() ?? '') ?? 0;
    final maxEntries = (c['max_entries'] is num)
        ? (c['max_entries'] as num).toInt()
        : int.tryParse(c['max_entries']?.toString() ?? '') ?? 500;
    final fillRatio = maxEntries > 0 ? entriesCount / maxEntries : 0.0;

    List<String> tags = [];
    if (c['tags'] is List) {
      tags = (c['tags'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (c['tags'] is String && (c['tags'] as String).isNotEmpty) {
      tags = (c['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    Color badgeColor;
    String badgeLabel;
    switch (status) {
      case 'open':
        badgeColor = _openBadge;
        badgeLabel = 'Open';
        break;
      case 'closed':
        badgeColor = _closedBadge;
        badgeLabel = 'Closed';
        break;
      default:
        badgeColor = _upcomingBadge;
        badgeLabel = 'Upcoming';
    }

    final imageUrl = c['image_url']?.toString() ?? '';
    final prize = c['prize']?.toString() ?? '';
    final title = c['title']?.toString() ?? '';
    final theme = c['theme']?.toString() ?? '';
    final organizer = c['organizer']?.toString() ?? '';
    final deadline = c['deadline']?.toString() ?? 'TBD';
    final location = c['location']?.toString() ?? 'Dubai, UAE';
    final entryFee = c['entry_fee']?.toString() ?? 'Free';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: AppCachedImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge + prize row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (prize.isNotEmpty) ...[
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          prize,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (theme.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Theme: $theme',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontStyle: FontStyle.italic),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Info row: organizer & deadline
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          organizer,
                          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.schedule, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        'Due: $deadline',
                        style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location & entry fee
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entryFee,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  if (maxEntries > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$entriesCount / $maxEntries entries',
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                        Text(
                          '${(fillRatio * 100).toInt()}% full',
                          style: TextStyle(
                            color: fillRatio > 0.9 ? _closedBadge : Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: fillRatio.clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fillRatio > 0.9 ? _closedBadge : _openBadge,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],

                  // Tags
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: status == 'closed' ? null : () => _showDetail(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'closed'
                            ? Colors.white.withValues(alpha: 0.08)
                            : _purpleLight,
                        foregroundColor: status == 'closed' ? Colors.white38 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        status == 'closed'
                            ? 'Competition Closed'
                            : status == 'upcoming'
                                ? 'View Details'
                                : 'Apply Now',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          final modalImageUrl = c['image_url']?.toString() ?? '';
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A1A7A), Color(0xFF2A1570)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (modalImageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppCachedImage(
                            imageUrl: modalImageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                    const SizedBox(height: 16),
                    Text(
                      c['title']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    if (c['theme'] != null && c['theme'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Theme: ${c['theme']}', style: const TextStyle(color: Colors.amber, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 12),
                    _detailRow(Icons.emoji_events, 'Prize', c['prize']?.toString() ?? 'N/A', Colors.amber),
                    _detailRow(Icons.schedule, 'Deadline', c['deadline']?.toString() ?? 'TBD', Colors.white),
                    _detailRow(Icons.person_outline, 'Organizer', c['organizer']?.toString() ?? '', Colors.white),
                    _detailRow(Icons.location_on_outlined, 'Location', c['location']?.toString() ?? '', Colors.white),
                    _detailRow(Icons.sell_outlined, 'Entry Fee', c['entry_fee']?.toString() ?? 'Free', Colors.white),
                    const SizedBox(height: 16),
                    if (c['description'] != null && c['description'].toString().isNotEmpty) ...[
                      _sectionTitle('About This Competition'),
                      Text(c['description'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 16),
                    ],
                    if (c['eligibility'] != null && c['eligibility'].toString().isNotEmpty) ...[
                      _sectionTitle('Eligibility'),
                      Text(c['eligibility'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 16),
                    ],
                    if (c['rules'] != null && c['rules'].toString().isNotEmpty) ...[
                      _sectionTitle('Rules & Submission'),
                      Text(c['rules'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 24),
                    ],
                    if (c['status'] != 'closed')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Application submitted! We will contact you shortly.'),
                                backgroundColor: Color(0xFF22C55E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Submit Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purpleLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _detailRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}
