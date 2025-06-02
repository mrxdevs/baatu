import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/word_models.dart';

class WordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<WordCategory>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('word_categories').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WordCategory(
          id: doc.id,
          name: data['name'] ?? '',
          icon: data['icon'] ?? '',
          description: data['description'] ?? '',
          wordCount: data['wordCount'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Word>> getWordsInCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('words')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Word(
          id: doc.id,
          word: data['word'] ?? '',
          meaning: data['meaning'] ?? '',
          pronunciation: data['pronunciation'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          example: data['example'] ?? '',
          categoryId: data['categoryId'] ?? '',
          synonyms: List<String>.from(data['synonyms'] ?? []),
          antonyms: List<String>.from(data['antonyms'] ?? []),
        );
      }).toList();
    } catch (e) {
      print('Error fetching words: $e');
      return [];
    }
  }
}
