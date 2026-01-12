// workout_logging_screen_basic.dart

import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/workout_summary_screen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class WorkoutLoggingScreenBasic extends StatefulWidget {
  final String programId;
  final WorkoutDay day;

  const WorkoutLoggingScreenBasic({
    super.key,
    required this.programId,
    required this.day,
  });

  @override
  State<WorkoutLoggingScreenBasic> createState() =>
      _WorkoutLoggingScreenBasicState();
}

class _WorkoutLoggingScreenBasicState extends State<WorkoutLoggingScreenBasic> {
  final FirestoreService _firestoreService = FirestoreService();
  Workout? _sessionWorkout;
  bool _isLoading = true;
  final Map<String, Exercise> _lastSessionData = {};

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final today = DateTime.now();
    Workout? existingWorkout =
        await _firestoreService.getInProgressWorkout(userId, today);

    if (existingWorkout == null) {
      existingWorkout = Workout(
        id: const Uuid().v4(),
        name: widget.day.dayName,
        date: today,
        startTime: today,
        endTime: today,
        duration: '0 mins',
        caloriesBurned: 0.0,
        exercises:
            widget.day.exercises.map((e) => e.copyWith(sets: [])).toList(),
      );
      await _firestoreService.saveInProgressWorkout(userId, existingWorkout);
    }

    for (var exercise in existingWorkout.exercises) {
      final prevLog =
          await _firestoreService.getPreviousExerciseLog(userId, exercise.name);
      if (prevLog != null) {
        _lastSessionData[exercise.name] = prevLog;
      }
    }

    if (mounted) {
      setState(() {
        _sessionWorkout = existingWorkout;
        _isLoading = false;
      });
    }
  }

  void _addSet(Exercise exercise) {
    setState(() {
      final lastSet = exercise.sets.isNotEmpty
          ? exercise.sets.last
          : ExerciseSet(id: const Uuid().v4(), weight: 0, reps: 0);
      exercise.sets.add(
        ExerciseSet(
            id: const Uuid().v4(), weight: lastSet.weight, reps: lastSet.reps),
      );
    });
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId != null && _sessionWorkout != null) {
      await _firestoreService.saveInProgressWorkout(userId, _sessionWorkout!);
    }
  }

  Future<void> _finishWorkout() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null || _sessionWorkout == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionWorkout!.startTime);

    final finishedWorkout = _sessionWorkout!.copyWith(
      endTime: endTime,
      duration: '${duration.inMinutes} mins',
      exercises:
          _sessionWorkout!.exercises.where((e) => e.sets.isNotEmpty).toList(),
    );

    if (finishedWorkout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot save an empty workout.")));
      return;
    }

    await _firestoreService.saveWorkoutLog(userId, finishedWorkout);
    await _firestoreService.deleteInProgressWorkout(
        userId, finishedWorkout.date);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSummaryScreen(
            workout: finishedWorkout,
            lastSessionData: _lastSessionData,
          ),
        ),
      );
    }
  }

  // NEW: Unified dialog for showing notes
  Future<void> _showEditNoteDialog({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final noteController = TextEditingController(text: initialValue);

    final String? newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: noteController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Your notes...'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(noteController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newNote != null) {
      onSave(newNote);
      _saveProgress(); // Save the entire workout whenever a note changes
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sessionWorkout == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionWorkout!.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _finishWorkout,
              child: const Text('FINISH'),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _sessionWorkout!.exercises.length,
        itemBuilder: (context, index) {
          final exercise = _sessionWorkout!.exercises[index];
          final lastSession = _lastSessionData[exercise.name];
          return _ExerciseCard(
            exercise: exercise,
            lastSession: lastSession,
            onSetAdded: () => _addSet(exercise),
            onSetChanged: _saveProgress,
            onExerciseNoteEdit: () => _showEditNoteDialog(
              title: 'Note for ${exercise.name}',
              initialValue: exercise.notes ?? '',
              onSave: (newNote) => setState(() => exercise.notes = newNote),
            ),
            onSetNoteEdit: (setIndex) => _showEditNoteDialog(
              title: 'Note for Set ${setIndex + 1}',
              initialValue: exercise.sets[setIndex].notes ?? '',
              onSave: (newNote) =>
                  setState(() => exercise.sets[setIndex].notes = newNote),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final Exercise? lastSession;
  final VoidCallback onSetAdded;
  final VoidCallback onSetChanged;
  final VoidCallback onExerciseNoteEdit; // NEW
  final ValueChanged<int> onSetNoteEdit; // NEW

  const _ExerciseCard({
    required this.exercise,
    this.lastSession,
    required this.onSetAdded,
    required this.onSetChanged,
    required this.onExerciseNoteEdit, // NEW
    required this.onSetNoteEdit, // NEW
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.exercise.programTarget.isNotEmpty)
                        Text(
                          'Target: ${widget.exercise.programTarget}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // NEW: Exercise note button
                IconButton(
                  icon: Icon(
                    widget.exercise.notes?.isNotEmpty ?? false
                        ? Icons.speaker_notes
                        : Icons.speaker_notes_off_outlined,
                  ),
                  tooltip: 'Add/Edit Exercise Note',
                  onPressed: widget.onExerciseNoteEdit,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSetTableHeader(),
            const Divider(),
            for (int i = 0; i < widget.exercise.sets.length; i++)
              _buildSetRow(i),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onSetAdded,
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTableHeader() {
    return DefaultTextStyle(
      style: Theme.of(context)
          .textTheme
          .bodySmall!
          .copyWith(fontWeight: FontWeight.bold),
      child: Row(
        children: const [
          SizedBox(width: 40, child: Text('Set')),
          Expanded(child: Center(child: Text('Last Time'))),
          Expanded(child: Center(child: Text('Weight'))),
          Expanded(child: Center(child: Text('Reps'))),
          SizedBox(width: 40, child: Center(child: Text('Note'))), // NEW
          SizedBox(width: 40, child: Center(child: Text('✔'))),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index) {
    final set = widget.exercise.sets[index];
    final lastSet = (widget.lastSession != null &&
            index < widget.lastSession!.sets.length)
        ? widget.lastSession!.sets[index]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 40, child: Center(child: Text('${index + 1}'))),
          Expanded(
            child: Center(
              child: Text(
                lastSet != null ? '${lastSet.weight} x ${lastSet.reps}' : '-',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: set.weight.toString(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
              onChanged: (value) {
                setState(() => set.weight = double.tryParse(value) ?? 0);
                widget.onSetChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: set.reps.toString(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
              onChanged: (value) {
                setState(() => set.reps = int.tryParse(value) ?? 0);
                widget.onSetChanged();
              },
            ),
          ),
          // NEW: Set note button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                set.notes?.isNotEmpty ?? false
                    ? Icons.comment
                    : Icons.add_comment_outlined,
                size: 18,
              ),
              onPressed: () => widget.onSetNoteEdit(index),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                setState(() => widget.exercise.sets.removeAt(index));
                widget.onSetChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}