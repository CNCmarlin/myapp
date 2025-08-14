import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/ai_workout_update.dart';
import 'package:myapp/models/chat_message.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/models/workout_data.dart';

class AIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<AIWorkoutUpdate?> processUserInput(
    String userInput,
    Workout currentWorkout, {
    List<ChatMessage> chatHistory = const [],
  }) async {
    try {
      final callable = _functions.httpsCallable('processWorkoutUserInput');
      final response = await callable.call({
        'userInput': userInput,
        'currentWorkout': currentWorkout.toMap(),
        'chatHistory': chatHistory.map((c) => c.toMap()).toList(),
      });

      final data = response.data as Map<String, dynamic>;
      final message = data['response_message'] ?? 'Understood.';
      final updatedWorkoutData = data['updated_workout_json'];

      Workout? updatedWorkout;
      if (updatedWorkoutData != null) {
        updatedWorkout = Workout.fromMap(
            Map<String, Object?>.from(updatedWorkoutData));
      }

      return AIWorkoutUpdate(
        updatedWorkout: updatedWorkout,
        responseMessage: message,
      );
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function Error (processWorkoutUserInput): ${e.message}');
      return AIWorkoutUpdate(
        updatedWorkout: null,
        responseMessage: "Sorry, I couldn't process that. Please try again.",
      );
    } catch (e) {
      print('Generic Error (processWorkoutUserInput): $e');
      return null;
    }
  }

  Future<Meal?> getMealFromText(String inputText) async {
    try {
      final callable = _functions.httpsCallable('getMealFromText');
      final response = await callable.call({'inputText': inputText});
      
      // FIX: Use our new, robust constructor to safely parse the nested data.
      return Meal.fromCloudFunction(response.data as Map<String, dynamic>);

    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function Error (getMealFromText): ${e.message}');
      return null;
    } catch (e) {
      print('Generic Error (getMealFromText): $e');
      return null;
    }
  }

  Future<String?> getWorkoutInsights(
    Workout completedWorkout,
    Map<String, Exercise?> lastSessionData,
    UserProfile userProfile,
  ) async {
    try {
      final Map<String, dynamic> serializableLastSession = lastSessionData.map(
        (key, value) => MapEntry(key, value?.toMap()),
      );

      final callable = _functions.httpsCallable('getWorkoutInsights');
      final response = await callable.call({
        'completedWorkout': completedWorkout.toMap(),
        'lastSessionData': serializableLastSession,
        'userProfile': userProfile.toMap(),
      });
      return response.data['insightText'] as String?;
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function Error (getWorkoutInsights): ${e.message}');
      return "Could not generate insights at this time.";
    } catch (e) {
      print('Generic Error (getWorkoutInsights): $e');
      return "An unexpected error occurred while generating insights.";
    }
  }
}