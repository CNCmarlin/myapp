import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/meal_insight_service.dart';

class NutritionLogProvider extends ChangeNotifier {
  final String userId;
  final DateTime date;
  final UserProfile? userProfile;

  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService();
  final MealInsightService _insightService = MealInsightService();

  NutritionLog? _log;
  NutritionLog? get log => _log;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  NutritionLogProvider({required this.userId, required this.date, this.userProfile}) {
    _loadLogForDate();
  }

  Future<void> _loadLogForDate() async {
    _isLoading = true;
    notifyListeners();
    _log = await _firestoreService.getNutritionLog(userId, date);
    _log ??= NutritionLog.empty(date: date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveLog() async {
    if (_log != null) {
      await _firestoreService.saveNutritionLog(userId, _log!);
    }
  }

  // --- NEW: Manual Food Entry Methods ---
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

  // REVISED AI Method: Now safely maps meal names
  Future<bool> addMealFromText(String text) async {
    if (text.trim().isEmpty) return false;
    _isAnalyzing = true;
    notifyListeners();

    final meal = await _aiService.getMealFromText(text);

    if (meal != null) {
      // Safely determine the meal category
      final mealType = _getMealTypeFromName(meal.mealName);

      // Add individual foods to the correct category
      for (var food in meal.foods) {
        addFoodToMeal(mealType, food);
      }
      
      // Still store the original AI meal object for its insight
      _log?.aiGeneratedMeals.add(meal);
      
      // Recalculate, notify, and save
      _log?.recalculateTotals();
      notifyListeners();
      _saveLog();
      _generateAndSaveInsight(meal); // This can stay as is
      
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } else {
      _isAnalyzing = false;
      notifyListeners();
      return false;
    }
  }
  
  // Helper function to categorize AI meals
  String _getMealTypeFromName(String aiMealName) {
    final lowerCaseName = aiMealName.toLowerCase();
    if (lowerCaseName.contains('breakfast')) return 'Breakfast';
    if (lowerCaseName.contains('lunch')) return 'Lunch';
    if (lowerCaseName.contains('dinner')) return 'Dinner';
    return 'Snacks'; // Default case
  }

  String? getInsightForMeal(String mealType) {
    // Find the last AI-generated meal that maps to this meal type.
    final relevantAiMeal = _log?.aiGeneratedMeals.lastWhere(
      (meal) => _getMealTypeFromName(meal.mealName) == mealType,
      orElse: () => Meal(mealName: '', foods: [], protein: 0, carbs: 0, fat: 0, calories: 0), // Return a dummy meal if not found
    );

    if (relevantAiMeal != null && (relevantAiMeal.aiInsight?.isNotEmpty ?? false)) {
      return relevantAiMeal.aiInsight;
    }
    return null;
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