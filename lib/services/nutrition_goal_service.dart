import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/user_profile.dart';

class NutritionGoalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // In lib/services/nutrition_goal_service.dart

Future<Map<String, dynamic>?> suggestGoals(UserProfile profile) async {
  try {
    final callable = _functions.httpsCallable('suggestNutritionGoals');
    
    // --- NEW: Unit Conversion Logic ---
    double weightKg = (profile.weight?['value'] as num?)?.toDouble() ?? 0.0;
    double heightCm = (profile.height?['value'] as num?)?.toDouble() ?? 0.0;

    // Check the user's preferred unit system from their profile.
    if (profile.unitSystem == 'imperial') {
      // If the stored weight unit is lbs, convert it to kg.
      if (profile.weight?['unit'] == 'lbs') {
        weightKg = weightKg * 0.453592;
      }
      // If the stored height unit is cm (which it should be from onboarding),
      // we don't need to convert it again. The 'ft' and 'in' are only for display.
    }
    // --- End of Unit Conversion Logic ---

    final result = await callable.call(<String, dynamic>{
      'primaryGoal': profile.primaryGoal,
      'biologicalSex': profile.biologicalSex,
      'weightKg': weightKg, // Send the correctly converted weight
      'heightCm': heightCm,
      'activityLevel': profile.activityLevel,
    });

    return Map<String, dynamic>.from(result.data);
  } on FirebaseFunctionsException catch (e) {
    print('Firebase Functions Exception: ${e.code} - ${e.message}');
    return null;
  } catch (e) {
    print('Generic Exception: $e');
    return null;
  }
}
}