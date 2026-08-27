import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_message_model.dart';

class ChatHistoryService {
  static const String _sessionsKey = 'baatu_chat_sessions_v1';
  static const String _activeSessionIdKey = 'baatu_active_session_id';
  static const String _userLevelKey = 'baatu_chat_user_level';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Loads all local sessions from SharedPreferences
  Future<List<ChatSessionModel>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_sessionsKey);
      if (rawData == null || rawData.isEmpty) {
        return [];
      }
      final List<dynamic> list = jsonDecode(rawData);
      return list
          .map((item) => ChatSessionModel.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('Error loading chat sessions from storage: $e');
      return [];
    }
  }

  /// Gets the currently active session or creates a new one
  Future<ChatSessionModel> getOrCreateActiveSession({String? userLevel}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeSessionIdKey);
    final currentLevel = userLevel ?? await getUserLevel();

    final sessions = await getSessions();
    if (activeId != null) {
      final match = sessions.where((s) => s.id == activeId).toList();
      if (match.isNotEmpty) {
        return match.first;
      }
    }

    if (sessions.isNotEmpty) {
      final latest = sessions.first;
      await setActiveSessionId(latest.id);
      return latest;
    }

    // Create brand new first session
    return await createNewSession(userLevel: currentLevel);
  }

  /// Creates a new session and sets it as active
  Future<ChatSessionModel> createNewSession({String userLevel = 'Intermediate'}) async {
    final newId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final newSession = ChatSessionModel(
      id: newId,
      title: 'New English Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userLevel: userLevel,
      messages: [],
    );

    await saveSession(newSession);
    await setActiveSessionId(newId);
    return newSession;
  }

  /// Sets the active session ID
  Future<void> setActiveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionIdKey, sessionId);
  }

  /// Saves or updates a session
  Future<void> saveSession(ChatSessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();

      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.insert(0, session);
      }

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, encoded);

      // Also backup to Cloud Firestore if logged in
      if (_userId != null) {
        _firestore
            .collection('users')
            .doc(_userId)
            .collection('chat_sessions')
            .doc(session.id)
            .set(session.toJson(), SetOptions(merge: true))
            .catchError((e) => debugPrint('Firestore chat sync error: $e'));
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Deletes a session
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();
      sessions.removeWhere((s) => s.id == sessionId);

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, encoded);

      if (_userId != null) {
        _firestore
            .collection('users')
            .doc(_userId)
            .collection('chat_sessions')
            .doc(sessionId)
            .delete()
            .catchError((e) => debugPrint('Firestore delete error: $e'));
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Saves the user's preferred learning level (Beginner, Intermediate, Advanced)
  Future<void> saveUserLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userLevelKey, level);
  }

  /// Gets the user's preferred learning level
  Future<String> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLevelKey) ?? 'Intermediate';
  }
}
