import 'package:flutter/material.dart';
import '../services/deepseek_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
  static const String routeName = '/chat_screen';
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  late final DeepSeekService _deepSeekService;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _deepSeekService = DeepSeekService(
        apiKey:
            'sk-1a96f19c8d6c4627a8a5a96f6c8f042e'); // Replace with your API key
    _addInitialMessage();
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I'm your English teacher. How can I help you improve your English today?",
          isUser: false,
          time: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text;
    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _chatHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      String fullResponse = '';
      await for (final chunk in _deepSeekService.streamChatResponse(userMessage, _chatHistory)) {
        if (mounted) {
          setState(() {
            fullResponse += chunk;
            // Update or add the bot message
            if (_messages.last.isUser) {
              _messages.add(
                ChatMessage(
                  text: fullResponse,
                  isUser: false,
                  time: DateTime.now(),
                ),
              );
            } else {
              _messages.removeLast();
              _messages.add(
                ChatMessage(
                  text: fullResponse,
                  isUser: false,
                  time: DateTime.now(),
                ),
              );
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          _chatHistory.add({
            'role': 'assistant',
            'content': fullResponse,
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: "I'm sorry, I'm having trouble connecting. Please try again.",
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: themeColor.withOpacity(0.2),
                child: const Icon(Icons.school, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Text('English Teacher'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text('...',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(themeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration(
                hintText: 'Send a message',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send, color: themeColor),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _handleSubmitted(_messageController.text);
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? themeColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
