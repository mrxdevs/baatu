import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/config/env_config.dart';
import '../../utils/app_styles.dart';

class AiTeacherScreen extends StatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

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

  // Word-by-word highlighting
  int _currentWordIndex = 0;
  List<String> _currentSpeakingWords = [];
  String _currentSpeakingText = '';
  Timer? _wordTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAI();
    _initializeTTS();

    // Initialize speech after first frame to avoid crashes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });

    // Add welcome message
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    // Pulse animation for the avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for speaking state
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);

    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
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
    await _flutterTts.setSpeechRate(0.45); // Slightly faster for natural pacing
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.95); // Slightly lower for warmer female voice

    // Set voice quality for more natural sound
    await _flutterTts.setQueueMode(1); // Queue mode for smoother transitions

    // Try to get a more natural voice if available
    List<dynamic>? voices = await _flutterTts.getVoices;
    if (voices != null) {
      // Look for a more natural female voice
      var preferredVoice = voices.firstWhere(
        (voice) =>
            voice['name'].toString().toLowerCase().contains('enhanced') ||
            voice['name'].toString().toLowerCase().contains('premium') ||
            voice['name'].toString().toLowerCase().contains('wavenet') ||
            voice['name'].toString().toLowerCase().contains('neural'),
        orElse: () => voices.firstWhere(
          (voice) =>
              voice['name'].toString().toLowerCase().contains('female') ||
              voice['name'].toString().toLowerCase().contains('samantha'),
          orElse: () => null,
        ),
      );

      if (preferredVoice != null) {
        await _flutterTts.setVoice({
          'name': preferredVoice['name'],
          'locale': preferredVoice['locale'] ?? 'en-US',
        });
        debugPrint('Using voice: ${preferredVoice['name']}');
      }
    }

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _avatarState = AvatarState.speaking;
      });
    });

    _flutterTts.setCompletionHandler(() {
      // Show last word briefly before clearing
      if (_currentSpeakingWords.isNotEmpty) {
        setState(() {
          _currentWordIndex = _currentSpeakingWords.length - 1;
        });
      }
      // Delay slightly then clear
      Future.delayed(const Duration(milliseconds: 300), () {
        _stopWordTimer();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _avatarState = AvatarState.idle;
          });
        }
      });
    });

    _flutterTts.setErrorHandler((msg) {
      _stopWordTimer();
      setState(() {
        _isSpeaking = false;
        _avatarState = AvatarState.idle;
      });
    });

    // Progress handler for exact word tracking (Android)
    _flutterTts.setProgressHandler((text, start, end, word) {
      if (mounted && _currentSpeakingText.isNotEmpty) {
        // Cancel timer - we're using real progress
        _wordTimer?.cancel();

        // Find which word index corresponds to this position
        int charCount = 0;
        for (int i = 0; i < _currentSpeakingWords.length; i++) {
          final wordEnd = charCount + _currentSpeakingWords[i].length;
          if (start >= charCount && start < wordEnd + 1) {
            if (_currentWordIndex != i) {
              setState(() {
                _currentWordIndex = i;
              });
            }
            break;
          }
          charCount = wordEnd + 1; // +1 for space
        }
      }
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
        if (mounted) {
          setState(() {
            _isListening = false;
            _avatarState = AvatarState.idle;
          });

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
          "Hello! I'm Nancy, your English teacher! 📚 I'm here to help you improve your English speaking skills. What would you like to practice today?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

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

    // Stop listening if active
    if (_isListening) {
      await _stopListening();
    }

    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isListening = false; // Ensure mic is off
      _avatarState = AvatarState.thinking;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
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
      _stopWordTimer();
    }

    // Setup word-by-word highlighting
    final words = text.split(RegExp(r'\s+'));
    setState(() {
      _currentSpeakingText = text;
      _currentSpeakingWords = words;
      _currentWordIndex = 0;
    });

    // Start timer as fallback for devices without progress handler
    _advanceToNextWord();

    await _flutterTts.speak(text);
  }

  void _advanceToNextWord() {
    if (_currentWordIndex >= _currentSpeakingWords.length - 1) {
      return;
    }

    // Simple fixed interval - progress handler or completion will sync
    // At speech rate 0.45, average ~3.5 words/sec = ~285ms per word
    const wordInterval = Duration(milliseconds: 280);

    _wordTimer = Timer(wordInterval, () {
      if (mounted && _currentWordIndex < _currentSpeakingWords.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
        _advanceToNextWord(); // Schedule next word
      }
    });
  }

  void _stopWordTimer() {
    _wordTimer?.cancel();
    _wordTimer = null;
    setState(() {
      _currentWordIndex = 0;
      _currentSpeakingWords = [];
      _currentSpeakingText = '';
    });
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    _stopWordTimer();
    setState(() {
      _isSpeaking = false;
      _avatarState = AvatarState.idle;
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'Nancy - AI Teacher',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_isSpeaking)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                onPressed: _stopSpeaking,
                tooltip: 'Stop Speaking',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF1A1F38),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background animated circles
            ..._buildBackgroundCircles(),

            // Avatar in CENTER BACKGROUND - Fixed position
            Positioned.fill(
              child: Center(
                child: _buildAvatarSection(),
              ),
            ),

            // Chat Messages - ON TOP of avatar, scrollable
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Chat takes most space
                    Expanded(
                      child: _buildChatSection(),
                    ),
                    // Input at bottom with minimal padding
                    _buildInputSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getAvatarColor().withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 100,
        left: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: () {
        if (_isSpeaking) {
          _stopSpeaking();
        } else if (!_isListening && !_isLoading) {
          _toggleListening();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with dynamic effects
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSpeaking ? _pulseAnimation.value : 1.0,
                child: _buildInteractiveAvatar(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Status Text with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _getStatusText(),
              key: ValueKey(_avatarState),
              style: TextStyle(
                color: _getAvatarColor(),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                shadows: [
                  Shadow(
                    color: _getAvatarColor().withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // Tap hint
          if (_avatarState == AvatarState.idle)
            Text(
              'Tap to speak',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow rings
        if (_isSpeaking || _isListening) ...[
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                width: 180 + (_waveAnimation.value * 40),
                height: 180 + (_waveAnimation.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getAvatarColor().withOpacity(0.3 - (_waveAnimation.value * 0.3)),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                width: 160 + (_waveAnimation.value * 60),
                height: 160 + (_waveAnimation.value * 60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getAvatarColor().withOpacity(0.2 - (_waveAnimation.value * 0.2)),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
        ],

        // Main avatar container
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getAvatarColor().withOpacity(0.3),
                _getAvatarColor().withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: _getAvatarColor().withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getAvatarColor().withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                alignment: Alignment.center,
                child: _buildAvatarContent(),
              ),
            ),
          ),
        ),

        // Sound wave bars for speaking state
        if (_isSpeaking)
          Positioned(
            bottom: 20,
            child: _buildSoundWaves(),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    IconData iconData;
    double iconSize = 60;

    switch (_avatarState) {
      case AvatarState.idle:
        iconData = Icons.school_rounded;
        break;
      case AvatarState.listening:
        iconData = Icons.mic_rounded;
        break;
      case AvatarState.thinking:
        iconData = Icons.psychology_rounded;
        break;
      case AvatarState.speaking:
        iconData = Icons.record_voice_over_rounded;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Icon(
        iconData,
        key: ValueKey(_avatarState),
        size: iconSize,
        color: _getAvatarColor(),
      ),
    );
  }

  Widget _buildSoundWaves() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final offset = (index - 2).abs() * 0.15;
            final height = 8.0 + (math.sin((_waveAnimation.value + offset) * math.pi * 2) * 8);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: _getAvatarColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Color _getAvatarColor() {
    switch (_avatarState) {
      case AvatarState.idle:
        return const Color(0xFF00D9FF);
      case AvatarState.listening:
        return const Color(0xFFFF6B6B);
      case AvatarState.thinking:
        return const Color(0xFFFFE66D);
      case AvatarState.speaking:
        return const Color(0xFF4ECDC4);
    }
  }

  String _getStatusText() {
    switch (_avatarState) {
      case AvatarState.idle:
        return '✨ Ready to learn!';
      case AvatarState.listening:
        return '🎤 Listening...';
      case AvatarState.thinking:
        return '🤔 Thinking...';
      case AvatarState.speaking:
        return '🗣️ Speaking...';
    }
  }

  Widget _buildChatSection() {
    return Container(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUser
                      ? [
                          AppStyles.primaryColor.withOpacity(0.6),
                          AppStyles.primaryColor.withOpacity(0.3),
                        ]
                      : [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser
                      ? AppStyles.primaryColor.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && message == _messages.last && _isSpeaking)
                    _buildAnimatedText(message.text)
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText(String text) {
    // Show word-by-word highlighting
    if (_currentSpeakingWords.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 15,
          height: 1.5,
          fontFamily: 'Poppins',
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: _currentSpeakingWords.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          final isCurrentWord = index == _currentWordIndex;
          final isSpoken = index < _currentWordIndex;

          return TextSpan(
            text: word + (index < _currentSpeakingWords.length - 1 ? ' ' : ''),
            style: TextStyle(
              color: isCurrentWord
                  ? const Color(0xFF4ECDC4) // Highlighted word (teal)
                  : isSpoken
                      ? Colors.white.withOpacity(0.9) // Already spoken
                      : Colors.white.withOpacity(0.4), // Not yet spoken
              fontSize: 15,
              height: 1.5,
              fontFamily: 'Poppins',
              fontWeight: isCurrentWord ? FontWeight.w600 : FontWeight.normal,
              backgroundColor: isCurrentWord ? const Color(0xFF4ECDC4).withOpacity(0.15) : null,
              shadows: isCurrentWord
                  ? [
                      Shadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFFFE66D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nancy is thinking...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type or tap the avatar to speak...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Poppins',
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
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
                        } else if (text.isEmpty &&
                            _avatarState == AvatarState.listening &&
                            !_isListening) {
                          setState(() {
                            _avatarState = AvatarState.idle;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Microphone button
                if (_speechAvailable)
                  _buildActionButton(
                    icon: _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? const Color(0xFFFF6B6B) : const Color(0xFF00D9FF),
                    onTap: _toggleListening,
                    isActive: _isListening,
                  ),
                const SizedBox(width: 8),
                // Send button
                _buildActionButton(
                  icon: Icons.send_rounded,
                  color: AppStyles.primaryColor,
                  onTap: _isLoading ? null : _sendMessage,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isActive ? 0.8 : 0.3),
              color.withOpacity(isActive ? 0.6 : 0.1),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
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
  thinking,
  speaking,
}
