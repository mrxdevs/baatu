import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:baatu/services/daily_words_service.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'API_BASE_URL': 'https://bmrt4amvpn.ap-south-1.awsapprunner.com',
    });
  });

  group('DailyWordsService Integration Tests', () {
    late DailyWordsService service;

    setUp(() {
      service = DailyWordsService();
    });

    test('getDailyWords returns real words from AWS Aurora DB', () async {
      final response = await service.getDailyWords();
      
      expect(response, isNotNull);
      expect(response.words.isNotEmpty, true);
      expect(response.words.length, greaterThanOrEqualTo(1));
      expect(response.wordOfDay.word.isNotEmpty, true);
      print('✅ Live Daily Words count: ${response.words.length}');
      print('✅ Live Word of the Day: ${response.wordOfDay.word} - ${response.wordOfDay.meaning}');
    });

    test('getWordOfDay returns valid featured word from live AWS API', () async {
      final word = await service.getWordOfDay();
      
      expect(word, isNotNull);
      expect(word.id, greaterThan(0));
      expect(word.word.isNotEmpty, true);
      expect(word.meaning.isNotEmpty, true);
      print('✅ Live Word Details: ID=${word.id}, Word=${word.word}');
    });
  });
}
