import 'package:baatu/secrete/api_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      apiKey:
          ApiKeys.googleApiKey, // Replace with your actual Gemini API key
    );
    _messages.addAll([
      _buildBotMessage(
        "What sport do you know?",
        const AssetImage('assets/images/bee.png'),
      ),
      const SizedBox(height: 20),
      _buildUserMessage(
        "I know football, volleyball, tennis and others",
        const AssetImage('assets/images/user.png'),
      ),
      const SizedBox(height: 20),
      _buildBotMessage(
        "Have you ever been played any sport?",
        const AssetImage('assets/images/bee.png'),
      ),
      const SizedBox(height: 20),
      _buildUserMessage(
        "Yes,I played volleyball",
        const AssetImage('assets/images/user.png'),
      ),
      const SizedBox(height: 20),
      _buildBotMessage(
        "What sport do you know?",
        const AssetImage('assets/images/bee.png'),
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleMessage() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) return;

    // Store message and clear input
    final userMessage = message;
    _messageController.clear();
    
    if (kDebugMode) {
      print('ChatScreen: Sending message: $userMessage');
    }

    // Add user message
    setState(() {
      _messages.add(const SizedBox(height: 20));
      _messages.add(_buildUserMessage(
        userMessage,
        const AssetImage('assets/images/user.png'),
      ));
      _messages.add(const SizedBox(height: 20));
      _isTyping = true;
      _currentStreamedResponse = '';
    });
    

    // Force scroll after adding user message
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    // Index to track where typing indicator is added
    int typingIndicatorIndex = -1;

    try {
      if (kDebugMode) {
        print('ChatScreen: Showing typing indicator');
      }
      
      // Show typing indicator and store its index
      setState(() {
        typingIndicatorIndex = _messages.length;
        _messages.add(_buildBotMessage(
          "Typing...",
          const AssetImage('assets/images/bee.png'),
        ));
        _messages.add(const SizedBox(height: 20));
      });
      
      // Create a history list for context
      List<Map<String, String>> chatHistory = [];
      // You can implement logic to extract previous messages if needed
      
      if (kDebugMode) {
        print('ChatScreen: Calling Gemini API');
      }
      
      // Get complete response from API
      final response = await _geminiService.getChatResponse(userMessage, chatHistory);
      
      if (kDebugMode) {
        print('ChatScreen: Received response from Gemini: ${response.substring(0, min(50, response.length))}...');
        print('ChatScreen: typingIndicatorIndex: $typingIndicatorIndex, messages length: ${_messages.length}');
      }
      
      if (mounted) {
        if (kDebugMode) {
          print('ChatScreen: Updating UI with response: $response');
        }
        
        setState(() {
          // Only remove typing indicator if it was added
          if (typingIndicatorIndex >= 0 && typingIndicatorIndex < _messages.length) {
            if (kDebugMode) {
              print('ChatScreen: Removing typing indicator at index $typingIndicatorIndex');
            }
            
            // Remove the typing indicator and spacing
            _messages.removeAt(typingIndicatorIndex + 1); // Remove height SizedBox
            _messages.removeAt(typingIndicatorIndex); // Remove typing message
            
            if (kDebugMode) {
              print('ChatScreen: Adding bot response at index $typingIndicatorIndex');
            }
            
            // Add the complete response at the same position
            _currentStreamedResponse = response;
            _messages.insert(typingIndicatorIndex, _buildBotMessage(
              _currentStreamedResponse,
              const AssetImage('assets/images/bee.png'),
            ));
            _messages.insert(typingIndicatorIndex + 1, const SizedBox(height: 20));
          } else {
            if (kDebugMode) {
              print('ChatScreen: Typing indicator not found, adding response at end');
              print('ChatScreen: Current messages length: ${_messages.length}');
            }
            
            // Fallback: just add the message at the end
            _currentStreamedResponse = response;
            _messages.add(_buildBotMessage(
              _currentStreamedResponse,
              const AssetImage('assets/images/bee.png'),
            ));
            _messages.add(const SizedBox(height: 20));
          }
          _isTyping = false;
          
          if (kDebugMode) {
            print('ChatScreen: Final messages length after update: ${_messages.length}');
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatScreen: Error handling message: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Remove typing indicator on error
        setState(() {
          if (typingIndicatorIndex >= 0 && typingIndicatorIndex < _messages.length) {
            _messages.removeAt(typingIndicatorIndex + 1); // Remove height SizedBox
            _messages.removeAt(typingIndicatorIndex); // Remove typing message
          }
          _isTyping = false;
        });
      }
    }
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
                      const Text(
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
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    children: _messages,
                  ),
                ),
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
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onSubmitted: (_) => _handleMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleMessage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E4585),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
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
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8E4585),
                fontSize: 16,
              ),
            ),
          ),
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
