import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        fetchUserProfile(user);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserProfile(User user) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading) {
        _isLoading = true;
        notifyListeners();
      }
    });

    try {
      UserProfile? profile = await _firestoreService.getUserProfile(user.uid);
      
      if (profile == null && (user.metadata.creationTime == user.metadata.lastSignInTime)) {
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

  // FIX: This method is now async and updates the state AFTER the save.
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      await _firestoreService.saveUserProfile(userId, profile);
      // Only update the local state and notify listeners after a successful save.
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      // Optionally re-throw or handle the error in the UI
    }
  }

  Future<void> updateActiveProgram(String? programId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _userProfile == null) return;
    
    // Create a new profile object with the updated program ID
    final updatedProfile = _userProfile!.copyWith(activeProgramId: programId);
    
    // Use the existing updateUserProfile method to save and notify listeners
    await updateUserProfile(userId, updatedProfile);
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}