import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  // Changed URL to use non-streaming endpoint
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent';
  final String _apiKey;
  // Use a persistent client for sending multiple requests over time
  final http.Client _client = http.Client();

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    debugPrint('GeminiService initialized with API key: ${_apiKey.substring(0, 5)}...');
  }

  // Remember to call dispose() when the service is no longer needed
  void dispose() {
    debugPrint('GeminiService disposed');
    _client.close();
  }

  /// Gets a complete chat response from the Gemini API.
  Future<String> getChatResponse(String message, List<Map<String, String>> history) async {
    debugPrint('GeminiService: Getting chat response for message: $message');
    debugPrint('GeminiService: History length: ${history.length}');
    
    try {
      // Build the conversation history for the 'contents' parameter
      final List<Map<String, dynamic>> contents = [];

      // Add historical messages
      for (var msg in history) {
         String role = msg['role'] == 'user' ? 'user' : 'model';
         contents.add({
           'role': role,
           'parts': [{'text': msg['content'] ?? ''}]
         });
         debugPrint('GeminiService: Added history message - Role: $role');
      }

      // Add the current user's message
      contents.add({
        'role': 'user',
        'parts': [{'text': message}]
      });
      debugPrint('GeminiService: Added current user message');

      // Construct the request body
      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
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
        
        // Extract the text from the response
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
          return formatResponse(responseText);
        } else {
          debugPrint('GeminiService: Error - Unexpected response format');
          return "Error: Unexpected response format";
        }
      } else {
        // Handle error response
        String errorMessage = 'Failed to get response: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson != null && errorJson['error'] != null && errorJson['error']['message'] != null) {
            errorMessage = 'API Error ${response.statusCode}: ${errorJson['error']['message']}';
            if (errorJson['error']['details'] != null) {
              errorMessage += ' - Details: ${jsonEncode(errorJson['error']['details'])}';
            }
          }
        } catch (e) {
          errorMessage = 'Failed to get response: ${response.statusCode}. Body: ${response.body}';
        }
        debugPrint('GeminiService: Error - $errorMessage');
        return "Error: $errorMessage";
      }
    } catch (e) {
      debugPrint('GeminiService: Exception caught - $e');
      return "Request failed: $e";
    }
  }

  // Format the response for display
  String formatResponse(String response) {
    debugPrint('GeminiService: Formatting response');
    return response.trim();
  }
}