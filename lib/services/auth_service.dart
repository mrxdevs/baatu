import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    print('Initializing AuthService');
    _auth.authStateChanges().listen((User? user) {
      print('Auth state changed. User: ${user?.email ?? 'null'}');
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    print('Attempting sign in for email: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).whenComplete((){
        _isLoading = false;
      notifyListeners();

      });
      print('Sign in successful for email: $email');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign in failed for email: $email. Error: ${e.code}');
      _isLoading = false;
      _errorMessage = _getMessageFromErrorCode(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmailAndPassword(
      String email, String password, Map<String, dynamic> preferences) async {
    print('Attempting registration for email: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First create the user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('User created successfully in Firebase Auth');
      
      // If we get here, the user was created successfully
      // Create user document in Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'preferences': preferences,
        });
        print('User document created in Firestore');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Registration failed for email: $email. Firebase Auth Error: ${e.code}');
      _isLoading = false;
      _errorMessage = _getMessageFromErrorCode(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      // Handle other exceptions
      print('Registration failed for email: $email. Unexpected error: $e');
      _isLoading = false;
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    print('Attempting password reset for email: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent successfully to: $email');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password reset failed for email: $email. Error: ${e.code}');
      _isLoading = false;
      _errorMessage = _getMessageFromErrorCode(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    print('Signing out current user');
    await _auth.signOut();
    print('Sign out completed');
  }

  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_user == null) {
      print('Cannot update preferences: No user logged in');
      return false;
    }
    
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'preferences': preferences,
      });
      print('Preferences updated successfully for user: ${_user!.email}');
      return true;
    } catch (e) {
      print('Failed to update preferences for user: ${_user!.email}. Error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  String _getMessageFromErrorCode(String errorCode) {
    print('Getting error message for code: $errorCode');
    switch (errorCode) {
      case 'invalid-email':
        return 'Your email address appears to be malformed.';
      case 'wrong-password':
        return 'Your password is incorrect.';
      case 'user-not-found':
        return 'User with this email doesn\'t exist.';
      case 'user-disabled':
        return 'User with this email has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      
      default:
        return 'An undefined error occurred.';
    }
  }
}