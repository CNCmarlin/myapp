import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final UserProfileProvider _userProfileProvider;

  List<WorkoutProgram> _availablePrograms = [];
  bool _isLoadingPrograms = false;

  List<WorkoutProgram> get availablePrograms => _availablePrograms;
  bool get isLoadingPrograms => _isLoadingPrograms;

  ProfileProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
    required UserProfileProvider userProfileProvider,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _userProfileProvider = userProfileProvider {
    // The automatic call to loadAvailablePrograms() has been removed.
    // The provider is now "lazy".
  }

  Future<void> loadAvailablePrograms() async {
    // Prevent re-fetching if we are already loading or already have the data.
    if (_isLoadingPrograms || _availablePrograms.isNotEmpty) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _isLoadingPrograms = true;
    notifyListeners();

    _availablePrograms = await _firestoreService.getAllWorkoutPrograms(userId);
    
    _isLoadingPrograms = false;
    notifyListeners();
  }

  // A dedicated method for saving goals and settings
  Future<void> saveGoals({
    required String activityLevel,
    required String primaryGoal,
    required String? activeProgramId,
    required String targetCalories,
    required String targetProtein,
    required String targetCarbs,
    required String targetFat,
  }) async {
    final userId = _authService.currentUser?.uid;
    final currentProfile = _userProfileProvider.userProfile;
    if (userId == null || currentProfile == null) throw Exception("User not found");

    final profileToSave = currentProfile.copyWith(
      activityLevel: activityLevel,
      primaryGoal: primaryGoal,
      activeProgramId: activeProgramId,
      targetCalories: double.tryParse(targetCalories) ?? 0.0,
      targetProtein: double.tryParse(targetProtein) ?? 0.0,
      targetCarbs: double.tryParse(targetCarbs) ?? 0.0,
      targetFat: double.tryParse(targetFat) ?? 0.0,
    );
    await _userProfileProvider.updateUserProfile(userId, profileToSave);
  }

  // A dedicated method for saving body stats
  Future<void> saveStats({
    required bool isMetric,
    required String biologicalSex,
    required String bodyFat,
    required String weight,
    required String heightCm,
    required String heightFt,
    required String heightIn,
    required Map<String, String> measurements,
  }) async {
    final userId = _authService.currentUser?.uid;
    final currentProfile = _userProfileProvider.userProfile;
    if (userId == null || currentProfile == null) throw Exception("User not found");

    double weightKg = 0.0;
    double heightCmValue = 0.0;
    if (isMetric) {
      weightKg = double.tryParse(weight) ?? 0.0;
      heightCmValue = double.tryParse(heightCm) ?? 0.0;
    } else {
      weightKg = (double.tryParse(weight) ?? 0.0) * 0.453592;
      final ft = double.tryParse(heightFt) ?? 0.0;
      final inches = double.tryParse(heightIn) ?? 0.0;
      heightCmValue = (ft * 12 + inches) * 2.54;
    }

    final measurementsMap = <String, dynamic>{};
    measurements.forEach((name, valueStr) {
      double value = double.tryParse(valueStr) ?? 0.0;
      if (!isMetric) value *= 2.54;
      measurementsMap[name] = value;
    });

    final profileToSave = currentProfile.copyWith(
      unitSystem: isMetric ? 'metric' : 'imperial',
      biologicalSex: biologicalSex,
      bodyFatPercentage: double.tryParse(bodyFat),
      weight: {'value': weightKg, 'unit': 'kg'},
      height: {'value': heightCmValue, 'unit': 'cm'},
      measurements: measurementsMap,
    );
    await _userProfileProvider.updateUserProfile(userId, profileToSave);
  }
}