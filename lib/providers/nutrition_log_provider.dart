// lib/providers/nutrition_log_provider.dart

import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart'; // NEW IMPORT
import '../services/firestore_service.dart';
import '../services/meal_insight_service.dart';
import '../utils/nutrition_utils.dart';

class NutritionLogProvider extends ChangeNotifier {
  final String userId;
  DateTime _date;
  UserProfile? userProfile;

  final FirestoreService _firestoreService = FirestoreService();
  late final AIService _aiService; // UPDATED
  final MealInsightService _insightService = MealInsightService();

  NutritionLog? _log;
  NutritionLog? get log => _log;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  NutritionLogProvider({
    required this.userId,
    required DateTime date,
    required AuthService authService, // NEW DEPENDENCY
    this.userProfile,
  }) : _date = date {
    _aiService = AIService(authService: authService); // INITIALIZE AIService
    _loadLogForDate();
  }

  void updateDependencies(DateTime newDate, UserProfile? newProfile) {
    bool needsReload = false;
    if (_date.year != newDate.year ||
        _date.month != newDate.month ||
        _date.day != newDate.day) {
      _date = newDate;
      needsReload = true;
    }
    userProfile = newProfile;
    if (needsReload) {
      _loadLogForDate();
    }
  }

  // ... rest of the file remains the same ...
  Future<void> _loadLogForDate() async {
    _isLoading = true;
    notifyListeners();
    _log = await _firestoreService.getNutritionLog(userId, _date);
    _log ??= NutritionLog.empty(date: _date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveLog() async {
    if (_log != null) {
      await _firestoreService.saveNutritionLog(userId, _log!);
    }
  }

  void addFoodToMeal(String mealType, FoodItem foodItem) {
    if (_log == null) return;
    if (!_log!.meals.containsKey(mealType)) {
      _log!.meals[mealType] = [];
    }
    _log!.meals[mealType]!.add(foodItem);
    _log!.recalculateTotals();
    notifyListeners();
    _saveLog();
  }

  void removeFoodFromMeal(String mealType, FoodItem foodItem) {
    if (_log == null || !_log!.meals.containsKey(mealType)) return;
    _log!.meals[mealType]!.remove(foodItem);
    _log!.recalculateTotals();
    notifyListeners();
    _saveLog();
  }

  Future<bool> addMealFromText(String text) async {
    if (text.trim().isEmpty) return false;
    _isAnalyzing = true;
    notifyListeners();

    final meal = await _aiService.getMealFromText(text);

    if (meal != null) {
      final mealType = getMealTypeFromName(meal.mealName);
      for (var food in meal.foods) {
        addFoodToMeal(mealType, food);
      }
      _log?.aiGeneratedMeals.add(meal);
      _log?.recalculateTotals();
      notifyListeners();
      _saveLog();
      _generateAndSaveInsight(meal);
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } else {
      _isAnalyzing = false;
      notifyListeners();
      return false;
    }
  }

  String? getInsightForMeal(String mealType) {
    final relevantAiMeal = _log?.aiGeneratedMeals.lastWhere(
      (meal) => getMealTypeFromName(meal.mealName) == mealType,
      orElse: () => Meal(
          mealName: '',
          foods: [],
          protein: 0,
          carbs: 0,
          fat: 0,
          calories: 0),
    );
    return relevantAiMeal?.aiInsight;
  }

  Future<void> _generateAndSaveInsight(Meal meal) async {
    if (userProfile != null) {
      final insightText = await _insightService.generateInsight(
        userProfile: userProfile!,
        meal: meal,
      );
      if (insightText != null) {
        final mealIndex = _log?.aiGeneratedMeals.indexWhere((m) => m == meal);
        if (mealIndex != null && mealIndex != -1) {
          _log?.aiGeneratedMeals[mealIndex].aiInsight = insightText;
          notifyListeners();
          _saveLog();
        }
      }
    }
  }
}