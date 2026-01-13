import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/insight_data.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/local_storage_service.dart';

class InsightsService {
  final AIService _aiService;
  final LocalStorageService _storage;
  final _uuid = const Uuid();

  InsightsService({
    required AIService aiService,
    required LocalStorageService storage,
  }) : _aiService = aiService, _storage = storage;

  // 🛡️ SHIELD: Stage 4 Summary Port (Ported from index.ts Lines 347+)
  Future<String> generateSummaryInsight({required bool isMonthly}) async {
    try {
      final profile = await _storage.getUserProfile();
      if (profile == null) return "Error: User profile not found.";

      // 1. Gather Local Data
      final days = isMonthly ? 30 : 7;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final workouts = await _storage.getWorkoutsInRange(startDate, endDate);
      final nutrition = await _storage.getNutritionInRange(startDate, endDate);

      if (workouts.isEmpty && nutrition.isEmpty) {
        return "Not enough data to analyze for the last $days days.";
      }

      // 2. Call local AI Service
      final summaryText = await _aiService.generateSummaryInsight(
        workoutData: workouts,
        nutritionData: nutrition,
        profile: profile,
        isMonthly: isMonthly,
      );

      if (summaryText == null) return "Error: AI failed to generate summary.";

      // 3. Persist Insight locally to Isar
      final newInsight = Insight(
        id: _uuid.v4(),
        title: isMonthly ? "Monthly Review" : "Weekly Review",
        summaryText: summaryText,
        insightType: InsightType.weeklySummary,
        generatedAt: DateTime.now(),
      );

      await _storage.saveInsight(newInsight);
      return "Insight generated successfully!";
    } catch (e) {
      debugPrint('Local Insight Error: $e');
      return 'Error: $e';
    }
  }

  Future<String> generateWorkoutInsight() async => "Workout trend logic pending port.";

  Future<String> generateNutritionInsight() async {
    try {
      final profile = await _storage.getUserProfile();
      if (profile == null) return "Error: User profile not found.";

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final nutrition = await _storage.getNutritionInRange(startDate, endDate);

      if (nutrition.isEmpty) {
        return "No nutrition data found for the last 7 days.";
      }

      final summaryText = await _aiService.generateNutritionInsight(
        nutritionData: nutrition,
        profile: profile,
      );

      if (summaryText == null) return "Error: AI failed to analyze nutrition.";

      final newInsight = Insight(
        id: _uuid.v4(),
        title: "Your Weekly Nutrition Review",
        summaryText: summaryText,
        insightType: InsightType.nutritionCorrelation,
        generatedAt: DateTime.now(),
      );

      await _storage.saveInsight(newInsight);
      return "Nutrition insight generated successfully!";
    } catch (e) {
      debugPrint('Nutrition Insight Logic Error: $e');
      return 'Error: $e';
    }
  }
}