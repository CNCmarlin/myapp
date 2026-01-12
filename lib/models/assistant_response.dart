// lib/models/assistant_response.dart

import '../models/workout_data.dart';
import '../utils/data_casting.dart'; // NEW IMPORT

enum AssistantResponseType { text, program }

class AssistantResponse {
  final AssistantResponseType type;
  final String? textResponse;
  final WorkoutProgram? programResponse;

  AssistantResponse({
    required this.type,
    this.textResponse,
    this.programResponse,
  });

  factory AssistantResponse.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String?;
    // Use deepCast on the entire data payload immediately.
    final data = deepCast(map['data']);

    switch (typeStr) {
      case 'program':
        return AssistantResponse(
          type: AssistantResponseType.program,
          programResponse: WorkoutProgram.fromMap(data as Map<String, dynamic>),
        );
      case 'text':
      default:
        return AssistantResponse(
          type: AssistantResponseType.text,
          textResponse: data as String? ?? "Sorry, I couldn't process that.",
        );
    }
  }
}
