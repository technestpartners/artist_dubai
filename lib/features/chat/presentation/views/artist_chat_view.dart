import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
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
  int _messageFilterIndex = 0; // 0 = All, 1 = Inbox, 2 = Sent
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

  int _remainingMessages = 10;
  int _maxMessages = 10;
  String _planName = 'Basic (Free)';
  StreamSubscription<Map<String, dynamic>>? _allowanceSub;
  StreamSubscription<List<ArtistMessageModel>>? _messagesSub;
  Timer? _pollingTimer;

  String get _currentEmail => (sl<StorageService>().getString('user_email') ?? '').trim().toLowerCase();
  String get _currentArtistId => (sl<StorageService>().getString('artist_profile_id') ?? '').trim();
  String get _currentUserId => (sl<StorageService>().getString('user_id') ?? '').trim();

  bool _isIncomingMessage(ArtistMessageModel msg) {
    final myEmail = _currentEmail;
    final myArtistId = _currentArtistId;
    final myUserId = _currentUserId;

    // Messages sent by me are sent, not incoming
    if (myEmail.isNotEmpty && msg.senderEmail.toLowerCase() == myEmail) {
      return false;
    }
    if (myArtistId.isNotEmpty && msg.senderId == myArtistId) {
      return false;
    }
    if (myUserId.isNotEmpty && (msg.senderId == myUserId || msg.senderId == 'user_$myUserId')) {
      return false;
    }

    // Messages addressed to my artist profile, email, or user id are incoming
    if (myArtistId.isNotEmpty && msg.recipientId == myArtistId) {
      return true;
    }
    if (myEmail.isNotEmpty && (msg.recipientId.toLowerCase() == myEmail || msg.recipientName.toLowerCase() == myEmail)) {
      return true;
    }
    if (myUserId.isNotEmpty && (msg.recipientId == myUserId || msg.recipientId == 'user_$myUserId')) {
      return true;
    }

    // Fallback: if sender is different from my email, treat as incoming
    return myEmail.isNotEmpty && msg.senderEmail.toLowerCase() != myEmail;
  }

  void _handleReplyToMessage(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    final targetId = isIncoming ? msg.senderId : msg.recipientId;
    final targetName = isIncoming ? msg.senderName : msg.recipientName;
    final targetEmail = isIncoming ? msg.senderEmail : '';
    final targetAvatarUrl = isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;
    final targetCategory = isIncoming
        ? 'Artist'
        : (msg.recipientCategory.isNotEmpty ? msg.recipientCategory : 'Artist');

    ArtistModel? replyArtist;
    try {
      replyArtist = _allArtists.firstWhere(
        (a) => (targetEmail.isNotEmpty && a.email.toLowerCase() == targetEmail.toLowerCase()) ||
               (targetId.isNotEmpty && a.id == targetId) ||
               (targetName.isNotEmpty && a.name.toLowerCase() == targetName.toLowerCase()),
      );
    } catch (_) {}

    replyArtist ??= ArtistModel(
      id: targetId.isNotEmpty ? targetId : (targetEmail.isNotEmpty ? targetEmail : 'artist_${DateTime.now().millisecondsSinceEpoch}'),
      name: targetName.isNotEmpty ? targetName : 'Artist',
      category: targetCategory,
      location: 'Dubai',
      bio: '',
      avatarUrl: targetAvatarUrl ?? '',
      bannerUrl: '',
      followersCount: 0,
      worksCount: 0,
      email: targetEmail,
    );

    setState(() {
      _selectedArtist = replyArtist;
      _selectedTabIndex = 1; // Switch to Send tab
      final sub = msg.subject.trim();
      if (sub.isNotEmpty) {
        _subjectController.text = sub.toLowerCase().startsWith('re:') ? sub : 'Re: $sub';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
    final chatService = sl<ChatService>();
    _remainingMessages = chatService.getRemainingAllowance();
    _maxMessages = chatService.getMaxMonthlyAllowance();
    _planName = chatService.getChatPlanName();

    _allowanceSub = chatService.allowanceStream.listen((data) {
      if (mounted) {
        setState(() {
          _remainingMessages = data['remaining'] as int? ?? _remainingMessages;
          _maxMessages = data['max'] as int? ?? _maxMessages;
          _planName = data['planName'] as String? ?? _planName;
        });
      }
    });

    _messagesSub = chatService.messagesStream.listen((msgs) {
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingMessages = false;
        });
      }
    });

    // Auto-refresh messages every 10 seconds to detect new messages from other accounts
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _selectedTabIndex == 0) {
        _loadMessages(silent: true);
      }
    });

    _loadMessages();
    _loadArtists();
    chatService.syncAllowanceFromBackend();
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _allowanceSub?.cancel();
    _messagesSub?.cancel();
    _pollingTimer?.cancel();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && _messages.isEmpty) {
      setState(() => _isLoadingMessages = true);
    }
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

  Future<void> _pickFlyerImage([ImageSource source = ImageSource.gallery]) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
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

  void _showFlyerPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attach Flyer or Artwork'.trData(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF5E227A)),
                ),
                title: Text(
                  'Choose from Gallery'.trData(context),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Select an image from your photos'.trData(context),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFlyerImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF5E227A)),
                ),
                title: Text(
                  'Take a Photo'.trData(context),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Use camera to capture flyer'.trData(context),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFlyerImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlyerPreviewDialog() {
    if (_attachedFlyerBytes == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  child: Image.memory(
                    _attachedFlyerBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _attachedFlyerName ?? 'Flyer preview'.trData(context),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showFlyerPickerSheet();
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text('Change'.trData(context)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF5E227A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                                                  ? artist.name.trData(modalCtx)[0].toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      artist.name.trData(modalCtx),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF5E227A)
                                            : const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${artist.category.trData(modalCtx)} • ${artist.location.trData(modalCtx)}',
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
    if (_isSending) return;
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
            onPressed: () => _showChatPlansModal(context),
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
        _messageFilterIndex = 0; // Show in All so the user immediately sees the sent card
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

  void _showNetworkFlyerPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flyer Attachment'.trData(context),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Close'.trData(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetailModal(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    showDialog(
      context: context,
      builder: (ctx) {
        final translatedRecipientName = msg.recipientName.trData(ctx);
        final translatedSenderName = msg.senderName.trData(ctx);
        final translatedSubject = msg.subject.isNotEmpty ? msg.subject.trData(ctx) : '';
        final translatedMessage = msg.message.trData(ctx);
        final translatedCategory = msg.recipientCategory.trData(ctx);

        final displayName = isIncoming ? translatedSenderName : translatedRecipientName;
        final displaySubtitle = isIncoming
            ? (msg.senderEmail.isNotEmpty ? msg.senderEmail : 'Artist'.trData(ctx))
            : (translatedCategory.isNotEmpty ? translatedCategory : 'Artist'.trData(ctx));
        final displayAvatarUrl = isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;

        final date = msg.createdAt;
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthName = months[(date.month - 1).clamp(0, 11)];
        final hour = date.hour;
        final minute = date.minute.toString().padLeft(2, '0');
        final isPm = hour >= 12;
        final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final timeAmPm = '$formattedHour:$minute ${isPm ? 'PM' : 'AM'}';
        final formattedDateStr = '$monthName ${date.day}, ${date.year} • $timeAmPm';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header with Avatar, Details, Chip & Dismiss button
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF5E227A),
                        backgroundImage: (displayAvatarUrl != null && displayAvatarUrl.isNotEmpty)
                            ? NetworkImage(displayAvatarUrl)
                            : null,
                        child: (displayAvatarUrl == null || displayAvatarUrl.isEmpty)
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isIncoming
                                        ? '${'From:'.trData(ctx)} $displayName'
                                        : '${'To:'.trData(ctx)} $displayName',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isIncoming ? const Color(0xFFDCFCE7) : const Color(0xFFFAF5FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isIncoming ? const Color(0xFF86EFAC) : const Color(0xFFE9D5FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isIncoming ? Icons.mark_email_read_outlined : Icons.check_circle_outline_rounded,
                                        size: 11,
                                        color: isIncoming ? const Color(0xFF15803D) : const Color(0xFF5E227A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isIncoming ? 'Inbox'.trData(ctx) : 'Sent'.trData(ctx),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isIncoming ? const Color(0xFF15803D) : const Color(0xFF5E227A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displaySubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Close'.trData(ctx),
                        onPressed: () => Navigator.pop(ctx),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 2. Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Banner
                        if (translatedSubject.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF5E227A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subject:'.trData(ctx),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5E227A),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        translatedSubject,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Message Section Label
                        Text(
                          'MESSAGE'.trData(ctx),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Message Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SelectableText(
                            translatedMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF334155),
                              height: 1.55,
                            ),
                          ),
                        ),

                        // Attached Flyer Section
                        if (msg.flyerUrl != null && msg.flyerUrl!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'ATTACHED FLYER'.trData(ctx),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showNetworkFlyerPreview(context, msg.flyerUrl!),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Image.network(
                                    msg.flyerUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 180,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 80,
                                      color: const Color(0xFFF1F5F9),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image_outlined, size: 20, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Flyer preview unavailable'.trData(ctx),
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                    color: Colors.black.withValues(alpha: 0.6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tap to view full flyer'.trData(ctx),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Timestamp Row
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Text(
                              formattedDateStr,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 3. Actions Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Close'.trData(ctx),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleReplyToMessage(msg);
                          },
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: Text(
                            'Reply'.trData(ctx),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E227A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
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
      },
    );
  }

  void _showChatPlansModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isUnlimited = _maxMessages >= 9000;
            final isPro = !isUnlimited && _maxMessages >= 50;
            final isStarter = !isUnlimited && !isPro;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E227A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF5E227A), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chat Allowance Plans'.trData(modalCtx),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Upgrade to connect with more artists across dubai.'.trData(modalCtx),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        children: [
                          _buildPlanTierCard(
                            context: modalCtx,
                            name: 'Starter Plan',
                            price: 'Free',
                            allowanceText: '10 messages / month',
                            badge: 'Default',
                            features: [
                              '10 direct messages per month',
                              'Direct artist collaboration inquiries',
                              'Flyer & artwork attachment support',
                              'Allowance auto-resets on the 1st',
                            ],
                            isCurrent: isStarter,
                            onUpgrade: () => _handleUpgradePlan('Starter Plan', 10, sheetCtx),
                          ),
                          const SizedBox(height: 14),
                          _buildPlanTierCard(
                            context: modalCtx,
                            name: 'Pro Artist',
                            price: '49 AED',
                            allowanceText: '50 messages / month',
                            badge: 'Most Popular',
                            isFeatured: true,
                            features: [
                              '50 direct messages per month',
                              'Direct artist outreach & networking',
                              'Priority delivery in artist inboxes',
                              'High-resolution flyer attachments',
                              'Monthly reset on the 1st',
                            ],
                            isCurrent: isPro,
                            onUpgrade: () => _handleUpgradePlan('Pro Artist', 50, sheetCtx),
                          ),
                          const SizedBox(height: 14),
                          _buildPlanTierCard(
                            context: modalCtx,
                            name: 'Unlimited VIP',
                            price: '99 AED',
                            allowanceText: 'Unlimited messages',
                            badge: 'For Agencies & Curators',
                            features: [
                              'Unlimited direct artist messages',
                              'Verified VIP sender badge',
                              'Ideal for galleries, curators & agencies',
                              'Priority instant customer support',
                            ],
                            isCurrent: isUnlimited,
                            onUpgrade: () => _handleUpgradePlan('Unlimited VIP', 9999, sheetCtx),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              context.push(RouteNames.listingPlans);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.campaign_outlined, color: Color(0xFF5E227A), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Looking to publish events, galleries or art centres? View Listing Plans →'.trData(modalCtx),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5E227A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _handleUpgradePlan(String planName, int maxAllowance, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    final success = await sl<ChatService>().upgradePlan(
      planName: planName,
      maxAllowance: maxAllowance,
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            maxAllowance >= 9000
                ? 'Upgraded to $planName! You now have unlimited messages.'.trData(context)
                : 'Upgraded to $planName! Your monthly allowance is now $maxAllowance messages.'.trData(context),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildPlanTierCard({
    required BuildContext context,
    required String name,
    required String price,
    required String allowanceText,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onUpgrade,
    String? badge,
    bool isFeatured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFFFAF5FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF10B981)
              : isFeatured
                  ? const Color(0xFF5E227A)
                  : const Color(0xFFE2E8F0),
          width: isFeatured || isCurrent ? 2 : 1,
        ),
        boxShadow: [
          if (isFeatured)
            BoxShadow(
              color: const Color(0xFF5E227A).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    name.trData(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFeatured ? const Color(0xFF5E227A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge.trData(context),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFeatured ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Active Plan'.trData(context),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price.trData(context),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5E227A),
                ),
              ),
              if (price != 'Free') ...[
                const SizedBox(width: 4),
                Text(
                  '/ month'.trData(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(
                '• ${allowanceText.trData(context)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f.trData(context),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFeatured ? const Color(0xFF5E227A) : const Color(0xFFF1F5F9),
                foregroundColor: isFeatured ? Colors.white : const Color(0xFF1E1E1E),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                isCurrent
                    ? 'Current Plan'.trData(context)
                    : isFeatured
                        ? 'Upgrade to Pro'.trData(context)
                        : (price == 'Free' ? 'Select Plan' : 'Upgrade').trData(context),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF5E227A),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5E227A),
          backgroundColor: Colors.white,
          onRefresh: () async {
            await _loadMessages();
            await sl<ChatService>().syncAllowanceFromBackend();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                      // Allowance Card
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _maxMessages >= 9000
                                            ? 'Unlimited messages left this month'.trData(context)
                                            : '$_remainingMessages of $_maxMessages messages left this month'.trData(context),
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showChatPlansModal(context),
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
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _maxMessages >= 9000
                                    ? 1.0
                                    : (_maxMessages > 0
                                        ? (_remainingMessages / _maxMessages).clamp(0.0, 1.0)
                                        : 0.0),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _maxMessages >= 9000
                                      ? const Color(0xFF5E227A)
                                      : (_remainingMessages == 0
                                          ? const Color(0xFFEF4444)
                                          : (_remainingMessages <= 3
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFF5E227A))),
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
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _selectedTabIndex = 0);
                                  _loadMessages(silent: true);
                                },
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

                      if (_selectedTabIndex == 0)
                        _buildMessagesTab()
                      else
                        _buildSendTab(),

                      const SizedBox(height: 36),

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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No messages yet. Search for an artist in the Send tab to start a conversation.'.trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _loadMessages();
                sl<ChatService>().syncAllowanceFromBackend();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Check for New Messages'.trData(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E227A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    // Helper to deduplicate messages for UI display in case identical duplicates arrive
    List<ArtistMessageModel> deduplicateForUi(List<ArtistMessageModel> list) {
      final result = <ArtistMessageModel>[];
      for (final m in list) {
        // Unique identity key based on IDs or content
        final contentKey = '${m.senderEmail.trim().toLowerCase()}_${m.recipientId.trim()}_${m.subject.trim().toLowerCase()}_${m.message.trim()}';
        final isDupe = result.any((r) {
          if (r.id.isNotEmpty && m.id.isNotEmpty && r.id == m.id) return true;
          final rKey = '${r.senderEmail.trim().toLowerCase()}_${r.recipientId.trim()}_${r.subject.trim().toLowerCase()}_${r.message.trim()}';
          return rKey == contentKey && r.createdAt.difference(m.createdAt).abs().inMinutes < 2;
        });
        if (!isDupe) {
          result.add(m);
        }
      }
      return result;
    }

    final uniqueAll = deduplicateForUi(_messages);
    final inboxMessages = uniqueAll.where(_isIncomingMessage).toList();
    final sentMessages = uniqueAll.where((m) => !_isIncomingMessage(m)).toList();

    List<ArtistMessageModel> displayedMessages;
    if (_messageFilterIndex == 1) {
      displayedMessages = inboxMessages;
    } else if (_messageFilterIndex == 2) {
      displayedMessages = sentMessages;
    } else {
      displayedMessages = uniqueAll;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Pills: All | Inbox | Sent + Refresh Icon
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildFilterPill(
                title: '${'All'.trData(context)} (${uniqueAll.length})',
                isSelected: _messageFilterIndex == 0,
                onTap: () => setState(() => _messageFilterIndex = 0),
              ),
              _buildFilterPill(
                title: '${'Inbox'.trData(context)} (${inboxMessages.length})',
                isSelected: _messageFilterIndex == 1,
                badgeColor: inboxMessages.isNotEmpty ? const Color(0xFF10B981) : null,
                onTap: () => setState(() => _messageFilterIndex = 1),
              ),
              _buildFilterPill(
                title: '${'Sent'.trData(context)} (${sentMessages.length})',
                isSelected: _messageFilterIndex == 2,
                onTap: () => setState(() => _messageFilterIndex = 2),
              ),
            ],
          ),
        ),

        if (displayedMessages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _messageFilterIndex == 1
                  ? 'No messages in inbox'.trData(context)
                  : 'No sent messages'.trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
              ),
            ),
          )
        else
          ...displayedMessages.map(_buildMessageCard),
      ],
    );
  }

  Widget _buildMessageCard(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    final translatedRecipientName = msg.recipientName.trData(context);
    final translatedSenderName = msg.senderName.trData(context);
    final rawSubject = msg.subject.trim();
    final translatedMessage = msg.message.trData(context);

    final displayName = isIncoming ? translatedSenderName : translatedRecipientName;
    final displaySubtitle = msg.recipientCategory.isNotEmpty
        ? msg.recipientCategory.trData(context)
        : '';
    final avatarUrl = isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;

    final now = DateTime.now();
    final isToday = now.year == msg.createdAt.year &&
        now.month == msg.createdAt.month &&
        now.day == msg.createdAt.day;
    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    final dateDisplay = isToday
        ? '${'Today'.trData(context)}, $timeStr'
        : '${msg.createdAt.month}/${msg.createdAt.day}, $timeStr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMessageDetailModal(msg),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Participant Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF5E227A),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isIncoming
                                      ? '${'From:'.trData(context)} $displayName'
                                      : '${'To:'.trData(context)} $displayName',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                size: 12,
                                color: isIncoming ? const Color(0xFF10B981) : const Color(0xFF5E227A),
                              ),
                            ],
                          ),
                          if (displaySubtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              displaySubtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isIncoming ? const Color(0xFFDCFCE7) : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isIncoming ? const Color(0xFF86EFAC) : const Color(0xFFE9D5FF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncoming ? Icons.mark_email_read_outlined : Icons.check_circle_outline_rounded,
                            size: 11,
                            color: isIncoming ? const Color(0xFF15803D) : const Color(0xFF5E227A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncoming ? 'Inbox'.trData(context) : 'Sent'.trData(context),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isIncoming ? const Color(0xFF15803D) : const Color(0xFF5E227A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Subject Pill Container
                if (rawSubject.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: Color(0xFF5E227A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Subject:'.trData(context),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E227A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rawSubject.trData(context),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 3. Message Excerpt
                Text(
                  translatedMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // 4. Flyer Attachment Indicator (if present)
                if (msg.flyerUrl != null && msg.flyerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            msg.flyerUrl!,
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image,
                              size: 20,
                              color: Color(0xFF5E227A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Flyer attached'.trData(context),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5E227A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to view →'.trData(context),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5E227A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // 5. Card Footer: Timestamp & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          dateDisplay,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View message →'.trData(context),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E227A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF5E227A) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
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
          Text(
            'Send to Artist'.trData(context),
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Search artist by name... field
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
                            '${_selectedArtist!.name.trData(context)} (${_selectedArtist!.category.trData(context)})',
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
          if (_attachedFlyerBytes == null)
            InkWell(
              onTap: _showFlyerPickerSheet,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E227A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                        color: Color(0xFF5E227A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attach a flyer image (optional)'.trData(context),
                            style: const TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Supports JPG, PNG (Max 10MB)'.trData(context),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E227A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Browse'.trData(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD8B4FE), width: 1.2),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showFlyerPreviewDialog,
                    child: Tooltip(
                      message: 'Flyer preview'.trData(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
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
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in, size: 11, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedFlyerName ?? 'Flyer selected'.trData(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Flyer attached'.trData(context),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Change'.trData(context),
                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF5E227A), size: 22),
                    onPressed: _showFlyerPickerSheet,
                  ),
                  IconButton(
                    tooltip: 'Remove'.trData(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                    onPressed: () {
                      setState(() {
                        _attachedFlyerBytes = null;
                        _attachedFlyerName = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Text(
            'This is a private message to the selected artist and uses 1 of your 10 monthly messages.'.trData(context),
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // 5. Submit Button
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
                              : 'Select an Artist First'.trData(context),
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
