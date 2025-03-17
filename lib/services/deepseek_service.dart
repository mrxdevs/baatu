import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  final String _apiKey;

  DeepSeekService({required String apiKey}) : _apiKey = apiKey;

  Stream<String> streamChatResponse(String message, List<Map<String, String>> history) async* {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an experienced and friendly English teacher. Your role is to:
              1. Help students improve their English through natural conversation
              2. Correct grammar mistakes politely and explain the corrections
              3. Teach new vocabulary in context
              4. Provide cultural context when relevant
              5. Encourage and motivate students to practice English
              Please maintain a supportive and patient demeanor at all times.'''
            },
            ...history.map((msg) => {
                  'role': msg['role'] ?? 'user',
                  'content': msg['content'] ?? '',
                }),
            {
              'role': 'user',
              'content': message,
            },
          ],
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final String responseText = response.body;
        final List<String> chunks = responseText.split('\n');
        
        for (var chunk in chunks) {
          if (chunk.isEmpty) continue;
          if (chunk.startsWith('data: ')) {
            chunk = chunk.substring(6);
            try {
              final data = jsonDecode(chunk);
              final content = data['choices'][0]['delta']['content'];
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              print('Error parsing chunk: $e');
            }
          }
        }
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with DeepSeek API: $e');
    }
  }

  String formatResponse(String response) {
    // Remove any markdown code block syntax
    response = response.replaceAll(RegExp(r'```[a-zA-Z]*\n'), '');
    response = response.replaceAll('```', '');
    
    // Format lists
    response = response.replaceAllMapped(
      RegExp(r'^\d+\.\s(.+)$', multiLine: true),
      (match) => '• ${match.group(1)}',
    );
    
    // Add proper line breaks
    response = response.replaceAll('\n\n', '\n');
    
    return response.trim();
  }
}
