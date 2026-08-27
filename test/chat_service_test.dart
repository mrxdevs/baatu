import 'package:flutter_test/flutter_test.dart';
import 'package:baatu/services/gemini_service.dart';

void main() {
  group('GeminiService Chat & Teacher Tests', () {
    late GeminiService service;

    setUp(() {
      const apiKey = "AIzaSyCW35n6G5c4J82DbuKGFafMZK0R1m3_8z0";
      service = GeminiService(apiKey: apiKey);
    });

    test('getChatResponse returns concise human-style micro-sentences under 100 words', () async {
      final history = [
        {'role': 'user', 'content': 'I goed to the park yesterday and seed birds.'},
      ];

      final response = await service.getChatResponse(
        'I goed to the park yesterday and seed birds.',
        history,
        userLevel: 'Beginner',
      );

      expect(response, isNotEmpty);
      final wordCount = response.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      print('Teacher response:\n"$response"');
      print('Total word count: $wordCount words');

      // Must be concise interactive teacher response under 100 words
      expect(wordCount, lessThanOrEqualTo(100));
    });

    test('getSuggestedReplies returns relevant student options', () async {
      final suggestions = await service.getSuggestedReplies(
        "That's lovely! What kinds of birds did you see?",
        userLevel: 'Intermediate',
      );

      print('Suggested replies: $suggestions');
      expect(suggestions, isNotEmpty);
      expect(suggestions.length, greaterThanOrEqualTo(1));
    });
  });
}
