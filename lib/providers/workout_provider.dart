// lib/providers/workout_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_data.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/user_profile_provider.dart'; // Import for inter-provider communication

enum DataStatus { uninitialized, loading, loaded, error }

class WorkoutProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final UserProfileProvider
      _userProfileProvider; // Dependency for checking active program

  late final StreamSubscription<User?> _authStateSubscription;

  List<WorkoutProgram> _programs = [];
  DataStatus _status = DataStatus.uninitialized;
  String? _errorMessage;

  // Getters
  List<WorkoutProgram> get programs => _programs;
  DataStatus get status => _status;
  bool get isLoading => _status == DataStatus.loading;
  String? get errorMessage => _errorMessage;

  WorkoutProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
    required UserProfileProvider userProfileProvider,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _userProfileProvider = userProfileProvider {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadWorkoutPrograms(user.uid);
      } else {
        _programs = [];
        _status = DataStatus.uninitialized;
        notifyListeners();
      }
    });
  }

  Future<void> _loadWorkoutPrograms(String userId) async {
    if (_status == DataStatus.loading) return;
    _status = DataStatus.loading;
    notifyListeners();

    try {
      _programs = await _firestoreService.getAllWorkoutPrograms(userId);
      _status = DataStatus.loaded;
    } catch (e) {
      _errorMessage = "Error fetching workout programs: $e";
      _status = DataStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshPrograms() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _loadWorkoutPrograms(userId);
    }
  }

  Future<void> renameWorkoutProgram(String programId, String newName) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.updateProgramName(userId, programId, newName);
      final index = _programs.indexWhere((p) => p.id == programId);
      if (index != -1) {
        _programs[index].name = newName;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error renaming program: $e';
      notifyListeners();
    }
  }

  Future<void> deleteWorkoutProgram(String programId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check if the program to be deleted is the active one.
      final bool wasActiveProgram =
          _userProfileProvider.userProfile?.activeProgramId == programId;

      await _firestoreService.deleteWorkoutProgram(userId, programId);
      _programs.removeWhere((p) => p.id == programId);

      // If it was the active program, notify UserProfileProvider to clear it.
      if (wasActiveProgram) {
        await _userProfileProvider.updateActiveProgram(null);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting program: $e';
      notifyListeners();
    }
  }

  Future<void> updateWorkoutProgram(WorkoutProgram program) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.updateWorkoutProgram(userId, program);
      final index = _programs.indexWhere((p) => p.id == program.id);
      if (index != -1) {
        _programs[index] = program;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error updating program: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
