import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // 🛡️ SHIELD: Direct SDK usage
import '../models/ai_workout_update.dart';
import '../models/chat_message.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../models/workout_data.dart';
import '../services/secure_storage_service.dart';

class AIService {
  final SecureStorageService _secureStorage;

  // 🛡️ SHIELD: AI Debug Logger
  // Change: Added deterministic logging for all analytical service calls.
  // Rationale: Allows verification of Isar data serialization before it reaches Gemini.
  void _log(String label, String content) {
    if (kDebugMode) {
      print("======== AI SERVICE DEBUG: $label ========");
      print(content);
      print("===========================================");
    }
  }
  
  // 🛡️ SHIELD: Centralized Model Constants
  // Rationale: Sets 'lite' as the default workhorse for 1,000 RPD free tier.
  static const String modelLite = 'gemini-2.5-flash-lite';
  static const String modelStandard = 'gemini-2.5-flash';

  AIService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  Future<GenerativeModel?> _getModel() async {
    final key = await _secureStorage.getGeminiKey();
    if (key == null || key.isEmpty) return null;

    return GenerativeModel(
      model: modelLite, // 📍 Switched to Flash-Lite for dev period
      apiKey: key,
    );
  }

  // ********************************** WORKOUT ************************************************ //=

  Future<AIWorkoutUpdate?> processWorkoutUserInput(
    String userInput,
    Workout currentWorkout,
    UserProfile userProfile, {
    List<ChatMessage> chatHistory = const [],
  }) async {
    final model = await _getModel();
    if (model == null) {
      return AIWorkoutUpdate(
        updatedWorkout: null,
        responseMessage: "Please set your Gemini API Key in Profile Settings.",
      );
    }

    final equipmentContext = userProfile.equipmentIds.isNotEmpty 
        ? userProfile.equipmentIds.join(', ') 
        : 'Standard Commercial Gym Equipment (Dumbbells, Barbells, Cables, and Machines)';

    final prompt = """
    Update this workout based on user input: '$userInput'.
    CURRENT WORKOUT: ${jsonEncode(currentWorkout.toMap())}
    
    **EQUIPMENT RESTRICTIONS:**
    You are FORBIDDEN from suggesting exercises requiring equipment not in this list: $equipmentContext.
    
    Respond ONLY in JSON format: {"response_message": "...", "updated_workout_json": {...}}
    """;

    _log("Workout Update Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      final data = jsonDecode(response.text!) as Map<String, dynamic>;

      return AIWorkoutUpdate(
        updatedWorkout: data['updated_workout_json'] != null
            ? Workout.fromMap(data['updated_workout_json'])
            : null,
        responseMessage: data['response_message'] ?? "Updated.",
      );
    } catch (e) {
      debugPrint("AI Logic Error: $e");
      return null;
    }
  }

  Future<String?> getWorkoutInsights(
    Workout completedWorkout,
    Map<String, Exercise?> lastSessionData,
    UserProfile userProfile,
  ) async {
    final model = await _getModel();
    if (model == null) return "Please set your API key to see insights.";

    final unitSuffix = userProfile.unitSystem == "metric" ? "kg" : "lbs";

    final currentSummary = completedWorkout.exercises
        .map((e) =>
            "${e.name}: ${e.sets?.map((s) => "${s.weight}$unitSuffix x ${s.reps}reps").join(", ")}")
        .join("\n");

    final previousSummary = lastSessionData.entries.map((entry) {
      final value = entry.value;
      if (value == null) return "${entry.key}: No data";
      return "${value.name}: ${value.sets?.map((s) => "${s.weight}$unitSuffix x ${s.reps}reps").join(", ")}";
    }).join("\n");

    final prompt = """
      You are a fitness coach. The user's unit is $unitSuffix. Analyze their workout and provide a concise summary.

      *IMPORTANT* do not include any ** use nothing. a dot, or a - instead.
      
      STRUCTURE:
      Overall Session Insights: [Your summary]
      ---
      Performance Notes: [Bulleted list]
      ---
      Recommendations for Next Time: [Bulleted list]

      CURRENT WORKOUT:
      $currentSummary

      PREVIOUS WORKOUT:
      $previousSummary
    """;

    _log("Workout Insight Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim() ?? "";
    } catch (e) {
      debugPrint("Deep Insights Error: $e");
      return "Unable to generate insights at this time.";
    }
  }

  Future<String?> getWorkoutSummary(
    Workout completedWorkout,
    Map<String, Exercise?> lastSessionData,
    UserProfile userProfile,
  ) async {
    final model = await _getModel();
    if (model == null) return "AI Summary unavailable (API Key missing).";

    // 🛡️ SHIELD: Data Serialization for AI Context
    // Change: Converting local models to JSON strings for the prompt.
    final completedJson = jsonEncode(completedWorkout.toMap());
    final lastSessionJson =
        jsonEncode(lastSessionData.map((k, v) => MapEntry(k, v?.toMap())));

    final prompt = """
      You are a fitness coach analyzing a user's just-completed workout compared to their last session. 
      Your tone is concise and encouraging.

      **User Goal:** ${userProfile.primaryGoal}
      **Unit System:** ${userProfile.unitSystem}

      **Your Task:**
      1. Compare the 'Completed Workout Data' to the 'Last Session Data'.
      2. **Crucially, pay attention to any user 'notes' on exercises.**
      3. Highlight 1-2 key improvements (increased weight or reps).
      4. If performance decreased, gently correlate with any notes (e.g., mention noted pain).
      5. Provide one brief, actionable tip for the next session.
      6. Keep the entire response under 75 words.

      **CRITICAL:** Respond with ONLY the user-facing text in markdown. 
      Do NOT include markdown headers like "###". Start with a bolded title.

      **Completed Workout Data:** $completedJson
      **Last Session Data:** $lastSessionJson
    """;

    _log("Workout Summary AI Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim() ?? "Great job completing your workout!";
    } catch (e) {
      debugPrint("Workout Summary AI Error: $e");
      return "Excellent work today! Keep pushing toward your goals.";
    }
  }

  // 🛡️ SHIELD: Function 11: generateWorkoutInsight (Complete index.ts Port)
  // Change: Integrated "Workout of the Week" and recurring theme analysis.
  // Rationale: Ensures parity with the analytical persona defined in the Cloud Function.
  Future<String?> generateWorkoutTrendInsight({
    required List<Workout> workoutData,
    required UserProfile profile,
  }) async {
    final model = await _getModel();
    if (model == null) return null;

    final workoutBlob = jsonEncode(workoutData
        .map((w) => {
              'date': w.date.toIso8601String(),
              'name': w.name,
              'duration': w.duration,
              'exercises': w.exercises
                  .map((e) => {
                        'name': e.name,
                        'notes': e.notes,
                        'sets': e.sets
                            ?.map((s) => '${s.weight} x ${s.reps}')
                            .toList(),
                      })
                  .toList(),
            })
        .toList());

    final prompt = """
      You are an expert personal trainer providing a weekly performance review. 
      Your tone is analytical, motivating, and forward-looking.
      User Goal: "${profile.primaryGoal}", Level: ${profile.fitnessProficiency}.

      **Your Task:**
      1. Analyze all workouts from the past 7 days.
      2. **Pay close attention to user notes.** Look for recurring themes like "felt tired," "form was great," or mentions of pain.
      3. Identify the "Workout of the Week" (session with most PRs or volume) and praise the user.
      4. Find one area for improvement using notes for context (e.g., suggesting carbs for fatigue).
      5. Conclude with an encouraging statement for the week ahead.
      6. Keep the entire response under 150 words.

      **CRITICAL:** Respond with ONLY markdown text.
      - Start with a bolded title on the first line.
      - Do NOT include markdown headers like "###".

      **Workout Data:** $workoutBlob
    """;

    _log("Workout Trend AI Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim();
    } catch (e) {
      debugPrint("Workout Trend AI Error: $e");
      return null;
    }
  }

  // ****************************** NUTRITION *********************************************** /

  Future<Map<String, double>?> suggestMacrosDefensive({
    required double targetCalories,
    required UserProfile profile,
  }) async {
    final model = await _getModel();
    if (model == null) return null;

    final weightKg = profile.weight?.unit == "lbs"
        ? (profile.weight?.value ?? 0) * 0.453592
        : (profile.weight?.value ?? 0);

    final prompt = """
      You are an expert nutritionist. 
      **TARGET CALORIES:** ${targetCalories.toStringAsFixed(0)}
      **USER WEIGHT:** ${weightKg.toStringAsFixed(1)}kg
      **PREFERENCE:** ${profile.prefersLowCarb ? "Low-Carb" : "Standard"}

      **MACRO DISTRIBUTION PROTOCOL:**
      1. IF Standard: Protein = 1.8g/kg. Fat = 25% of total calories. Carbs = Remainder.
      2. IF Low-Carb: Protein = 2.2g/kg. Carbs = Max 50g or 10% of calories. Fat = Remainder.

      **CRITICAL:** Respond ONLY with raw JSON. No text. No markdown.
      {"targetCalories": $targetCalories, "targetProtein": 0, "targetCarbs": 0, "targetFat": 0}
    """;

    _log("Defensive Macro Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      final cleanJson = _cleanJson(response.text ?? '{}');
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      debugPrint("Macro Calculation Error: $e");
      return null;
    }
  }

  // 🛡️ SHIELD: Ported from index.ts (Lines 405-464)
  // Change: Integrated specific parsing rules, examples, and context blobs.
  // Rationale: Moves the server-side "Secret Sauce" into the local-first SDK.
  Future<Meal?> getMealFromText(String inputText, UserProfile profile) async {
    final model = await _getModel();
    if (model == null) return null;

    final prompt = """
      ${_buildSystemInstruction('nutritionist')}
      ${_userDataBlob(profile)}

      Your task is to analyze the user's text and extract detailed meal information into a single, valid JSON object.

      **CRITICAL RULE:**
      If the user describes a composite food item (e.g., "a ham and cheese sandwich", "a bowl of oatmeal with berries"), you MUST identify the primary item and return it as a SINGLE entry in the "foods" array. 
      Do NOT break it down into its constituent ingredients. Instead, list the key ingredients within the "name" field for clarity.

      **EXAMPLES:**
      - Input: "turkey and swiss sandwich on rye" -> {"foods": [{"name": "Sandwich - Turkey, Swiss, Rye", ...}]}
      - Input: "2 eggs, 3 strips of bacon, and a coffee" -> {"foods": [{"name": "Eggs", ...}, {"name": "Bacon", ...}, {"name": "Coffee", ...}]}

      **JSON STRUCTURE:**
      {
        "mealName": "...", "protein": 0.0, "carbs": 0.0, "fat": 0.0, "calories": 0.0,
        "foods": [
          {"name": "...", "protein": 0.0, "carbs": 0.0, "fat": 0.0, "calories": 0.0}
        ]
      }

      **Meal Description to Parse:** "$inputText"
    """;

    _log("Direct getMealFromText Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      final cleanJson = _cleanJson(response.text ?? '{}');

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      return Meal.fromMap(data);
    } catch (e) {
      debugPrint("Direct getMealFromText Error: $e");
      return null;
    }
  }

Future<String?> generateMealInsight({
    required String primaryGoal,
    required Map<String, dynamic> mealData,
  }) async {
    final model = await _getModel();
    if (model == null) return null;

    final prompt = """
      You are a positive fitness coach. A user's goal is "$primaryGoal".
      Meal Data: Calories: ${mealData['calories']}, P: ${mealData['protein']}g, C: ${mealData['carbs']}g, F: ${mealData['fat']}g.

      Write a single, encouraging sentence (under 20 words) positively framing how this meal impacts their goal.
    """;

    _log("Meal Insight Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim();
    } catch (e) {
      debugPrint("Meal Insight Error: $e");
      return null;
    }
  }

  Future<String?> generateNutritionInsight({
    required List<NutritionLog> nutritionData,
    required UserProfile profile,
  }) async {
    final model = await _getModel();
    if (model == null) return null;

    final nutritionBlob = jsonEncode(nutritionData.map((n) {
      final log = n as dynamic;
      return {
        'date': n.date.toIso8601String(),
        'calories': n.totalCalories,
        'macros': n.totalMacros,
        'notes': log.notes ?? '', // Fix: Defensive property access
        'meals': n.meals.map((m) {
          final slot = m as dynamic;
          return {
            'mealType': slot.type.toString(), // Fix: Uses native enum toString
            'calories': slot.calories ?? 0,
            'summary': slot.toString(), // Provides meal contents if available
          };
        }).toList(),
      };
    }).toList());

    final prompt = """
      You are an expert nutrition coach with a light, honest, and encouraging tone. 
      Analyze the user's nutrition data for the last 7 days against their stated goals.

      **User Profile & Goals:**
      - Primary Goal: ${profile.primaryGoal}
      - Target Calories: ${profile.targetCalories ?? 2000}
      - Target Protein: ${profile.targetProtein ?? 0}g
      - Target Carbs: ${profile.targetCarbs ?? 0}g
      - Target Fat: ${profile.targetFat ?? 0}g

      **Your Task:**
      1. Analyze logged meals, paying special attention to any user notes (e.g. "felt bloated", "great energy").
      2. If the user consistently eats high-calorie or processed foods conflicting with goals, gently point this out.
      3. Identify patterns from notes (e.g. tiredness or satiety trends).
      4. If user is consistently over/under a target macro by 30-50g, suggest specific food replacements to bridge the gap.
      5. Provide one piece of positive reinforcement based on a good choice or note.
      6. Offer a single, actionable suggestion for a healthier alternative or habit.
      7. Keep the entire response positive but honest and under 200 words.

      **CRITICAL:** Respond with ONLY markdown. Bolded title on the first line. No headers like "###". 
      Ensure it looks human-formatted and contains no raw data characters like { or *.

      **Nutrition Data:** $nutritionBlob
    """;

    _log("Nutrition Insight Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim();
    } catch (e) {
      debugPrint("Nutrition Insight AI Error: $e");
      return null;
    }
  }

  //*********************************** Summary ************************************************ /

  Future<String?> generateSummaryInsight({
    required List<Workout> workoutData,
    required List<NutritionLog> nutritionData,
    required UserProfile profile,
    required bool isMonthly,
  }) async {
    final model = await _getModel();
    if (model == null) return null;

    final days = isMonthly ? 30 : 7;

    final workoutBlob = jsonEncode(workoutData
        .map((w) => {
              'date': w.date.toIso8601String(),
              'exercises': w.exercises.map((e) => e.name).toList(),
              'calories': w.caloriesBurned,
            })
        .toList());

    final nutritionBlob = jsonEncode(nutritionData
        .map((n) => {
              'date': n.date.toIso8601String(),
              'calories': n.totalCalories,
              'macros': n.totalMacros,
            })
        .toList());

    final prompt = """
      You are an expert fitness and nutrition coach. Analyze the data for the last $days days.
      User Goal: "${profile.primaryGoal}"

      **Analyze for patterns:**
      1. Performance Trend: Identify the most improved area.
      2. Milestone: Celebrate a consistency achievement.
      3. Nutrition Correlation: Link food intake to workout energy.
      4. Summary: General overview of the period.

      **CRITICAL:** Respond with ONLY user-facing markdown text.
      - Start with a bolded title on the first line.
      - Do NOT use headers like "###".
      - Ensure it looks like a human-formatted letter.
      - Do NOT include JSON curly braces or raw data characters.

      **Workouts:** $workoutBlob
      **Nutrition:** $nutritionBlob
    """;

    _log("Summary AI Prompt", prompt);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Update Response", response.text ?? "EMPTY");
      return response.text?.trim();
    } catch (e) {
      debugPrint("Summary Generation Error: $e");
      return null;
    }
  }

  //*********************************** Helpers ************************************************ /

  Future<Map<String, double>?> suggestGoals(UserProfile profile) async {
    final model = await _getModel();
    if (model == null) return null;

    final weightKg = profile.weight?.unit == "lbs"
        ? (profile.weight?.value ?? 0) * 0.453592
        : (profile.weight?.value ?? 0);
    final heightCm = profile.height?.value ?? 0;

    final prompt = """
      ${_buildSystemInstruction('nutritionist')}
      You are an expert nutritionist following a strict calculation protocol.

      **USER DATA:**
      - Goal: ${profile.primaryGoal}
      - Biological Sex: ${profile.biologicalSex}
      - Weight: ${weightKg.toStringAsFixed(2)} kg
      - Height: ${heightCm.toStringAsFixed(2)} cm
      - Age: ${profile.birthDate ?? 25}
      - Proficiency: ${profile.fitnessProficiency}
      - Activity: "${profile.activityLevel}"
      - Exercise Days/Week: ${profile.exerciseDaysPerWeek}
      - Preference: ${profile.prefersLowCarb ? "Low-Carb" : "Standard"}
      - Loss Goal: ${profile.weeklyWeightLossGoal} lbs/week

      **PROTOCOL:**
      1. BMR (Mifflin-St Jeor): 
         - Male: (10 * kg) + (6.25 * cm) - (5 * age) + 5
         - Female: (10 * kg) + (6.25 * cm) - (5 * age) - 161
      2. TDEE: BMR * Multiplier (Sedentary: 1.2, Lightly: 1.375, Mod: 1.55, Very: 1.725).
      3. Exercise Bonus: (Days * [Beginner:300, Int:400, Adv:500]) / 7.
      4. Adjust for Goal: Lose (-500 to -1000 deficit), Gain (+350 surplus), Maintain (0).
      5. Macros: Protein = kg * 1.8. Fat = 25% of calories. Carbs = Remaining.

      **CRITICAL:** You are FORBIDDEN from including any conversational text, pleasantries, or markdown other than the JSON itself. 
      **OUTPUT:** Respond ONLY with a raw JSON object:
      {"targetCalories": 0, "targetProtein": 0, "targetCarbs": 0, "targetFat": 0}
    """;

    _log("Nutrition Suggestion Prompt", prompt); // 📍 Ensure correct label for debugging

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      _log("Raw Suggestion Response", response.text ?? "EMPTY"); // 📍 Log the "Chatty" response
      
      final cleanJson = _cleanJson(response.text ?? '{}');
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      // Determinism: Ensure all numeric values are cast to double for the Profile model
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      debugPrint("Nutrition Suggestion Error: $e");
      return null;
    }
  }

// 🛡️ SHIELD: Deterministic JSON Cleanup
  // Change: Logic to strip Markdown decorators and extract raw JSON.
  // Rationale: Direct SDK calls often wrap JSON in backticks, which breaks jsonDecode.
 // 🛡️ SHIELD: Surgical JSON Extraction
  // Change: Refactored to find the actual JSON boundaries within potentially chatty text.
  // Rationale: Handles cases where Gemini adds encouraging words before/after the JSON block.
  String _cleanJson(String text) {
    String cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    
    // Find the first '{' and last '}' to strip any surrounding chatter
    int firstBrace = cleaned.indexOf('{');
    int lastBrace = cleaned.lastIndexOf('}');
    
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return cleaned.substring(firstBrace, lastBrace + 1);
    }
    
    return cleaned;
  }

  // 🛡️ SHIELD: Centralized Role Definition
  // Change: Moves persona logic from index.ts to a single Dart helper.
  String _buildSystemInstruction(String role) {
    switch (role) {
      case 'nutritionist':
        return "You are an expert nutritionist and dietary coach with an encouraging tone.";
      case 'trainer':
        return "You are an expert personal trainer and fitness coach focusing on technique and safety.";
      default:
        return "You are a helpful fitness and health assistant.";
    }
  }

  // 🛡️ SHIELD: Standardized Context Blob
  // Change: Creates a consistent string of user data for every AI call.
  String _userDataBlob(UserProfile profile) {
    return """
    USER GOAL: ${profile.primaryGoal}
    UNIT SYSTEM: ${profile.unitSystem}
    BIO: ${profile.biologicalSex}, Activity: ${profile.activityLevel}
    """;
  }

  Future calculateMacrosFromCalories(double calories, UserProfile userProfile) async {}
}
