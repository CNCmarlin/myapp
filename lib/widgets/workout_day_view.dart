import 'package:flutter/material.dart';
import '../models/workout_data.dart'; // Adjust import path as necessary// Adjust import path as necessary
import '../screens/workout_logging_screen_basic.dart';

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (day.exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No exercises for this day yet.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Prevent nested scrolling
            itemCount: day.exercises.length,
            itemBuilder: (context, index) {
              final exercise = day.exercises[index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text('Target: ${exercise.programTarget}'),
              );
            },
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start This Workout'),
          onPressed: () {
            // UPDATED: Always navigate to the basic logger screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutLoggingScreenBasic(
                  programId: programId,
                  day: day,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
