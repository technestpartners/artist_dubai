import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_helper.dart';

class AiArtGuideView extends StatefulWidget {
  const AiArtGuideView({super.key});

  @override
  State<AiArtGuideView> createState() => _AiArtGuideViewState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AiArtGuideViewState extends State<AiArtGuideView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestedPrompts = [
    'Which art districts can I visit in Dubai?',
    'How do I register as an artist in this app?',
    'Ideas for a weekend art tour in Dubai',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final query = text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _inputController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Generate intelligent AI response based on Dubai art context
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final response = _generateArtResponse(query);
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _isTyping = false;
    });
  }

  String _generateArtResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('district') || q.contains('visit') || q.contains('where') || q.contains('area') || q.contains('place')) {
      return 'Dubai has several vibrant, world-renowned art and creative hubs:\n\n'
          '1. **Alserkal Avenue (Al Quoz)**:\n'
          'The premier contemporary art hub of Dubai with over 70 creative spaces, world-class galleries (Green Art Gallery, Carbon 12, Grey Noise), artisan cafes, and indie cinemas.\n\n'
          '2. **Dubai Design District (d3)**:\n'
          'A hub for high-end fashion, architecture, modern sculpture installations, and design festivals.\n\n'
          '3. **DIFC Gate Village**:\n'
          'Sophisticated commercial galleries (Christie’s, Opera Gallery, Ayyam Gallery) and fine dining.\n\n'
          '4. **Al Fahidi Historical Neighbourhood**:\n'
          'Historic wind-tower quarter hosting the Sikka Art & Design Festival, XVA Gallery, and heritage craft studios.\n\n'
          '5. **Jameel Arts Centre (Jaddaf Waterfront)**:\n'
          'An innovative institution displaying modern Middle Eastern and South Asian art in minimalist architectural spaces.';
    }

    if (q.contains('register') || q.contains('join') || q.contains('sign up') || q.contains('profile') || q.contains('artist')) {
      return 'Registering as an artist on **Artist Dubai** is straightforward:\n\n'
          '1. Go to the Home screen.\n'
          '2. Tap on the **ARTIST REGISTRATION** card.\n'
          '3. Fill in your artist name, discipline (Painting, Sculpture, Photography, Digital Art, etc.), bio, and contact information.\n'
          '4. Upload your portfolio artwork samples and exhibitions.\n'
          '5. Submit your profile for immediate feature and verification across the Dubai art network.';
    }

    if (q.contains('tour') || q.contains('weekend') || q.contains('itinerary') || q.contains('day')) {
      return 'Here is a curated **Weekend Art Tour** in Dubai:\n\n'
          '**Day 1 (Friday - Modern & Design):**\n'
          '• **Morning:** Stroll through Dubai Design District (d3), enjoy breakfast at a creative café, and explore cutting-edge design showcases.\n'
          '• **Afternoon:** Visit DIFC Gate Village for prestigious contemporary galleries and sculpture walks.\n'
          '• **Evening:** Sunset visit to Jameel Arts Centre by the serene Jaddaf waterfront.\n\n'
          '**Day 2 (Saturday - Underground & Heritage):**\n'
          '• **Morning:** Wander through the historic Al Fahidi cultural quarters and visit XVA Art Hotel.\n'
          '• **Afternoon:** Dive into Alserkal Avenue — visit warehouse galleries, live artist workshops, and creative concept stores.\n'
          '• **Night:** Catch an independent art cinema screening or live music at Cinema Akil.';
    }

    if (q.contains('gallery') || q.contains('galleries') || q.contains('center')) {
      return 'Dubai boasts prestigious private and institutional art galleries:\n\n'
          '• **XVA Gallery** (Al Fahidi) - Specializes in contemporary Middle Eastern art.\n'
          '• **Ayyam Gallery** (Alserkal Avenue) - Leading regional contemporary artists.\n'
          '• **Custot Gallery** (Alserkal Avenue) - Modern and contemporary Western and international art.\n'
          '• **Opera Gallery** (DIFC) - Renowned master and contemporary artworks.\n'
          '• **Tashkeel** (Nad Al Sheba) - Studio spaces, residency programs, and workshops.\n\n'
          'Explore our in-app **GALLERIES** directory from the main menu for direct contacts and locations!';
    }

    if (q.contains('event') || q.contains('competition') || q.contains('exhibition')) {
      return 'You can discover all active competitions, exhibitions, and cultural gatherings directly inside our app!\n\n'
          '• Tap **EVENTS / COMPETITION** from the home screen.\n'
          '• Filter by dates, locations, and prize competitions.\n'
          '• Registered artists can also submit and showcase their own art events to the community.';
    }

    // Default general response
    return 'I am your **Artist Dubai Guide**! You can ask me anything about:\n\n'
        '• Art districts and galleries in Dubai (Alserkal, d3, DIFC)\n'
        '• How to register, exhibit, and showcase your artworks\n'
        '• Upcoming cultural events and competitions\n'
        '• Curated art weekend tours and gallery hopping tips\n\n'
        'Feel free to type any question below!';
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5E1788), // Rich Royal Violet
              Color(0xFF501275), // Mid Violet
              Color(0xFF420E62), // Deep Violet base
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. App Bar Header
              _buildAppBar(context),

              // 2. Chat / Suggestion Body
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(rh)
                    : _buildMessageList(),
              ),

              // 3. Bottom Prompt Input
              _buildInputArea(rh),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),

          // Logo badge
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'AI ART GUIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'New chat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // History action
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history is saved on device.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.history, color: Colors.white70, size: 22),
            tooltip: 'History',
            splashRadius: 20,
          ),

          // New Chat action
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white70, size: 21),
            tooltip: 'New chat',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper rh) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth.clamp(320.0, 500.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Central circular logo
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/header_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Main Title
              const Text(
                'ARTIST DUBAI Guide',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Ask about artists, events, galleries and art centers in Dubai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Suggestion buttons
              ..._suggestedPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _sendMessage(prompt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final msg = _messages[index];
        final isUser = msg.isUser;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/header_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF8A2BE2).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 14),
                    ),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFFD03BF7).withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: SelectableText(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.8,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ResponsiveHelper rh) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 14.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask the art guide...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) => _sendMessage(val),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () => _sendMessage(_inputController.text),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_return,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
