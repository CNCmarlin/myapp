import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/user_profile.dart';

class MealInsightService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String?> generateInsight({
    required UserProfile userProfile,
    required Meal meal,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateMealInsight');
      final result = await callable.call(<String, dynamic>{
        'primaryGoal': userProfile.primaryGoal,
        'meal': meal.toMap(), // Send the full meal object
      });
      return result.data['insightText'] as String?;
    } catch (e) {
      print('Error calling generateMealInsight function: $e');
      return null;
    }
  }
}