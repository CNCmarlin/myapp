import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:provider/provider.dart';

class EditWorkoutDayScreen extends StatefulWidget {
  // IT NOW ACCEPTS THE FULL PROGRAM OBJECT
  final WorkoutProgram program;

  const EditWorkoutDayScreen({
    super.key,
    required this.program,
  });

  @override
  State<EditWorkoutDayScreen> createState() => _EditWorkoutDayScreenState();
}

class _EditWorkoutDayScreenState extends State<EditWorkoutDayScreen> {
  late WorkoutProgram _program;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the state with the program passed from the previous screen
    _program = widget.program;
  }

  // NEW: This method handles the FINAL save to Firestore.
  Future<void> _confirmAndSaveChanges() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not save. User not found.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final firestoreService = FirestoreService();

    try {
      // If the program doesn't have an ID, it's new. Create it.
      if (_program.id.isEmpty) {
        final newProgramId = await firestoreService.createNewWorkoutProgram(
          userId,
          _program.name,
          _program.days.map((d) => d.dayName).toList(),
        );
        // We get the new ID back and update our local object.
        _program.id = newProgramId;
        // Now we update it with any exercises that were added.
        await firestoreService.updateWorkoutProgram(userId, _program);

        // Update the active program in the onboarding provider
        // ignore: use_build_context_synchronously
        Provider.of<OnboardingProvider>(context, listen: false)
            .updateActiveProgramId(newProgramId);
      } else {
        // If it already has an ID, just update it.
        await firestoreService.updateWorkoutProgram(userId, _program);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program Saved Successfully!')),
        );
        Navigator.of(context).pop(); // Go back after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving program: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onAddExercise(WorkoutDay day) {
    final exerciseNameController = TextEditingController();
    final setsRepsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciseNameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
              autofocus: true,
            ),
            TextField(
              controller: setsRepsController,
              decoration: const InputDecoration(labelText: 'Sets/Reps Target (e.g., 3x 8-10)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newExerciseName = exerciseNameController.text.trim();
              if (newExerciseName.isNotEmpty) {
                setState(() {
                  day.exercises.add(
                    Exercise(
                      name: newExerciseName,
                      programTarget: setsRepsController.text.trim(),
                      status: 'Incomplete',
                      sets: [],
                    ),
                  );
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  // NEW: Method to handle renaming a day.
  void _onRenameDay(WorkoutDay day) {
    final nameController = TextEditingController(text: day.dayName);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Rename Day'),
              content: TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Day Name (e.g., "Chest Day")'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty) {
                      setState(() {
                        day.dayName = newName;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Rename'),
                ),
              ],
            ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${_program.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            // The button now confirms and saves the program.
            onPressed: _isLoading ? null : _confirmAndSaveChanges,
            tooltip: 'Confirm and Save Program',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _program.days.length,
              itemBuilder: (context, index) {
                final day = _program.days[index];
                return _WorkoutDayCard(
                  day: day,
                  onAddExercise: () => _onAddExercise(day),
                  onRename: () => _onRenameDay(day),
                  onExerciseDeleted: (exerciseIndex) {
                    setState(() {
                      day.exercises.removeAt(exerciseIndex);
                    });
                  },
                );
              },
            ),
    );
  }
}

class _WorkoutDayCard extends StatelessWidget {
  final WorkoutDay day;
  final VoidCallback onAddExercise;
  final VoidCallback onRename;
  final ValueChanged<int> onExerciseDeleted;

  const _WorkoutDayCard({
    required this.day,
    required this.onAddExercise,
    required this.onRename,
    required this.onExerciseDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton( // NEW: Rename button for each day
          icon: const Icon(Icons.drive_file_rename_outline, size: 20),
          onPressed: onRename,
          tooltip: 'Rename Day',
        ),
        initiallyExpanded: true,
        children: [
          for (int i = 0; i < day.exercises.length; i++)
            ListTile(
              title: Text(day.exercises[i].name),
              subtitle: Text('Target: ${day.exercises[i].programTarget}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => onExerciseDeleted(i),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}