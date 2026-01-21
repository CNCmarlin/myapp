// workout_logging_screen_basic.dart

import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/auth_service.dart';

import 'package:myapp/screens/workout_summary_screen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../services/local_storage_service.dart';

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
 late final LocalStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = context.read<LocalStorageService>();
    _initializeSession();
  }

  Workout? _sessionWorkout;
  bool _isLoading = true;
  final Map<String, Exercise> _lastSessionData = {};

  Future<void> _initializeSession() async {
    final today = DateTime.now();
    Workout? existingWorkout = await _storageService.getInProgressWorkout(today);

    if (existingWorkout == null) {
      existingWorkout = Workout(
        id: const Uuid().v4(),
        name: widget.day.dayName ?? 'Unnamed Day', // Fix: Fallback for nullable dayName
        date: today,
        startTime: today,
        endTime: today,
        duration: '0 mins',
        caloriesBurned: 0.0,
        exercises:
            widget.day.exercises?.map((e) => e.copyWith(sets: [])).toList() ?? [], // Fix: Null-safe list mapping
      );
      await _storageService.saveInProgressWorkout(existingWorkout);
    }

    for (var exercise in existingWorkout.exercises) {
      final exerciseName = exercise.name ?? '';
      if (exerciseName.isEmpty) continue;

      final prevLog = await _storageService.getPreviousExerciseLog(exerciseName);
      if (prevLog != null) {
        _lastSessionData[exerciseName] = prevLog;
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
      // Fix: Initialize sets list if null and use null-safe checks for length/access
      exercise.sets ??= [];
      final lastSet = exercise.sets!.isNotEmpty
          ? exercise.sets!.last
          : ExerciseSet(id: const Uuid().v4(), weight: 0, reps: 0);
      
      exercise.sets!.add(
        ExerciseSet(
            id: const Uuid().v4(), 
            weight: lastSet.weight ?? 0, 
            reps: lastSet.reps ?? 0),
      );
    });
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (_sessionWorkout != null) {
      await _storageService.saveInProgressWorkout(_sessionWorkout!);
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
          // Fix: Added null-safe check for the sets list before checking for emptiness
          _sessionWorkout!.exercises.where((e) => e.sets?.isNotEmpty ?? false).toList(),
    );

    if (finishedWorkout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot save an empty workout.")));
      return;
    }

    await _storageService.saveWorkoutLog(finishedWorkout);
    await _storageService.deleteInProgressWorkout(finishedWorkout.date);

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
          // Fix: Handle nullable exercise name for map lookup
          final lastSession = _lastSessionData[exercise.name ?? ''];
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
              initialValue: exercise.sets?[setIndex].notes ?? '', // Change: Added null safety for sets list access
              onSave: (newNote) =>
                  setState(() => exercise.sets?[setIndex].notes = newNote), // Change: Added null safety for sets list assignment
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
                        // Fix: Added null fallback for nullable name field
                        widget.exercise.name ?? 'Unknown Exercise',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Fix: Added null safety for programTarget string check
                      if (widget.exercise.programTarget?.isNotEmpty ?? false)
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
                    widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty // Change: Simplified check to resolve non_bool_condition error
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
            for (int i = 0; i < (widget.exercise.sets?.length ?? 0); i++) // Change: Added null-aware length check for nullable sets list
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
    // Fix: Null-aware indexing for the current exercise sets
    final set = widget.exercise.sets?[index];
    if (set == null) return const SizedBox.shrink(); // Guard against index out of bounds or null list

    // Fix: Replaced complex ternary with explicit conditional logic to resolve non_bool_condition and parser errors
    ExerciseSet? lastSet;
    final lastSessionSets = widget.lastSession?.sets;
    if (lastSessionSets != null && index < lastSessionSets.length) {
      lastSet = lastSessionSets[index];
    }

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
          // NEW: Set note button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                // Fix: Access property on the 'set' variable with null safety
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
                // Fix: Null-safe removal from the sets list
                setState(() => widget.exercise.sets?.removeAt(index));
                widget.onSetChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}