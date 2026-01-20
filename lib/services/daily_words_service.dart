import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/daily_word_models.dart';

/// Service for interacting with the Daily Words API endpoints
class DailyWordsService {
  final String _baseUrl;

  DailyWordsService() : _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  /// Get today's vocabulary words (10 words)
  Future<DailyWordsResponse> getDailyWords() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/words/daily'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DailyWordsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load daily words: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching daily words: $e');
      // Return mock data for development/testing
      return _getMockDailyWords();
    }
  }

  /// Get today's featured word only
  Future<DailyWord> getWordOfDay() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/words/today'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DailyWord.fromJson(jsonData['data'] ?? jsonData);
      } else {
        throw Exception('Failed to load word of the day: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching word of the day: $e');
      return _getMockWordOfDay();
    }
  }

  /// Save a word to user's collection (requires authentication)
  Future<bool> saveWord(int wordId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/words/$wordId/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving word: $e');
      return false;
    }
  }

  /// Get user's saved words (requires authentication)
  Future<List<DailyWord>> getSavedWords(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/words/saved'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final wordsData = jsonData['data']['words'] as List<dynamic>? ?? [];
        return wordsData.map((w) => DailyWord.fromJson(w)).toList();
      } else {
        throw Exception('Failed to load saved words: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching saved words: $e');
      return [];
    }
  }

  /// Mock data for development when API is not available
  DailyWordsResponse _getMockDailyWords() {
    final mockWords = [
      DailyWord(
        id: 1,
        word: 'Eloquent',
        meaning: 'Fluent or persuasive in speaking or writing',
        partOfSpeech: 'adjective',
        difficultyLevel: 'intermediate',
        exampleSentence: 'The CEO gave an eloquent speech at the conference.',
        synonyms: ['articulate', 'fluent', 'expressive', 'persuasive'],
        antonyms: ['inarticulate', 'hesitant', 'tongue-tied'],
      ),
      DailyWord(
        id: 2,
        word: 'Ephemeral',
        meaning: 'Lasting for a very short time',
        partOfSpeech: 'adjective',
        difficultyLevel: 'advanced',
        exampleSentence: 'The beauty of cherry blossoms is ephemeral.',
        synonyms: ['fleeting', 'transient', 'momentary', 'brief'],
        antonyms: ['permanent', 'lasting', 'enduring'],
      ),
      DailyWord(
        id: 3,
        word: 'Resilient',
        meaning: 'Able to recover quickly from difficulties',
        partOfSpeech: 'adjective',
        difficultyLevel: 'intermediate',
        exampleSentence: 'Children are often more resilient than adults give them credit for.',
        synonyms: ['tough', 'strong', 'hardy', 'adaptable'],
        antonyms: ['fragile', 'weak', 'vulnerable'],
      ),
      DailyWord(
        id: 4,
        word: 'Ambiguous',
        meaning: 'Open to more than one interpretation',
        partOfSpeech: 'adjective',
        difficultyLevel: 'intermediate',
        exampleSentence: 'The ending of the movie was deliberately ambiguous.',
        synonyms: ['unclear', 'vague', 'obscure', 'cryptic'],
        antonyms: ['clear', 'unambiguous', 'explicit'],
      ),
      DailyWord(
        id: 5,
        word: 'Pragmatic',
        meaning: 'Dealing with things sensibly and realistically',
        partOfSpeech: 'adjective',
        difficultyLevel: 'advanced',
        exampleSentence: 'We need a pragmatic approach to solve this problem.',
        synonyms: ['practical', 'realistic', 'sensible', 'rational'],
        antonyms: ['idealistic', 'impractical', 'unrealistic'],
      ),
      DailyWord(
        id: 6,
        word: 'Meticulous',
        meaning: 'Showing great attention to detail; very careful',
        partOfSpeech: 'adjective',
        difficultyLevel: 'intermediate',
        exampleSentence: 'She is meticulous about her research methodology.',
        synonyms: ['careful', 'precise', 'thorough', 'painstaking'],
        antonyms: ['careless', 'sloppy', 'negligent'],
      ),
      DailyWord(
        id: 7,
        word: 'Ubiquitous',
        meaning: 'Present, appearing, or found everywhere',
        partOfSpeech: 'adjective',
        difficultyLevel: 'advanced',
        exampleSentence: 'Smartphones have become ubiquitous in modern society.',
        synonyms: ['omnipresent', 'pervasive', 'universal', 'widespread'],
        antonyms: ['rare', 'scarce', 'uncommon'],
      ),
      DailyWord(
        id: 8,
        word: 'Serendipity',
        meaning: 'The occurrence of events by chance in a happy way',
        partOfSpeech: 'noun',
        difficultyLevel: 'advanced',
        exampleSentence: 'Finding that book was pure serendipity.',
        synonyms: ['luck', 'fortune', 'chance', 'coincidence'],
        antonyms: ['misfortune', 'bad luck'],
      ),
      DailyWord(
        id: 9,
        word: 'Candid',
        meaning: 'Truthful and straightforward; frank',
        partOfSpeech: 'adjective',
        difficultyLevel: 'beginner',
        exampleSentence: 'I appreciate your candid feedback on my work.',
        synonyms: ['honest', 'frank', 'direct', 'sincere'],
        antonyms: ['dishonest', 'insincere', 'evasive'],
      ),
      DailyWord(
        id: 10,
        word: 'Plethora',
        meaning: 'A large or excessive amount of something',
        partOfSpeech: 'noun',
        difficultyLevel: 'intermediate',
        exampleSentence: 'There is a plethora of options to choose from.',
        synonyms: ['abundance', 'excess', 'surplus', 'profusion'],
        antonyms: ['scarcity', 'lack', 'shortage'],
      ),
    ];

    return DailyWordsResponse(
      date: DateTime.now().toIso8601String().split('T')[0],
      wordOfDay: mockWords[0],
      words: mockWords,
      totalWords: mockWords.length,
    );
  }

  DailyWord _getMockWordOfDay() {
    return DailyWord(
      id: 1,
      word: 'Eloquent',
      meaning: 'Fluent or persuasive in speaking or writing',
      partOfSpeech: 'adjective',
      difficultyLevel: 'intermediate',
      exampleSentence: 'The CEO gave an eloquent speech at the conference.',
      synonyms: ['articulate', 'fluent', 'expressive', 'persuasive'],
      antonyms: ['inarticulate', 'hesitant', 'tongue-tied'],
    );
  }
}
