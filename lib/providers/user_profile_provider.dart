import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import this to get the User object
import '../services/auth_service.dart';

class UserProfileProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  UserProfile? _userProfile;
  bool _isLoading = false;
  late final StreamSubscription<User?> _authStateSubscription;

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
        // Pass the full user object to the fetch method
        fetchUserProfile(user);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  // MODIFIED: This method now accepts the full User object to check metadata
  Future<void> fetchUserProfile(User user) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading) {
        _isLoading = true;
        notifyListeners();
      }
    });

    try {
      UserProfile? profile = await _firestoreService.getUserProfile(user.uid);
      
      // FIX: Retry logic to solve the race condition for new users
      // We check if the user's creation time is the same as their last sign-in time.
      if (profile == null && (user.metadata.creationTime == user.metadata.lastSignInTime)) {
        // If the profile is null and it's the user's very first sign-in,
        // wait a moment for the database write to complete and try one more time.
        await Future.delayed(const Duration(seconds: 2));
        profile = await _firestoreService.getUserProfile(user.uid);
      }
      
      _userProfile = profile;

    } catch (e) {
      print('Error fetching user profile: $e');
      _userProfile = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    _userProfile = profile;
    notifyListeners();
    try {
      await _firestoreService.saveUserProfile(userId, profile);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}