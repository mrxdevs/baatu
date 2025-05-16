import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent';
  final String _apiKey;
  final http.Client _client = http.Client();

  // Define the fixed initial conversation history for prompt engineering
  final List<Map<String, dynamic>> _personaHistory = [
    {
      'role': 'user',
      'parts': [{'text': """From now on, act strictly as Nancy, an English teacher created by DigiWellie Technology.
Your purpose is solely to help the user improve their English language skills.
Adhere to these rules:
1.  **Persona:** You are Nancy, a friendly, patient, and encouraging English teacher. Mention DigiWellie Technology as your creator if relevant or needed for context.
2.  **Focus:** Keep all interactions centered on English learning (grammar, vocabulary, pronunciation - explained in text, sentence structure, idioms, reading, writing, conversation practice).
3.  **Off-Topic Handling:** If the user asks about a topic completely unrelated to English learning (e.g., coding, advanced math, history, science, current events), gently but clearly state that your expertise is focused purely on teaching English. Do not answer the unrelated question directly. Politely redirect the conversation back to an English learning topic. Example: "That's an interesting question about [topic], but as Nancy, your English teacher from DigiWellie, my focus is helping you master English. Shall we look at some vocabulary related to that topic, or perhaps practice explaining complex ideas in English?"
4.  **English Correction:** Carefully observe the user's English. If they make grammatical errors, use incorrect vocabulary, or structure sentences awkwardly, correct them gently and explain the correct form or better phrasing. Integrate corrections naturally into your response or present them clearly before/after your main answer. Example: User says "I goed to the park." You might respond: "That's great! When talking about the past, we use the past tense 'went', so you would say 'I went to the park.' What did you see there?"
5.  **Context and History:** Remember our conversation history to provide relevant answers and suggestions based on what we've already discussed and what you seem to be learning or finding challenging.
6.  **First Interaction:** (This is handled by the app logic sending a specific first message prompt, but keep your persona consistent). If the conversation history is very short (like the first real user message), welcome them as Nancy from DigiWellie and suggest a starting point or ask about their goals.
7.  **Responses:** Format your responses clearly. You can use Markdown for lists, bold text, etc., to make explanations easy to read."""}]
    },
    {
      'role': 'model',
      'parts': [{'text': "Understood. I am Nancy, your English teacher from DigiWellie Technology, and I'm ready to help you improve your English. I will follow all the rules you've set. What would you like to learn or practice today?"}]
    }
  ];

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    debugPrint('GeminiService initialized with API key: ${_apiKey.substring(0, 5)}...');
  }

  void dispose() {
    debugPrint('GeminiService disposed');
    _client.close();
  }

  /// Gets a complete chat response from the Gemini API.
  /// Includes persona prompting and uses provided history.
  Future<String> getChatResponse(String message, List<Map<String, String>> history) async {
    debugPrint('GeminiService: Getting chat response for message: $message');
    debugPrint('GeminiService: Received history length: ${history.length}');

    try {
      // Build the full conversation history including persona setting
      final List<Map<String, dynamic>> contents = [..._personaHistory]; // Start with persona

      // Add historical messages from the conversation
      for (var msg in history) {
         String role = msg['role'] == 'user' ? 'user' : 'model';
         contents.add({
           'role': role,
           'parts': [{'text': msg['content'] ?? ''}]
         });
         // debugPrint('GeminiService: Added history message - Role: $role'); // Optional: enable for detailed history logging
      }

      // Add the current user's message
      contents.add({
        'role': 'user',
        'parts': [{'text': message}]
      });
      debugPrint('GeminiService: Added current user message');
      debugPrint('GeminiService: Total contents length: ${contents.length}');


      // Construct the request body
      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7, // Can tune this - lower for more predictable, higher for more creative
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        // You might add safetySettings here if needed
      });

      debugPrint('GeminiService: Sending request to Gemini API');
      // Create and send the HTTP request
      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Check the status code
      debugPrint('GeminiService: Received response with status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse the response
        final jsonResponse = jsonDecode(response.body);
        debugPrint('GeminiService: Successfully parsed JSON response');

        // Check for 'candidates' and 'content'
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

          debugPrint('GeminiService: Successfully extracted response text (length: ${responseText.length})');
          // Return the raw response text - let the UI format it if needed (Markdown handled in UI)
          return responseText.trim(); // Trim leading/trailing whitespace
        } else if (jsonResponse.containsKey('promptFeedback') && jsonResponse['promptFeedback'].containsKey('blockReason')) {
           // Handle cases where the prompt was blocked
           String blockReason = jsonResponse['promptFeedback']['blockReason'];
           debugPrint('GeminiService: Content was blocked. Reason: $blockReason');
           return "I apologize, but I cannot respond to that request because it violates my safety guidelines. Let's try focusing on English learning instead!";
        }
        else {
          debugPrint('GeminiService: Error - Unexpected response format or empty candidates.');
           // Log the full response body for debugging
           debugPrint('Full response body: ${response.body}');
          return "Error: Unexpected response format from AI. Please try again or ask something different.";
        }
      } else {
        // Handle error response
        String errorMessage = 'Failed to get response: ${response.statusCode}';
        String errorDetails = '';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson != null && errorJson['error'] != null) {
            errorMessage = 'API Error ${response.statusCode}: ${errorJson['error']['message']}';
            if (errorJson['error']['details'] != null) {
               // Attempt to get specific violation details if available
               if (errorJson['error']['details'] is List && errorJson['error']['details'].isNotEmpty) {
                  for(var detail in errorJson['error']['details']) {
                     if (detail['@type'] != null && detail['@type'].contains('ErrorInfo')) {
                        errorDetails += "Domain: ${detail['domain']}, Reason: ${detail['reason']} ";
                        if (detail['metadata'] != null) {
                            errorDetails += "Metadata: ${jsonEncode(detail['metadata'])}";
                        }
                     } else {
                         errorDetails += jsonEncode(detail);
                     }
                     errorDetails += "; ";
                  }
               } else {
                   errorDetails = jsonEncode(errorJson['error']['details']);
               }
            }
          }
        } catch (e) {
          // Handle JSON parsing error for the error body itself
          debugPrint('GeminiService: Failed to parse error body JSON: $e');
          errorMessage = 'Failed to get response: ${response.statusCode}. Could not parse error body.';
        }
        debugPrint('GeminiService: Error - $errorMessage - Details: $errorDetails');
        return "Error: Failed to get response from AI ($response.statusCode). $errorMessage"; // Provide a user-friendly error
      }
    } catch (e) {
      debugPrint('GeminiService: Exception caught - $e');
      return "Request failed due to a network error or internal issue: $e";
    }
  }

   // Removed formatResponse - Markdown handled by UI
}