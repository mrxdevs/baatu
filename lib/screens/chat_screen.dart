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
  bool _autoSpeak = true;

  List<String> _suggestedReplies = [
    "Help me practice speaking!",
    "Teach me a new phrase today",
    "How can I improve my fluency?",
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
        .replaceAll(RegExp(r'✨|🎯|🗣️|✂️|📏|🎓|❓|📈|🚫|💡|☕|🥣|😅'), '')
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
        _suggestedReplies = [
          "My day was great!",
          "I was quite busy today.",
          "Tell me something interesting!",
        ];
      });

      await _historyService.saveSession(updated);
      _scrollToBottom();

      if (_autoSpeak) {
        _speakText(botMsg.id, botMsg.content);
      }
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
      _suggestedReplies = []; // Immediately clear old suggestions during thinking
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
      final rawResponseText = await _geminiService.getChatResponse(
        text,
        apiHistory,
        userLevel: _userLevel,
      );

      final parsed = GeminiService.parseResponseAndSuggestions(rawResponseText);
      final cleanText = parsed['cleanText'] as String;
      final newSuggestions = parsed['suggestions'] as List<String>;

      final botMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: 'model',
        content: cleanText,
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
          _suggestedReplies = newSuggestions;
          _isTyping = false;
        });

        await _historyService.saveSession(finalSession);
        _scrollToBottom();

        if (_autoSpeak) {
          _speakText(botMsg.id, botMsg.content);
        }
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

  /// Single Unified Settings & Tools Modal
  void _showUnifiedSettingsModal() async {
    final sessions = await _historyService.getSessions();
    setState(() => _allSessions = sessions);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 25,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E4585).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF8E4585),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nancy Teacher Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E4585),
                                ),
                              ),
                              Text(
                                'Customise voice, level & chat sessions',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        // 1. AUTO-SPEAK SETTING
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F6FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8E4585).withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _autoSpeak
                                      ? const Color(0xFF8E4585)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _autoSpeak
                                      ? Icons.record_voice_over_rounded
                                      : Icons.voice_over_off_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Auto-Speak Responses',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _autoSpeak
                                          ? 'Nancy automatically reads out each reply'
                                          : 'Responses appear silently (tap to read)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _autoSpeak,
                                activeColor: const Color(0xFF8E4585),
                                onChanged: (val) {
                                  setModalState(() => _autoSpeak = val);
                                  setState(() => _autoSpeak = val);
                                  if (!_autoSpeak && _currentlySpeakingMessageId != null) {
                                    _flutterTts.stop();
                                    setState(() => _currentlySpeakingMessageId = null);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. LEARNING LEVEL SELECTOR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Learning Level',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E4585),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E4585).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Current: $_userLevel',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8E4585),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildLevelOption(
                              level: 'Beginner',
                              label: '🟢 Beginner',
                              desc: 'Foundations',
                              setModalState: setModalState,
                            ),
                            const SizedBox(width: 8),
                            _buildLevelOption(
                              level: 'Intermediate',
                              label: '🟡 Inter',
                              desc: 'Fluency',
                              setModalState: setModalState,
                            ),
                            const SizedBox(width: 8),
                            _buildLevelOption(
                              level: 'Advanced',
                              label: '🟣 Advanced',
                              desc: 'Nuances',
                              setModalState: setModalState,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 3. SESSION HISTORY & START NEW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chat History & Sessions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E4585),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _startNewSession();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E4585),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 15),
                                    SizedBox(width: 4),
                                    Text(
                                      'New Chat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        _allSessions.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No saved sessions yet.\nStart learning with Nancy!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _allSessions.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final s = _allSessions[index];
                                  final isCurrent = s.id == _currentSession?.id;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFF8E4585).withOpacity(0.08)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent
                                            ? const Color(0xFF8E4585).withOpacity(0.3)
                                            : Colors.grey[200]!,
                                      ),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isCurrent
                                            ? const Color(0xFF8E4585)
                                            : Colors.grey[300],
                                        child: Icon(
                                          Icons.chat_bubble_outline,
                                          color: isCurrent ? Colors.white : Colors.grey[700],
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                          color: isCurrent
                                              ? const Color(0xFF8E4585)
                                              : Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${s.messages.length} msgs • ${s.userLevel}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
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
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                        setState(() {
                                          _currentSession = s;
                                          _userLevel = s.userLevel;
                                        });
                                        _refreshSuggestedReplies();
                                        _scrollToBottom();
                                      },
                                    ),
                                  );
                                },
                              ),
                      ],
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

  Widget _buildLevelOption({
    required String level,
    required String label,
    required String desc,
    required StateSetter setModalState,
  }) {
    final isSelected = _userLevel == level;

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (_userLevel == level) return;

          setModalState(() => _userLevel = level);
          setState(() => _userLevel = level);

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

          if (mounted) {
            _handleSendMessage(
              customMessage:
                  "I've changed my learning level to $level. Please adapt your questions and feedback!",
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8E4585).withOpacity(0.12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF8E4585) : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF8E4585) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFF8E4585) : Colors.grey[600],
                ),
              ),
            ],
          ),
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
                    _isTyping ? 'Typing feedback...' : '$_userLevel Tutor • DigiWellie',
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
          // Cool Unified Settings & History Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E4585).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF8E4585).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF8E4585),
                size: 22,
              ),
              tooltip: 'Settings, Level & History',
              onPressed: _showUnifiedSettingsModal,
            ),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

                  // Interactive Dynamic Suggestion Chips
                  if (_suggestedReplies.isNotEmpty && !_isTyping)
                    Container(
                      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Color(0xFF8E4585),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Suggested follow-ups:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _suggestedReplies.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final text = _suggestedReplies[i];
                                return GestureDetector(
                                  onTap: () => _handleSendMessage(customMessage: text),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFF8E4585).withOpacity(0.35),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E4585),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
                                    : 'Reply in English or tap suggestion...',
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
                  children: [
                    Text(
                      _formatTime(msg.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _speakText(msg.id, msg.content),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              isSpeaking
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                              size: 14,
                              color: isSpeaking ? Colors.redAccent : const Color(0xFF8E4585),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isSpeaking ? 'Stop' : 'Listen',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSpeaking ? Colors.redAccent : const Color(0xFF8E4585),
                                fontWeight: FontWeight.bold,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E4585), Color(0xFFA05295)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E4585).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E4585)),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Nancy is formulating tips...',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E4585)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
