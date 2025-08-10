import 'package:myapp/models/user_profile.dart';

import '../models/meal_data.dart';
import '../models/workout_data.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import 'package:myapp/models/ai_workout_update.dart';
import 'package:myapp/models/chat_message.dart'; // Import ChatMessage

class AIService {
  final GenerativeModel _model; // Use GenerativeModel

  AIService()
      : _model = FirebaseAI.googleAI()
            .generativeModel(model: 'gemini-2.5-flash'); // Initialize model

  // New unified method for handling all AI interactions
  Future<AIWorkoutUpdate?> processUserInput(
      String userInput, Workout currentWorkout,
      {List<ChatMessage> chatHistory = const []}) async {
    // final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

    // Build the conversational history
    final historyContent = chatHistory
        .map(
            (msg) => Content.text('${msg.isUser ? 'User' : 'AI'}: ${msg.text}'))
        .toList();
    // 1. Serialize the current workout state into a JSON string.
    final workoutJson = jsonEncode(currentWorkout.toMap());

    // 2. This is the sophisticated prompt that gives the AI its instructions.
    final prompt = '''
  You are an expert fitness coach and a precise data entry assistant.
  Your task is to analyze a user's text command and update their current workout session data accordingly.
 If the user is not logging a set or asking for workout analysis, respond conversationally but DO NOT return updated_workout_json.

  RULES:
  - The user's command might be ambiguous (e.g., "100 x 8"). Infer the exercise based on which exercises are currently selected or the last one you prompted for. If still ambiguous, ask for clarification.
  - If the user provides a correction (e.g., "oops, 12 reps not 10"), modify the LAST logged set of the relevant exercise.
  - You MUST return a single, valid JSON object and nothing else. Your entire response must be only the JSON.
 - If the user command does not involve logging a set or requesting workout analysis, set "updated_workout_json" to null.
  - If the user says they are 'done' with an exercise, or asks to 'mark it complete', find that exercise in the current_workout_json and update its 'status' field to 'complete'.

  INPUT:
- current_workout_json: The user's entire workout session as a JSON object.
- user_input: The text command from the user.

  CHAT HISTORY EXAMPLE:
  User: Log 135 x 10 for bench press
  AI: Got it. Logged 135lbs x 10 reps for Bench Press.
  OUTPUT FORMAT:
  You must return a JSON object with two keys:
  1. "updated_workout_json": The complete, modified workout JSON object after applying the user's command.
  2. "response_message": A short, encouraging confirmation message for the user (e.g., "Got it. Logged 100lbs x 8 reps for Bench Press.").

  HERE IS THE DATA:
"current_workout_json": $workoutJson,
"user_input": "$userInput"
''';

    final fullPrompt = historyContent + [Content.text(prompt)];

    // In lib/services/ai_service.dart
    try {
      final response = await _model.generateContent(fullPrompt);
      String responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) return null;

      // SANITIZE THE RESPONSE: Find the start and end of the actual JSON object.
      final startIndex = responseText.indexOf('{');
      final endIndex = responseText.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        // If we can't find a JSON object, we can't proceed.
        print('Error: No valid JSON object found in AI response.');
        return null;
      }

      final jsonString = responseText.substring(startIndex, endIndex + 1);
      final jsonResponse =
          jsonDecode(jsonString); // Now we parse the clean string.

      final updatedWorkoutJson = jsonResponse['updated_workout_json'];
      final message = jsonResponse['response_message'] ??
          'Understood.'; // Provide a default message

      Workout? updatedWorkout = null;
      if (updatedWorkoutJson != null) {
        try {
          updatedWorkout = Workout.fromMap(updatedWorkoutJson);
        } catch (e) {
          print('Error parsing updated workout JSON: $e');
        }
      }

      return AIWorkoutUpdate(
          updatedWorkout: updatedWorkout, responseMessage: message);
    } catch (e) {
      return null;
    }
  }

  Future<Meal?> getMealFromText(String inputText) async {
    final model = _model;

     final prompt = '''
    You are an expert nutrition parser. Your task is to analyze the user's input
    text describing a meal and extract detailed information.

    1. Identify each individual food item in the user's description.
    2. For each item, find its nutritional information (calories, protein, carbs, fat). Use professional, cleaned-up names for each item.
    3. Calculate the TOTAL macros and calories for the entire meal by summing up the individual items.
    4. Determine a suitable name for the meal (e.g., "Breakfast", "Lunch", "Dinner", "Snack").

    You MUST return the information as a single, valid JSON object and nothing else.

    The JSON structure must be exactly:
    {
      "mealName": "...",
      "totalProtein": 0.0,
      "totalCarbs": 0.0,
      "totalFat": 0.0,
      "totalCalories": 0.0,
      "foods": [
        {
          "name": "Cleaned Up Item Name 1",
          "protein": 0.0,
          "carbs": 0.0,
          "fat": 0.0,
          "calories": 0.0
        }
      ]
    }

    Here is the meal description:
    $inputText
  ''';

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    String responseText = response.text?.trim() ?? '';

    // NEW: Sanitize the AI's response to remove markdown
    if (responseText.startsWith('```json')) {
      responseText = responseText.substring(7); // Remove '```json\n'
    }
    if (responseText.endsWith('```')) {
      responseText = responseText.substring(0, responseText.length - 3);
    }

    final jsonData = jsonDecode(responseText);

    if (jsonData is Map<String, dynamic>) {
      return Meal(
        mealName: jsonData['mealName'] ?? 'Meal',
        protein: (jsonData['totalProtein'] as num?)?.toDouble() ?? 0.0,
        carbs: (jsonData['totalCarbs'] as num?)?.toDouble() ?? 0.0,
        fat: (jsonData['totalFat'] as num?)?.toDouble() ?? 0.0,
        calories: (jsonData['totalCalories'] as num?)?.toDouble() ?? 0.0,
        foods: (jsonData['foods'] as List<dynamic>?)
                ?.map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
                .toList() ?? [],
      );
    }
  } catch (e) {
    print('Error calling Gemini API or parsing response: $e');
  }
  return null;
}

  Future<Map<String, dynamic>?> getWorkoutSetFromText(String inputText) async {
    final model = _model;

    final prompt = '''
You are an expert workout set parser. Your task is to analyze the user's input text describing an exercise set and extract the exercise name, weight, and repetitions (reps).

You MUST return the information as a valid JSON object. Do NOT include any other text, explanation, or formatting before or after the JSON.

The JSON format must be exactly:
{"exerciseName": "string_or_null", "weight": 0.0, "reps": 0}

If the exercise name is not explicitly mentioned, set "exerciseName" to null. Extract the weight as a decimal number and the reps as an integer.

Here is the workout set description:
$inputText
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        return null;
      }
      String jsonString = response.text!.trim();
      final startIndex = jsonString.indexOf('{');
      final endIndex = jsonString.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonString = jsonString.substring(startIndex, endIndex + 1);
      }
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error calling Gemini API or parsing workout response: $e');
    }
    return null; // Return null for API errors or invalid JSON
  }

// Add this complete method inside your AIService class

Future<String?> getWorkoutInsights(Workout completedWorkout, Map<String, Exercise?> lastSessionData, UserProfile userProfile) async {
  final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  // Determine the correct unit based on the user's profile
  final String unitSuffix = userProfile.unitSystem == 'metric' ? 'kg' : 'lbs';

  // Pass the unit to the helper methods
  String currentWorkoutSummary = _formatWorkoutForPrompt(completedWorkout, unitSuffix);
  String previousWorkoutSummary = _formatLastSessionForPrompt(lastSessionData, unitSuffix);

  final prompt = '''
  You are an expert fitness coach providing encouraging and safe advice.
  Analyze the user's completed workout and compare it to their last session.
  IMPORTANT: The user's preferred weight unit is ${unitSuffix}. Ensure your entire response uses this unit.

  Here is the summary of the workout they just completed:
  $currentWorkoutSummary

  Here is the summary of their performance on those exercises last time:
  $previousWorkoutSummary

  Based on this data, provide a concise, encouraging, and actionable summary.
  Structure your response exactly like this, using "---" as a separator:
  Overall Session Insights: [Your brief summary of the overall workout]
  ---
  Performance Notes: [A bulleted list of specific observations about performance on each exercise]
  ---
  Recommendations for Next Time: [A bulleted list of specific, actionable tips for the next workout]

  IMPORTANT: Do not include any other text, greetings, or formatting.
  ''';

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text;
  } catch (e) {
    print('Error getting workout insights from AI: $e');
    return null;
  }
}

// Add these two helper methods inside the AIService class as well

String _formatWorkoutForPrompt(Workout workout, String unitSuffix) {
  return workout.exercises
      .map((e) =>
          '${e.name}: ${e.sets.map((s) => '${s.weight}$unitSuffix x ${s.reps}reps').join(', ')}')
      .join('\n');
}

// REPLACE this helper method
String _formatLastSessionForPrompt(Map<String, Exercise?> lastSessionData, String unitSuffix) {
  if (lastSessionData.isEmpty) return "No data available for the last session.";
  return lastSessionData.entries.map((entry) {
    final exercise = entry.value;
    if (exercise == null) return '${entry.key}: No data';
    return '${exercise.name}: ${exercise.sets.map((s) => '${s.weight}$unitSuffix x ${s.reps}reps').join(', ')}';
  }).join('\n');
}

}
