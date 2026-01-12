// lib/providers/user_profile_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserProfileStatus { uninitialized, loading, loaded, error }

class UserProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  late final StreamSubscription<User?> _authStateSubscription;

  UserProfile? _userProfile;
  UserProfile? _savedProfile;
  UserProfileStatus _status = UserProfileStatus.uninitialized;
  String? _errorMessage;
  bool hasUnsavedChanges = false;

  bool _isSaving = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  UserProfileStatus get status => _status;
  bool get isLoading => _status == UserProfileStatus.loading;
  bool get isSaving => _isSaving;

  UserProfileProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadInitialData(user.uid);
      } else {
        _userProfile = null;
        _savedProfile = null;
        _status = UserProfileStatus.uninitialized;
        notifyListeners();
      }
    });
  }

  void setInitialProfile(UserProfile profile) {
    if (_status != UserProfileStatus.loading) {
      _userProfile = profile; 
       _savedProfile = profile.copyWith();
      notifyListeners();
    }
  }

  Future<void> _loadInitialData(String userId) async {
    if (_status == UserProfileStatus.loading) return;
    _status = UserProfileStatus.loading;
    notifyListeners();
    try {
      _userProfile = await _firestoreService.getUserProfile(userId);
      _savedProfile = _userProfile?.copyWith(); 
      hasUnsavedChanges = false;
      _status = UserProfileStatus.loaded;
    } catch (e) {
      _errorMessage = 'Error fetching user data: $e';
      _status = UserProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _loadInitialData(userId);
    }
  }

  Future<void> updateActiveProgram(String? newProgramId) async {
    final userId = _authService.currentUser?.uid;
    if (_userProfile == null || userId == null) return;

    _userProfile = _userProfile!.copyWith(activeProgramId: newProgramId);
    notifyListeners(); // Optimistic update
    await _firestoreService.saveUserProfile(userId, _userProfile!);
  }

// NEW: Method to discard changes
  void revertChanges() {
    _userProfile = _savedProfile?.copyWith();
    hasUnsavedChanges = false;
    notifyListeners();
  }

  void updateGoals({
    String? primaryGoal,
    String? activityLevel,
    String? activeProgramId,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(
      primaryGoal: primaryGoal ?? _userProfile!.primaryGoal,
      activityLevel: activityLevel ?? _userProfile!.activityLevel,
      activeProgramId: activeProgramId ?? _userProfile!.activeProgramId,
      targetCalories: targetCalories ?? _userProfile!.targetCalories,
      targetProtein: targetProtein ?? _userProfile!.targetProtein,
      targetCarbs: targetCarbs ?? _userProfile!.targetCarbs,
      targetFat: targetFat ?? _userProfile!.targetFat,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateBodyStats({
    String? unitSystem,
    String? biologicalSex,
    Map<String, dynamic>? weight,
    Map<String, dynamic>? height,
    double? bodyFatPercentage,
    Map<String, dynamic>? measurements,
    String? fitnessProficiency,
  }) {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(
      unitSystem: unitSystem,
      biologicalSex: biologicalSex,
      weight: weight,
      height: height,
      bodyFatPercentage: bodyFatPercentage,
      measurements: measurements,
      fitnessProficiency: fitnessProficiency,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> saveProfileChanges() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _userProfile == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await _firestoreService.saveUserProfile(userId, _userProfile!);
      _savedProfile = _userProfile?.copyWith(); // Update the cache on successful save
      hasUnsavedChanges = false;
      return true;
    } catch (e) {
      _errorMessage = "Failed to save profile: $e";
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
