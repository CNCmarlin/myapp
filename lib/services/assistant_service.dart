import 'package:cloud_functions/cloud_functions.dart';

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
}