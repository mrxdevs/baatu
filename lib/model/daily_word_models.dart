/// Model classes for Daily Words API responses

class DailyWord {
  final int id;
  final String word;
  final String meaning;
  final String partOfSpeech;
  final String difficultyLevel;
  final String exampleSentence;
  final List<String> synonyms;
  final List<String> antonyms;

  DailyWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.partOfSpeech,
    required this.difficultyLevel,
    required this.exampleSentence,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  factory DailyWord.fromJson(Map<String, dynamic> json) {
    return DailyWord(
      id: json['id'] ?? 0,
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      partOfSpeech: json['part_of_speech'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 'beginner',
      exampleSentence: json['example_sentence'] ?? '',
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'part_of_speech': partOfSpeech,
      'difficulty_level': difficultyLevel,
      'example_sentence': exampleSentence,
      'synonyms': synonyms,
      'antonyms': antonyms,
    };
  }
}

class DailyWordsResponse {
  final String date;
  final DailyWord wordOfDay;
  final List<DailyWord> words;
  final int totalWords;

  DailyWordsResponse({
    required this.date,
    required this.wordOfDay,
    required this.words,
    required this.totalWords,
  });

  factory DailyWordsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DailyWordsResponse(
      date: data['date'] ?? '',
      wordOfDay: DailyWord.fromJson(data['word_of_day'] ?? {}),
      words: (data['words'] as List<dynamic>?)?.map((w) => DailyWord.fromJson(w)).toList() ?? [],
      totalWords: data['total_words'] ?? 0,
    );
  }
}
