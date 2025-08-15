import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:provider/provider.dart';

class EditWorkoutDayScreen extends StatefulWidget {
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
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _program = WorkoutProgram.fromMap(widget.program.toMap())..id = widget.program.id;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard & Leave'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  // --- FIXED: Restored the save logic ---
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
      if (_program.id.isEmpty) {
        // This logic is for creating a new program during onboarding
        final newProgramId = await firestoreService.createNewWorkoutProgram(
          userId,
          _program.name,
          _program.days.map((d) => d.dayName).toList(),
        );
        _program.id = newProgramId;
        await firestoreService.updateWorkoutProgram(userId, _program);
        
        // ignore: use_build_context_synchronously
        Provider.of<OnboardingProvider>(context, listen: false)
            .updateActiveProgramId(newProgramId);
      } else {
        // This logic is for updating an existing program
        await firestoreService.updateWorkoutProgram(userId, _program);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program Saved Successfully!')),
        );
        _hasUnsavedChanges = false; // Mark changes as saved
        Navigator.of(context).pop();
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
    _showEditExerciseDialog(day: day);
  }
  
  void _onEditExercise(WorkoutDay day, int exerciseIndex) {
    final exercise = day.exercises[exerciseIndex];
    _showEditExerciseDialog(day: day, exercise: exercise, exerciseIndex: exerciseIndex);
  }

  void _showEditExerciseDialog({required WorkoutDay day, Exercise? exercise, int? exerciseIndex}) {
    final isEditing = exercise != null;
    final exerciseNameController = TextEditingController(text: isEditing ? exercise.name : '');
    final setsRepsController = TextEditingController(text: isEditing ? exercise.programTarget : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Exercise' : 'Add New Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: exerciseNameController, decoration: const InputDecoration(labelText: 'Exercise Name'), autofocus: true),
            TextField(controller: setsRepsController, decoration: const InputDecoration(labelText: 'Sets/Reps Target (e.g., 3x 8-10)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newExerciseName = exerciseNameController.text.trim();
              if (newExerciseName.isNotEmpty) {
                setState(() {
                  _hasUnsavedChanges = true;
                  final updatedExercise = Exercise(
                    name: newExerciseName,
                    programTarget: setsRepsController.text.trim(),
                    status: 'Incomplete',
                    sets: isEditing ? exercise.sets : [],
                  );
                  if (isEditing && exerciseIndex != null) {
                    day.exercises[exerciseIndex] = updatedExercise;
                  } else {
                    day.exercises.add(updatedExercise);
                  }
                });
              }
              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

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
                        _hasUnsavedChanges = true;
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit: ${_program.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
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
                    onExerciseEdited: (exerciseIndex) => _onEditExercise(day, exerciseIndex),
                    onExerciseDeleted: (exerciseIndex) {
                      setState(() {
                        _hasUnsavedChanges = true;
                        day.exercises.removeAt(exerciseIndex);
                      });
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _WorkoutDayCard extends StatelessWidget {
  final WorkoutDay day;
  final VoidCallback onAddExercise;
  final VoidCallback onRename;
  final ValueChanged<int> onExerciseDeleted;
  final ValueChanged<int> onExerciseEdited;

  const _WorkoutDayCard({
    required this.day,
    required this.onAddExercise,
    required this.onRename,
    required this.onExerciseDeleted,
    required this.onExerciseEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    onPressed: () => onExerciseEdited(i),
                    tooltip: 'Edit Exercise',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => onExerciseDeleted(i),
                    tooltip: 'Delete Exercise',
                  ),
                ],
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