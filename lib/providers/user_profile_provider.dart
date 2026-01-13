// lib/providers/user_profile_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart'; // Change: Imported LocalStorageService
import 'package:firebase_auth/firebase_auth.dart';

enum UserProfileStatus { uninitialized, loading, loaded, error }

class UserProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _localStorageService; // Change: Replaced FirestoreService with LocalStorageService
  late final StreamSubscription<User?> _authStateSubscription;

  UserProfile? _userProfile;
  UserProfile? _savedProfile;
  UserProfileStatus _status = UserProfileStatus.uninitialized;
  // Change: Removed unused _errorMessage field to resolve diagnostic
  bool hasUnsavedChanges = false;

  bool _isSaving = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  UserProfileStatus get status => _status;
  bool get isLoading => _status == UserProfileStatus.loading;
  bool get isSaving => _isSaving;

 UserProfileProvider({
    required AuthService authService,
    required LocalStorageService localStorageService, // Change: Update parameter to local service
  })  : _authService = authService,
        _localStorageService = localStorageService { // Change: Initialize local service
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadInitialData(); // Change: Local lookup doesn't strictly require userId
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

  Future<void> _loadInitialData() async { // Change: Removed userId parameter
    if (_status == UserProfileStatus.loading) return;
    _status = UserProfileStatus.loading;
    notifyListeners();
    try {
      // Change: Retrieve from Isar instead of Firestore
      _userProfile = await _localStorageService.getUserProfile();
      _savedProfile = _userProfile?.copyWith(); 
      hasUnsavedChanges = false;
      _status = UserProfileStatus.loaded;
    } catch (e) {
      // Change: Replaced field assignment with debugPrint
      debugPrint('Local Profile Load Error: $e');
      _status = UserProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      // Fix: Removed positional argument to match the new local-first signature
      await _loadInitialData(); 
    }
  }

 Future<void> updateActiveProgram(String? newProgramId) async {
    if (_userProfile == null) return; // Change: Removed userId requirement

    _userProfile = _userProfile!.copyWith(activeProgramId: newProgramId);
    notifyListeners(); // Optimistic update
    
    // Change: Persist to local storage
    await _localStorageService.saveUserProfile(_userProfile!);
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
      weight: WeightData.fromAny(weight), // SURGICAL: Shielded conversion
      height: HeightData.fromAny(height), // SURGICAL: Shielded conversion
      bodyFatPercentage: bodyFatPercentage,
      measurements: MeasurementData.fromAny(measurements), // SURGICAL: Shielded conversion
      fitnessProficiency: fitnessProficiency,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> saveProfileChanges() async {
    // Fix: Removed userId requirement for local-first persistence
    if (_userProfile == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      // Fix: Swapped legacy Firestore call for LocalStorage persistence
      await _localStorageService.saveUserProfile(_userProfile!);
      _savedProfile = _userProfile?.copyWith(); 
      hasUnsavedChanges = false;
      return true;
    } catch (e) {
      // Fix: Replaced undefined _errorMessage with debugPrint for error logging
      debugPrint("Failed to save profile: $e");
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
