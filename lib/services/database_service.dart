import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? uid;

  DatabaseService({this.uid});

  // Collection references
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference learningCollection = FirebaseFirestore.instance.collection('learning_content');

  // Get user data
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    return await userCollection.doc(uid).update({
      'preferences': preferences,
    });
  }

  // Get learning content
  Future<List<Map<String, dynamic>>> getLearningContent(String contentType) async {
    QuerySnapshot snapshot = await learningCollection
        .where('type', isEqualTo: contentType)
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Save user progress
  Future<void> saveUserProgress(String contentId, double progress) async {
    if (uid == null) return;
    
    return await userCollection.doc(uid).collection('progress').doc(contentId).set({
      'progress': progress,
      'lastAccessed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user progress
  Future<Map<String, dynamic>> getUserProgress() async {
    if (uid == null) return {};
    
    QuerySnapshot snapshot = await userCollection
        .doc(uid)
        .collection('progress')
        .get();
    
    Map<String, dynamic> progress = {};
    for (var doc in snapshot.docs) {
      progress[doc.id] = doc.data();
    }
    
    return progress;
  }
}