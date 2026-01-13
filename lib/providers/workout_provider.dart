// lib/providers/workout_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_data.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../providers/user_profile_provider.dart'; // Import for inter-provider communication

enum DataStatus { uninitialized, loading, loaded, error }

class WorkoutProvider with ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _localStorageService;
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
    required LocalStorageService localStorageService, // Change: Constructor parameter updated to LocalStorageService
    required UserProfileProvider userProfileProvider,
  })  : _authService = authService,
        _localStorageService = localStorageService,
        _userProfileProvider = userProfileProvider {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadWorkoutPrograms(); // Change: Removed userId requirement for local disk access
      } else {
        _programs = [];
        _status = DataStatus.uninitialized;
        notifyListeners();
      }
    });
  }

  Future<void> _loadWorkoutPrograms() async { // Change: Signature updated to match local-first logic
    if (_status == DataStatus.loading) return;
    _status = DataStatus.loading;
    notifyListeners();

    try {
      _programs = await _localStorageService.getAllWorkoutPrograms(); // Change: Switched to local disk read (userId removed as disk is user-scoped)
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
      await _loadWorkoutPrograms();
    }
  }

  Future<void> renameWorkoutProgram(String programId, String newName) async {
    // 🛡️ SHIELD: Removed Auth check. Local storage operations should not be blocked by network auth state.
    try {
      await _localStorageService.updateProgramName(programId, newName);
      final index = _programs.indexWhere((p) => p.id == programId);
      if (index != -1) {
        // Fix: Use copyWith to ensure immutability and trigger clean state updates
        _programs[index] = _programs[index].copyWith(name: newName);
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

      await _localStorageService.deleteWorkoutProgram(programId); // Change: Switched to local service for deletion
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
    // 🛡️ SHIELD: Local persistence is now the primary source of truth; auth check removed.
    try {
      await _localStorageService.saveWorkoutProgram(program);
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
