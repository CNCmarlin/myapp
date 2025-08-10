// lib/screens/edit_workout_day_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_data.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';

class EditWorkoutDayScreen extends StatefulWidget {
  final String programId;
  final int dayIndex;

  const EditWorkoutDayScreen({
    super.key,
    required this.programId,
    required this.dayIndex,
  });

  @override
  State<EditWorkoutDayScreen> createState() => _EditWorkoutDayScreenState();
}

class _EditWorkoutDayScreenState extends State<EditWorkoutDayScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  List<Exercise> _exercisesForDay = [];
  String _dayName = '';

  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _setsRepsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // We must use a post-frame callback to safely access the context/provider
    // from within initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutProgram();
    });
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _setsRepsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutProgram() async {
    // 1. Get the real user ID from AuthService.
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. Fetch using the REAL userId.
    final program =
        await _firestoreService.getWorkoutProgramById(userId, widget.programId);

    if (mounted && program != null) {
      final workoutDay = program.days[widget.dayIndex];
      setState(() {
        _dayName = workoutDay.dayName;
        _exercisesForDay = List<Exercise>.from(workoutDay.exercises);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // The corrected _saveChanges method
  Future<void> _saveChanges() async {
    // 1. Get the real user ID from AuthService via Provider.
    final userId = context.read<AuthService>().currentUser?.uid;

    // 2. Add a guard clause in case the user is not logged in.
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: Could not save changes. User not found.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // 3. Call the firestoreService with the REAL userId.
    await _firestoreService.updateWorkoutDay(
        userId, widget.programId, widget.dayIndex, _exercisesForDay);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final Exercise item = _exercisesForDay.removeAt(oldIndex);
      _exercisesForDay.insert(newIndex, item);
    });
  }

  void _onDelete(int index) {
    setState(() {
      _exercisesForDay.removeAt(index);
    });
  }

  void _onAddExercise() {
    final newExerciseName = _exerciseNameController.text.trim();
    final newSetsReps = _setsRepsController.text.trim();
    if (newExerciseName.isNotEmpty) {
      setState(() {
        _exercisesForDay.add(
          Exercise(
            name: newExerciseName,
            programTarget: newSetsReps,
            status: 'Incomplete',
            sets: [],
          ),
        );
      });
      Navigator.of(context).pop();
      _exerciseNameController.clear();
      _setsRepsController.clear();
    }
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _exerciseNameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
              autofocus: true,
            ),
            TextField(
              controller: _setsRepsController,
              decoration: const InputDecoration(
                  labelText: 'Sets/Reps Target (e.g., 3x 8-10 reps)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _onAddExercise,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 3. Update the title to be dynamic.
        title: Text('Edit: $_dayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
            tooltip: 'Save Changes',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _exercisesForDay.length,
              itemBuilder: (context, index) {
                final exercise = _exercisesForDay[index];
                return Card(
                  key: ValueKey(exercise.name),
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('Target: ${exercise.programTarget}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _onDelete(index),
                    ),
                  ),
                );
              },
              onReorder: _onReorder,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
