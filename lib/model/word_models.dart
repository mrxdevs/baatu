class WordCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int wordCount;

  WordCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.wordCount,
  });
}

class Word {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String audioUrl;
  final String example;
  final String categoryId;
  final List<String> synonyms;
  final List<String> antonyms;

  Word({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.audioUrl,
    required this.example,
    required this.categoryId,
    this.synonyms = const [],
    this.antonyms = const [],
  });
}
