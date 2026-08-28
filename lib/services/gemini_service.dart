import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  // List of fallback models in order of priority when a model is overloaded (503 / 429)
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-flash-latest',
  ];

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
8. 💡 MANDATORY CONTEXTUAL SUGGESTIONS: At the very end of your response, on a completely new line, ALWAYS provide 2 to 3 short context-specific replies or follow-up questions the student can tap to answer your question or continue the conversation.
Format it EXACTLY as:
SUGGESTIONS: <Option 1> | <Option 2> | <Option 3>
""";
  }

  /// Sends a request with automatic multi-model failover and retry on 503 / 429 errors.
  Future<http.Response?> _sendWithModelFallback(String requestBody) async {
    for (int i = 0; i < _models.length; i++) {
      final model = _models[i];
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';

      try {
        final response = await _client
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 12));

        // If successful, return immediately
        if (response.statusCode == 200) {
          return response;
        }

        // If 503 (High demand / overloaded) or 429 (Rate limit) or 500, log and try next model
        if (response.statusCode == 503 ||
            response.statusCode == 429 ||
            response.statusCode == 500 ||
            response.statusCode == 404) {
          debugPrint('Gemini model $model returned ${response.statusCode}. Trying fallback model...');
          // Brief pause before trying next candidate to prevent stampede
          await Future.delayed(const Duration(milliseconds: 350));
          continue;
        }

        // For other status codes, log and attempt next model
        debugPrint('Gemini model $model returned status ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        debugPrint('Gemini model $model timed out. Trying fallback model...');
      } catch (e) {
        debugPrint('Gemini model $model error: $e. Trying fallback model...');
      }
    }
    return null;
  }

  /// Parse response into clean text and context-aware suggestions
  static Map<String, dynamic> parseResponseAndSuggestions(String rawResponse) {
    final suggestionsRegex = RegExp(r'SUGGESTIONS:\s*(.*)', caseSensitive: false, multiLine: true);
    final match = suggestionsRegex.firstMatch(rawResponse);

    String cleanText = rawResponse;
    List<String> suggestions = [];

    if (match != null) {
      cleanText = rawResponse.replaceAll(suggestionsRegex, '').trim();
      final suggestionsStr = match.group(1) ?? '';
      final rawList = suggestionsStr.split('|');
      for (var s in rawList) {
        var cleaned = s.trim();
        if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
          cleaned = cleaned.substring(1, cleaned.length - 1).trim();
        }
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          suggestions.add(cleaned);
        }
      }
    }

    // Dynamic contextual fallback generation based on the text if no suggestions tag found
    if (suggestions.isEmpty) {
      suggestions = generateDynamicFallbacks(cleanText);
    }

    return {
      'cleanText': cleanText.isNotEmpty ? cleanText : rawResponse,
      'suggestions': suggestions,
    };
  }

  /// Generates dynamic contextual follow-up questions/replies based on the message content
  static List<String> generateDynamicFallbacks(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('what') || lower.contains('tell me') || lower.contains('which')) {
      return [
        "Let me share my thoughts!",
        "Could you give an example first?",
        "What's your recommendation?",
      ];
    } else if (lower.contains('how')) {
      return [
        "Can you break it down step-by-step?",
        "How can I practice this daily?",
        "Is there a simpler way?",
      ];
    } else if (lower.contains('why') || lower.contains('explain')) {
      return [
        "That makes total sense!",
        "Why is that so common?",
        "Can we test it with a sentence?",
      ];
    } else if (lower.contains('?') || lower.contains('do you') || lower.contains('have you') || lower.contains('are you')) {
      return [
        "Yes, absolutely!",
        "Not quite, tell me more.",
        "How would a native speaker answer?",
      ];
    } else if (lower.contains('mistake') || lower.contains('tip') || lower.contains('say')) {
      return [
        "Thanks for the correction! ✨",
        "Let me try another sentence.",
        "What are other common errors?",
      ];
    }

    return [
      "Let's practice a conversation!",
      "Teach me a new idiom for this.",
      "How do I sound more natural?",
    ];
  }

  /// Gets a complete chat response from the Gemini API with automatic model failover.
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
                  "Hello! I'm Nancy, your English tutor at DigiWellie. I'm excited to practice with you at your $userLevel level! What's on your mind today?\nSUGGESTIONS: Help me practice speaking! | Teach me a new phrase | How can I improve my fluency?"
            }
          ]
        }
      ];

      // Add conversation history
      for (final h in history) {
        contents.add({
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': h['content'] ?? ''}
          ]
        });
      }

      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 300,
        },
      });

      final response = await _sendWithModelFallback(requestBody);

      if (response != null && response.statusCode == 200) {
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
        }
      }

      // Fallback friendly teacher response if all models are momentarily busy
      return "I'm right here with you! 🌟 Let's continue practicing together. What topic would you like to explore?\nSUGGESTIONS: Daily conversation | Travel & food | Business English";
    } catch (e) {
      debugPrint('GeminiService exception: $e');
      return "I'm ready whenever you are! 🌟 Tap below to choose a topic or type anything.\nSUGGESTIONS: Tell me a story | Practice interview | Useful idioms";
    }
  }

  /// Generates 3 contextual quick-reply suggestion chips for the user based on recent conversation.
  Future<List<String>> getSuggestedReplies(
    String lastBotMessage, {
    String userLevel = 'Intermediate',
  }) async {
    // If the message already has parsed suggestions in it, return them directly
    final parsed = parseResponseAndSuggestions(lastBotMessage);
    final suggestions = parsed['suggestions'] as List<String>;
    if (suggestions.isNotEmpty) {
      return suggestions;
    }

    try {
      final prompt = """Based on this English teacher message: "${parsed['cleanText']}"
Provide 3 short, natural student replies (each 2-5 words) that a $userLevel English learner could tap to respond or ask next.
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

      final response = await _sendWithModelFallback(requestBody);

      if (response != null && response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final parts = jsonResponse['candidates']?[0]?['content']?[0]?['parts'] ?? jsonResponse['candidates']?[0]?['content']?['parts'];
        if (parts != null && parts.isNotEmpty) {
          String raw = parts[0]['text'] ?? '';
          raw = raw.replaceAll(RegExp(r'```json|```'), '').trim();
          final startIdx = raw.indexOf('[');
          final endIdx = raw.lastIndexOf(']');
          if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
            final jsonSubstring = raw.substring(startIdx, endIdx + 1);
            final List<dynamic> parsedList = jsonDecode(jsonSubstring);
            return parsedList.map((e) => e.toString().trim()).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
    }

    return generateDynamicFallbacks(lastBotMessage);
  }
}
