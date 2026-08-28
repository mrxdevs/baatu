import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/config/env_config.dart';
import '../../services/gemini_service.dart';
import '../../utils/app_styles.dart';
import '../../widgets/sia_character.dart';

class LiveAiTeacherScreen extends StatefulWidget {
  const LiveAiTeacherScreen({super.key});
  static const String routeName = '/live_ai_teacher';

  @override
  State<LiveAiTeacherScreen> createState() => _LiveAiTeacherScreenState();
}

typedef AiTeacherScreen = LiveAiTeacherScreen;

class _LiveAiTeacherScreenState extends State<LiveAiTeacherScreen> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Note: Old animation controllers removed — SiaCharacterWidget manages its own animations

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
  bool _isMuted = false; // Mute/unmute audio
  bool _autoSpeak = true; // Auto-speak responses toggle
  AvatarState _avatarState = AvatarState.idle;

  // Context-aware dynamic suggestions
  List<String> _suggestions = [
    'How are you today?',
    'Teach me common idioms',
    'Let\'s practice a restaurant roleplay',
    'How can I improve pronunciation?',
  ];

  // Word-by-word highlighting
  int _currentWordIndex = 0;
  List<String> _currentSpeakingWords = [];
  Timer? _wordTimer;
  bool _useProgressHandler = false; // Use real TTS progress when available

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _initializeTTS();

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
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          '''You are Sia, a friendly, warm, and highly interactive English speaking teacher created by DigiWellie Technology.

Your core rules:
1. **Human Conversational Style**: Speak naturally with warmth, supportive encouragement, and enthusiasm.
2. **Micro-Sentences Only**: Use short, punchy 1-2 sentence thoughts that are easy to listen to and speak aloud.
3. **Strict Word Limit**: Keep your main response UNDER 60-80 WORDS (ABSOLUTE MAXIMUM 100 WORDS). Never give long lecture paragraphs.
4. **Active Teacher Feedback**:
   - If the student makes an error, gently give a 1-line correction (e.g. "✨ Quick tip: Say 'I saw him yesterday' instead of 'I see him yesterday'").
   - If their English is great, praise them warmly ("Spot on!", "Great pronunciation!").
5. **Always End with ONE Question**: Conclude your response with ONE simple, engaging question to keep the speaking practice interactive.
6. **Adaptive Level**: Match vocabulary and pace to whether the user is speaking simply (Beginner) or with nuance (Advanced).
7. **Suggestions Line**: At the very end of your response, on a completely new line, ALWAYS provide 2 to 3 short follow-up questions or replies the user might want to ask or say next based on the new context. Format it EXACTLY as:
SUGGESTIONS: [Question 1] | [Question 2] | [Question 3]'''),
    );

    _chatSession = _model.startChat();
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.48); // Natural conversational pacing
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setQueueMode(0); // QUEUE_FLUSH for zero audio buffering delay

    // Set voice quality for more natural sound
    List<dynamic>? voices = await _flutterTts.getVoices;
    if (voices != null) {
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
      debugPrint('TTS speech actually started on speaker');
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _avatarState = AvatarState.speaking;
          _currentWordIndex = 0;
        });

        // Only start fallback pacing timer if native progress handler doesn't take over
        _startFallbackPacingAfterStart();
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (_currentSpeakingWords.isNotEmpty && mounted) {
        setState(() {
          _currentWordIndex = _currentSpeakingWords.length - 1;
        });
      }
      Future.delayed(const Duration(milliseconds: 250), () {
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
      debugPrint('TTS Error: $msg');
      _stopWordTimer();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _avatarState = AvatarState.idle;
        });
      }
    });

    // Native progress handler for real-time word-by-word tracking
    _flutterTts.setProgressHandler((text, start, end, word) {
      if (mounted && _currentSpeakingWords.isNotEmpty) {
        // Native progress received — cancel fallback timer immediately
        if (!_useProgressHandler) {
          _wordTimer?.cancel();
          _wordTimer = null;
          _useProgressHandler = true;
        }

        // Find which word index corresponds to character position 'start'
        int charCount = 0;
        for (int i = 0; i < _currentSpeakingWords.length; i++) {
          final wordLen = _currentSpeakingWords[i].length;
          if (start >= charCount && start <= charCount + wordLen + 1) {
            if (_currentWordIndex != i) {
              setState(() {
                _currentWordIndex = i;
              });
            }
            break;
          }
          charCount += wordLen + 1; // +1 for whitespace
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
          if (mounted && _isListening) {
            final hadText = _messageController.text.isNotEmpty;
            setState(() {
              _isListening = false;
              if (_avatarState == AvatarState.listening && !_isLoading) {
                _avatarState = AvatarState.idle;
              }
            });
            debugPrint('Speech ended, had text: $hadText');
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
    // Prevent double-start issues
    if (_isListening) {
      debugPrint('Already listening, ignoring start request');
      return;
    }

    if (!_speechAvailable) {
      _showError('Speech recognition not available. Please check your device settings.');
      return;
    }

    if (_isSpeaking) {
      await _stopSpeaking();
    }

    // Ensure clean state before starting
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    setState(() {
      _isListening = true;
      _avatarState = AvatarState.listening;
      _messageController.clear();
    });

    debugPrint('Starting speech recognition...');

    try {
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
              if (!_isListening && _messageController.text.isNotEmpty) {
                _sendMessage();
              }
            });
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      setState(() {
        _isListening = false;
        _avatarState = AvatarState.idle;
      });
    }
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
    const welcomeText =
        "Hello! I'm Sia, your English teacher! 📚 I'm here to help you improve your English speaking skills. What would you like to practice today?";
    final welcomeMessage = ChatMessage(
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    if (_autoSpeak && !_isMuted) {
      _speak(welcomeMessage.text);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Parse response text to extract clean content and dynamic follow-up suggestions
  Map<String, dynamic> _parseResponseAndSuggestions(String rawResponse) {
    final suggestionsRegex = RegExp(r'SUGGESTIONS:\s*(.*)', caseSensitive: false, multiLine: true);
    final match = suggestionsRegex.firstMatch(rawResponse);

    String cleanText = rawResponse;
    List<String> newSuggestions = [];

    if (match != null) {
      // Remove SUGGESTIONS line from chat text
      cleanText = rawResponse.replaceAll(suggestionsRegex, '').trim();

      final suggestionsStr = match.group(1) ?? '';
      final rawList = suggestionsStr.split('|');
      for (var s in rawList) {
        var cleaned = s.trim();
        // Remove surrounding brackets if AI included them: [How is work?] -> How is work?
        if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
          cleaned = cleaned.substring(1, cleaned.length - 1).trim();
        }
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          newSuggestions.add(cleaned);
        }
      }
    }

    // Dynamic contextual fallback suggestions if AI did not return any
    if (newSuggestions.isEmpty) {
      newSuggestions = GeminiService.generateDynamicFallbacks(cleanText);
    }

    return {
      'cleanText': cleanText.isNotEmpty ? cleanText : rawResponse,
      'suggestions': newSuggestions,
    };
  }

  Future<void> _sendMessage([String? customMessage]) async {
    final message = (customMessage ?? _messageController.text).trim();
    if (message.isEmpty || _isLoading) return;

    // Stop listening or speaking if active
    if (_isListening) {
      await _stopListening();
    }
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isListening = false;
      _avatarState = AvatarState.thinking;
      _suggestions = [];
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      final rawResponseText = response.text ?? 'Sorry, I couldn\'t generate a response.';

      final parsed = _parseResponseAndSuggestions(rawResponseText);
      final cleanText = parsed['cleanText'] as String;
      final newSuggestions = parsed['suggestions'] as List<String>;

      final aiMessage = ChatMessage(
        text: cleanText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _suggestions = newSuggestions;
        _isLoading = false;
      });

      _scrollToBottom();

      // Only auto-speak if user has Auto-Speak enabled and audio is not muted
      if (_autoSpeak && !_isMuted) {
        await _speak(cleanText);
      } else {
        setState(() {
          _avatarState = AvatarState.idle;
        });
      }
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

    final words = text.split(RegExp(r'\s+'));
    setState(() {
      _currentSpeakingWords = words;
      _currentWordIndex = 0;
      _useProgressHandler = false;
    });

    // Set volume based on mute state and speak immediately
    await _flutterTts.setVolume(_isMuted ? 0.0 : 1.0);
    await _flutterTts.speak(text);
  }

  void _startFallbackPacingAfterStart() {
    _wordTimer?.cancel();
    if (_currentSpeakingWords.isEmpty) return;

    // First word duration
    final firstWord = _currentSpeakingWords[0];
    final estimatedSyllables = (firstWord.length / 2.5).ceil().clamp(1, 6);
    final wordDuration = Duration(milliseconds: (estimatedSyllables * 200) + 120);

    _wordTimer = Timer(wordDuration, () {
      if (mounted && _isSpeaking && !_useProgressHandler) {
        _advanceToNextWord();
      }
    });
  }

  void _advanceToNextWord() {
    if (_currentWordIndex >= _currentSpeakingWords.length - 1) {
      return;
    }

    // Do not use timer if native progress handler is active
    if (_useProgressHandler) return;

    setState(() {
      _currentWordIndex++;
    });

    final currentWord = _currentSpeakingWords[_currentWordIndex];
    final wordLength = currentWord.length;
    final estimatedSyllables = (wordLength / 2.5).ceil().clamp(1, 6);
    final wordDuration = Duration(milliseconds: (estimatedSyllables * 200) + 120);

    _wordTimer = Timer(wordDuration, () {
      if (mounted &&
          _isSpeaking &&
          _currentWordIndex < _currentSpeakingWords.length - 1 &&
          !_useProgressHandler) {
        _advanceToNextWord();
      }
    });
  }

  void _stopWordTimer() {
    _wordTimer?.cancel();
    _wordTimer = null;
    setState(() {
      _currentWordIndex = 0;
      _currentSpeakingWords = [];
      _useProgressHandler = false;
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

  void _toggleAutoSpeak() {
    setState(() {
      _autoSpeak = !_autoSpeak;
    });

    if (!_autoSpeak && _isSpeaking) {
      _stopSpeaking();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _autoSpeak ? Icons.record_voice_over : Icons.voice_over_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _autoSpeak
                  ? '🗣️ Auto-Speak enabled (Sia will speak responses)'
                  : '🤫 Auto-Speak disabled (Tap message to listen)',
            ),
          ],
        ),
        backgroundColor: _autoSpeak ? AppStyles.primaryColor : const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    _flutterTts.setVolume(_isMuted ? 0.0 : 1.0);

    if (_isMuted && _isSpeaking) {
      _flutterTts.stop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? '🔇 Audio muted' : '🔊 Audio unmuted'),
        backgroundColor: AppStyles.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showUnifiedSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF141A32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 25,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppStyles.secondaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppStyles.secondaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sia Voice & Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                'Control speaking, audio & chat flow',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white60, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // 1. Auto-speak setting
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _autoSpeak
                            ? AppStyles.secondaryColor.withValues(alpha: 0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _autoSpeak
                                ? AppStyles.secondaryColor.withValues(alpha: 0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _autoSpeak
                                ? Icons.record_voice_over_rounded
                                : Icons.voice_over_off_rounded,
                            color: _autoSpeak ? AppStyles.secondaryColor : Colors.white60,
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
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _autoSpeak
                                    ? 'Sia automatically reads out each reply'
                                    : 'Responses appear silently (tap to read)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _autoSpeak,
                          activeColor: AppStyles.secondaryColor,
                          onChanged: (val) {
                            setModalState(() => _autoSpeak = val);
                            setState(() => _autoSpeak = val);
                            if (!_autoSpeak && _isSpeaking) {
                              _stopSpeaking();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Mute/Unmute Audio
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isMuted ? Colors.orange.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up_rounded,
                            color: _isMuted ? Colors.orange : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isMuted ? 'TTS Audio Muted' : 'TTS Audio Enabled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isMuted ? 'Mute speaker voice' : 'Volume active',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white60, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: !_isMuted,
                          activeColor: AppStyles.secondaryColor,
                          onChanged: (val) {
                            setModalState(() => _isMuted = !val);
                            _toggleMute();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Clear / Reset Chat
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (_isSpeaking) _stopSpeaking();
                      setState(() {
                        _messages.clear();
                        _suggestions = [
                          'How are you today?',
                          'Teach me common idioms',
                          'Let\'s practice a restaurant roleplay',
                          'How can I improve pronunciation?',
                        ];
                      });
                      _addWelcomeMessage();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Restart Practice Session',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Poppins',
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // titleSpacing: 16,
        leading: SizedBox(
          child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              )),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Glowing LIVE Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3366),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFF3366),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xFFFF3366),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getStatusText(),
                    key: ValueKey(_avatarState),
                    style: TextStyle(
                      color: _getAvatarColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          color: _getAvatarColor().withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
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
                    Colors.black.withValues(alpha: 0.3),
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
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                onPressed: _stopSpeaking,
                tooltip: 'Stop Speaking',
              ),
            ),

          // Unified Cool Settings Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppStyles.secondaryColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: AppStyles.secondaryColor,
                size: 22,
              ),
              tooltip: 'Sia Settings & Voice',
              onPressed: _showUnifiedSettingsModal,
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
            // ── Full-screen Sia Character (background layer) ──
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_isSpeaking) {
                    _stopSpeaking();
                  } else if (!_isListening && !_isLoading) {
                    _toggleListening();
                  }
                },
                child: SiaCharacterWidget(
                  state: _mapAvatarStateToSiaState(),
                  isSpeaking: _isSpeaking,
                  currentWordIndex: _currentWordIndex,
                  totalWords: _currentSpeakingWords.length,
                ),
              ),
            ),

            // ── Chat Messages & Input (floating over full screen) ──
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Chat floats across full screen over character
                    Expanded(
                      child: _buildChatSection(),
                    ),
                    // Context-aware dynamic suggestions bar
                    _buildDynamicSuggestionsSection(),
                    // Input at bottom
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

  /// Maps the local AvatarState enum to the SiaCharacterWidget's SiaState.
  SiaState _mapAvatarStateToSiaState() {
    switch (_avatarState) {
      case AvatarState.idle:
        return SiaState.idle;
      case AvatarState.listening:
        return SiaState.listening;
      case AvatarState.thinking:
        return SiaState.thinking;
      case AvatarState.speaking:
        return SiaState.speaking;
    }
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
        return AppStyles.secondaryColor;
    }
  }

  String _getStatusText() {
    switch (_avatarState) {
      case AvatarState.idle:
        return '✨ Sia is ready to practice!';
      case AvatarState.listening:
        return '🎤 Sia is listening...';
      case AvatarState.thinking:
        return '🤔 Sia is thinking...';
      case AvatarState.speaking:
        return '🗣️ Sia is speaking live...';
    }
  }

  Widget _buildChatSection() {
    return ListView.builder(
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isCurrentlySpeaking = _isSpeaking && !isUser && message == _messages.last;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppStyles.primaryColor.withValues(alpha: 0.38)
              : isCurrentlySpeaking
                  ? const Color(0xFF00D9FF).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: Border.all(
            color: isUser
                ? AppStyles.primaryColor.withValues(alpha: 0.45)
                : isCurrentlySpeaking
                    ? const Color(0xFF00D9FF).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
            width: isCurrentlySpeaking ? 1.5 : 1,
          ),
          boxShadow: isCurrentlySpeaking
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCurrentlySpeaking)
              _buildAnimatedText(message.text)
            else
              Text(
                message.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 15,
                  height: 1.5,
                  fontFamily: 'Poppins',
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Speak on-demand button for AI messages
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _speak(message.text),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 14,
                            color: AppStyles.secondaryColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Listen',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppStyles.secondaryColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedText(String text) {
    if (_currentSpeakingWords.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.96),
          fontSize: 15,
          height: 1.5,
          fontFamily: 'Poppins',
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
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
                  ? const Color(0xFF00FFFF)
                  : isSpoken
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.45),
              fontSize: isCurrentWord ? 15.5 : 15,
              height: 1.5,
              fontFamily: 'Poppins',
              fontWeight: isCurrentWord
                  ? FontWeight.bold
                  : isSpoken
                      ? FontWeight.w500
                      : FontWeight.normal,
              backgroundColor:
                  isCurrentWord ? const Color(0xFF00D9FF).withValues(alpha: 0.3) : null,
              shadows: isCurrentWord
                  ? const [
                      Shadow(
                        color: Color(0xFF00FFFF),
                        blurRadius: 14,
                      ),
                      Shadow(
                        color: Color(0xFF8E4585),
                        blurRadius: 6,
                      ),
                    ]
                  : const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFE66D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sia is thinking...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontFamily: 'Poppins',
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Suggestions Bar above input
  Widget _buildDynamicSuggestionsSection() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 13,
                color: AppStyles.secondaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Suggested follow-ups:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return GestureDetector(
                  onTap: _isLoading ? null : () => _sendMessage(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppStyles.secondaryColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
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
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.12),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
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
                        hintText: 'Type or tap suggestion above...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
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
                const SizedBox(width: 10),
                // Microphone button
                if (_speechAvailable)
                  _buildActionButton(
                    icon: _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? const Color(0xFFFF6B6B) : const Color(0xFF00D9FF),
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                        if (_messageController.text.isNotEmpty) {
                          _sendMessage();
                        }
                      } else {
                        _startListening();
                      }
                    },
                    isActive: _isListening,
                  ),
                const SizedBox(width: 8),
                // Send button
                _buildActionButton(
                  icon: Icons.send_rounded,
                  color: AppStyles.primaryColor,
                  onTap: _isLoading ? null : () => _sendMessage(),
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isActive ? 0.8 : 0.3),
              color.withValues(alpha: isActive ? 0.6 : 0.1),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
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
