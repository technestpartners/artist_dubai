import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../data/chat_service.dart';
import '../../domain/models/artist_message_model.dart';
import '../../domain/models/listing_plan_model.dart';

class ArtistChatView extends StatefulWidget {
  final ArtistModel? initialArtist;
  final Map<String, dynamic>? initialArgs;

  const ArtistChatView({
    super.key,
    this.initialArtist,
    this.initialArgs,
  });

  @override
  State<ArtistChatView> createState() => _ArtistChatViewState();
}

class _ArtistChatViewState extends State<ArtistChatView> {
  int _selectedTabIndex = 0; // 0 = Messages, 1 = Send
  int _messageFilterIndex = 0; // 0 = All, 1 = Inbox, 2 = Sent
  bool _isUserWise = true; // Group messages user-wise (by conversation partner)
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
  StreamSubscription<List<ListingPlanItem>>? _plansSub;
  List<ListingPlanItem> _chatPlans = [];
  Timer? _pollingTimer;

  bool get _hasActivePlan {
    final clean = _planName.toLowerCase().trim();
    if (clean.isEmpty) return false;
    if (clean == 'basic (free)' ||
        clean == 'free' ||
        clean == 'starter plan' ||
        clean == 'basic' ||
        clean.contains('free') ||
        clean.contains('gallery') ||
        clean.contains('event') ||
        clean.contains('centre') ||
        clean.contains('center') ||
        clean.contains('portfolio')) {
      return false;
    }
    return _maxMessages >= 9000 || _maxMessages > 10;
  }

  String get _currentEmail =>
      (sl<StorageService>().getString('user_email') ?? '').trim().toLowerCase();
  String get _currentArtistId =>
      (sl<StorageService>().getString('artist_profile_id') ?? '').trim();
  String get _currentUserId =>
      (sl<StorageService>().getString('user_id') ?? '').trim();
  String get _currentName =>
      (sl<StorageService>().getString('artist_profile_name') ??
              sl<StorageService>().getString('user_name') ??
              '')
          .trim()
          .toLowerCase();
  bool get _isAdmin =>
      (sl<StorageService>().getBool('is_admin') ?? false) ||
      [
        'admin@artistdubai.com',
        'admin@dubaiart.ae',
        'admin@admin.com',
        'admin@technestpartners.com',
      ].contains(_currentEmail);

  bool _isIncomingMessage(ArtistMessageModel msg) {
    final myEmail = _currentEmail;
    final myArtistId = _currentArtistId;
    final myUserId = _currentUserId;
    final myName = _currentName;
    final isAdmin = _isAdmin;

    // 1. If viewing as Admin or Dubai Art Administrator profile
    if (isAdmin ||
        myName.contains('dubai art administrator') ||
        myEmail == 'admin@artistdubai.com' ||
        myArtistId == '28') {
      final isAddressedToAdmin =
          msg.recipientId == '28' ||
          msg.recipientName.toLowerCase().contains('dubai art administrator') ||
          msg.recipientId.toLowerCase() == 'admin@artistdubai.com';
      final isSentByAdmin =
          msg.senderId == '28' ||
          msg.senderEmail.toLowerCase() == 'admin@artistdubai.com' ||
          msg.senderName.toLowerCase().contains('dubai art administrator');

      if (isAddressedToAdmin && !isSentByAdmin) return true;
      if (isSentByAdmin && !isAddressedToAdmin) return false;
    }

    // 2. Direct checks: Messages sent by me are sent, not incoming
    if (myEmail.isNotEmpty && msg.senderEmail.toLowerCase() == myEmail) {
      return false;
    }
    if (myArtistId.isNotEmpty && msg.senderId == myArtistId) {
      return false;
    }
    if (myUserId.isNotEmpty &&
        (msg.senderId == myUserId || msg.senderId == 'user_$myUserId')) {
      return false;
    }
    if (myName.isNotEmpty &&
        msg.senderName.trim().toLowerCase() == myName &&
        msg.recipientName.trim().toLowerCase() != myName) {
      return false;
    }

    // 3. Direct checks: Messages addressed to my artist profile, email, or user id are incoming
    if (myArtistId.isNotEmpty && msg.recipientId == myArtistId) {
      return true;
    }
    if (myEmail.isNotEmpty &&
        (msg.recipientId.toLowerCase() == myEmail ||
            msg.recipientName.toLowerCase() == myEmail)) {
      return true;
    }
    if (myUserId.isNotEmpty &&
        (msg.recipientId == myUserId || msg.recipientId == 'user_$myUserId')) {
      return true;
    }
    if (myName.isNotEmpty &&
        (msg.recipientName.trim().toLowerCase() == myName ||
            msg.recipientName.trim().toLowerCase().contains(myName))) {
      return true;
    }

    // 4. Fallback when myEmail is known
    if (myEmail.isNotEmpty) {
      return msg.senderEmail.toLowerCase() != myEmail;
    }

    // 5. Default fallback if recipient is Dubai Art Administrator (the admin artist profile)
    if (msg.recipientName.toLowerCase().contains('dubai art administrator') ||
        msg.recipientId == '28') {
      return true;
    }

    return false;
  }

  void _handleReplyToMessage(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    final targetId = isIncoming ? msg.senderId : msg.recipientId;
    final targetName = isIncoming ? msg.senderName : msg.recipientName;
    final targetEmail = isIncoming ? msg.senderEmail : '';
    final targetAvatarUrl =
        isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;
    final targetCategory =
        isIncoming
            ? 'Artist'
            : (msg.recipientCategory.isNotEmpty
                ? msg.recipientCategory
                : 'Artist');

    ArtistModel? replyArtist;
    try {
      replyArtist = _allArtists.firstWhere(
        (a) =>
            (targetEmail.isNotEmpty &&
                a.email.toLowerCase() == targetEmail.toLowerCase()) ||
            (targetId.isNotEmpty && a.id == targetId) ||
            (targetName.isNotEmpty &&
                a.name.toLowerCase() == targetName.toLowerCase()),
      );
    } catch (_) {}

    replyArtist ??= ArtistModel(
      id:
          targetId.isNotEmpty
              ? targetId
              : (targetEmail.isNotEmpty
                  ? targetEmail
                  : 'artist_${DateTime.now().millisecondsSinceEpoch}'),
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
        _subjectController.text =
            sub.toLowerCase().startsWith('re:') ? sub : 'Re: $sub';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialArtist != null) {
      _selectedArtist = widget.initialArtist;
      _selectedTabIndex = 1;
    } else if (widget.initialArgs != null) {
      final args = widget.initialArgs!;
      final artistObj = args['artist'];
      if (artistObj is ArtistModel) {
        _selectedArtist = artistObj;
        _selectedTabIndex = 1;
      } else {
        final id = (args['artistId'] ?? args['id'] ?? '').toString();
        final name = (args['artistName'] ?? args['name'] ?? '').toString();
        if (id.isNotEmpty || name.isNotEmpty) {
          _selectedArtist = ArtistModel(
            id: id,
            name: name.isNotEmpty ? name : 'Artist',
            category: (args['artistCategory'] ?? args['category'] ?? 'Artist').toString(),
            location: (args['artistLocation'] ?? args['location'] ?? 'Dubai').toString(),
            bio: '',
            avatarUrl: (args['artistAvatarUrl'] ?? args['avatarUrl'] ?? '').toString(),
            bannerUrl: '',
            followersCount: 0,
            worksCount: 0,
            email: (args['artistEmail'] ?? args['email'] ?? '').toString(),
          );
          _selectedTabIndex = 1;
        }
      }
    }
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
    _initChatPlans();
  }

  void _initChatPlans() {
    final cached = sl<ApiService>().cachedListingPlans;
    if (cached != null && cached.isNotEmpty) {
      _chatPlans = _filterChatPlans(cached);
    } else {
      _chatPlans = _filterChatPlans(ListingPlanItem.defaultBaselinePlans);
    }

    sl<ApiService>().getListingPlans().then((plans) {
      if (mounted && plans.isNotEmpty) {
        setState(() {
          _chatPlans = _filterChatPlans(plans);
        });
      }
    }).catchError((_) {});

    try {
      _plansSub = sl<LiveSyncService>().listingPlansStream.listen((updated) {
        if (mounted && updated.isNotEmpty) {
          setState(() {
            _chatPlans = _filterChatPlans(updated);
          });
        }
      });
    } catch (_) {}
  }

  List<ListingPlanItem> _filterChatPlans(List<ListingPlanItem> plans) {
    final list = plans.where((p) {
      if (!p.isActive) return false;
      final t = p.itemType.toLowerCase().trim();
      final cat = p.category.toLowerCase().trim();
      final title = p.title.toLowerCase().trim();

      // Exclude non-chat types
      if (t == 'gallery' ||
          t == 'event' ||
          t == 'art_centre' ||
          t == 'center' ||
          t == 'artist' ||
          title.contains('portfolio')) {
        return false;
      }

      return t == 'chat' ||
          t == 'messaging' ||
          cat.contains('chat') ||
          cat.contains('messag') ||
          title.contains('chat') ||
          title.contains('messaging') ||
          title.contains('starter') ||
          title == 'pro artist' ||
          title.contains('unlimited vip') ||
          title.contains('allowance');
    }).toList();

    if (list.isEmpty) {
      return ListingPlanItem.defaultBaselinePlans
          .where((p) => p.itemType == 'chat')
          .toList();
    }

    // Ensure standard baseline tiers (Starter Free, Unlimited VIP) are present alongside admin-created plans
    final hasFree = list.any((p) =>
        p.price.toLowerCase() == 'free' ||
        p.title.toLowerCase().contains('starter') ||
        p.title.toLowerCase().contains('basic'));
    if (!hasFree) {
      final starter = ListingPlanItem.defaultBaselinePlans.firstWhere(
        (p) =>
            p.itemType == 'chat' &&
            (p.price.toLowerCase() == 'free' ||
                p.title.toLowerCase().contains('starter')),
        orElse: () => const ListingPlanItem(
          id: 4,
          title: 'Starter Plan (Free)',
          category: 'Messaging',
          price: 'Free',
          description:
              '10 direct messages per month included for all registered artists',
          features: [
            '10 direct artist messages per month',
            'Direct inbox messaging with other artists',
            'Allowance auto-resets on the 1st',
          ],
          buttonText: 'Current Plan',
          itemType: 'chat',
          isActive: true,
          sortOrder: 1,
          duration: 'Monthly Reset',
          durationDays: 30,
        ),
      );
      list.insert(0, starter);
    }

    final hasUnlimited = list.any((p) =>
        p.title.toLowerCase().contains('unlimited') ||
        p.title.toLowerCase().contains('vip') ||
        p.features.any((f) => f.toLowerCase().contains('unlimited')));
    if (!hasUnlimited) {
      final vip = ListingPlanItem.defaultBaselinePlans.firstWhere(
        (p) =>
            p.itemType == 'chat' &&
            (p.title.toLowerCase().contains('vip') ||
                p.title.toLowerCase().contains('unlimited')),
        orElse: () => const ListingPlanItem(
          id: 6,
          title: 'Unlimited VIP',
          category: 'Messaging',
          badge: 'For Agencies & Curators',
          price: 'AED 99',
          description:
              'Unlimited direct artist messages with verified VIP sender badge',
          features: [
            'Unlimited direct artist messages',
            'Verified VIP sender badge',
            'Ideal for galleries, curators & agencies',
            'Priority instant customer support',
          ],
          buttonText: 'Upgrade to VIP',
          itemType: 'chat',
          isActive: true,
          sortOrder: 99,
          duration: 'Monthly Subscription',
          durationDays: 30,
        ),
      );
      list.add(vip);
    }

    list.sort((a, b) {
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      final aFree = a.price.toLowerCase() == 'free';
      final bFree = b.price.toLowerCase() == 'free';
      if (aFree && !bFree) return -1;
      if (!aFree && bFree) return 1;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

    return list;
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ArtistChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialArtist != null &&
        widget.initialArtist != oldWidget.initialArtist) {
      setState(() {
        _selectedArtist = widget.initialArtist;
        _selectedTabIndex = 1;
      });
    }
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _allowanceSub?.cancel();
    _messagesSub?.cancel();
    _plansSub?.cancel();
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
          if (_selectedArtist != null) {
            final match = res.where((a) =>
              (a.id.isNotEmpty && a.id == _selectedArtist!.id) ||
              (a.email.isNotEmpty && _selectedArtist!.email.isNotEmpty && a.email.toLowerCase() == _selectedArtist!.email.toLowerCase()) ||
              (a.name.isNotEmpty && a.name.toLowerCase() == _selectedArtist!.name.toLowerCase())
            ).firstOrNull;
            if (match != null) {
              _selectedArtist = match;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingArtists = false);
    }
  }

  Future<void> _pickFlyerImage([
    ImageSource source = ImageSource.gallery,
  ]) async {
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
      builder:
          (ctx) => SafeArea(
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFlyerImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: Color(0xFF5E227A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose from Gallery'.trData(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Select an image from your photos'.trData(
                                      context,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFlyerImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF5E227A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Take a Photo'.trData(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Use camera to capture flyer'.trData(
                                      context,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
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
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(ctx).size.height * 0.82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          color: const Color(0xFF0F172A),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: InteractiveViewer(
                            clipBehavior: Clip.antiAlias,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.memory(
                              _attachedFlyerBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(ctx),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attachment_rounded,
                          size: 18,
                          color: Color(0xFF5E227A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _attachedFlyerName ??
                                'Flyer preview'.trData(context),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
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
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5E227A),
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

  void _openArtistSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered =
                _allArtists.where((a) {
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
                        icon: const Icon(Icons.close, color: Color(0xFF1E1E1E)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search artist by name or category...'.trData(
                        modalCtx,
                      ),
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF5E227A),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                    child:
                        _isLoadingArtists
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF5E227A),
                              ),
                            )
                            : filtered.isEmpty
                            ? Center(
                              child: Text(
                                'No artists found'.trData(modalCtx),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (itemCtx, index) {
                                final artist = filtered[index];
                                final isSelected =
                                    _selectedArtist?.id == artist.id;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF5E227A),
                                    backgroundImage:
                                        artist.avatarUrl.isNotEmpty
                                            ? NetworkImage(artist.avatarUrl)
                                            : null,
                                    child:
                                        artist.avatarUrl.isEmpty
                                            ? Text(
                                              artist.name.isNotEmpty
                                                  ? artist.name
                                                      .trData(modalCtx)[0]
                                                      .toUpperCase()
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
                                      color:
                                          isSelected
                                              ? const Color(0xFF5E227A)
                                              : const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${artist.category.trData(modalCtx)} • ${artist.location.trData(modalCtx)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing:
                                      isSelected
                                          ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF5E227A),
                                          )
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
          content: Text(
            'Monthly message limit reached. Upgrade your plan for more.'.trData(
              context,
            ),
          ),
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
        flyerUrl = await sl<ApiService>().uploadImageBytes(
          _attachedFlyerBytes!,
          ext: 'jpg',
        );
      }

      await chatService.sendMessage(
        recipientId: _selectedArtist!.id,
        recipientName: _selectedArtist!.name,
        recipientCategory: _selectedArtist!.category,
        recipientAvatarUrl: _selectedArtist!.avatarUrl,
        subject:
            _subjectController.text.trim().isEmpty
                ? 'Direct Artist Message'
                : _subjectController.text.trim(),
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
        _messageFilterIndex =
            0; // Show in All so the user immediately sees the sent card
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
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(ctx).size.height * 0.82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          color: const Color(0xFF0F172A),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: InteractiveViewer(
                            clipBehavior: Clip.antiAlias,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    height: 200,
                                    color: const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 40,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(ctx),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: Color(0xFF5E227A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Flyer Attachment'.trData(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5E227A),
                          ),
                          child: Text(
                            'Close'.trData(context),
                            style: const TextStyle(fontWeight: FontWeight.w600),
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

  void _showMessageDetailModal(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    showDialog(
      context: context,
      builder: (ctx) {
        final translatedRecipientName = msg.recipientName.trData(ctx);
        final translatedSenderName = msg.senderName.trData(ctx);
        final translatedSubject =
            msg.subject.isNotEmpty ? msg.subject.trData(ctx) : '';
        final translatedMessage = msg.message.trData(ctx);
        final translatedCategory = msg.recipientCategory.trData(ctx);

        final displayName =
            isIncoming ? translatedSenderName : translatedRecipientName;
        final displaySubtitle =
            isIncoming
                ? (msg.senderEmail.isNotEmpty
                    ? msg.senderEmail
                    : 'Artist'.trData(ctx))
                : (translatedCategory.isNotEmpty
                    ? translatedCategory
                    : 'Artist'.trData(ctx));
        final displayAvatarUrl =
            isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;

        final date = msg.createdAt;
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final monthName = months[(date.month - 1).clamp(0, 11)];
        final hour = date.hour;
        final minute = date.minute.toString().padLeft(2, '0');
        final isPm = hour >= 12;
        final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final timeAmPm = '$formattedHour:$minute ${isPm ? 'PM' : 'AM'}';
        final formattedDateStr =
            '$monthName ${date.day}, ${date.year} • $timeAmPm';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
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
                        backgroundImage:
                            (displayAvatarUrl != null &&
                                    displayAvatarUrl.isNotEmpty)
                                ? NetworkImage(displayAvatarUrl)
                                : null,
                        child:
                            (displayAvatarUrl == null ||
                                    displayAvatarUrl.isEmpty)
                                ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'A',
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isIncoming
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFAF5FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          isIncoming
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFFE9D5FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isIncoming
                                            ? Icons.mark_email_read_outlined
                                            : Icons
                                                .check_circle_outline_rounded,
                                        size: 11,
                                        color:
                                            isIncoming
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF5E227A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isIncoming
                                            ? 'Inbox'.trData(ctx)
                                            : 'Sent'.trData(ctx),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isIncoming
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF5E227A),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE9D5FF),
                                width: 1.2,
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                        if (msg.flyerUrl != null &&
                            msg.flyerUrl!.isNotEmpty) ...[
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
                            onTap:
                                () => _showNetworkFlyerPreview(
                                  context,
                                  msg.flyerUrl!,
                                ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          height: 80,
                                          color: const Color(0xFFF1F5F9),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.broken_image_outlined,
                                                size: 20,
                                                color: Color(0xFF94A3B8),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Flyer preview unavailable'
                                                    .trData(ctx),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 10,
                                    ),
                                    color: Colors.black.withValues(alpha: 0.6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 14,
                                        ),
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
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDateStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Close'.trData(ctx),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E227A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
            final plans = _chatPlans.isNotEmpty
                ? _chatPlans
                : _filterChatPlans(
                    sl<ApiService>().cachedListingPlans ??
                        ListingPlanItem.defaultBaselinePlans,
                  );

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
                            color: const Color(
                              0xFF5E227A,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFF5E227A),
                            size: 26,
                          ),
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
                                'Upgrade to connect with more artists across dubai.'
                                    .trData(modalCtx),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
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
                          for (int i = 0; i < plans.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _buildDynamicPlanTierCard(
                              context: modalCtx,
                              plan: plans[i],
                              sheetCtx: sheetCtx,
                            ),
                          ],
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              context.push(RouteNames.listingPlans);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.campaign_outlined,
                                    color: Color(0xFF5E227A),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Looking to publish events, galleries or art centres? View Listing Plans →'
                                          .trData(modalCtx),
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

  Widget _buildDynamicPlanTierCard({
    required BuildContext context,
    required ListingPlanItem plan,
    required BuildContext sheetCtx,
  }) {
    final allowance = _extractAllowanceFromPlan(plan);
    final allowanceText = _getAllowanceText(allowance);
    final isCurrent = _isPlanCurrent(plan, allowance);
    final isFeatured = plan.badge.toLowerCase().contains('popular') ||
        plan.badge.toLowerCase().contains('recommended') ||
        plan.badge.toLowerCase().contains('best') ||
        plan.title.toLowerCase().contains('pro');

    return _buildPlanTierCard(
      context: context,
      name: plan.title,
      price: plan.price,
      allowanceText: allowanceText,
      badge: plan.badge.isNotEmpty ? plan.badge : null,
      isFeatured: isFeatured,
      features: plan.effectiveFeatures,
      isCurrent: isCurrent,
      customButtonText: plan.buttonText.isNotEmpty &&
              plan.buttonText != 'Pay from My Listings' &&
              plan.buttonText != 'Subscribe to Chat' &&
              !(isFeatured && (plan.buttonText == 'Select Plan' || plan.buttonText == 'Upgrade'))
          ? plan.buttonText
          : null,
      onUpgrade: () => _handleUpgradePlan(
        plan: plan,
        maxAllowance: allowance,
        sheetCtx: sheetCtx,
      ),
    );
  }

  int _extractAllowanceFromPlan(ListingPlanItem plan) {
    final combined =
        '${plan.title} ${plan.description} ${plan.features.join(' ')}'
            .toLowerCase();
    if (combined.contains('unlimited') || plan.price.contains('99')) {
      return 9999;
    }
    final match = RegExp(
      r'(\d+)\s*(?:direct\s*)?messages?',
      caseSensitive: false,
    ).firstMatch(combined);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 10;
    }
    if (plan.price.toLowerCase() == 'free' ||
        plan.title.toLowerCase().contains('starter')) {
      return 10;
    }
    if (plan.price.toLowerCase().contains('49') ||
        plan.title.toLowerCase().contains('pro')) {
      return 50;
    }
    return 10;
  }

  String _getAllowanceText(int allowance) {
    if (allowance >= 9000) return 'Unlimited Messages';
    return '$allowance Messages / Month';
  }

  bool _isPlanCurrent(ListingPlanItem plan, int allowance) {
    final currentPlanClean = _planName.toLowerCase().trim();
    final planTitleClean = plan.title.toLowerCase().trim();

    if (!_hasActivePlan) {
      return plan.price.toLowerCase() == 'free' ||
          planTitleClean.contains('starter') ||
          planTitleClean.contains('free');
    }

    if (currentPlanClean.isNotEmpty && !currentPlanClean.contains('free')) {
      if (currentPlanClean == planTitleClean) return true;
      if (currentPlanClean.contains(planTitleClean) ||
          planTitleClean.contains(currentPlanClean)) {
        return true;
      }
      if (planTitleClean.contains('vip') && currentPlanClean.contains('vip')) {
        return true;
      }
      if (planTitleClean.contains('pro') &&
          currentPlanClean.contains('pro') &&
          !currentPlanClean.contains('vip')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _handleUpgradePlan({
    ListingPlanItem? plan,
    String? planName,
    int? maxAllowance,
    required BuildContext sheetCtx,
  }) async {
    Navigator.pop(sheetCtx);
    final effectiveName = plan?.title ?? planName ?? 'Pro Artist';
    final effectivePrice =
        plan?.price ??
        (effectiveName.toLowerCase().contains('free') ||
                effectiveName.toLowerCase().contains('starter')
            ? 'Free'
            : (effectiveName == 'Pro Artist' ? 'AED 49' : 'AED 99'));
    final effectiveAllowance =
        maxAllowance ??
        (plan != null
            ? _extractAllowanceFromPlan(plan)
            : (effectiveName == 'Pro Artist' ? 50 : 9999));
    final effectiveFeatures =
        plan?.effectiveFeatures ??
        [
          effectiveAllowance >= 9000
              ? 'Unlimited direct artist messages'
              : '$effectiveAllowance direct messages per month',
          'Priority delivery in recipient inbox',
          'VIP sender badge',
        ];
    final isFree =
        effectivePrice.toLowerCase() == 'free' ||
        effectiveName.toLowerCase().contains('starter');

    if (!isFree) {
      try {
        context.push(
          RouteNames.planPayment,
          extra: {
            'isPlanPurchase': true,
            'itemType': 'chat',
            'planId':
                plan?.id?.toString() ??
                effectiveName.toLowerCase().replaceAll(' ', '_'),
            'planName': effectiveName,
            'planPeriod':
                plan?.duration.isNotEmpty == true
                    ? plan!.duration
                    : 'Monthly Subscription',
            'planAmount': effectivePrice,
            'amount': effectivePrice,
            'maxAllowance': effectiveAllowance,
            'features': effectiveFeatures,
          },
        ).then((_) async {
          await sl<ChatService>().syncAllowanceFromBackend();
          if (mounted) setState(() {});
        });
        return;
      } catch (_) {
        // Fallback for test harness without GoRouter
      }
    }
    final success = await sl<ChatService>().upgradePlan(
      planName: effectiveName,
      maxAllowance: effectiveAllowance,
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            effectiveAllowance >= 9000
                ? 'Upgraded to $effectiveName! You now have unlimited messages.'
                    .trData(context)
                : 'Upgraded to $effectiveName! Your monthly allowance is now $effectiveAllowance messages.'
                    .trData(context),
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
    String? customButtonText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFFFAF5FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCurrent
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
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.trData(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isFeatured
                                  ? const Color(0xFF5E227A)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge.trData(context),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                isFeatured
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
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
                backgroundColor:
                    isFeatured
                        ? const Color(0xFF5E227A)
                        : const Color(0xFFF1F5F9),
                foregroundColor:
                    isFeatured ? Colors.white : const Color(0xFF1E1E1E),
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
                    : (customButtonText != null &&
                            customButtonText.isNotEmpty &&
                            customButtonText != 'Pay from My Listings' &&
                            customButtonText != 'Subscribe to Chat')
                        ? customButtonText.trData(context)
                        : (isFeatured
                            ? 'Upgrade to Pro'.trData(context)
                            : (price == 'Free' ? 'Select Plan' : 'Upgrade')
                                .trData(context)),
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
                      Row(
                        children: [
                          if (Navigator.of(context).canPop()) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                    if (_hasActivePlan) ...[
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () => _showChatPlansModal(context),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFEF3C7),
                                              Color(0xFFFDE68A),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium_rounded,
                                              size: 13,
                                              color: Color(0xFFB45309),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _planName.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFB45309),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Send a private message to another artist.'.trData(
                                    context,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFE2D4F0),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Allowance Card (hidden when user has an active plan)
                      if (!_hasActivePlan) ...[
                        const SizedBox(height: 16),
                        Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_remainingMessages.clamp(0, 10)} of 10 messages left this month'
                                            .trData(context),
                                        style: const TextStyle(
                                          color: Color(0xFF1E1E1E),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your allowance resets on the 1st. Upgrade your plan for more.'
                                            .trData(context),
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
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
                                value: (_remainingMessages.clamp(0, 10) / 10.0)
                                    .clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _remainingMessages == 0
                                      ? const Color(0xFFEF4444)
                                      : (_remainingMessages <= 3
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF5E227A)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                    color:
                                        _selectedTabIndex == 0
                                            ? const Color(0xFF5E227A)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        _selectedTabIndex == 0
                                            ? Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1,
                                            )
                                            : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Messages'.trData(context),
                                    style: TextStyle(
                                      color:
                                          _selectedTabIndex == 0
                                              ? Colors.white
                                              : const Color(0xFFD4BEE4),
                                      fontWeight:
                                          _selectedTabIndex == 0
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedTabIndex == 1
                                            ? const Color(0xFF5E227A)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        _selectedTabIndex == 1
                                            ? Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1,
                                            )
                                            : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Send'.trData(context),
                                    style: TextStyle(
                                      color:
                                          _selectedTabIndex == 1
                                              ? Colors.white
                                              : const Color(0xFFD4BEE4),
                                      fontWeight:
                                          _selectedTabIndex == 1
                                              ? FontWeight.bold
                                              : FontWeight.w500,
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
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet. Search for an artist in the Send tab to start a conversation.'
                  .trData(context),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        final contentKey =
            '${m.senderEmail.trim().toLowerCase()}_${m.recipientId.trim()}_${m.subject.trim().toLowerCase()}_${m.message.trim()}';
        final isDupe = result.any((r) {
          if (r.id.isNotEmpty && m.id.isNotEmpty && r.id == m.id) return true;
          final rKey =
              '${r.senderEmail.trim().toLowerCase()}_${r.recipientId.trim()}_${r.subject.trim().toLowerCase()}_${r.message.trim()}';
          return rKey == contentKey &&
              r.createdAt.difference(m.createdAt).abs().inMinutes < 2;
        });
        if (!isDupe) {
          result.add(m);
        }
      }
      return result;
    }

    final uniqueAll = deduplicateForUi(_messages);
    final inboxMessages = uniqueAll.where(_isIncomingMessage).toList();
    final sentMessages =
        uniqueAll.where((m) => !_isIncomingMessage(m)).toList();

    // Group messages by user partner into conversation threads
    final allConversations = _groupMessagesByUser(uniqueAll);
    final inboxConversations = allConversations
        .where((c) => c.messages.any(_isIncomingMessage))
        .toList();
    final sentConversations = allConversations
        .where((c) => c.messages.any((m) => !_isIncomingMessage(m)))
        .toList();

    List<ArtistMessageModel> displayedMessages;
    List<ArtistChatConversation> displayedConversations;

    if (_messageFilterIndex == 1) {
      displayedMessages = inboxMessages;
      displayedConversations = inboxConversations;
    } else if (_messageFilterIndex == 2) {
      displayedMessages = sentMessages;
      displayedConversations = sentConversations;
    } else {
      displayedMessages = uniqueAll;
      displayedConversations = allConversations;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Pills: All | Inbox | Sent
        Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                badgeColor:
                    inboxMessages.isNotEmpty ? const Color(0xFF10B981) : null,
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

        // Subheader Row: View Mode Switcher (By User vs Messages)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isUserWise
                      ? '${'Conversations by User'.trData(context)} (${displayedConversations.length})'
                      : '${'All Individual Messages'.trData(context)} (${displayedMessages.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isUserWise = true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: _isUserWise
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _isUserWise
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 13,
                              color: _isUserWise
                                  ? const Color(0xFF5E227A)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'By User'.trData(context),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _isUserWise
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _isUserWise
                                    ? const Color(0xFF5E227A)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => setState(() => _isUserWise = false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: !_isUserWise
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !_isUserWise
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 13,
                              color: !_isUserWise
                                  ? const Color(0xFF5E227A)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Messages'.trData(context),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: !_isUserWise
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: !_isUserWise
                                    ? const Color(0xFF5E227A)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_isUserWise) ...[
          if (displayedConversations.isEmpty)
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
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
              ),
            )
          else
            ...displayedConversations.map(_buildUserWiseCard),
        ] else ...[
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
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
              ),
            )
          else
            ...displayedMessages.map(_buildMessageCard),
        ],
      ],
    );
  }

  /// Groups messages into conversation threads by conversation partner.
  List<ArtistChatConversation> _groupMessagesByUser(List<ArtistMessageModel> msgs) {
    final Map<String, List<ArtistMessageModel>> grouped = {};
    final Map<String, _PartnerInfo> partnerInfos = {};

    for (final msg in msgs) {
      final isIncoming = _isIncomingMessage(msg);
      final rawName = (isIncoming ? msg.senderName : msg.recipientName).trim();
      final rawEmail = (isIncoming ? msg.senderEmail : '').trim().toLowerCase();
      final rawId = (isIncoming ? msg.senderId : msg.recipientId).trim();
      final rawAvatar = isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;
      final rawCategory = isIncoming ? 'Artist' : msg.recipientCategory;

      String convKey;
      final lowerName = rawName.toLowerCase();
      if (lowerName.contains('dubai art administrator') ||
          rawId == '28' ||
          rawEmail == 'admin@artistdubai.com') {
        convKey = 'admin_dubai_art_administrator';
      } else if (rawId.isNotEmpty && rawId != '0') {
        convKey = 'id_$rawId';
      } else if (rawEmail.isNotEmpty) {
        convKey = 'email_$rawEmail';
      } else if (lowerName.isNotEmpty) {
        convKey = 'name_$lowerName';
      } else {
        convKey = 'msg_${msg.id}';
      }

      grouped.putIfAbsent(convKey, () => []).add(msg);

      final existing = partnerInfos[convKey];
      if (existing == null) {
        partnerInfos[convKey] = _PartnerInfo(
          partnerId: rawId,
          partnerName: rawName.isNotEmpty ? rawName : (isIncoming ? 'Sender' : 'Recipient'),
          partnerEmail: rawEmail,
          partnerAvatarUrl: rawAvatar,
          partnerCategory: rawCategory.isNotEmpty ? rawCategory : 'Artist',
        );
      } else {
        partnerInfos[convKey] = _PartnerInfo(
          partnerId: existing.partnerId.isNotEmpty ? existing.partnerId : rawId,
          partnerName: existing.partnerName.isNotEmpty ? existing.partnerName : rawName,
          partnerEmail: existing.partnerEmail.isNotEmpty ? existing.partnerEmail : rawEmail,
          partnerAvatarUrl: existing.partnerAvatarUrl ?? rawAvatar,
          partnerCategory: existing.partnerCategory.isNotEmpty && existing.partnerCategory != 'Artist'
              ? existing.partnerCategory
              : (rawCategory.isNotEmpty ? rawCategory : existing.partnerCategory),
        );
      }
    }

    final List<ArtistChatConversation> conversations = [];
    grouped.forEach((key, list) {
      // Sort messages chronologically (oldest first, newest last)
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final info = partnerInfos[key]!;
      conversations.add(
        ArtistChatConversation(
          key: key,
          partnerId: info.partnerId,
          partnerName: info.partnerName,
          partnerEmail: info.partnerEmail,
          partnerAvatarUrl: info.partnerAvatarUrl,
          partnerCategory: info.partnerCategory,
          messages: list,
        ),
      );
    });

    conversations.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));
    return conversations;
  }

  /// Builds a single user-wise conversation card grouping all interactions with this partner.
  Widget _buildUserWiseCard(ArtistChatConversation conv) {
    final latestMsg = conv.latestMessage;
    final isLatestIncoming = _isIncomingMessage(latestMsg);
    final translatedPartnerName = conv.partnerName.trData(context);
    final translatedPartnerCategory = conv.partnerCategory.isNotEmpty
        ? conv.partnerCategory.trData(context)
        : 'Artist'.trData(context);
    final avatarUrl = conv.partnerAvatarUrl;

    final now = DateTime.now();
    final isToday =
        now.year == latestMsg.createdAt.year &&
        now.month == latestMsg.createdAt.month &&
        now.day == latestMsg.createdAt.day;
    final timeStr =
        '${latestMsg.createdAt.hour.toString().padLeft(2, '0')}:${latestMsg.createdAt.minute.toString().padLeft(2, '0')}';
    final dateDisplay = isToday
        ? '${'Today'.trData(context)}, $timeStr'
        : '${latestMsg.createdAt.month}/${latestMsg.createdAt.day}, $timeStr';

    final totalCount = conv.totalMessages;
    final incomingCount = conv.messages.where(_isIncomingMessage).length;
    final sentCount = conv.messages.where((m) => !_isIncomingMessage(m)).length;

    final String directionText = isLatestIncoming
        ? '${'From:'.trData(context)} $translatedPartnerName'
        : '${'To:'.trData(context)} $translatedPartnerName';

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
          onTap: () => _showConversationThreadModal(conv),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF5E227A),
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              translatedPartnerName.isNotEmpty
                                  ? translatedPartnerName[0].toUpperCase()
                                  : 'A',
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
                                  totalCount > 1
                                      ? translatedPartnerName
                                      : directionText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isLatestIncoming
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 13,
                                color: isLatestIncoming
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF5E227A),
                              ),
                            ],
                          ),
                          if (totalCount > 1) ...[
                            const SizedBox(height: 1),
                            Text(
                              directionText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLatestIncoming
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF5E227A),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (translatedPartnerCategory.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              translatedPartnerCategory,
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

                    // Badges: Message Count & Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE9D5FF),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 10.5,
                                color: Color(0xFF5E227A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                totalCount == 1
                                    ? (isLatestIncoming
                                        ? 'Inbox'.trData(context)
                                        : 'Sent'.trData(context))
                                    : '$totalCount ${'msgs'.trData(context)}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5E227A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (totalCount > 1) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${incomingCount > 0 ? '$incomingCount in' : ''}${incomingCount > 0 && sentCount > 0 ? ' • ' : ''}${sentCount > 0 ? '$sentCount out' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Latest Message Preview Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject if available
                      if (latestMsg.subject.trim().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 13,
                              color: Color(0xFF5E227A),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                latestMsg.subject.trData(context),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Message snippet
                      Text(
                        latestMsg.message.trData(context),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Flyer preview if attached
                      if (latestMsg.flyerUrl != null &&
                          latestMsg.flyerUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  latestMsg.flyerUrl!,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: Color(0xFF5E227A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Flyer Attached'.trData(context),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5E227A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Footer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      totalCount > 1
                          ? '${'View Conversation'.trData(context)} ($totalCount) →'
                          : 'View message →'.trData(context),
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
          ),
        ),
      ),
    );
  }

  /// Opens an interactive conversation thread modal displaying the full message history with this partner.
  void _showConversationThreadModal(ArtistChatConversation conv) {
    final TextEditingController replyController = TextEditingController();
    bool isSendingInline = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final translatedPartnerName = conv.partnerName.trData(modalCtx);
            final translatedPartnerCategory = conv.partnerCategory.isNotEmpty
                ? conv.partnerCategory.trData(modalCtx)
                : 'Artist'.trData(modalCtx);
            final avatarUrl = conv.partnerAvatarUrl;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Row
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF5E227A),
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    translatedPartnerName.isNotEmpty
                                        ? translatedPartnerName[0].toUpperCase()
                                        : 'A',
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
                                        translatedPartnerName,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (translatedPartnerCategory.isNotEmpty) ...[
                                      Text(
                                        translatedPartnerCategory,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                    Text(
                                      '${conv.totalMessages} ${conv.totalMessages == 1 ? 'message'.trData(modalCtx) : 'messages'.trData(modalCtx)}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF5E227A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            tooltip: 'Close'.trData(modalCtx),
                            onPressed: () => Navigator.pop(ctx),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // 2. Chat Bubbles List
                    Flexible(
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          itemCount: conv.messages.length,
                          itemBuilder: (listCtx, idx) {
                            final m = conv.messages[idx];
                            final isIncoming = _isIncomingMessage(m);
                            final timeStr =
                                '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
                            final dateStr =
                                '${m.createdAt.month}/${m.createdAt.day}, $timeStr';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: isIncoming
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                                children: [
                                  // Participant Label & Time
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isIncoming
                                              ? '${'From:'.trData(modalCtx)} ${m.senderName.trData(modalCtx)}'
                                              : '${'To:'.trData(modalCtx)} ${m.recipientName.trData(modalCtx)}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Bubble Container
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 360,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isIncoming
                                          ? Colors.white
                                          : const Color(0xFF5E227A),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(14),
                                        topRight: const Radius.circular(14),
                                        bottomLeft: Radius.circular(
                                          isIncoming ? 2 : 14,
                                        ),
                                        bottomRight: Radius.circular(
                                          isIncoming ? 14 : 2,
                                        ),
                                      ),
                                      border: isIncoming
                                          ? Border.all(
                                              color: const Color(0xFFE2E8F0),
                                              width: 1,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Subject badge if non-empty
                                        if (m.subject.trim().isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isIncoming
                                                  ? const Color(0xFFFAF5FF)
                                                  : Colors.white.withValues(
                                                      alpha: 0.18,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: isIncoming
                                                  ? Border.all(
                                                      color: const Color(
                                                        0xFFE9D5FF,
                                                      ),
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bookmark_outline_rounded,
                                                  size: 11,
                                                  color: isIncoming
                                                      ? const Color(0xFF5E227A)
                                                      : Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    m.subject.trData(modalCtx),
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isIncoming
                                                          ? const Color(
                                                              0xFF5E227A,
                                                            )
                                                          : Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                        ],

                                        // Message Body
                                        SelectableText(
                                          m.message.trData(modalCtx),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: isIncoming
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            height: 1.4,
                                          ),
                                        ),

                                        // Sender Email if available
                                        if (isIncoming &&
                                            m.senderEmail.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            m.senderEmail,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],

                                        // Flyer preview if attached
                                        if (m.flyerUrl != null &&
                                            m.flyerUrl!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () =>
                                                _showNetworkFlyerPreview(
                                              context,
                                              m.flyerUrl!,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Stack(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                children: [
                                                  Image.network(
                                                    m.flyerUrl!,
                                                    width: 220,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      width: 220,
                                                      height: 60,
                                                      color: Colors.black12,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        'Flyer attached'
                                                            .trData(modalCtx),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 220,
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                    color: Colors.black54,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Icon(
                                                          Icons.zoom_in,
                                                          color: Colors.white,
                                                          size: 13,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Tap to view'
                                                              .trData(modalCtx),
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 3. Bottom Actions: Reply Buttons & Quick Send
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quick inline reply text field
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: replyController,
                                    enabled: !isSendingInline,
                                    textInputAction: TextInputAction.send,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    cursorColor: const Color(0xFF5E227A),
                                    onSubmitted: (val) async {
                                      if (val.trim().isEmpty || isSendingInline) return;
                                      setModalState(() => isSendingInline = true);
                                      try {
                                        final chatService = sl<ChatService>();
                                        final lastSubject = conv.latestMessage.subject.trim();
                                        final sub = lastSubject.isNotEmpty
                                            ? (lastSubject.toLowerCase().startsWith('re:')
                                                ? lastSubject
                                                : 'Re: $lastSubject')
                                            : 'Direct Artist Message';

                                        final sentMsg = await chatService.sendMessage(
                                          recipientId: conv.partnerId.isNotEmpty ? conv.partnerId : 'artist_${DateTime.now().millisecondsSinceEpoch}',
                                          recipientName: conv.partnerName,
                                          recipientCategory: conv.partnerCategory,
                                          recipientAvatarUrl: conv.partnerAvatarUrl,
                                          subject: sub,
                                          message: val.trim(),
                                        );
                                        replyController.clear();
                                        setModalState(() {
                                          conv.messages.add(sentMsg);
                                          isSendingInline = false;
                                        });
                                        _loadMessages();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Message sent successfully!'.trData(context)),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (err) {
                                        setModalState(() => isSendingInline = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(err.toString()),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: '${'Write a reply to'.trData(modalCtx)} $translatedPartnerName...',
                                      hintStyle: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: isSendingInline
                                    ? null
                                    : () async {
                                        final val = replyController.text.trim();
                                        if (val.isEmpty) return;
                                        setModalState(() => isSendingInline = true);
                                        try {
                                          final chatService = sl<ChatService>();
                                          final lastSubject = conv.latestMessage.subject.trim();
                                          final sub = lastSubject.isNotEmpty
                                              ? (lastSubject.toLowerCase().startsWith('re:')
                                                  ? lastSubject
                                                  : 'Re: $lastSubject')
                                              : 'Direct Artist Message';

                                          final sentMsg = await chatService.sendMessage(
                                            recipientId: conv.partnerId.isNotEmpty ? conv.partnerId : 'artist_${DateTime.now().millisecondsSinceEpoch}',
                                            recipientName: conv.partnerName,
                                            recipientCategory: conv.partnerCategory,
                                            recipientAvatarUrl: conv.partnerAvatarUrl,
                                            subject: sub,
                                            message: val,
                                          );
                                          replyController.clear();
                                          setModalState(() {
                                            conv.messages.add(sentMsg);
                                            isSendingInline = false;
                                          });
                                          _loadMessages();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Message sent successfully!'.trData(context)),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (err) {
                                          setModalState(() => isSendingInline = false);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(err.toString()),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5E227A),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: isSendingInline
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Secondary action buttons: Reply in Send tab & Close
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Close'.trData(modalCtx),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleReplyToMessage(conv.latestMessage);
                                  },
                                  icon: const Icon(Icons.reply_rounded, size: 15),
                                  label: Text(
                                    'Reply'.trData(modalCtx),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E227A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }

  Widget _buildMessageCard(ArtistMessageModel msg) {
    final isIncoming = _isIncomingMessage(msg);
    final translatedRecipientName = msg.recipientName.trData(context);
    final translatedSenderName = msg.senderName.trData(context);
    final rawSubject = msg.subject.trim();
    final translatedMessage = msg.message.trData(context);

    final displayName =
        isIncoming ? translatedSenderName : translatedRecipientName;
    final displaySubtitle =
        msg.recipientCategory.isNotEmpty
            ? msg.recipientCategory.trData(context)
            : 'Artist'.trData(context);
    final avatarUrl = isIncoming ? msg.senderAvatarUrl : msg.recipientAvatarUrl;

    final now = DateTime.now();
    final isToday =
        now.year == msg.createdAt.year &&
        now.month == msg.createdAt.month &&
        now.day == msg.createdAt.day;
    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    final dateDisplay =
        isToday
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
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child:
                          (avatarUrl == null || avatarUrl.isEmpty)
                              ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'A',
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
                                isIncoming
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 12,
                                color:
                                    isIncoming
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF5E227A),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isIncoming
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              isIncoming
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE9D5FF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncoming
                                ? Icons.mark_email_read_outlined
                                : Icons.check_circle_outline_rounded,
                            size: 11,
                            color:
                                isIncoming
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF5E227A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncoming
                                ? 'Inbox'.trData(context)
                                : 'Sent'.trData(context),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isIncoming
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF5E227A),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                            errorBuilder:
                                (_, __, ___) => const Icon(
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
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
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
            boxShadow:
                isSelected
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
                    child:
                        hasArtist
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
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
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
                hintStyle: const TextStyle(
                  color: Color(0xFFD4BEE4),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                hintStyle: const TextStyle(
                  color: Color(0xFFD4BEE4),
                  fontSize: 13.5,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE9D5FF),
                    width: 1.2,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E227A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.file_upload_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
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
                            child: const Icon(
                              Icons.zoom_in,
                              size: 11,
                              color: Colors.white,
                            ),
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
                          _attachedFlyerName ??
                              'Flyer selected'.trData(context),
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
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
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
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF5E227A),
                      size: 22,
                    ),
                    onPressed: _showFlyerPickerSheet,
                  ),
                  IconButton(
                    tooltip: 'Remove'.trData(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
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
            'This is a private message to the selected artist and uses 1 of your 10 monthly messages.'
                .trData(context),
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
                backgroundColor:
                    hasArtist
                        ? const Color(0xFF5E227A)
                        : const Color(0xFFBCA6C8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBCA6C8),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child:
                  _isSending
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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

/// Represents a grouped conversation thread with an artist / user partner.
class ArtistChatConversation {
  final String key;
  final String partnerId;
  final String partnerName;
  final String partnerEmail;
  final String? partnerAvatarUrl;
  final String partnerCategory;
  final List<ArtistMessageModel> messages;

  ArtistChatConversation({
    required this.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    this.partnerAvatarUrl,
    required this.partnerCategory,
    required this.messages,
  });

  ArtistMessageModel get latestMessage => messages.last;
  DateTime get latestTimestamp => latestMessage.createdAt;
  int get totalMessages => messages.length;
  bool get hasUnread => messages.any((m) => !m.isRead);
}

class _PartnerInfo {
  final String partnerId;
  final String partnerName;
  final String partnerEmail;
  final String? partnerAvatarUrl;
  final String partnerCategory;

  const _PartnerInfo({
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    this.partnerAvatarUrl,
    required this.partnerCategory,
  });
}
