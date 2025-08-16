import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/models/user_profile.dart';

class AssistantService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> sendMessage(String prompt) async {
    try {
      final callable = _functions.httpsCallable('aiAssistant');
      final result = await callable.call({'prompt': prompt});
      return result.data['responseText'] as String? ?? "Sorry, I didn't understand that.";
    } catch (e) {
      print("Error calling AI Assistant: $e");
      return "An error occurred while contacting the assistant.";
    }
  }

  // In lib/services/assistant_service.dart

  Future<WorkoutProgram?> generateProgram({
    required String prompt,
    required String equipmentInfo,
    required UserProfile userProfile, // NEW PARAMETER
  }) async {
    try {
      final callable = _functions.httpsCallable('generateAiWorkoutProgram');
      final result = await callable.call({
        'prompt': prompt,
        'equipmentInfo': equipmentInfo,
        'userProfile': userProfile.toMap(), // Pass the user profile data
      });

      if (result.data == null) return null;
      return WorkoutProgram.fromCloudFunction(result.data as Map<String, dynamic>);

    } on FirebaseFunctionsException catch (e) {
      print("Cloud Function Error (generateAiWorkoutProgram): ${e.code} ${e.message}");
      return null;
    } catch (e) {
      print("Error parsing AI program response: $e");
      return null;
    }
  }
}                                 