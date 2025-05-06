import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/deepseek_service.dart';

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
  late final DeepSeekService _deepSeekService;
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
    _deepSeekService = DeepSeekService(
      apiKey:
          'sk-1a96f19c8d6c4627a8a5a96f6c8f042e', // Replace with your actual API key
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

    try {
      bool isFirstChunk = true;
      String partialResponse = '';
      
      await for (final chunk in _deepSeekService.streamChatResponse(userMessage, [])) {
        if (mounted) {
          partialResponse += chunk;
          
          setState(() {
            // For first chunk, add typing indicator
            if (isFirstChunk) {
              _messages.add(_buildBotMessage(
                "Typing...",
                const AssetImage('assets/images/bee.png'),
              ));
              _messages.add(const SizedBox(height: 20));
              isFirstChunk = false;
            }
            
            // Update the response every few characters
            if (chunk.length > 3 || partialResponse.length % 3 == 0) {
              // Remove previous response
              if (_messages.length >= 2) {
                _messages.removeLast();
                _messages.removeLast();
              }
              
              // Add updated response
              _messages.add(_buildBotMessage(
                partialResponse,
                const AssetImage('assets/images/bee.png'),
              ));
              _messages.add(const SizedBox(height: 20));
              
              // Scroll to bottom with each update
              _scrollToBottom();
            }
          });
        }
      }

      // Final update with formatted response
      if (mounted && partialResponse.isNotEmpty) {
        setState(() {
          _currentStreamedResponse = _deepSeekService.formatResponse(partialResponse);
          if (_messages.length >= 2) {
            _messages.removeLast();
            _messages.removeLast();
          }
          _messages.add(_buildBotMessage(
            _currentStreamedResponse,
            const AssetImage('assets/images/bee.png'),
          ));
          _messages.add(const SizedBox(height: 20));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
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
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildTypingIndicator(),
                  ),
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
