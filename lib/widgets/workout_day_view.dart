import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart'; // Adjust import path as necessary
import 'package:myapp/screens/workout_logging_screen.dart'; // Adjust import path as necessary

class WorkoutDayView extends StatelessWidget {
  final WorkoutDay day;
  final String programId;

  const WorkoutDayView({
    super.key,
    required this.day,
    required this.programId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: day.exercises.length,
              itemBuilder: (context, index) {
                final exercise = day.exercises[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('Target: ${exercise.programTarget}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            // Inside workout_day_view.dart
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutLoggingScreen(
                    programId: programId,
                    day:
                        day, // CORRECT: Pass the 'day' object this widget holds
                  ),
                ),
              );
            },
            child: const Text("Start Today's Workout"),
          ),
        ],
      ),
    );
  }
}
