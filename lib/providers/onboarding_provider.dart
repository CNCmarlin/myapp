import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart'; // Adjust import if needed

class OnboardingProvider with ChangeNotifier {
  // A private, temporary UserProfile object to store onboarding data.
  // It starts with default values from the UserProfile constructor.
  UserProfile _temporaryProfile = UserProfile();

  // Public getter to allow the UI to access the profile data.
  UserProfile get finalProfile => _temporaryProfile;

  // --- Public methods to update the temporary profile ---

  void updateUnitSystem(String system) {
    _temporaryProfile = _temporaryProfile.copyWith(unitSystem: system);
    notifyListeners();
  }

  void updatePrimaryGoal(String goal) {
    _temporaryProfile = _temporaryProfile.copyWith(primaryGoal: goal);
    notifyListeners();
  }

  void updateBiologicalSex(String sex) {
    _temporaryProfile = _temporaryProfile.copyWith(biologicalSex: sex);
    notifyListeners();
  }

  void updateActivityLevel(String level) {
    _temporaryProfile = _temporaryProfile.copyWith(activityLevel: level);
    notifyListeners();
  }

  void updateActiveProgramId(String programId) {
    _temporaryProfile = _temporaryProfile.copyWith(activeProgramId: programId);
    notifyListeners();
  }

  void updateWeight(double value, String unit) {
    _temporaryProfile =
        _temporaryProfile.copyWith(weight: {'value': value, 'unit': unit});
    notifyListeners();
  }

  void updateHeight(double value, String unit) {
    _temporaryProfile =
        _temporaryProfile.copyWith(height: {'value': value, 'unit': unit});
    notifyListeners();
  }

  void updateNutritionGoals(
      {double? calories, double? protein, double? carbs, double? fat}) {
    _temporaryProfile = _temporaryProfile.copyWith(
      targetCalories: calories ?? _temporaryProfile.targetCalories,
      targetProtein: protein ?? _temporaryProfile.targetProtein,
      targetCarbs: carbs ?? _temporaryProfile.targetCarbs,
      targetFat: fat ?? _temporaryProfile.targetFat,
    );
    notifyListeners();
  }
  
  // NEW: Methods for enhanced onboarding data
  
  void updatePrefersLowCarb(bool prefersLowCarb) {
    _temporaryProfile = _temporaryProfile.copyWith(prefersLowCarb: prefersLowCarb);
    notifyListeners();
  }

  void updateWeeklyWeightLossGoal(double goal) {
    _temporaryProfile = _temporaryProfile.copyWith(weeklyWeightLossGoal: goal);
    notifyListeners();
  }

  void updateExerciseDaysPerWeek(int days) {
    _temporaryProfile = _temporaryProfile.copyWith(exerciseDaysPerWeek: days);
    notifyListeners();
  }
}