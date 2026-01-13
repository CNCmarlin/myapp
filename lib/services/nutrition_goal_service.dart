import '../models/user_profile.dart';
import '../services/ai_service.dart';

class NutritionGoalService {
  // 🛡️ SHIELD: Stage 4 BYOK Transition
  // Change: Removed FirebaseFunctions. Switched to direct AIService calls.
  final AIService _aiService;

  NutritionGoalService({required AIService aiService}) : _aiService = aiService;

  Future<Map<String, dynamic>?> suggestGoals(UserProfile profile) async {
    final suggestions = await _aiService.suggestGoals(profile);
    return suggestions;
  }

  Future<Map<String, dynamic>?> getMacrosFromCalories(
      double calories, UserProfile userProfile) async {
    final macros = await _aiService.calculateMacrosFromCalories(calories, userProfile);
    return macros;
  }
}
