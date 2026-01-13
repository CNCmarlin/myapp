// lib/providers/nutrition_log_provider.dart

import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/local_storage_service.dart'; // Change: Imported LocalStorageService
import '../services/meal_insight_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/nutrition_utils.dart';
import '../providers/user_profile_provider.dart';

class NutritionLogProvider extends ChangeNotifier {
  final String userId;
  DateTime _date;
  final UserProfileProvider _userProfileProvider;

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
    required SecureStorageService secureStorageService,
    required LocalStorageService localStorageService, 
    required UserProfileProvider userProfileProvider,
  })  : _date = date,
        _userProfileProvider = userProfileProvider,
        _localStorageService = localStorageService {
    _aiService = AIService(secureStorage: secureStorageService);
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
      await _localStorageService.saveNutritionLog(_log!);
      _userProfileProvider.triggerBackgroundSync();
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

    final profile = _userProfileProvider.userProfile;
    if (profile == null) return false;

    final meal = await _aiService.getMealFromText(text, profile);

    if (meal != null) {
      final mealName = meal.mealName ??
          'Unknown Meal'; // Change: Fallback for nullable field
      final mealType = getMealTypeFromName(mealName);
      for (var food in meal.foods ?? []) {
        // Change: Null-safe iterator for foods list
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
      (meal) =>
          getMealTypeFromName(meal.mealName ?? '') ==
          mealType, // Change: Added null fallback for comparison
      orElse: () => Meal(
          mealName: '', foods: [], protein: 0, carbs: 0, fat: 0, calories: 0),
    );
    return relevantAiMeal?.aiInsight;
  }

  Future<void> _generateAndSaveInsight(Meal meal) async {
    final profile = _userProfileProvider.userProfile; // Change: Use the centralized provider
    if (profile != null) {
      final insightText = await _insightService.generateInsight(
        userProfile: profile,
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
