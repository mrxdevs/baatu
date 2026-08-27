import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  final String _apiKey;
  final http.Client _client = http.Client();

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    if (_apiKey.isEmpty) {
      debugPrint('WARNING: GeminiService initialized with EMPTY API key!');
    }
  }

  void dispose() {
    _client.close();
  }

  /// Builds the dynamic system prompt tailored to user learning level, micro-sentences, and interactive teaching.
  String _buildSystemPrompt(String userLevel) {
    return """You are Nancy, a friendly, warm, and highly interactive English teacher from DigiWellie Technology.
Your sole mission is to help the user practice and master English speaking and writing.

🎯 CURRENT STUDENT LEVEL: $userLevel

Strict Teaching Rules:
1. 🗣️ HUMAN CONVERSATIONAL STYLE: Speak naturally with warmth, personality, and encouragement. Avoid stiff textbook jargon.
2. ✂️ MICRO-SENTENCES ONLY: Use short, punchy 1-2 sentence thoughts that are effortless to read and understand.
3. 📏 STRICT WORD LIMIT: Keep your ENTIRE response UNDER 60-80 WORDS (ABSOLUTE MAXIMUM 100 WORDS). Never write long essays or walls of text.
4. 🎓 ACTIVE TEACHER FEEDBACK:
   - If the user made a grammar/spelling/phrasing mistake, give a gentle, friendly 1-line micro-correction (e.g. "✨ Quick tip: Say 'I went' instead of 'I goed'").
   - If their English was great, give a quick 2-word cheer ("Spot on!", "Lovely expression!").
5. ❓ ALWAYS ASK ONE ENGAGING QUESTION: End every message with ONE simple, fun follow-up question so the student is eager to reply.
6. 📈 LEVEL ADAPTATION:
   - Beginner: Use simple everyday vocabulary, short sentences, explain simply.
   - Intermediate: Natural conversational fluency, common expressions, phrasing variety.
   - Advanced: Nuanced vocabulary, idioms, precision, and natural collocations.
7. 🚫 OFF-TOPIC HANDLING: If asked about coding, math, or unrelated topics, politely redirect back to practicing English on that theme in one short sentence.
""";
  }

  /// Gets a complete chat response from the Gemini API.
  Future<String> getChatResponse(
    String message,
    List<Map<String, String>> history, {
    String userLevel = 'Intermediate',
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(userLevel);

      final List<Map<String, dynamic>> contents = [
        {
          'role': 'user',
          'parts': [
            {'text': systemPrompt}
          ]
        },
        {
          'role': 'model',
          'parts': [
            {
              'text':
                  "Hello! I'm Nancy, your English tutor at DigiWellie. I'm excited to practice with you at your $userLevel level! What's on your mind today?"
            }
          ]
        }
      ];

      // Add conversation history (limiting to recent 15 turns for optimal context & speed)
      final recentHistory = history.length > 15 ? history.sublist(history.length - 15) : history;
      for (var msg in recentHistory) {
        String role = msg['role'] == 'user' ? 'user' : 'model';
        contents.add({
          'role': role,
          'parts': [
            {'text': msg['content'] ?? ''}
          ]
        });
      }

      // Add the current user's message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      });

      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topP': 0.95,
          'maxOutputTokens': 500, // Ample tokens to complete sentence while prompt enforces <80 words
        },
      });

      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts')) {
          final parts = jsonResponse['candidates'][0]['content']['parts'];
          String responseText = '';

          for (var part in parts) {
            if (part.containsKey('text')) {
              responseText += part['text'];
            }
          }

          return responseText.trim();
        } else {
          return "I'm here! What would you like to practice today?";
        }
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        return "I'm having a little trouble connecting right now, but let's keep practicing! Could you try saying that again?";
      }
    } catch (e) {
      debugPrint('GeminiService exception: $e');
      return "Oops, connection hiccup! Let's try again. What were we talking about?";
    }
  }

  /// Generates 3 contextual quick-reply suggestion chips for the user based on recent conversation.
  Future<List<String>> getSuggestedReplies(
    String lastBotMessage, {
    String userLevel = 'Intermediate',
  }) async {
    try {
      final prompt = """Based on this teacher message: "$lastBotMessage"
Provide 3 natural, short English student replies (each 2-5 words) that a $userLevel English learner could tap to respond.
Return ONLY a valid JSON array of 3 strings, example: ["Yes, I did!", "Can you give an example?", "Tell me more"]""";

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 150,
          'responseMimeType': 'application/json',
        },
      });

      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final parts = jsonResponse['candidates']?[0]?['content']?['parts'];
        if (parts != null && parts.isNotEmpty) {
          String raw = parts[0]['text'] ?? '';
          raw = raw.replaceAll(RegExp(r'```json|```'), '').trim();
          final startIdx = raw.indexOf('[');
          final endIdx = raw.lastIndexOf(']');
          if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
            final jsonSubstring = raw.substring(startIdx, endIdx + 1);
            final List<dynamic> parsed = jsonDecode(jsonSubstring);
            return parsed.map((e) => e.toString().trim()).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
    }

    // Default contextual fallbacks
    return [
      "Can you give an example?",
      "How do I say this better?",
      "Let's practice a topic!",
    ];
  }
}
