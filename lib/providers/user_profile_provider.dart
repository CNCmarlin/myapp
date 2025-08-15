import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserProfileStatus { uninitialized, loading, loaded, error }

 


class UserProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  late final StreamSubscription<User?> _authStateSubscription;

  UserProfile? _userProfile;
  List<WorkoutProgram> _availablePrograms = [];
  UserProfileStatus _status = UserProfileStatus.uninitialized;
  String? _errorMessage;

  bool _isSaving = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<WorkoutProgram> get availablePrograms => _availablePrograms;
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
        _availablePrograms = [];
        _status = UserProfileStatus.uninitialized;
        notifyListeners();
      }
    });
  } // END OF THE CONSTRUCTOR

  // PLACE THE METHOD HERE, AFTER THE CONSTRUCTOR
  void setInitialProfile(UserProfile profile) {
    if (_status != UserProfileStatus.loading) {
      _userProfile = profile;
      notifyListeners();
    }
  }

  Future<void> _loadInitialData(String userId) async {
    if (_status == UserProfileStatus.loading) return;
    _status = UserProfileStatus.loading;
    notifyListeners();
    try {
      final profileFuture = _firestoreService.getUserProfile(userId);
      // CORRECTED: Using the verified method name from your file.
      final programsFuture = _firestoreService.getAllWorkoutPrograms(userId);

      final results = await Future.wait([profileFuture, programsFuture]);
      
      _userProfile = results[0] as UserProfile?;
      _availablePrograms = results[1] as List<WorkoutProgram>;
      
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

   Future<void> updateActiveProgram(String newProgramId) async {
    final userId = _authService.currentUser?.uid;
    if (_userProfile == null || userId == null) return;
    
    _userProfile = _userProfile!.copyWith(activeProgramId: newProgramId);
    notifyListeners(); // Optimistic update for the UI
    await _firestoreService.saveUserProfile(userId, _userProfile!);
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
      primaryGoal: primaryGoal,
      activityLevel: activityLevel,
      activeProgramId: activeProgramId,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
    );
    notifyListeners();
  }

  void updateBodyStats({
    String? unitSystem,
    String? biologicalSex,
    Map<String, dynamic>? weight,
    Map<String, dynamic>? height,
    double? bodyFatPercentage,
    Map<String, dynamic>? measurements,
    String? fitnessProficiency, // NEW PARAMETER
  }) {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(
      unitSystem: unitSystem,
      biologicalSex: biologicalSex,
      weight: weight,
      height: height,
      bodyFatPercentage: bodyFatPercentage,
      measurements: measurements,
      fitnessProficiency: fitnessProficiency, // NEW
    );
    notifyListeners();
  }

  Future<bool> saveProfileChanges() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _userProfile == null) return false;

    _isSaving = true;
    notifyListeners(); // Notify listeners to show loading indicator on the button

    try {
      await _firestoreService.saveUserProfile(userId, _userProfile!);
      return true;
    } catch (e) {
      _errorMessage = "Failed to save profile: $e";
      return false;
    } finally {
      _isSaving = false;
      notifyListeners(); // Notify listeners to hide loading indicator
    }
  }

  Future<void> renameWorkoutProgram(String programId, String newName) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.updateProgramName(userId, programId, newName);
      // Update local state for immediate UI feedback
      final index = _availablePrograms.indexWhere((p) => p.id == programId);
      if (index != -1) {
        _availablePrograms[index].name = newName;
        notifyListeners();
      }
    } catch (e) {
      // Optionally handle and expose the error
      _errorMessage = 'Error renaming program: $e';
      notifyListeners();
    }
  }

  Future<void> deleteWorkoutProgram(String programId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.deleteWorkoutProgram(userId, programId);
      // Update local state
      _availablePrograms.removeWhere((p) => p.id == programId);
      
      // If the deleted program was the active one, clear it
      if (_userProfile?.activeProgramId == programId) {
        _userProfile = _userProfile?.copyWith(activeProgramId: null);
        // We need to save this change on the user's profile document
        await saveProfileChanges(); 
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting program: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}