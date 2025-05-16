import 'package:baatu/secrete/api_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
  static const String routeName = '/chat_screen';
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Widget> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late final GeminiService _geminiService;
  bool _isTyping = false;
  String _currentStreamedResponse = '';

  // Add a list to store the conversation history for the API
  final List<Map<String, String>> _conversationHistory = [];

  // Add Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID (replace with your actual user management logic)
  String? get _userId => _auth.currentUser?.uid;
  // Define a chat session ID (can be fixed per user or per session)
  // For simplicity, let's use the user ID as the chat ID for now
  String? get _chatId => _userId;

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
  void initState() {
    super.initState();
    _geminiService = GeminiService(
      apiKey: ApiKeys.googleApiKey, // Replace with your actual Gemini API key
    );

    _loadChatHistory();
    // _messages.addAll([
    //   _buildBotMessage(
    //     "What sport do you know?",
    //     const AssetImage('assets/images/bee.png'),
    //   ),
    //   const SizedBox(height: 20),
    //   _buildUserMessage(
    //     "I know football, volleyball, tennis and others",
    //     const AssetImage('assets/images/user.png'),
    //   ),
    //   const SizedBox(height: 20),
    //   _buildBotMessage(
    //     "Have you ever been played any sport?",
    //     const AssetImage('assets/images/bee.png'),
    //   ),
    //   const SizedBox(height: 20),
    //   _buildUserMessage(
    //     "Yes,I played volleyball",
    //     const AssetImage('assets/images/user.png'),
    //   ),
    //   const SizedBox(height: 20),
    //   _buildBotMessage(
    //     "What sport do you know?",
    //     const AssetImage('assets/images/bee.png'),
    //   ),
    // ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null || _chatId == null) {
      debugPrint("User not logged in or chat ID not available.");
      // Handle cases where user is not logged in
      _showErrorSnackbar("Please log in to use the chat feature.");
      return;
    }

    debugPrint("Loading chat history for user: $_userId, chat: $_chatId");

    try {
      // Fetch messages from Firestore, ordered by timestamp
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(20) // Limit history to a reasonable number of messages
          .get();

      debugPrint("Found ${querySnapshot.docs.length} historical messages.");

      if (mounted) {
        setState(() {
          // Clear any existing messages (like the hardcoded ones)
          _messages.clear();
          _conversationHistory.clear();

          if (querySnapshot.docs.isEmpty) {
            // First time user scenario
            debugPrint("No history found. Triggering first-time greeting.");
            _handleFirstTimeUser();
          } else {
            // Load existing history
            for (var doc in querySnapshot.docs) {
              final data = doc.data();
              final role = data['role'];
              final content = data['content'];
              // final timestamp = data['timestamp']; // Assuming you save timestamp

              if (role != null && content != null) {
                // Add to history list for API
                _conversationHistory.add({'role': role, 'content': content});

                // Add to display list
                if (role == 'user') {
                  _messages.add(const SizedBox(height: 20));
                  _messages.add(_buildUserMessage(
                      content, const AssetImage('assets/images/user.png')));
                  _messages.add(const SizedBox(height: 20));
                } else if (role == 'model') {
                  _messages.add(const SizedBox(height: 20));
                  _messages.add(_buildBotMessage(
                      content, const AssetImage('assets/images/bee.png')));
                  _messages.add(const SizedBox(height: 20));
                }
              }
            }
            // Force scroll after loading history
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading chat history: $e");
      _showErrorSnackbar("Failed to load chat history.");
      // Optionally handle error gracefully in UI
    }
  }

  // New method for the first-time user experience
  Future<void> _handleFirstTimeUser() async {
    // Craft a specific prompt for the first message from Nancy
    final firstMessagePrompt =
        "This is my first time chatting with you. Please introduce yourself as Nancy, the English teacher from DigiWellie Technology, welcome me, and ask about my English learning goals or suggest a simple topic to start with.";

    if (kDebugMode) {
      print('ChatScreen: Triggering first-time message.');
    }

    // Add a placeholder message while waiting for the first response
    setState(() {
      _messages.add(const SizedBox(height: 20));
      _messages.add(_buildBotMessage(
          "...", const AssetImage('assets/images/bee.png'))); // Placeholder
      _messages.add(const SizedBox(height: 20));
      _isTyping = true;
    });

    // Force scroll
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    // Use _handleMessage logic to get the first response from Gemini
    // Note: _handleMessage will add this prompt as a user message to the history it sends to the API
    await _handleMessage(initialPrompt: firstMessagePrompt);

    // The _handleMessage function will update the UI and history lists
    // based on the response it gets from Gemini.
  }

  Future<void> _handleMessage({String? initialPrompt}) async {
    final message = initialPrompt ??
        _messageController.text.trim(); // Use initialPrompt if provided

    if (message.isEmpty) return;

    // Store message and clear input
    final userMessage = message;
    if (initialPrompt == null) {
      // Only clear controller for user-typed messages
      _messageController.clear();
    }

    if (kDebugMode) {
      print(
          'ChatScreen: Sending message: $userMessage (initial: ${initialPrompt != null})');
    }

    // Add user message to history and display
    // Note: If it's the initialPrompt, we don't add a visible user message widget
    // immediately, as it's just an instruction *to* Gemini. The first visible
    // message will be Nancy's response.
    if (initialPrompt == null) {
      setState(() {
        _conversationHistory.add({'role': 'user', 'content': userMessage});
        _messages.add(const SizedBox(height: 20));
        _messages.add(_buildUserMessage(
          userMessage,
          const AssetImage('assets/images/user.png'),
        ));
        _messages.add(const SizedBox(height: 20));
        _isTyping = true;
        _currentStreamedResponse =
            ''; // Clear for new streamed response if applicable
      });
      // Force scroll after adding user message
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } else {
      // If it's an initial prompt from the app, don't add a user bubble,
      // just set typing and wait for the bot's first message.
      if (!_isTyping) {
        // Prevent setting typing if already set by _handleFirstTimeUser
        setState(() {
          _isTyping = true;
          _currentStreamedResponse = '';
        });
      }
    }

    // Force scroll after adding user message (or setting typing for initial prompt)
    // Already done above, but good to be sure.
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    // Index to track where typing indicator is added (relative to _messages list)
    // This index needs to be calculated carefully based on whether
    // a user message widget was just added or if we are replacing
    // the initial placeholder for the first-time user.
    int typingIndicatorMessageIndex = -1;
    int placeholderIndex = -1;

    // If it's the first message from the bot (_handleFirstTimeUser triggered it),
    // find and replace the placeholder.
    if (initialPrompt != null) {
      // Find the placeholder message
      placeholderIndex = _messages.indexWhere((widget) =>
              widget is SizedBox &&
              widget.height == 20 &&
              _messages.indexOf(widget) > 0 && // Not the very first SizedBox
              _messages[_messages.indexOf(widget) - 1]
                  is Row // Check previous widget is a Row (bot message)
          );
      if (placeholderIndex > 0) {
        // The placeholder is the SizedBox *after* the temporary bot message
        // We will replace the temporary bot message and its trailing SizedBox.
        typingIndicatorMessageIndex =
            placeholderIndex - 1; // Index of the temporary bot message
      } else {
        // Could not find placeholder, add typing indicator at the end
        typingIndicatorMessageIndex = _messages.length;
        setState(() {
          _messages.add(_buildBotMessage(
              "Typing...", const AssetImage('assets/images/bee.png')));
          _messages.add(const SizedBox(height: 20));
        });
      }
    } else {
      // For regular user messages, add typing indicator at the end
      typingIndicatorMessageIndex = _messages.length;
      setState(() {
        _messages.add(_buildBotMessage(
            "Typing...", const AssetImage('assets/images/bee.png')));
        _messages.add(const SizedBox(height: 20));
      });
    }

    if (kDebugMode) {
      print(
          'ChatScreen: Showing typing indicator at messages index: $typingIndicatorMessageIndex');
    }

    // Force scroll after adding typing indicator
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    try {
      if (kDebugMode) {
        print(
            'ChatScreen: Calling Gemini API with history length: ${_conversationHistory.length}');
      }

      // Get complete response from API using the managed history
      final response = await _geminiService.getChatResponse(
          userMessage, List.from(_conversationHistory)); // Pass a copy

      if (kDebugMode) {
        print(
            'ChatScreen: Received response from Gemini: ${response.substring(0, min(50, response.length))}...');
        print(
            'ChatScreen: typingIndicatorMessageIndex: $typingIndicatorMessageIndex, messages length: ${_messages.length}');
      }

      if (mounted) {
        if (kDebugMode) {
          print('ChatScreen: Updating UI with response: $response');
        }

        setState(() {
          // Remove the typing indicator and spacing
          // Need to be careful with indices as we are removing elements
          if (typingIndicatorMessageIndex >= 0 &&
              typingIndicatorMessageIndex < _messages.length - 1) {
            // Ensure there's a SizedBox after
            if (kDebugMode) {
              print(
                  'ChatScreen: Removing typing indicator and SizedBox at indices $typingIndicatorMessageIndex and ${typingIndicatorMessageIndex + 1}');
            }
            _messages.removeAt(
                typingIndicatorMessageIndex + 1); // Remove height SizedBox
            _messages
                .removeAt(typingIndicatorMessageIndex); // Remove typing message
          } else {
            if (kDebugMode) {
              print(
                  'ChatScreen: Could not find typing indicator at expected index, removing last two elements assuming they are indicator + SizedBox');
              // Fallback: Remove the last two elements assuming they are the typing indicator and SizedBox
              if (_messages.length >= 2) {
                _messages.removeLast(); // Remove SizedBox
                _messages.removeLast(); // Remove typing message
              } else if (_messages.isNotEmpty) {
                _messages
                    .removeLast(); // Remove just the typing message if no SizedBox
              }
            }
          }

          if (kDebugMode) {
            print(
                'ChatScreen: Adding bot response at index $typingIndicatorMessageIndex');
          }

          // Add the complete response at the position where the typing indicator was (or end)
          _currentStreamedResponse =
              response; // Not actually streaming, but reusing the variable name
          _messages.insert(
              typingIndicatorMessageIndex >= 0 &&
                      typingIndicatorMessageIndex <= _messages.length
                  ? typingIndicatorMessageIndex
                  : _messages.length,
              _buildBotMessage(
                _currentStreamedResponse,
                const AssetImage('assets/images/bee.png'),
              ));
          _messages.insert(
              typingIndicatorMessageIndex >= 0 &&
                      typingIndicatorMessageIndex <= _messages.length
                  ? typingIndicatorMessageIndex + 1
                  : _messages.length,
              const SizedBox(height: 20));

          // **Add bot response to conversation history**
          _conversationHistory
              .add({'role': 'model', 'content': _currentStreamedResponse});

          _isTyping = false;

          if (kDebugMode) {
            print(
                'ChatScreen: Final messages length after update: ${_messages.length}');
            print(
                'ChatScreen: Final conversation history length: ${_conversationHistory.length}');
          }
        });

        // **Save conversation history to Firebase**
        _saveMessage(role: 'user', content: userMessage);
        _saveMessage(role: 'model', content: _currentStreamedResponse);

        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatScreen: Error handling message: $e');
      }
      if (mounted) {
        // Remove typing indicator on error
        setState(() {
          if (typingIndicatorMessageIndex >= 0 &&
              typingIndicatorMessageIndex < _messages.length - 1) {
            // Ensure there's a SizedBox after
            _messages.removeAt(
                typingIndicatorMessageIndex + 1); // Remove height SizedBox
            _messages
                .removeAt(typingIndicatorMessageIndex); // Remove typing message
          } else {
            // Fallback: Remove the last two elements assuming they are the typing indicator and SizedBox
            if (_messages.length >= 2) {
              _messages.removeLast(); // Remove SizedBox
              _messages.removeLast(); // Remove typing message
            } else if (_messages.isNotEmpty) {
              _messages
                  .removeLast(); // Remove just the typing message if no SizedBox
            }
          }
          _isTyping = false;
        });
        _showErrorSnackbar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _saveMessage(
      {required String role, required String content}) async {
    if (_userId == null || _chatId == null) {
      debugPrint(
          "Cannot save message: User not logged in or chat ID not available.");
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
      });
      debugPrint(
          "Message saved to Firebase: $role - ${content.substring(0, min(50, content.length))}");
    } catch (e) {
      debugPrint("Error saving message to Firebase: $e");
      // Optionally handle error gracefully - perhaps keep a local unsaved queue?
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFF5F5F5),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF8E4585),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Loading indicator or static title based on state
                      _isTyping &&
                              _messages.isNotEmpty &&
                              _messages.last is Row &&
                              (_messages.last as Row).children.first
                                  is CircleAvatar &&
                              ((_messages.last as Row).children.first
                                      as CircleAvatar)
                                  .backgroundImage is AssetImage &&
                              (((_messages.last as Row).children.first
                                          as CircleAvatar)
                                      .backgroundImage as AssetImage)
                                  .assetName
                                  .contains('bee')
                          ? const Text(
                              "Nancy is typing...",
                              style: TextStyle(
                                fontSize: 20, // Slightly smaller when typing
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E4585),
                              ),
                            )
                          : const Text(
                              "Let's talk!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E4585),
                              ),
                            ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _messages[index];
                    },
                  ),
                ),
                // typing indicator handled inline in _messages list now
                // if (_isTyping)
                //   Padding(
                //     padding: const EdgeInsets.all(20.0),
                //     child: _buildTypingIndicator(),
                //   ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF8E4585).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isTyping, // Disable input while typing
                      decoration: InputDecoration(
                        hintText: _isTyping
                            ? 'Nancy is thinking...'
                            : 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onSubmitted: _isTyping
                          ? null
                          : (_) =>
                              _handleMessage(), // Disable submit while typing
                    ),
                  ),
                  GestureDetector(
                    onTap: _isTyping
                        ? null
                        : _handleMessage, // Disable button while typing
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? Colors.grey
                            : const Color(0xFF8E4585), // Grey out when disabled
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay (optional, but good for long waits)
          if (_isTyping &&
              _messages
                  .isEmpty) // Show a central indicator if loading the very first message
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF8E4585))),
        ],
      ),
    );
  }

  Widget _buildBotMessage(String message, ImageProvider avatarImage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: avatarImage,
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8E7F8),
                border: Border.all(
                  color: const Color(0xFF8E4585).withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MarkdownBody(
                shrinkWrap: true,
                data: message,
                // styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                styleSheet: MarkdownStyleSheet(),
              )),
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildUserMessage(String message, ImageProvider avatarImage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 50),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF8E4585).withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundImage: avatarImage,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: const AssetImage('assets/images/bee.png'),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8E7F8),
            borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
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
