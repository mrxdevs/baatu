import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/config/env_config.dart';
import '../model/chat_message_model.dart';
import '../services/chat_history_service.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
  static const String routeName = '/chat_screen';
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final GeminiService _geminiService;
  late final ChatHistoryService _historyService;
  final FlutterTts _flutterTts = FlutterTts();

  ChatSessionModel? _currentSession;
  List<ChatSessionModel> _allSessions = [];
  bool _isLoading = true;
  bool _isTyping = false;
  String _userLevel = 'Intermediate';
  String? _currentlySpeakingMessageId;

  List<String> _suggestedReplies = [
    "Hello Nancy!",
    "Help me practice speaking!",
    "Teach me a new phrase today",
  ];

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(apiKey: EnvConfig.googleApiKey);
    _historyService = ChatHistoryService();
    _initTTS();
    _loadSessionAndHistory();
  }

  void _initTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _currentlySpeakingMessageId = null;
          });
        }
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) {
          setState(() {
            _currentlySpeakingMessageId = null;
          });
        }
      });
    } catch (e) {
      debugPrint('TTS Init error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  Future<void> _speakText(String messageId, String text) async {
    if (_currentlySpeakingMessageId == messageId) {
      await _flutterTts.stop();
      setState(() {
        _currentlySpeakingMessageId = null;
      });
      return;
    }

    // Strip markdown formatting symbols for speech
    final cleanText = text
        .replaceAll(RegExp(r'\*\*|\*|`|#|_'), '')
        .replaceAll(RegExp(r'✨|🎯|🗣️|✂️|📏|🎓|❓|📈|🚫'), '')
        .trim();

    setState(() {
      _currentlySpeakingMessageId = messageId;
    });
    await _flutterTts.speak(cleanText);
  }

  Future<void> _loadSessionAndHistory() async {
    setState(() => _isLoading = true);
    try {
      final savedLevel = await _historyService.getUserLevel();
      final session = await _historyService.getOrCreateActiveSession(userLevel: savedLevel);
      final sessions = await _historyService.getSessions();

      setState(() {
        _userLevel = session.userLevel.isNotEmpty ? session.userLevel : savedLevel;
        _currentSession = session;
        _allSessions = sessions;
        _isLoading = false;
      });

      if (session.messages.isEmpty) {
        _sendInitialGreeting();
      } else {
        _refreshSuggestedReplies();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat session: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendInitialGreeting() async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    String greeting = "";
    if (_userLevel == 'Beginner') {
      greeting =
          "Hi there! 👋 I'm Nancy, your English tutor. Let's learn simple words together. How was your day?";
    } else if (_userLevel == 'Advanced') {
      greeting =
          "Hello! I'm Nancy, your English coach. We'll refine your fluency, nuances, and idioms. What interesting topic shall we explore today?";
    } else {
      greeting =
          "Hey there! 😊 I'm Nancy, your English coach. I'm excited to practice with you! What did you do today?";
    }

    final botMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'model',
      content: greeting,
      timestamp: DateTime.now(),
    );

    if (_currentSession != null) {
      final updated = ChatSessionModel(
        id: _currentSession!.id,
        title: _currentSession!.title,
        createdAt: _currentSession!.createdAt,
        updatedAt: DateTime.now(),
        userLevel: _userLevel,
        messages: [botMsg],
      );

      setState(() {
        _currentSession = updated;
        _isTyping = false;
      });

      await _historyService.saveSession(updated);
      _refreshSuggestedReplies();
      _scrollToBottom();
    }
  }

  Future<void> _refreshSuggestedReplies() async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;

    final lastBotMsg = _currentSession!.messages.lastWhere(
      (m) => !m.isUser,
      orElse: () => _currentSession!.messages.last,
    );

    final suggestions = await _geminiService.getSuggestedReplies(
      lastBotMsg.content,
      userLevel: _userLevel,
    );

    if (mounted && suggestions.isNotEmpty) {
      setState(() {
        _suggestedReplies = suggestions;
      });
    }
  }

  Future<void> _handleSendMessage({String? customMessage}) async {
    final text = (customMessage ?? _messageController.text).trim();
    if (text.isEmpty || _isTyping || _currentSession == null) return;

    _messageController.clear();

    final userMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    // Update local session title if first user message
    String updatedTitle = _currentSession!.title;
    if (_currentSession!.messages.where((m) => m.isUser).isEmpty) {
      updatedTitle = text.length > 28 ? '${text.substring(0, 25)}...' : text;
    }

    final updatedMessages = List<ChatMessageModel>.from(_currentSession!.messages)..add(userMsg);
    final intermediateSession = ChatSessionModel(
      id: _currentSession!.id,
      title: updatedTitle,
      createdAt: _currentSession!.createdAt,
      updatedAt: DateTime.now(),
      userLevel: _userLevel,
      messages: updatedMessages,
    );

    setState(() {
      _currentSession = intermediateSession;
      _isTyping = true;
    });

    _scrollToBottom();

    // Prepare history for Gemini
    final apiHistory = updatedMessages
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();

    try {
      final responseText = await _geminiService.getChatResponse(
        text,
        apiHistory,
        userLevel: _userLevel,
      );

      final botMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: 'model',
        content: responseText,
        timestamp: DateTime.now(),
      );

      final finalMessages = List<ChatMessageModel>.from(updatedMessages)..add(botMsg);
      final finalSession = ChatSessionModel(
        id: _currentSession!.id,
        title: updatedTitle,
        createdAt: _currentSession!.createdAt,
        updatedAt: DateTime.now(),
        userLevel: _userLevel,
        messages: finalMessages,
      );

      if (mounted) {
        setState(() {
          _currentSession = finalSession;
          _isTyping = false;
        });

        await _historyService.saveSession(finalSession);
        _refreshSuggestedReplies();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _showSnackbar('Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _startNewSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start New Session?'),
        content: const Text(
          'Your current conversation will be saved in your session history, and Nancy will start a fresh chat with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E4585),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('New Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final newSession = await _historyService.createNewSession(userLevel: _userLevel);
    final all = await _historyService.getSessions();

    setState(() {
      _currentSession = newSession;
      _allSessions = all;
      _isLoading = false;
    });

    _sendInitialGreeting();
  }

  void _showSessionHistoryModal() async {
    final sessions = await _historyService.getSessions();
    setState(() => _allSessions = sessions);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chat Sessions History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E4585),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startNewSession();
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Start New Session', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E4585),
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _allSessions.isEmpty
                        ? const Center(
                            child: Text(
                              'No previous sessions yet.\nStart chatting with Nancy!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _allSessions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = _allSessions[index];
                              final isCurrent = s.id == _currentSession?.id;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent
                                      ? const Color(0xFF8E4585)
                                      : const Color(0xFF8E4585).withOpacity(0.1),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: isCurrent ? Colors.white : const Color(0xFF8E4585),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    color: isCurrent ? const Color(0xFF8E4585) : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '${s.messages.length} messages • Level: ${s.userLevel}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    await _historyService.deleteSession(s.id);
                                    final updated = await _historyService.getSessions();
                                    setModalState(() {
                                      _allSessions = updated;
                                    });
                                    setState(() {
                                      _allSessions = updated;
                                    });
                                    if (isCurrent && updated.isNotEmpty) {
                                      _historyService.setActiveSessionId(updated.first.id);
                                      setState(() => _currentSession = updated.first);
                                    }
                                  },
                                ),
                                onTap: () async {
                                  await _historyService.setActiveSessionId(s.id);
                                  Navigator.pop(context);
                                  setState(() {
                                    _currentSession = s;
                                    _userLevel = s.userLevel;
                                  });
                                  _refreshSuggestedReplies();
                                  _scrollToBottom();
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

  void _showLevelSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Learning Level',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E4585),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nancy will immediately adapt her vocabulary, speed, and sentence complexity.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _buildLevelTile(
                level: 'Beginner',
                title: '🟢 Beginner (Foundations)',
                desc: 'Simple everyday words, short sentences, and friendly gentle guidance.',
              ),
              const SizedBox(height: 10),
              _buildLevelTile(
                level: 'Intermediate',
                title: '🟡 Intermediate (Conversational)',
                desc: 'Everyday conversations, common idioms, sentence variation, and fluency.',
              ),
              const SizedBox(height: 10),
              _buildLevelTile(
                level: 'Advanced',
                title: '🟣 Advanced (Nuance & Mastery)',
                desc: 'Rich vocabulary, complex phrases, formal vs informal nuances, and precision.',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelTile({
    required String level,
    required String title,
    required String desc,
  }) {
    final isSelected = _userLevel == level;

    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (_userLevel == level) return;

        setState(() {
          _userLevel = level;
        });

        await _historyService.saveUserLevel(level);

        if (_currentSession != null) {
          final updated = ChatSessionModel(
            id: _currentSession!.id,
            title: _currentSession!.title,
            createdAt: _currentSession!.createdAt,
            updatedAt: DateTime.now(),
            userLevel: level,
            messages: _currentSession!.messages,
          );
          setState(() => _currentSession = updated);
          await _historyService.saveSession(updated);
        }

        // Notify Nancy of level change
        _handleSendMessage(
          customMessage: "I've changed my learning level to $level. Please adapt your questions and feedback!",
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8E4585).withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E4585) : Colors.grey[300]!,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? const Color(0xFF8E4585) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF8E4585), size: 22),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF8E4585),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E4585), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundImage: AssetImage('assets/images/bee.png'),
                  backgroundColor: Colors.transparent,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nancy (AI Teacher)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4585),
                    ),
                  ),
                  Text(
                    _isTyping ? 'Typing feedback...' : 'Active Tutor • DigiWellie',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isTyping ? const Color(0xFF8E4585) : Colors.grey[600],
                      fontWeight: _isTyping ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Level selector chip
          GestureDetector(
            onTap: _showLevelSelectorModal,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8E4585).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8E4585).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userLevel == 'Beginner'
                        ? '🟢 Beg'
                        : _userLevel == 'Advanced'
                            ? '🟣 Adv'
                            : '🟡 Inter',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4585),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF8E4585), size: 16),
                ],
              ),
            ),
          ),
          // History & New Session Actions
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF8E4585)),
            tooltip: 'Session History',
            onPressed: _showSessionHistoryModal,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8E4585)),
            tooltip: 'New Chat Session',
            onPressed: _startNewSession,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E4585)))
          : SafeArea(
              child: Column(
                children: [
                  // Message list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: (_currentSession?.messages.length ?? 0) + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _currentSession?.messages.length && _isTyping) {
                          return _buildTypingIndicator();
                        }
                        final msg = _currentSession!.messages[index];
                        return msg.isUser
                            ? _buildUserMessageBubble(msg)
                            : _buildBotMessageBubble(msg);
                      },
                    ),
                  ),

                  // Interactive Suggestion Chips
                  if (_suggestedReplies.isNotEmpty && !_isTyping)
                    Container(
                      height: 42,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _suggestedReplies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final text = _suggestedReplies[i];
                          return ActionChip(
                            label: Text(text, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: const Color(0xFF8E4585).withOpacity(0.3)),
                            labelStyle: const TextStyle(
                              color: Color(0xFF8E4585),
                              fontWeight: FontWeight.w500,
                            ),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.04),
                            onPressed: () => _handleSendMessage(customMessage: text),
                          );
                        },
                      ),
                    ),

                  // Input bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3F7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              enabled: !_isTyping,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _isTyping
                                    ? 'Nancy is thinking...'
                                    : 'Reply in English (micro-sentences)...',
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: _isTyping ? null : (_) => _handleSendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isTyping ? null : () => _handleSendMessage(),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                _isTyping ? Colors.grey[300] : const Color(0xFF8E4585),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildBotMessageBubble(ChatMessageModel msg) {
    final isSpeaking = _currentlySpeakingMessageId == msg.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundImage: AssetImage('assets/images/bee.png'),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E7F8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: const Color(0xFF8E4585).withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: msg.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                      strong: const TextStyle(
                        color: Color(0xFF8E4585),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _speakText(msg.id, msg.content),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                              size: 16,
                              color: isSpeaking ? Colors.green : const Color(0xFF8E4585),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSpeaking ? 'Listening...' : 'Listen',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSpeaking ? Colors.green : const Color(0xFF8E4585),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.content));
                        _showSnackbar('Message copied to clipboard');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(Icons.copy_outlined, size: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildUserMessageBubble(ChatMessageModel msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 45),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E4585),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E4585).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 17,
            backgroundImage: AssetImage('assets/images/user.png'),
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundImage: AssetImage('assets/images/bee.png'),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8E7F8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6 + (value * 3),
          width: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF8E4585),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}
