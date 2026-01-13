// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveAppdataScope,
    ],
  );

  // Stream to notify the app of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // 🛡️ SHIELD: Stage 3 Sync Accessor
  // Change: Added getter to allow GoogleDriveService to access the authenticated session
  GoogleSignIn get googleSignIn => _googleSignIn;

  // In lib/services/auth_service.dart, inside the AuthService class

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (kDebugMode) {
        print('user credentials signed in successfully');
      }

     // 5. 🛡️ SHIELD: Local-First Session Initialization
      // Change: Removed Firestore-specific creation logic and fixed orphaned braces.
      // Logic: New user detection now triggers local onboarding via UI, not a background Firestore write.
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        if (kDebugMode) {
          debugPrint('New user detected. Simply Fit will initialize local state via Onboarding.');
        }
      }

      if (kDebugMode) {
        debugPrint('Authentication successful for UID: ${userCredential.user?.uid}');
      }

      return userCredential;

    } catch (e) {
      if (kDebugMode) {
        print('Error during Google Sign-In: $e');
      }
      // It's often helpful to rethrow the exception to see it higher up
      // in the call stack if needed for debugging.
      throw Exception('Error during Google Sign-In: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
