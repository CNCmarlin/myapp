import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/user_profile.dart';

class NutritionGoalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>?> suggestGoals(UserProfile profile) async {
    try {
      final callable = _functions.httpsCallable('suggestNutritionGoals');
      
      // FIX: Instead of sending individual fields, we now send the entire
      // UserProfile object as a map. This ensures the Cloud Function
      // receives all the new, detailed data it needs.
      final result = await callable.call(profile.toMap());

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Exception (suggestNutritionGoals): ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Generic Exception (suggestNutritionGoals): $e');
      return null;
    }
  }
   Future<Map<String, dynamic>?> getMacrosFromCalories(
      double calories, UserProfile userProfile) async {
    try {
      final callable = _functions.httpsCallable('calculateMacrosFromCalories');
      final result = await callable.call({
        'targetCalories': calories,
        'userProfile': userProfile.toMap(),
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print(
          "Cloud Function Error (calculateMacrosFromCalories): ${e.code} ${e.message}");
      return null;
    } catch (e) {
      print("Error calling calculateMacrosFromCalories: $e");
      return null;
    }
  }
}