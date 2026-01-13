// lib/providers/nutrition_log_provider.dart

import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart'; 
import '../services/local_storage_service.dart'; // Change: Imported LocalStorageService
import '../services/meal_insight_service.dart';
import '../utils/nutrition_utils.dart';

class NutritionLogProvider extends ChangeNotifier {
  final String userId;
  DateTime _date;
  UserProfile? userProfile;

  final LocalStorageService _localStorageService; // Change: Replaced FirestoreService with LocalStorageService
  late final AIService _aiService;
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
    required AuthService authService,
    required LocalStorageService localStorageService, // Change: Injected LocalStorageService dependency
    this.userProfile,
  }) : _date = date,
       _localStorageService = localStorageService { // Change: Initialized private service
    _aiService = AIService(authService: authService); 
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
    // Change: Logic swapped to fetch log from local disk by date
    _log = await _localStorageService.getNutritionLogByDate(_date);
    _log ??= NutritionLog.empty(date: _date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveLog() async {
    if (_log != null) {
      // Change: Swapped Firestore save for immediate Isar persistence
      await _localStorageService.saveNutritionLog(_log!);
    }
  }

  void addFoodToMeal(String mealType, FoodItem foodItem) {
    if (_log == null) return;
    // Change: Find or create the slot within the new List structure
    final slotIndex = _log!.meals.indexWhere((s) => s.slotName == mealType);
    if (slotIndex != -1) {
      _log!.meals[slotIndex].items ??= [];
      _log!.meals[slotIndex].items!.add(foodItem);
    } else {
      _log!.meals.add(MealSlot()
        ..slotName = mealType
        ..items = [foodItem]);
    }
    _log!.recalculateTotals();
    notifyListeners();
    _saveLog();
  }

  void removeFoodFromMeal(String mealType, FoodItem foodItem) {
    if (_log == null) return;
    // Change: Find the slot index to remove the item from its items list
    final slotIndex = _log!.meals.indexWhere((s) => s.slotName == mealType);
    if (slotIndex != -1 && _log!.meals[slotIndex].items != null) {
      _log!.meals[slotIndex].items!.remove(foodItem);
      _log!.recalculateTotals();
      notifyListeners();
      _saveLog();
    }
  }

  Future<bool> addMealFromText(String text) async {
    if (text.trim().isEmpty) return false;
    _isAnalyzing = true;
    notifyListeners();

    final meal = await _aiService.getMealFromText(text);

    if (meal != null) {
      final mealName = meal.mealName ?? 'Unknown Meal'; // Change: Fallback for nullable field
      final mealType = getMealTypeFromName(mealName);
      for (var food in meal.foods ?? []) { // Change: Null-safe iterator for foods list
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
      (meal) => getMealTypeFromName(meal.mealName ?? '') == mealType, // Change: Added null fallback for comparison
      orElse: () => Meal(
          mealName: '', foods: [], protein: 0, carbs: 0, fat: 0, calories: 0),
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
