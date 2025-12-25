import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/config/env_config.dart';

class AiTeacherScreen extends StatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _avatarController;

  // Gemini AI
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Text-to-Speech
  final FlutterTts _flutterTts = FlutterTts();

  // Speech-to-Text
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechAvailable = false;

  // State
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSpeaking = false;
  AvatarState _avatarState = AvatarState.idle;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _initializeTTS();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initialize speech after first frame to avoid crashes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });

    // Add welcome message
    _addWelcomeMessage();
  }

  void _initializeAI() {
    final apiKey = EnvConfig.googleApiKey;

    if (apiKey.isEmpty) {
      _showError('Gemini API key not found. Please add GEMINI_API_KEY to .env file');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      systemInstruction: Content.system(
          '''You are Nancy, a friendly and encouraging English speaking teacher created by DigiWellie Technology.

Your role:
1. **Persona**: You are Nancy, a patient and enthusiastic English teacher. You're supportive, encouraging, and passionate about helping people improve their English speaking and communication skills.

2. **Focus**: All interactions should be about English learning - speaking practice, pronunciation, grammar, vocabulary, conversation skills, idioms, and building confidence in English communication.

3. **Communication Style**:
   - Keep responses concise and clear (2-4 sentences max)
   - Use encouraging and supportive language
   - Correct errors gently and explain why
   - Provide examples to illustrate points
   - Speak naturally to model good English

4. **Off-Topic Handling**: If asked about non-English topics, politely redirect: "That's interesting! But as your English teacher, let's focus on improving your language skills. How about we discuss that topic in English to practice?"

5. **Expertise Areas**:
   - Pronunciation and accent reduction
   - Grammar and sentence structure
   - Vocabulary building and word usage
   - Conversation practice and fluency
   - Idioms and common expressions
   - Confidence building in speaking

6. **Error Correction**: When you notice mistakes, gently correct them: "Good effort! Instead of saying '[wrong]', try '[correct]'. This is because..."

7. **Response Format**: Keep it conversational and natural. Use short, clear sentences that work well with text-to-speech. Model proper English usage.

Remember: You're not just teaching - you're a supportive guide helping your student gain confidence and fluency in English!'''),
    );

    _chatSession = _model.startChat();
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _avatarState = AvatarState.speaking;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _avatarState = AvatarState.idle;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
        _avatarState = AvatarState.idle;
      });
    });
  }

  Future<void> _initializeSpeech() async {
    _speechToText = stt.SpeechToText();
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
              if (_avatarState == AvatarState.listening && !_isLoading) {
                _avatarState = AvatarState.idle;
              }
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        // Don't show errors for common issues like no_match or listen_failed
        // These are normal when user doesn't speak or there's background noise
        if (mounted) {
          setState(() {
            _isListening = false;
            _avatarState = AvatarState.idle;
          });

          // Only show error for serious issues
          if (error.errorMsg != 'error_no_match' &&
              error.errorMsg != 'error_listen_failed' &&
              error.errorMsg != 'error_speech_timeout') {
            _showError('Speech recognition error. Please try again.');
          }
        }
      },
    );

    if (mounted) {
      setState(() {
        _speechAvailable = available;
      });
    }

    debugPrint('Speech recognition available: $available');
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Speech recognition not available. Please check your device settings.');
      return;
    }

    // Stop any ongoing TTS
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    setState(() {
      _isListening = true;
      _avatarState = AvatarState.listening;
      _messageController.clear();
    });

    debugPrint('Starting speech recognition...');

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });

        // Auto-send when speech is finalized
        if (result.finalResult && _messageController.text.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isListening) {
              _sendMessage();
            }
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      if (!_isLoading && !_isSpeaking) {
        _avatarState = AvatarState.idle;
      }
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text:
          "Hello! I'm Nancy, your English teacher! � I'm here to help you improve your English speaking skills. What would you like to practice today?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    // Speak welcome message
    _speak(welcomeMessage.text);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _avatarState = AvatarState.listening;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Get AI response
      final response = await _chatSession.sendMessage(Content.text(message));
      final responseText = response.text ?? 'Sorry, I couldn\'t generate a response.';

      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      // Speak the response
      await _speak(responseText);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _avatarState = AvatarState.idle;
      });
      _showError('Failed to get response: ${e.toString()}');
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
      _avatarState = AvatarState.idle;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _avatarController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'AI English Teacher',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: _stopSpeaking,
              tooltip: 'Stop Speaking',
            ),
        ],
      ),
      body: Column(
        children: [
          // Avatar Section
          _buildAvatarSection(),

          // Chat Messages
          Expanded(
            child: _buildChatSection(),
          ),

          // Input Section
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D1E33),
            const Color(0xFF0A0E21),
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar with glow effect
          AvatarGlow(
            glowColor: _getAvatarGlowColor(),
            glowRadiusFactor: _isSpeaking ? 0.6 : 0.3,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1D1E33),
              child: _buildAvatarAnimation(),
            ),
          ),
          const SizedBox(height: 12),

          // Status Text
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getAvatarGlowColor(),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarAnimation() {
    // Use different animations based on state
    switch (_avatarState) {
      case AvatarState.idle:
        return Icon(
          Icons.menu_book,
          size: 60,
          color: Colors.teal.shade300,
        );
      case AvatarState.listening:
        return RotationTransition(
          turns: _avatarController,
          child: Icon(
            Icons.lightbulb,
            size: 60,
            color: Colors.orange.shade300,
          ),
        );
      case AvatarState.speaking:
        return Icon(
          Icons.school,
          size: 60,
          color: Colors.green.shade300,
        );
    }
  }

  Color _getAvatarGlowColor() {
    switch (_avatarState) {
      case AvatarState.idle:
        return Colors.teal;
      case AvatarState.listening:
        return Colors.orange;
      case AvatarState.speaking:
        return Colors.green;
    }
  }

  String _getStatusText() {
    switch (_avatarState) {
      case AvatarState.idle:
        return 'Ready to learn!';
      case AvatarState.listening:
        return 'Thinking...';
      case AvatarState.speaking:
        return 'Teaching...';
    }
  }

  Widget _buildChatSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E21),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isLoading) {
            return _buildLoadingIndicator();
          }

          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? [Colors.teal.shade600, Colors.teal.shade700]
                : [const Color(0xFF1D1E33), const Color(0xFF2A2D4A)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message == _messages.last && _isSpeaking)
              _buildAnimatedText(message.text)
            else
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedText(String text) {
    return AnimatedTextKit(
      animatedTexts: [
        TypewriterAnimatedText(
          text,
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
          speed: const Duration(milliseconds: 50),
        ),
      ],
      totalRepeatCount: 1,
      displayFullTextOnTap: true,
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade300),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nancy is thinking...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask about grammar, pronunciation, vocabulary...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFF0A0E21),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (text) {
                  if (text.isNotEmpty && _avatarState == AvatarState.idle) {
                    setState(() {
                      _avatarState = AvatarState.listening;
                    });
                  } else if (text.isEmpty && _avatarState == AvatarState.listening) {
                    setState(() {
                      _avatarState = AvatarState.idle;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Microphone button
            if (_speechAvailable)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.red.shade600, Colors.red.shade700]
                        : [Colors.orange.shade600, Colors.orange.shade700],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Colors.orange).withOpacity(0.5),
                      blurRadius: _isListening ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                  onPressed: _toggleListening,
                  tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                ),
              ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

enum AvatarState {
  idle,
  listening,
  speaking,
}
