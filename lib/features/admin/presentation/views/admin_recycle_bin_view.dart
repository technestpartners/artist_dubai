import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';

/// Admin Recycle Bin Screen — soft-deleted items recovery & permanent deletion
class AdminRecycleBinView extends StatefulWidget {
  const AdminRecycleBinView({super.key});

  @override
  State<AdminRecycleBinView> createState() => _AdminRecycleBinViewState();
}

class _AdminRecycleBinViewState extends State<AdminRecycleBinView>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF6A2777);
  static const _redDanger = Color(0xFFDC2626);
  static const _greenRestore = Color(0xFF16A34A);

  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  late TabController _tabController;

  final List<_TabDef> _tabs = const [
    _TabDef('All', null, Icons.delete_outline_rounded),
    _TabDef('Artists', 'artists', Icons.palette_outlined),
    _TabDef('Events', 'events', Icons.event_outlined),
    _TabDef('Galleries', 'galleries', Icons.photo_library_outlined),
    _TabDef('Gov. Entities', 'government_entities', Icons.account_balance_outlined),
    _TabDef('Categories', 'categories', Icons.category_outlined),
    _TabDef('Locations', 'locations', Icons.location_on_outlined),
    _TabDef('Exp. Levels', 'experience_levels', Icons.workspace_premium_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrash();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrash() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final items = await sl<ApiService>().getTrash();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  List<Map<String, dynamic>> _itemsForTab(int index) {
    final filter = _tabs[index].typeFilter;
    if (filter == null) return _allItems;
    return _allItems.where((item) => item['type'] == filter).toList();
  }

  // ── Restore confirmation dialog ──────────────────────────────────────────
  void _confirmRestore(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Restore Item',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Restore "${item['display_name']}" (${item['label']}) so it becomes visible again in the app?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenRestore,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreItem(item);
            },
          ),
        ],
      ),
    );
  }

  // ── Permanent delete confirmation dialog ─────────────────────────────────
  void _confirmPermanentDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚠️  Delete Permanently',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        content: Text(
          'This will permanently erase "${item['display_name']}" from the database. This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _redDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Delete Forever', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _permanentDelete(item);
            },
          ),
        ],
      ),
    );
  }

  // ── Empty bin confirmation dialog ────────────────────────────────────────
  void _confirmEmptyBin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🗑️  Empty Recycle Bin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        content: Text(
          'All ${_allItems.length} item(s) in the bin will be permanently erased. This cannot be undone.',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _redDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Empty Bin', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _emptyBin();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await sl<ApiService>().restoreFromTrash(
      id: item['id'],
      type: item['type'] as String,
    );
    if (ok) {
      setState(() => _allItems.removeWhere(
            (i) => i['id'] == item['id'] && i['type'] == item['type'],
          ));
      messenger.showSnackBar(SnackBar(
        content: Text('✅  "${item['display_name']}" restored successfully'),
        backgroundColor: _greenRestore,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('Failed to restore item. Please try again.'),
        backgroundColor: _redDanger,
      ));
    }
  }

  Future<void> _permanentDelete(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await sl<ApiService>().permanentlyDeleteFromTrash(
      id: item['id'],
      type: item['type'] as String,
    );
    if (ok) {
      setState(() => _allItems.removeWhere(
            (i) => i['id'] == item['id'] && i['type'] == item['type'],
          ));
      messenger.showSnackBar(SnackBar(
        content: Text('🗑️  "${item['display_name']}" permanently deleted'),
        backgroundColor: const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('Failed to delete item. Please try again.'),
        backgroundColor: _redDanger,
      ));
    }
  }

  Future<void> _emptyBin() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await sl<ApiService>().emptyTrash();
    if (ok) {
      setState(() => _allItems.clear());
      messenger.showSnackBar(const SnackBar(
        content: Text('🗑️  Recycle bin emptied successfully'),
        backgroundColor: Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('Failed to empty bin. Please try again.'),
        backgroundColor: _redDanger,
      ));
    }
  }

  // ── Helper: entity icon ───────────────────────────────────────────────────
  IconData _iconForType(String type) {
    switch (type) {
      case 'artists': return Icons.palette_outlined;
      case 'events': return Icons.event_outlined;
      case 'galleries': return Icons.photo_library_outlined;
      case 'government_entities': return Icons.account_balance_outlined;
      case 'categories': return Icons.category_outlined;
      case 'locations': return Icons.location_on_outlined;
      case 'experience_levels': return Icons.workspace_premium_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'artists': return const Color(0xFF6A2777);
      case 'events': return const Color(0xFF0369A1);
      case 'galleries': return const Color(0xFF7C3AED);
      case 'government_entities': return const Color(0xFF0F766E);
      case 'categories': return const Color(0xFFD97706);
      case 'locations': return const Color(0xFFDC2626);
      case 'experience_levels': return const Color(0xFF1D4ED8);
      default: return const Color(0xFF64748B);
    }
  }

  // ── Time ago helper ───────────────────────────────────────────────────────
  String _timeAgo(String? deletedAt) {
    if (deletedAt == null || deletedAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(deletedAt.replaceAll(' ', 'T'));
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return deletedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Recycle Bin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (_allItems.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      '${_allItems.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Text(
              'Artist Dubai management',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (_allItems.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmEmptyBin,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFDC2626)),
              label: const Text(
                'Empty Bin',
                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          IconButton(
            onPressed: _loadTrash,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: const Color(0xFF6A2777),
                  indicatorWeight: 2.5,
                  labelColor: const Color(0xFF6A2777),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: _tabs.map((t) {
                    final index = _tabs.indexOf(t);
                    final count = _itemsForTab(index).length;
                    final isSelected = _tabController.index == index;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 14),
                          const SizedBox(width: 5),
                          Text(t.label),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? const Color(0xFF6A2777) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _purple),
                  SizedBox(height: 16),
                  Text('Loading recycle bin...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load recycle bin',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadTrash,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (i) => _buildTabContent(i)),
                ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final items = _itemsForTab(tabIndex);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tabIndex == 0 ? Icons.delete_outline_rounded : _tabs[tabIndex].icon,
              size: 72,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recycle Bin is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deleted items appear here and can be\nrestored or permanently removed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _purple,
      onRefresh: _loadTrash,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildItemCard(items[i]),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final name = item['display_name'] as String? ?? 'Untitled';
    final label = item['label'] as String? ?? type;
    final sub = item['entity_sub'] as String?;
    final imageUrl = item['image_url'] as String?;
    final deletedAt = item['deleted_at'] as String?;
    final color = _colorForType(type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail / icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(_iconForType(type), color: color, size: 26),
                    )
                  : Icon(_iconForType(type), color: color, size: 26),
            ),
            const SizedBox(width: 12),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (deletedAt != null)
                        Text(
                          'deleted ${_timeAgo(deletedAt)}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub != null && sub.isNotEmpty)
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restore button
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenRestore,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _confirmRestore(item),
                    icon: const Icon(Icons.restore_rounded, size: 14),
                    label: const Text('Restore'),
                  ),
                ),
                const SizedBox(height: 6),
                // Permanent delete button
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _redDanger,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _confirmPermanentDelete(item),
                    icon: const Icon(Icons.delete_forever_rounded, size: 14),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab definition data class ─────────────────────────────────────────────────
class _TabDef {
  final String label;
  final String? typeFilter; // null = All
  final IconData icon;
  const _TabDef(this.label, this.typeFilter, this.icon);
}
