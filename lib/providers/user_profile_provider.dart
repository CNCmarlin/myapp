// lib/providers/user_profile_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

enum UserProfileStatus { uninitialized, loading, loaded, error }

class UserProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  final AIService _aiService;
  late final StreamSubscription<User?> _authStateSubscription;

  UserProfile? _userProfile;
  UserProfile? _savedProfile;
  UserProfileStatus _status = UserProfileStatus.uninitialized;
  bool hasUnsavedChanges = false;

  bool _isSaving = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  UserProfileStatus get status => _status;
  bool get isLoading => _status == UserProfileStatus.loading;
  bool get isSaving => _isSaving;

  UserProfileProvider({
    required AuthService authService,
    required LocalStorageService localStorageService,
    required SyncService syncService,
    required AIService aiService,
  })  : _authService = authService,
        _localStorageService = localStorageService,
        _syncService = syncService,
        _aiService = aiService {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadInitialData();
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

  Future<void> _loadInitialData() async {
    if (_status == UserProfileStatus.loading) return;
    _status = UserProfileStatus.loading;
    notifyListeners();
    try {
      _userProfile = await _localStorageService.getUserProfile();
      _savedProfile = _userProfile?.copyWith();
      hasUnsavedChanges = false;
      _status = UserProfileStatus.loaded;
    } catch (e) {
      debugPrint('Local Profile Load Error: $e');
      _status = UserProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _loadInitialData();
    }
  }

  Future<void> updateActiveProgram(String? newProgramId) async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(activeProgramId: newProgramId);
    notifyListeners();

    await _localStorageService.saveUserProfile(_userProfile!);
  }

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
      weight: WeightData.fromAny(weight),
      height: HeightData.fromAny(height),
      bodyFatPercentage: bodyFatPercentage,
      measurements: MeasurementData.fromAny(measurements),
      fitnessProficiency: fitnessProficiency,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void toggleEquipment(String id) {
    if (_userProfile == null) return;
    final currentList = List<String>.from(_userProfile!.equipmentIds);
    if (currentList.contains(id)) {
      currentList.remove(id);
    } else {
      currentList.add(id);
    }
    _userProfile = _userProfile!.copyWith(equipmentIds: currentList);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void setEquipmentList(List<String> ids) {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(equipmentIds: ids);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> applyEssentialsForEnvironment(String env) async {
    if (_userProfile == null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/equipment_library.json');
      final List<dynamic> library = json.decode(response);

      final List<String> essentials = library.where((item) {
        final bool checkFlag = (env == 'gym')
            ? (item['is_essential'] == true)
            : (item['is_essential_home'] == true);
        return checkFlag;
      }).map((item) => item['id'] as String).toList();

      _userProfile = _userProfile!.copyWith(equipmentIds: essentials);
      hasUnsavedChanges = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading equipment library: $e");
    }
  }

  Future<bool> saveProfileChanges() async {
    if (_userProfile == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await _localStorageService.saveUserProfile(_userProfile!);
      _savedProfile = _userProfile?.copyWith();
      hasUnsavedChanges = false;
      return true;
    } catch (e) {
      debugPrint("Failed to save profile: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void triggerBackgroundSync() {
    _syncService.performBackup();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
