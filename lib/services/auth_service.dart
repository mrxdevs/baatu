import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get userData => _userData;

  AuthService() {
    print('Initializing AuthService');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) async {
      print('Auth state changed. User: ${user?.email ?? 'null'}');
      _user = user;

      if (user != null) {
        // Fetch and store user data when authenticated
        await _fetchAndStoreUserData(user.uid);
      } else {
        _userData = null;
      }

      notifyListeners();
    });

    // Check for cached user data on startup
    await _loadCachedUserData();
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('user_data');
      final String? userId = prefs.getString('user_id');

      if (userDataString != null && userId != null && _user == null) {
        // If we have cached data but no authenticated user,
        // check if the token is still valid
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Token is still valid, update user
          _user = currentUser;

          // Parse cached user data
          // This is a simple approach - for complex objects consider using json_serializable
          Map<String, dynamic> cachedData = {};
          userDataString.split(',').forEach((item) {
            if (item.contains(':')) {
              List<String> keyValue = item.split(':');
              cachedData[keyValue[0].trim()] = keyValue[1].trim();
            }
          });

          _userData = cachedData;
          notifyListeners();

          // Refresh user data in background
          _fetchAndStoreUserData(userId);
        }
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }

  Future<void> _fetchAndStoreUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>?;

        // Cache user data for offline access
        _cacheUserData(uid, _userData);

        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _cacheUserData(
      String uid, Map<String, dynamic>? userData) async {
    if (userData == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Store user ID
      await prefs.setString('user_id', uid);

      // Convert userData to a simple string representation
      // For complex objects, consider using json_encode
      String userDataString =
          userData.entries.map((e) => '${e.key}:${e.value}').join(',');

      await prefs.setString('user_data', userDataString);
    } catch (e) {
      print('Error caching user data: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    print('Attempting sign in for email: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user token for API calls if needed
      String? token = await result.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print('Token stored successfully');
      }

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

  // Check if user is authenticated and token is valid
  Future<bool> validateUser() async {
    try {
      // Check if user is already authenticated
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('No current user found');
        return false;
      }

      // Verify token is still valid
      try {
        await currentUser.reload();
        String? token = await currentUser.getIdToken(true);
        print('User authenticated with valid token');
        return token != null;
      } catch (e) {
        print('Token validation failed: $e');
        return false;
      }
    } catch (e) {
      print('Error validating user: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    print('Signing out current user');

    try {
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('user_id');
      await prefs.remove('auth_token');

      // Sign out from Firebase
      await _auth.signOut();

      _userData = null;
      print('Sign out completed');
    } catch (e) {
      print('Error during sign out: $e');
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
      print(
          'Registration failed for email: $email. Firebase Auth Error: ${e.code}');
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
      print(
          'Failed to update preferences for user: ${_user!.email}. Error: $e');
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
