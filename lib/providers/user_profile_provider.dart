import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class UserProfileProvider with ChangeNotifier {
  final FirestoreService _firestoreService; // <-- CHANGE THIS
  final AuthService _authService;

  UserProfile? _userProfile;
  bool _isLoading = false;
  late final StreamSubscription _authStateSubscription;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  String? get activeProgramId => _userProfile?.activeProgramId;

  UserProfileProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserProfile(String userId) async {
   WidgetsBinding.instance.addPostFrameCallback((_) {
      if (
          _isLoading == false) { // Optional: check to prevent unnecessary notifications
        _isLoading = true;
        notifyListeners();
      }
    });
    try {
      _userProfile = await _firestoreService.getUserProfile(userId);
    } catch (e) {
      print('Error fetching user profile: $e');
      _userProfile = null;
    }
    _isLoading = false;
    notifyListeners();
  }

 Future<void> updateUserProfile(String userId, UserProfile profile) async {
  // The userId parameter is now expected, no need to get from authService
  // final userId = _authService.currentUser?.uid; 
  // if (userId == null) {
  //   print('[DEBUG ERROR] UserProfileProvider: Attempted to update profile with no user logged in.');
  //   return;
  // }

  _isLoading = true;
  // Notify listeners that an update process is starting.
  notifyListeners();



    try {
      // DEBUG STEP 2: Confirm the data we received.
      print('[DEBUG 2] UserProfileProvider: Entering updateUserProfile. The incoming profile has onboardingCompleted=${profile.onboardingCompleted}');
      
      // DEBUG STEP 3: Log the state BEFORE the update.
      print('[DEBUG 3] UserProfileProvider: Current state BEFORE update is: ${_userProfile?.onboardingCompleted}');

      _userProfile = profile;

      // DEBUG STEP 4: Log the state AFTER the update.
      print('[DEBUG 4] UserProfileProvider: Local state AFTER update is: ${_userProfile?.onboardingCompleted}');
      
      // DEBUG STEP 5: Confirm we are about to notify listeners.
      print('[DEBUG 5] UserProfileProvider: Calling notifyListeners()...');
      notifyListeners();
      print('[DEBUG 6] UserProfileProvider: ...notifyListeners() finished.');

      await _firestoreService.saveUserProfile(userId, profile); // Use updateUserProfile method
    } catch (e) {
      // Handle error
      print('Error updating user profile: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
