import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../utils/fitness_math.dart';

class NutritionGoalService {
  // 🛡️ SHIELD: Stage 4 BYOK Transition
  // Change: Removed FirebaseFunctions. Switched to direct AIService calls.
  final AIService _aiService;

  NutritionGoalService({required AIService aiService}) : _aiService = aiService;

Future<Map<String, dynamic>?> suggestGoals(UserProfile profile) async {
    final weightKg = profile.weight?.unit == "lbs"
        ? (profile.weight?.value ?? 0) * 0.453592
        : (profile.weight?.value ?? 0);
    final heightCm = profile.height?.value ?? 0;
    final age = DateTime.now().year - (profile.birthDate?.year ?? 1995);

    // 📍 Local Ground Truth Calculation
    final bmr = FitnessMath.calculateBMR(weightKg, heightCm, age, profile.biologicalSex ?? 'male');
    final tdee = FitnessMath.calculateTDEE(
      bmr, 
      profile.activityLevel ?? 'sedentary', 
      profile.exerciseDaysPerWeek
    );
    
    // Rationale: Deficit/Surplus based on the user's weekly slider selection
    final adjustment = FitnessMath.calculateGoalAdjustment(
        profile.weeklyWeightLossGoal, 
        profile.primaryGoal ?? 'maintain'
    );

    final targetCalories = tdee + adjustment;

    // 🤖 AI Only handles the "Flavor" (Macro distribution)
    return await _aiService.suggestMacrosDefensive(
      targetCalories: targetCalories, 
      profile: profile
    );
  }

  Future<Map<String, dynamic>?> getMacrosFromCalories(
      double calories, UserProfile userProfile) async {
    // Rationale: Direct pass-through for macro-only calculation
    final macros = await _aiService.calculateMacrosFromCalories(calories, userProfile);
    return macros;
  }
}
