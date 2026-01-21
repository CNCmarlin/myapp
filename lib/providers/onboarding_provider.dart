import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';

class OnboardingProvider with ChangeNotifier {
  UserProfile _temporaryProfile = UserProfile();

  UserProfile get finalProfile => _temporaryProfile;

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
    _temporaryProfile = _temporaryProfile.copyWith(
        weight: WeightData.fromAny({'value': value, 'unit': unit})); 
    notifyListeners();
  }

  void updateHeight(double value, String unit) {
    _temporaryProfile = _temporaryProfile.copyWith(
        height: HeightData.fromAny({'value': value, 'unit': unit}));
    notifyListeners();
  }

  void updateFitnessProficiency(String proficiency) {
    _temporaryProfile =
        _temporaryProfile.copyWith(fitnessProficiency: proficiency);
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


  void updatePrefersLowCarb(bool prefersLowCarb) {
    _temporaryProfile =
        _temporaryProfile.copyWith(prefersLowCarb: prefersLowCarb);
    notifyListeners();
  }

  void updateWeeklyWeightLossGoal(double goal) {
    _temporaryProfile = _temporaryProfile.copyWith(weeklyWeightLossGoal: goal);
    notifyListeners();
  }

  void updateBirthDate(DateTime date) {
    _temporaryProfile = _temporaryProfile.copyWith(birthDate: date);
    notifyListeners();
  }

  void updateExerciseDaysPerWeek(int days) {
    _temporaryProfile = _temporaryProfile.copyWith(exerciseDaysPerWeek: days);
    notifyListeners();
  }

  void updateGoalWeight(double value, String unit) {
    _temporaryProfile = _temporaryProfile.copyWith(
        goalWeight: WeightData.fromAny({'value': value, 'unit': unit}));
    notifyListeners();
  }


  void toggleEquipment(String id) {
    final currentList = List<String>.from(_temporaryProfile.equipmentIds);
    if (currentList.contains(id)) {
      currentList.remove(id);
    } else {
      currentList.add(id);
    }
    _temporaryProfile = _temporaryProfile.copyWith(equipmentIds: currentList);
    notifyListeners();
  }

  void applyEquipmentPackage(List<String> ids) {
    final currentSet = _temporaryProfile.equipmentIds.toSet();
    currentSet.addAll(ids);
    _temporaryProfile = _temporaryProfile.copyWith(equipmentIds: currentSet.toList());
    notifyListeners();
  }

  void setEquipmentList(List<String> ids) {
    _temporaryProfile = _temporaryProfile.copyWith(equipmentIds: ids);
    notifyListeners();
  }

  Future<String> getEquipmentName(String id) async {
    final String response = await rootBundle.loadString('assets/data/equipment_library.json');
    final List<dynamic> library = json.decode(response);
    final item = library.firstWhere((element) => element['id'] == id, orElse: () => null);
    return item != null ? item['name'] : id;
  }

  Future<void> applyEssentialsForEnvironment(String env) async {
    final String response = await rootBundle.loadString('assets/data/equipment_library.json');
    final List<dynamic> library = json.decode(response);
    
    final List<String> essentials = library.where((item) {
      final isEssential = (env == 'gym') 
          ? (item['is_essential'] == true) 
          : (item['is_essential_home'] == true);
      
      return isEssential;
    }).map((item) => item['id'] as String).toList();

    _temporaryProfile = _temporaryProfile.copyWith(equipmentIds: essentials);
    notifyListeners();
  }
}
