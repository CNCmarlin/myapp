import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/assistant_response.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/workout_data.dart';
import '../models/meal_data.dart';
import '../services/secure_storage_service.dart';

class AssistantService {
  final SecureStorageService _secureStorage;
  final _uuid = const Uuid();

  String _cleanJson(String text) {
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  AssistantService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  void _log(String label, String content) {
    if (kDebugMode) {
      print("******** ASSISTANT DEBUG: $label ********");
      print(content);
      print("*****************************************");
    }
  }

  Future<WorkoutProgram?> generateAiWorkoutProgram({
    required String prompt,
    required String equipmentInfo,
    required UserProfile userProfile,
  }) async {
    final key = await _secureStorage.getGeminiKey();
    if (key == null || key.isEmpty) return null;

    final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: key);

    final finalPrompt = """
      You are an expert fitness coach creating a personalized workout program.

      **USER PROFILE:**
      - Goal: ${userProfile.primaryGoal}
      - Fitness Level: ${userProfile.fitnessProficiency ?? "Beginner"}
      - Exercise Days Per Week: ${userProfile.exerciseDaysPerWeek}

      **USER'S REQUEST:** "$prompt"
      **GROUND TRUTH EQUIPMENT:** ${userProfile.equipmentIds.join(', ')}

      **STRICT CONSTRAINTS:**
      1. ONLY use the equipment listed above. 
      2. If a requested exercise requires equipment NOT in the list, you MUST swap it for a functional equivalent using the available equipment.
      3. If the list above is "Bodyweight Only", do not suggest any weighted movements.

      **TASK:**
      1. Tailor exercise selection and volume to the user's **Fitness Level**:
         - **Beginner:** Compound movements, simple progressions.
         - **Intermediate:** More variety and isolation work.
         - **Advanced:** High work capacity; can include supersets.
      2. Create a functional name for each day (e.g., "Full Body A").
      3. Provide standard targets for each exercise (e.g., "3x 8-12 reps").

      **IMPORTANT:** Respond with ONLY a valid JSON object.
      {
        "id": "${_uuid.v4()}", 
        "name": "AI Program Name", 
        "days": [
          {"dayName": "Day 1: Upper Body", "exercises": [
            {"name": "Bench Press", "programTarget": "4x 8-10 reps", "status": "Incomplete", "sets": []}
          ]}
        ]
      }
    """;

    _log("Program Generation Prompt", finalPrompt);

    try {
      final response = await model.generateContent([Content.text(finalPrompt)]);
      _log("Raw AI Response", response.text ?? "EMPTY");
      
      final cleanJson = _cleanJson(response.text ?? '{}');

      // Surgical Intervention: Isar model mapping
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      return WorkoutProgram.fromMap(data);
    } catch (e) {
      debugPrint("Workout Generation Error: $e");
      return null;
    }
  }

  Future<AssistantResponse> getAssistantResponse({
    required String prompt,
    required List<ChatMessage> history,
    required UserProfile userProfile,
    Workout? lastWorkout,
    List<NutritionLog>? recentNutritionLogs,
  }) async {
    final key = await _secureStorage.getGeminiKey();
    if (key == null || key.isEmpty) {
      return AssistantResponse(
          type: AssistantResponseType.text,
          textResponse:
              "Please enter your Gemini API Key in the Profile tab to use the Assistant.");
    }

    // 🛡️ SHIELD: Context Optimization (Stage 4)
    // Change: Building the AI context locally rather than on a remote server.
    final systemInstruction = """
    You are Simply Fit AI.
    USER GOAL: ${userProfile.primaryGoal}
    USER BIO: ${userProfile.biologicalSex}, Activity: ${userProfile.activityLevel}.
    LAST WORKOUT: ${lastWorkout?.name ?? 'None'}
    """;

    final chatHistory = history.reversed
        .map((m) =>
            m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]))
        .toList();

    // 🛡️ SHIELD: Tool Definition (Ported from index.ts logic)
    // Change: Added Tools to the model to detect when a user wants a program vs advice.
    // 🛡️ SHIELD: Expert Persona Tools (Ported from index.ts Lines 118-145)
    // Change: Added advice tools and corrected Schema syntax.
    final tools = [
      Tool(functionDeclarations: [
        FunctionDeclaration(
          'generate_workout_program',
          'Generates a detailed, personalized workout program.',
          Schema.object(
            properties: {
              'prompt': Schema.string(description: 'The users request'),
              'equipmentInfo':
                  Schema.string(description: 'Available equipment'),
            },
            requiredProperties: ['prompt', 'equipmentInfo'],
          ),
        ),
        FunctionDeclaration(
          'get_fitness_advice',
          'Answers user questions about training, exercises, and fitness.',
          Schema.object(
            properties: {
              'question': Schema.string(description: 'The fitness question'),
            },
            requiredProperties: ['question'],
          ),
        ),
        FunctionDeclaration(
          'get_nutrition_advice',
          'Answers user questions about food, macros, and diet.',
          Schema.object(
            properties: {
              'question': Schema.string(description: 'The nutrition question'),
            }, 
            requiredProperties: ['question'],
          ),
        ),
        // 🛡️ SHIELD: Ported from index.ts (createNewWorkoutProgram tool)
        // Change: Added tool definition for creating skeleton programs.
        // Rationale: Completes the legacy aiAssistant port.
        FunctionDeclaration(
          'createNewWorkoutProgram',
          'Creates a new, empty workout program structure for the user to fill in.',
          Schema.object(
            properties: {
              'name': Schema.string(description: 'The name of the new program'),
              'days': Schema.number(description: 'Number of workout days to create'),
            }, 
            requiredProperties: ['name', 'days'],
          ),
        ),
      ])
    ];

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite', 
      apiKey: key,
      tools: tools,
    );

    final chat = model.startChat(history: chatHistory);

    try {
      // 🛡️ SHIELD: Intent Routing Logic
      // Change: Swapped simple generateContent for a chat session that supports Tools.
      final response = await chat.sendMessage(
          Content.text("$systemInstruction\n\nUser Request: $prompt"));

      final functionCall = response.functionCalls.firstOrNull;

      if (functionCall != null) {
        switch (functionCall.name) {
          case 'generate_workout_program':

            final generatedProgram = await generateAiWorkoutProgram(
              prompt: functionCall.args['prompt'] as String? ?? prompt,
              equipmentInfo: userProfile.equipmentIds.isNotEmpty 
                  ? userProfile.equipmentIds.join(', ') 
                  : 'Bodyweight Only',
              userProfile: userProfile,
            );
            return AssistantResponse(type: AssistantResponseType.program, programResponse: generatedProgram);

          case 'createNewWorkoutProgram':
            // 🛡️ SHIELD: Legacy aiAssistant Port
            // Change: Logic to build an empty skeleton program locally.
            // Rationale: Replaces server-side Firestore creation with local Isar-ready objects.
            final name = functionCall.args['name'] as String? ?? 'New Program';
            final daysCount = (functionCall.args['days'] as num?)?.toInt() ?? 3;
            
            final emptyProgram = WorkoutProgram(
              id: _uuid.v4(),
              name: name,
              days: List.generate(daysCount, (i) => WorkoutDay(
                dayName: 'Day ${i + 1}',
                exercises: [],
              )),
            );
            
            return AssistantResponse(
              type: AssistantResponseType.program, 
              programResponse: emptyProgram
            );

          case 'get_fitness_advice':
          case 'get_nutrition_advice':
            final question = functionCall.args['question'] as String? ?? prompt;
            final isNutrition = functionCall.name == 'get_nutrition_advice';

            final advicePrompt = """
              You are an expert ${isNutrition ? 'Nutritionist' : 'Personal Trainer'}. 
              Question: "$question". 
              Provide a clear, helpful, and encouraging answer in markdown.
            """;

            final adviceRes =
                await model.generateContent([Content.text(advicePrompt)]);
            return AssistantResponse(
                type: AssistantResponseType.text, textResponse: adviceRes.text);

          default:
            return AssistantResponse(
                type: AssistantResponseType.text, textResponse: response.text);
        }
      }
      return AssistantResponse(
        type: AssistantResponseType.text,
        textResponse: response.text ?? "I'm not sure how to respond to that.",
      );
    } catch (e) {
      debugPrint("Assistant Error: $e");
      return AssistantResponse(
          type: AssistantResponseType.text, textResponse: "AI Error: $e");
    }
  }
}
