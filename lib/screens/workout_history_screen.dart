// lib/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import '../models/workout_data.dart';


class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late Future<List<Workout>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

 void _loadHistory() {
    final storage = context.read<LocalStorageService>();
    _historyFuture = storage.getWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: FutureBuilder<List<Workout>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workout history.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No completed workouts found.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final workout = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(workout.name),
                  subtitle: Text('Duration: ${workout.duration}'),
                  trailing: Text(DateFormat.yMMMd().format(workout.date)),
                  onTap: () {
                    // Optional: Navigate to a detailed summary view of this workout
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}