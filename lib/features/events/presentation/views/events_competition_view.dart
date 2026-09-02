import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../domain/models/art_event_model.dart';

class EventsCompetitionView extends StatefulWidget {
  const EventsCompetitionView({super.key});

  @override
  State<EventsCompetitionView> createState() => _EventsCompetitionViewState();
}

class _EventsCompetitionViewState extends State<EventsCompetitionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _competitions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription<List<ArtEventModel>>? _compSub;

  static const Color _purple = Color(0xFF5E227A);
  static const Color _purpleLight = Color(0xFF7B3FA0);
  static const Color _bgGradientTop = Color(0xFF6B1C9B);
  static const Color _bgGradientBot = Color(0xFF4D249E);
  static const Color _cardBg = Color(0xFF301B92);
  static const Color _openBadge = Color(0xFF22C55E);
  static const Color _closedBadge = Color(0xFFEF4444);
  static const Color _upcomingBadge = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchCompetitions();
    _compSub = sl<LiveSyncService>().eventsStream.listen((_) {
      _fetchCompetitions(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _compSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompetitions({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = _competitions.isEmpty);
    try {
      final data = await sl<ApiService>().getCompetitions(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _competitions = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String? status) {
    var list = _competitions;
    if (status != null && status.isNotEmpty) {
      list = list.where((c) => c['status'] == status).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final title = (c['title'] as String? ?? '').toLowerCase();
        final theme = (c['theme'] as String? ?? '').toLowerCase();
        final organizer = (c['organizer'] as String? ?? '').toLowerCase();
        final category = (c['category'] as String? ?? '').toLowerCase();
        return title.contains(q) || theme.contains(q) || organizer.contains(q) || category.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(),
      body: Column(
        children: [
          // Hero header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgGradientTop, _bgGradientBot],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with trophy
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'EVENTS COMPETITION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open calls and art competitions in Dubai',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search competitions...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close, color: Colors.white54, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 14),

                // Tab bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2.5,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'All (${_competitions.length})'),
                    Tab(text: 'Open (${_filtered('open').length})'),
                    Tab(text: 'Upcoming (${_filtered('upcoming').length})'),
                    Tab(text: 'Closed (${_filtered('closed').length})'),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(null),
                _buildList('open'),
                _buildList('upcoming'),
                _buildList('closed'),
              ],
            ),
          ),

          // Hosted by footer
          Container(
            width: double.infinity,
            color: _bgGradientBot,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text(
              'Hosted by Nizar Fahem',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildList(String? status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final items = _filtered(status);

    if (items.isEmpty) {
      return _buildEmpty(status);
    }

    return RefreshIndicator(
      color: _purple,
      onRefresh: () => _fetchCompetitions(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildEmpty(String? status) {
    final label = status == null ? 'competitions' : '$status competitions';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.white38),
          ),
          const SizedBox(height: 20),
          Text(
            'No $label announced yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'New competitions will appear\nhere as soon as they are published.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetchCompetitions(forceRefresh: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'open';
    final entriesCount = c['entries_count'] as int? ?? 0;
    final maxEntries = c['max_entries'] as int? ?? 500;
    final fillRatio = maxEntries > 0 ? entriesCount / maxEntries : 0.0;
    final tags = (c['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

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
            if (c['image_url'] != null && (c['image_url'] as String).isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: AppCachedImage(
                  imageUrl: c['image_url'] as String,
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
                      if (c['prize'] != null) ...[
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          c['prize'] as String,
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
                    c['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (c['theme'] != null && (c['theme'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Theme: ${c['theme']}',
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
                          c['organizer'] as String? ?? '',
                          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.schedule, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${c['deadline'] ?? 'TBD'}',
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
                          c['location'] as String? ?? 'Dubai, UAE',
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
                          c['entry_fee'] as String? ?? 'Free',
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
        builder: (_, controller) => Container(
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
                    if (c['image_url'] != null && (c['image_url'] as String).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppCachedImage(
                          imageUrl: c['image_url'] as String,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      c['title'] as String? ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    if (c['theme'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Theme: ${c['theme']}', style: const TextStyle(color: Colors.amber, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 12),
                    _detailRow(Icons.emoji_events, 'Prize', c['prize'] as String? ?? 'N/A', Colors.amber),
                    _detailRow(Icons.schedule, 'Deadline', c['deadline'] as String? ?? 'TBD', Colors.white),
                    _detailRow(Icons.person_outline, 'Organizer', c['organizer'] as String? ?? '', Colors.white),
                    _detailRow(Icons.location_on_outlined, 'Location', c['location'] as String? ?? '', Colors.white),
                    _detailRow(Icons.sell_outlined, 'Entry Fee', c['entry_fee'] as String? ?? 'Free', Colors.white),
                    const SizedBox(height: 16),
                    if (c['description'] != null && (c['description'] as String).isNotEmpty) ...[
                      _sectionTitle('About This Competition'),
                      Text(c['description'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 16),
                    ],
                    if (c['eligibility'] != null && (c['eligibility'] as String).isNotEmpty) ...[
                      _sectionTitle('Eligibility'),
                      Text(c['eligibility'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 16),
                    ],
                    if (c['rules'] != null && (c['rules'] as String).isNotEmpty) ...[
                      _sectionTitle('Rules & Submission'),
                      Text(c['rules'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
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
        ),
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
