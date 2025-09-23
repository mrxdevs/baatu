import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // The state for loading and errors is handled directly within the UI or via state management.
  // We'll remove the local state variables and getter for these, as they are often
  // managed more effectively by the widgets themselves (e.g., using `FutureBuilder` or a
  // dedicated state management solution).

  /// Get the current Firebase user.
  User? get firebaseUser => _firebaseAuth.currentUser;

  /// Check if the user is signed in.
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// A getter for the GoogleSignIn provider.
  final GoogleAuthProvider _googleProvider = GoogleAuthProvider();

  GoogleSignInProvider() {
    // We don't need a separate listener for auth state changes if we're using
    // a Consumer/Provider architecture, as the UI will rebuild when `notifyListeners()` is called.
    // The previous listener was a good pattern, but a modern approach often
    // simplifies the provider to focus on actions, letting the UI react to state changes.
  }

  // Google Sign In
  Future<UserCredential?> googleSignIn() async {
    try {
      // The `signInWithProvider` method handles the entire flow:
      // 1. Presents the Google Sign-In UI to the user.
      // 2. Exchanges the authentication token with Google.
      // 3. Authenticates the user with Firebase.
      // This single line replaces all the complex logic of getting tokens and creating credentials.
      final userCredential =
          await _firebaseAuth.signInWithProvider(_googleProvider);
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors directly from the Firebase SDK.
      debugPrint('Firebase Auth Exception: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('General Sign-In Error: $e');
      return null;
    }
  }

  // Sign out from Firebase
  Future<void> signOut() async {
    try {
      // Sign out from Firebase. The user's Google session will persist,
      // but they will no longer be authenticated with Firebase.
      await _firebaseAuth.signOut();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign Out Error: ${e.code}');
    } catch (e) {
      debugPrint('General Sign Out Error: $e');
    }
  }
}
