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
      // No need to notify listeners here, UI is already updated.
      // This happens in the background.
      await _firestoreService.saveNutritionLog(userId, _log!);
    }
  }

  Future<bool> addMealFromText(String text) async {
    if (text.trim().isEmpty) return false;

    _isAnalyzing = true;
    notifyListeners();

    final meal = await _aiService.getMealFromText(text);

    if (meal != null) {
      _log?.meals.add(meal);
      _log?.recalculateTotals();
      
      // Notify UI immediately for instant update
      notifyListeners(); 
      
      // Save the log and generate insight in the background
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

  Future<void> _generateAndSaveInsight(Meal meal) async {
    if (userProfile != null) {
      final insightText = await _insightService.generateInsight(
        userProfile: userProfile!,
        meal: meal,
      );
      if (insightText != null) {
        final mealIndex = _log?.meals.indexOf(meal);
        if (mealIndex != null && mealIndex != -1) {
          _log?.meals[mealIndex].aiInsight = insightText;
          notifyListeners(); // Update UI with insight
          _saveLog(); // Save again with the new insight
        }
      }
    }
  }
  
  void updateSecondaryData({double? water, bool? isLowCarb}) {
      if (water != null) _log?.waterIntake = water;
      if (isLowCarb != null) _log?.isLowCarbDay = isLowCarb;
      _log?.recalculateTotals();
      notifyListeners();
      _saveLog();
  }
}