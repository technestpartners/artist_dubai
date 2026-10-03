import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../data/chat_service.dart';
import '../../domain/models/artist_message_model.dart';

class ArtistChatView extends StatefulWidget {
  const ArtistChatView({super.key});

  @override
  State<ArtistChatView> createState() => _ArtistChatViewState();
}

class _ArtistChatViewState extends State<ArtistChatView> {
  int _selectedTabIndex = 0; // 0 = Messages, 1 = Send
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  ArtistModel? _selectedArtist;
  List<ArtistModel> _allArtists = [];
  bool _isLoadingArtists = false;

  Uint8List? _attachedFlyerBytes;
  String? _attachedFlyerName;
  bool _isSending = false;

  List<ArtistMessageModel> _messages = [];
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadArtists();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoadingMessages = true);
    final msgs = await sl<ChatService>().getMessages();
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoadingArtists = true);
    try {
      final res = await sl<ApiService>().getArtists();
      if (mounted) {
        setState(() {
          _allArtists = res;
          _isLoadingArtists = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingArtists = false);
    }
  }

  Future<void> _pickFlyerImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _attachedFlyerBytes = bytes;
          _attachedFlyerName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'.trData(context)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _openArtistSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = _allArtists.where((a) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return a.name.toLowerCase().contains(q) ||
                  a.category.toLowerCase().contains(q) ||
                  a.location.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Artist'.trData(modalCtx),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search artist by name or category...'.trData(modalCtx),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF5E227A)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingArtists
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5E227A)))
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No artists found'.trData(modalCtx),
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (itemCtx, index) {
                                  final artist = filtered[index];
                                  final isSelected = _selectedArtist?.id == artist.id;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF5E227A),
                                      backgroundImage: artist.avatarUrl.isNotEmpty
                                          ? NetworkImage(artist.avatarUrl)
                                          : null,
                                      child: artist.avatarUrl.isEmpty
                                          ? Text(
                                              artist.name.isNotEmpty
                                                  ? artist.name[0].toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      artist.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF5E227A)
                                            : const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${artist.category} • ${artist.location}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: Color(0xFF5E227A))
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedArtist = artist;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSendMessage() async {
    if (_selectedArtist == null) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write your message.'.trData(context)),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final chatService = sl<ChatService>();
    if (!chatService.canSendMessage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monthly message limit reached. Upgrade your plan for more.'.trData(context)),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'Plans'.trData(context),
            textColor: Colors.white,
            onPressed: () => context.push(RouteNames.listingPlans),
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      String? flyerUrl;
      if (_attachedFlyerBytes != null) {
        flyerUrl = await sl<ApiService>().uploadImageBytes(_attachedFlyerBytes!, ext: 'jpg');
      }

      await chatService.sendMessage(
        recipientId: _selectedArtist!.id,
        recipientName: _selectedArtist!.name,
        recipientCategory: _selectedArtist!.category,
        recipientAvatarUrl: _selectedArtist!.avatarUrl,
        subject: _subjectController.text.trim().isEmpty ? 'Direct Artist Message' : _subjectController.text.trim(),
        message: message,
        flyerUrl: flyerUrl,
      );

      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedArtist = null;
        _attachedFlyerBytes = null;
        _attachedFlyerName = null;
        _selectedTabIndex = 0; // Switch to Messages tab
      });

      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent successfully!'.trData(context)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'.trData(context)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessageDetailModal(ArtistMessageModel msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5E227A),
              backgroundImage: (msg.recipientAvatarUrl != null && msg.recipientAvatarUrl!.isNotEmpty)
                  ? NetworkImage(msg.recipientAvatarUrl!)
                  : null,
              child: (msg.recipientAvatarUrl == null || msg.recipientAvatarUrl!.isEmpty)
                  ? Text(
                      msg.recipientName.isNotEmpty ? msg.recipientName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.recipientName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    msg.recipientCategory,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.subject.isNotEmpty) ...[
                Text(
                  msg.subject,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                msg.message,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
              ),
              if (msg.flyerUrl != null && msg.flyerUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg.flyerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Sent: ${msg.createdAt.year}-${msg.createdAt.month.toString().padLeft(2, '0')}-${msg.createdAt.day.toString().padLeft(2, '0')} ${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'.trData(ctx), style: const TextStyle(color: Color(0xFF5E227A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final chatService = sl<ChatService>();
    final remainingMessages = chatService.getRemainingAllowance();
    final maxMessages = chatService.getMaxMonthlyAllowance();

    return Scaffold(
      backgroundColor: const Color(0xFF5E227A),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: rh.horizontalPadding,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title & Subtitle (Image 2 & 3)
                    Text(
                      'ARTIST CHAT'.trData(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send a private message to another artist.'.trData(context),
                      style: const TextStyle(
                        color: Color(0xFFE2D4F0),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Allowance Card (Image 2 & 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$remainingMessages of $maxMessages messages left this month'.trData(context),
                                  style: const TextStyle(
                                    color: Color(0xFF1E1E1E),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your allowance resets on the 1st. Upgrade your plan for more.'.trData(context),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.push(RouteNames.listingPlans),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E227A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Plans'.trData(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Two-tab Switcher (Messages | Send)
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Tab 0: Messages
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _selectedTabIndex = 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0
                                      ? const Color(0xFF5E227A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: _selectedTabIndex == 0
                                      ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Messages'.trData(context),
                                  style: TextStyle(
                                    color: _selectedTabIndex == 0 ? Colors.white : const Color(0xFFD4BEE4),
                                    fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Tab 1: Send
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _selectedTabIndex = 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1
                                      ? const Color(0xFF5E227A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: _selectedTabIndex == 1
                                      ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Send'.trData(context),
                                  style: TextStyle(
                                    color: _selectedTabIndex == 1 ? Colors.white : const Color(0xFFD4BEE4),
                                    fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Content Body
                    if (_selectedTabIndex == 0)
                      _buildMessagesTab()
                    else
                      _buildSendTab(),

                    const SizedBox(height: 36),

                    // Hosted by Nizar Fahem Footer (Image 2 & 3)
                    Center(
                      child: Text(
                        'Hosted by Nizar Fahem'.trData(context),
                        style: const TextStyle(
                          color: Color(0xFFD4BEE4),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoadingMessages) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_messages.isEmpty) {
      // Empty state (matching Image 2)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'No messages yet. Search for an artist in the Send tab to start a conversation.'.trData(context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
    }

    return Column(
      children: _messages.map((msg) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF5E227A),
              backgroundImage: (msg.recipientAvatarUrl != null && msg.recipientAvatarUrl!.isNotEmpty)
                  ? NetworkImage(msg.recipientAvatarUrl!)
                  : null,
              child: (msg.recipientAvatarUrl == null || msg.recipientAvatarUrl!.isEmpty)
                  ? Text(
                      msg.recipientName.isNotEmpty ? msg.recipientName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    msg.recipientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${msg.createdAt.month}/${msg.createdAt.day}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.subject.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    msg.subject,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  msg.message,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (msg.flyerUrl != null && msg.flyerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attachment, size: 14, color: Color(0xFF5E227A)),
                      const SizedBox(width: 4),
                      Text(
                        'Flyer attached'.trData(context),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF5E227A), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            onTap: () => _showMessageDetailModal(msg),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSendTab() {
    final hasArtist = _selectedArtist != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Send to artist" header
          Text(
            'Send to artist'.trData(context),
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Search artist by name... field (deep purple container)
          InkWell(
            onTap: _openArtistSearchModal,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5E227A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFD4BEE4), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: hasArtist
                        ? Text(
                            '${_selectedArtist!.name} (${_selectedArtist!.category})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Search artist by name...'.trData(context),
                            style: const TextStyle(
                              color: Color(0xFFD4BEE4),
                              fontSize: 13.5,
                            ),
                          ),
                  ),
                  if (hasArtist)
                    GestureDetector(
                      onTap: () => setState(() => _selectedArtist = null),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    )
                  else
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFD4BEE4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Subject field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5E227A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Subject'.trData(context),
                hintStyle: const TextStyle(color: Color(0xFFD4BEE4), fontSize: 13.5),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Write your message... multiline textarea
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5E227A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Write your message...'.trData(context),
                hintStyle: const TextStyle(color: Color(0xFFD4BEE4), fontSize: 13.5),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Attach a flyer image (optional)
          InkWell(
            onTap: _pickFlyerImage,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 20, color: Color(0xFF5E227A)),
                  const SizedBox(width: 8),
                  Text(
                    'Attach a flyer image (optional)'.trData(context),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_attachedFlyerBytes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    _attachedFlyerBytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _attachedFlyerName ?? 'Flyer selected',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                  onPressed: () {
                    setState(() {
                      _attachedFlyerBytes = null;
                      _attachedFlyerName = null;
                    });
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Notice text
          Text(
            'This is a private message to the selected artist and uses 1 of your 10 monthly messages.'.trData(context),
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // 5. Submit Button (Disabled or Enabled)
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: (!hasArtist || _isSending) ? null : _handleSendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasArtist ? const Color(0xFF5E227A) : const Color(0xFFBCA6C8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBCA6C8),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          hasArtist
                              ? 'Send Message'.trData(context)
                              : 'Select an artist first'.trData(context),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
