import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/user_profile.dart';

class NutritionGoalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>?> suggestGoals(UserProfile profile) async {
    try {
      final callable = _functions.httpsCallable('suggestNutritionGoals');
      
      // We need to convert the weight from the map to a double
      final weightKg = (profile.weight?['value'] as num?)?.toDouble() ?? 0.0;
      final heightCm = (profile.height?['value'] as num?)?.toDouble() ?? 0.0;

      final result = await callable.call(<String, dynamic>{
        'primaryGoal': profile.primaryGoal,
        'biologicalSex': profile.biologicalSex,
        'weightKg': weightKg,
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