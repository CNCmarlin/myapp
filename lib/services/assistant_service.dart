// lib/services/assistant_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/workout_data.dart';
import '../models/assistant_response.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class AssistantService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

   Future<AssistantResponse> getAssistantResponse({
    required String prompt,
    required List<ChatMessage> history,
    required UserProfile userProfile,
    Workout? lastWorkout, // NEW optional parameter
    List<NutritionLog>? recentNutritionLogs, // NEW optional parameter
  }) async {
    try {
      final callable = _functions.httpsCallable('aiAssistantRouter');
      final result = await callable.call({
        'prompt': prompt,
        'history': history.map((m) => m.toMap()).toList(),
        'userProfile': userProfile.toMap(),
        'lastWorkout': lastWorkout?.toMap(), // Pass to backend
        'recentNutritionLogs':
            recentNutritionLogs?.map((l) => l.toMap()).toList(), // Pass to backend
      });

      return AssistantResponse.fromMap(result.data as Map<String, dynamic>);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print("Cloud Function Error (aiAssistantRouter): ${e.code} ${e.message}");
      }
      return AssistantResponse(
        type: AssistantResponseType.text,
        textResponse: "An error occurred while contacting the assistant.",
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing AI response: $e");
      }
      return AssistantResponse(
        type: AssistantResponseType.text,
        textResponse: "An unexpected error occurred.",
      );
    }
  }
}
