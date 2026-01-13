import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/utils/data_casting.dart';
import '../models/ai_workout_update.dart';
import '../models/chat_message.dart';
import '../models/meal_data.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../models/workout_data.dart';

class AIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final AuthService _authService; // Dependency

  // Constructor requires AuthService
  AIService({required AuthService authService}) : _authService = authService;

  // lib/services/ai_service.dart

  // lib/services/ai_service.dart

 // lib/services/ai_service.dart

  // lib/services/ai_service.dart

  Future<AIWorkoutUpdate?> processWorkoutUserInput(
    String userInput,
    Workout currentWorkout, {
    List<ChatMessage> chatHistory = const [],
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    // !!! REPLACE THIS WITH THE URL FOR YOUR V3 FUNCTION !!!
    final url = Uri.parse(
        'https://us-central1-simply-fit-no-more-stress.cloudfunctions.net/processWorkoutUserInputV3');

    try {
      // 1. Manually get the ID token from the signed-in user.
      final idToken = await user.getIdToken();

      // 2. Manually construct the headers.
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken', // This is the critical part
      };

      // 3. Manually construct the body. The 'data' key is required by callable functions.
      final body = json.encode({
        'data': {
          'userInput': userInput,
          'currentWorkout': currentWorkout.toMap(),
          'chatHistory': chatHistory.map((c) => c.toMap()).toList(),
        }
      });

      // 4. Make a direct HTTPS POST request.
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // The 'result' key contains the data returned by the function.
        final responseData = json.decode(response.body)['result'];
        final message = responseData['response_message'] ?? 'Understood.';
        final updatedWorkoutData = responseData['updated_workout_json'];

        Workout? updatedWorkout;
        // 🛡️ SHIELD: Added explicit Map type check to protect against unexpected cloud return types
        if (updatedWorkoutData != null && updatedWorkoutData is Map) {
          updatedWorkout =
              Workout.fromMap(Map<String, dynamic>.from(updatedWorkoutData));
        }
        return AIWorkoutUpdate(
          updatedWorkout: updatedWorkout,
          responseMessage: message,
        );
      } else {
        // Handle non-200 responses (like 4xx, 5xx errors)
        print('Cloud Function Error: ${response.statusCode} ${response.body}');
        return AIWorkoutUpdate(
          updatedWorkout: null,
          responseMessage: "Sorry, there was a server error. Please try again.",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Generic Error (processWorkoutUserInput): $e');
      }
      return null;
    }
  }
  Future<Meal?> getMealFromText(String inputText) async {
    if (_authService.currentUser == null) {
      throw Exception('User is not authenticated.');
    }
    try {
      final callable = _functions.httpsCallable('getMealFromText');
      final response = await callable.call({'inputText': inputText});
      final safeData = deepCast(response.data);
      return Meal.fromMap(safeData as Map<String, dynamic>);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Cloud Function Error (getMealFromText): ${e.code} ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Generic Error (getMealFromText): $e');
      }
      return null;
    }
  }

  Future<String?> getWorkoutSummary(
    Workout completedWorkout,
    Map<String, Exercise?> lastSessionData,
    UserProfile userProfile,
  ) async {
    if (_authService.currentUser == null) {
      throw Exception('User is not authenticated.');
    }
    try {
      final Map<String, dynamic> serializableLastSession =
          lastSessionData.map(
        (key, value) => MapEntry(key, value?.toMap()),
      );

      final callable = _functions.httpsCallable('getWorkoutSummary');
      final response = await callable.call({
        'completedWorkout': completedWorkout.toMap(),
        'lastSessionData': serializableLastSession,
        'userProfile': userProfile.toMap(),
      });
      return response.data['summaryText'] as String?;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Cloud Function Error (getWorkoutSummary): ${e.message}');
      }
      return "Could not generate a summary at this time.";
    } catch (e) {
      if (kDebugMode) {
        print('Generic Error (getWorkoutSummary): $e');
      }
      return "An unexpected error occurred while generating your summary.";
    }
  }


  Future<String?> getWorkoutInsights(
    Workout completedWorkout,
    Map<String, Exercise?> lastSessionData,
    UserProfile userProfile,
  ) async {
    if (_authService.currentUser == null) {
      throw Exception('User is not authenticated.');
    }
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
      if (kDebugMode) {
        print('Cloud Function Error (getWorkoutInsights): ${e.message}');
      }
      return "Could not generate insights at this time.";
    } catch (e) {
      if (kDebugMode) {
        print('Generic Error (getWorkoutInsights): $e');
      }
      return "An unexpected error occurred while generating insights.";
    }
  }
}
