import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // Import for Stream and StreamTransformer

class GeminiService {
  // Corrected URL using the specified model
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:streamGenerateContent';
  final String _apiKey;
  // Use a persistent client for sending multiple requests over time
  final http.Client _client = http.Client();

  // Buffer to accumulate partial JSON chunks from the stream
  String _streamBuffer = '';
  // This flag might not be strictly necessary for this API's streaming format
  // bool _isFirstChunk = true; // Keeping it for potential future adjustments if needed

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  // Remember to call dispose() when the service is no longer needed
  void dispose() {
    _client.close();
  }

  /// Streams chat responses from the Gemini API.
  Stream<String> streamChatResponse(String message, List<Map<String, String>> history) async* {
    try {
      // Build the conversation history for the 'contents' parameter
      final List<Map<String, dynamic>> contents = [];

      // Add the system instruction/persona as the first user message if needed
      // This is a common way to handle persona in the Generative Language API
      // as it doesn't support a dedicated 'systemInstruction' parameter in the request body.
      // You might adjust this depending on how you want to structure the conversation.
      // A common pattern is: User (setting the stage/persona) -> Model (acknowledges) -> User (actual query)
      // Or just add the persona instruction to the very first user turn.
      // For simplicity and to fix the immediate error, we'll just remove the invalid parameter.
      // If you need the persona, you should add a system message or initial user message
      // in your 'history' list BEFORE calling this function for the first turn.
      /*
      // Example of adding persona as an initial user message (if history is empty initially)
      if (history.isEmpty) {
         contents.add({
           'role': 'user',
           'parts': [{'text': '''You are an experienced and friendly English teacher. Your role is to:
            1. Help students improve their English through natural conversation
            2. Correct grammar mistakes politely and explain the corrections
            3. Teach new vocabulary in context
            4. Provide cultural context when relevant
            5. Encourage and motivate students to practice English
            Please maintain a supportive and patient demeanor at all times.'''}]
         });
         // Add a placeholder model response if the pattern requires user->model->user
         // contents.add({'role': 'model', 'parts': [{'text': 'Okay, I understand. I am ready to help you with your English!'}]});
      }
      */


      // Add historical messages
      for (var msg in history) {
         String role = msg['role'] == 'user' ? 'user' : 'model';
         contents.add({
           'role': role,
           'parts': [{'text': msg['content'] ?? ''}]
         });
      }

      // Add the current user's message
      contents.add({
        'role': 'user',
        'parts': [{'text': message}]
      });

      // Construct the request body - REMOVING the system instruction block
      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        // The 'systemInstruction' block is removed as it's not supported here
        // 'systemInstruction': {
        //   'parts': [{
        //     'text': '''You are an experienced and friendly English teacher...'''
        //   }]
        // }
      });

      // Create an HTTP POST request object
      final request = http.Request('POST', Uri.parse('$_baseUrl?key=$_apiKey'))
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      // Send the request and get the streamed response
      final streamedResponse = await _client.send(request);

      // Check the initial status code from the response headers
      if (streamedResponse.statusCode == 200) {
        // Reset buffer and first chunk flag for new stream
        _streamBuffer = '';
        // _isFirstChunk = true; // Not using this flag currently

        // Create a transformer to handle JSON streaming
        // The API streams JSON objects delimited by newlines, but they might be incomplete.
        // The buffer logic is attempting to reassemble complete JSON objects.
        final jsonStreamTransformer = StreamTransformer<String, String>.fromHandlers(
          handleData: (chunk, sink) {
            // Add the chunk to our buffer
            _streamBuffer += chunk;

            // API response chunks often look like:
            // [
            //   {"candidates": ...}
            // ]
            // followed by
            // ,
            // [
            //   {"candidates": ...}
            // ]
            // etc., ending with a final ']'

            // We need to handle the array brackets and commas that wrap the JSON objects.
            // A simple approach is to clean the buffer and then try to split and parse.

            // Remove potential leading '[' from the very first chunk or leading ','
            if (_streamBuffer.startsWith('[') || _streamBuffer.startsWith(',')) {
                 _streamBuffer = _streamBuffer.substring(1).trimLeft();
            }

            // Remove potential trailing ']'
            if (_streamBuffer.endsWith(']')) {
                 _streamBuffer = _streamBuffer.substring(0, _streamBuffer.length - 1).trimRight();
            }

            // Split by ',\n' which is often the delimiter between JSON objects in the stream
            List<String> potentialJsonStrings = _streamBuffer.split(',\n');

            // The last item might be incomplete, so keep it in the buffer
            _streamBuffer = potentialJsonStrings.last;
            potentialJsonStrings.removeLast();

            // Process the complete JSON strings we've extracted
            for (String jsonStr in potentialJsonStrings) {
              String trimmedJsonStr = jsonStr.trim();
              if (trimmedJsonStr.isNotEmpty) {
                 // Each item should be a JSON object like {"candidates": ...}
                 // We need to re-add the square brackets to make it a valid JSON array for parsing
                 String fullJsonArrayCandidate = '[' + trimmedJsonStr + ']';

                 try {
                   final data = jsonDecode(fullJsonArrayCandidate);

                   // The API streams an array of candidate objects
                   if (data is List && data.isNotEmpty) {
                       // Process the first (and usually only) object in the array chunk
                       var candidateObject = data[0];
                        if (candidateObject.containsKey('candidates')) {
                          for (var candidate in candidateObject['candidates']) {
                            if (candidate.containsKey('content') &&
                                candidate['content'].containsKey('parts')) {
                              for (var part in candidate['content']['parts']) {
                                if (part.containsKey('text')) {
                                  sink.add(part['text']);
                                }
                              }
                            }
                          }
                        }
                    }
                 } catch (e) {
                    // This might happen if a split was not clean or a chunk was malformed.
                    // For streaming, errors here might mean a corrupted stream.
                    print("Error parsing potential JSON chunk: $e\nChunk: $trimmedJsonStr");
                    // Decide if you want to stop or try to continue. Logging is a minimum.
                 }
              }
            }
          },
          handleError: (error, stackTrace, sink) {
            print("Stream Transformer Error: $error");
            sink.addError("Stream processing error: $error", stackTrace);
          },
          handleDone: (sink) {
             // After the stream is done, try to process any remaining buffer content.
             // It should theoretically end with ']' and have parsed everything by now,
             // but handle any leftover just in case.
             String remainingBuffer = _streamBuffer.trim();
             if (remainingBuffer.isNotEmpty) {
                 // Again, wrap in brackets to attempt parsing as an array
                 String fullJsonArrayCandidate = '[' + remainingBuffer + ']';
                 try {
                    final data = jsonDecode(fullJsonArrayCandidate);
                    if (data is List && data.isNotEmpty) {
                       var candidateObject = data[0];
                        if (candidateObject.containsKey('candidates')) {
                          for (var candidate in candidateObject['candidates']) {
                            if (candidate.containsKey('content') &&
                                candidate['content'].containsKey('parts')) {
                              for (var part in candidate['content']['parts']) {
                                if (part.containsKey('text')) {
                                  sink.add(part['text']);
                                }
                              }
                            }
                          }
                        }
                    }
                 } catch (e) {
                    print("Error parsing remaining buffer on done: $e\nBuffer: $remainingBuffer");
                 }
             }
            _streamBuffer = ''; // Clear buffer on completion
            sink.close();
          },
        );


        // Transform the stream and yield the results
        yield* streamedResponse.stream
            .transform(utf8.decoder)
            // Apply the custom JSON streaming transformer
            .transform(jsonStreamTransformer);

      } else {
        // Handle non-200 status code
        final errorBody = await streamedResponse.stream.bytesToString();
        String errorMessage = 'Failed to get response: ${streamedResponse.statusCode}';
        try {
          // The error body might itself be a JSON object with error details
          final errorJson = jsonDecode(errorBody);
          if (errorJson != null && errorJson['error'] != null && errorJson['error']['message'] != null) {
            errorMessage = 'API Error ${streamedResponse.statusCode}: ${errorJson['error']['message']}';
            if (errorJson['error']['details'] != null) {
              errorMessage += ' - Details: ${jsonEncode(errorJson['error']['details'])}';
            }
          }
        } catch (e) {
          // This catch block handles the case where errorBody is NOT valid JSON.
          // This was the original print statement you saw, because the initial errorBody
          // was the specific JSON explaining the "systemInstruction" issue.
          print("Could not parse error body as JSON after receiving ${streamedResponse.statusCode}: $errorBody");
           errorMessage = 'Failed to get response: ${streamedResponse.statusCode}. Body: $errorBody'; // Include body in message
        }
        // Yield the error message so the caller receives it through the stream
        yield "Error: $errorMessage";
        // Or throw an exception if you prefer to signal errors this way
        // throw Exception(errorMessage);
      }
    } catch (e) {
      // Catch any other errors during the request setup or sending
      yield "Request failed: $e";
    }
  }

  // Helper method to check if a string is valid JSON
  // This might not be the most reliable way for chunks,
  // the splitting logic within the transformer is better suited.
  // Keeping it for potential simple checks if needed elsewhere.
  bool _isValidJson(String jsonString) {
    if (jsonString.trim().isEmpty) return false;

    // Quick check for common JSON delimiters at start/end
    final trimmed = jsonString.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[') && !trimmed.startsWith('"')) {
        return false; // Doesn't look like the start of JSON
    }
     if (!trimmed.endsWith('}') && !trimmed.endsWith(']') && !trimmed.endsWith('"')) {
        return false; // Doesn't look like the end of JSON
    }

    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Format the response for display
  String formatResponse(String response) {
    return response.trim();
  }
}