// lib/models/ai_workout_update.dart

import 'package:myapp/models/workout_data.dart'; // Adjust import based on your project structure

/// Represents the result of an AI workout analysis, including the updated workout
/// and a user-friendly response message.
class AIWorkoutUpdate {
  final Workout? updatedWorkout; // Make updatedWorkout nullable
  final String responseMessage;

  AIWorkoutUpdate({
    this.updatedWorkout, // Make updatedWorkout optional
    required this.responseMessage,
  });
}