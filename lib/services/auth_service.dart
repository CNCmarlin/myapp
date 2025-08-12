// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/models/user_profile.dart'; // Make sure this path is correct
import 'package:myapp/services/firestore_service.dart'; // Make sure this path is correct

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Stream to notify the app of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

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
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create a new credential for Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the credential
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
        print('user credentials signed in successfully');

    // 5. CRITICAL: Check if the user is new. If so, create their profile document.
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      print('creating required user objects');
      // FIX: This UserProfile object now EXACTLY matches the requirements
      // of our 'isValidNewUserProfile' security rule.
      final newUserProfile = UserProfile(
        onboardingCompleted: false,
        unitSystem: 'imperial',
        targetCalories: 0.0,
        targetProtein: 0.0,
        targetCarbs: 0.0,
        targetFat: 0.0,
        // All other fields will be null or use their defaults from the model
      );
      print('created user profile required objects');
      await _firestoreService.createNewUserProfile(
          userCredential.user!, newUserProfile);
    }
    print('user profile created successfully');

    return userCredential;
  } catch (e) {
    print('Error during Google Sign-In: $e');
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