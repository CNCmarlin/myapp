import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/models/chat_message.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/workout_summary_screen.dart';
// FIX: Import the new shared widget
import 'package:myapp/widgets/shared_info_card.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

enum ActivePanel { none, program, progress }

class WorkoutLoggingScreen extends StatefulWidget {
  final String programId;
  final WorkoutDay day;

  const WorkoutLoggingScreen({
    super.key,
    required this.programId,
    required this.day,
  });

  @override
  State<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends State<WorkoutLoggingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Workout? _sessionWorkout;
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();
  final Set<String> _selectedExerciseNames = {};
  final Map<String, Exercise> _lastSessionData = {};
  final List<ChatMessage> _chatHistory = [];
  bool _isAiProcessing = false;
  ActivePanel _activePanel = ActivePanel.none;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _togglePanel(ActivePanel panel) {
    setState(() {
      _activePanel = (_activePanel == panel) ? ActivePanel.none : panel;
    });
  }

  Future<void> _initializeSession() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final today = DateTime.now();
    final existingWorkout =
        await _firestoreService.getInProgressWorkout(userId, today);
    if (existingWorkout != null) {
      setState(() {
        _sessionWorkout = existingWorkout;
        _isLoading = false;
      });
    } else {
      final newWorkout = Workout(
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
      await _firestoreService.saveInProgressWorkout(userId, newWorkout);
      setState(() {
        _sessionWorkout = newWorkout;
        _isLoading = false;
      });
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
    );
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

  void _toggleExerciseCompletionStatus(Exercise exercise) {
    setState(() {
      if (exercise.status == 'complete') {
        exercise.status = 'incomplete';
      } else {
        exercise.status = 'complete';
      }
    });
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId != null && _sessionWorkout != null) {
      _firestoreService.saveInProgressWorkout(userId, _sessionWorkout!);
    }
  }

  Future<void> _submitToAi() async {
    final userInput = _textController.text.trim();
    if (userInput.isEmpty || _isAiProcessing) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isAiProcessing = true;
      _chatHistory.add(ChatMessage(text: userInput, isUser: true));
    });

    final aiService = AIService();
    _textController.clear();
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      setState(() => _isAiProcessing = false);
      return;
    }

    final update = await aiService.processUserInput(userInput, _sessionWorkout!,
        chatHistory: _chatHistory);

    if (update != null && update.updatedWorkout != null) {
      _sessionWorkout = update.updatedWorkout;

      Exercise? updatedExercise;
      for (var ex in _sessionWorkout!.exercises) {
        if (update.responseMessage
            .toLowerCase()
            .contains(ex.name.toLowerCase())) {
          updatedExercise = ex;
          break;
        }
      }

      if (updatedExercise != null) {
        int programmedSets = 0;
        final match =
            RegExp(r'(\d+)\s*x').firstMatch(updatedExercise.programTarget);
        if (match != null) {
          programmedSets = int.tryParse(match.group(1)!) ?? 0;
        }

        if (programmedSets > 0 &&
            updatedExercise.sets.length >= programmedSets) {
          updatedExercise.status = 'complete';
        }
      }

      await _firestoreService.saveInProgressWorkout(userId, _sessionWorkout!);
      _chatHistory.add(ChatMessage(text: update.responseMessage, isUser: false));
    } else if (update != null) {
      _chatHistory.add(ChatMessage(text: update.responseMessage, isUser: false));
    }
    else {
      _chatHistory.add(
          ChatMessage(text: 'Sorry, I had trouble processing that.', isUser: false));
    }

    setState(() => _isAiProcessing = false);
  }

  Future<void> _toggleExerciseSelection(String exerciseName) async {
    setState(() {
      if (_selectedExerciseNames.contains(exerciseName)) {
        _selectedExerciseNames.remove(exerciseName);
      } else {
        _selectedExerciseNames.add(exerciseName);
        _fetchPreviousLogFor(exerciseName);
      }
    });
  }

  Future<void> _fetchPreviousLogFor(String exerciseName) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;
    final previousLog =
        await _firestoreService.getPreviousExerciseLog(userId, exerciseName);
    if (mounted && previousLog != null) {
      setState(() {
        _lastSessionData[exerciseName] = previousLog;
      });
    }
  }

  Future<void> _showEditNoteDialog(Exercise exercise, int setIndex) async {
    if (setIndex >= exercise.sets.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log the set before adding a note.')),
      );
      return;
    }
    final noteController =
        TextEditingController(text: exercise.sets[setIndex].notes);

    final String? newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note for Set ${setIndex + 1}'),
        content: TextField(
          controller: noteController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Your notes...'),
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
      setState(() {
        exercise.sets[setIndex].notes = newNote;
      });
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null && _sessionWorkout != null) {
        await _firestoreService.saveInProgressWorkout(userId, _sessionWorkout!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (_isLoading || _sessionWorkout == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Logging: ${_sessionWorkout!.name}'),
        actions: [
          TextButton(onPressed: _finishWorkout, child: const Text('FINISH'))
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildChatHistory()),
              // Reserve space for the bottom command center
              const SizedBox(height: 120),
            ],
          ),
          if (!isKeyboardVisible)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, -1.2), end: Offset.zero)
                      .animate(animation),
                  child: child,
                );
              },
              child: _buildActivePanel(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomCommandCenter(),
    );
  }

  Widget _buildBottomCommandCenter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlChips(),
          const SizedBox(height: 8),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatHistory() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    double topPadding =
        (_activePanel != ActivePanel.none && !isKeyboardVisible)
            ? MediaQuery.of(context).size.height * 0.45
            : 8.0;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(8, topPadding, 8, 8),
      reverse: true,
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory.reversed.toList()[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            enabled: !_isAiProcessing,
            decoration: InputDecoration(
              hintText:
                  _isAiProcessing ? 'Processing...' : 'e.g., "135 x 8 incline"',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => _submitToAi(),
          ),
        ),
        const SizedBox(width: 8),
        _isAiProcessing
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator())
            : IconButton(icon: const Icon(Icons.send), onPressed: _submitToAi),
      ],
    );
  }

  Widget _buildControlChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ActionChip(
          label: const Text("View Program"),
          avatar: const Icon(Icons.description_outlined, size: 18),
          onPressed: () => _togglePanel(ActivePanel.program),
          backgroundColor: _activePanel == ActivePanel.program
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
        const SizedBox(width: 8),
        ActionChip(
          label: const Text("View Progress"),
          avatar: const Icon(Icons.checklist_rtl, size: 18),
          onPressed: () => _togglePanel(ActivePanel.progress),
          backgroundColor: _activePanel == ActivePanel.progress
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
      ],
    );
  }

  Widget _buildActivePanel() {
    switch (_activePanel) {
      case ActivePanel.program:
        return _buildProgramPanel();
      case ActivePanel.progress:
        return _buildProgressPanel();
      case ActivePanel.none:
      return Container(key: const ValueKey('none'));
    }
  }

  Widget _buildProgramPanel() {
    return Align(
      key: const ValueKey('program'),
      alignment: Alignment.topCenter,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  child: Row(
                    children: const [
                      SizedBox(width: 48, child: Text('DONE?')),
                      Expanded(child: Text('EXERCISE')),
                      SizedBox(
                          width: 48, child: Center(child: Text('VIEW'))),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _sessionWorkout!.exercises.map((exercise) {
                      final isSelected =
                          _selectedExerciseNames.contains(exercise.name);
                      final isComplete = exercise.status == 'complete';
                      return Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Checkbox(
                              value: isComplete,
                              onChanged: (bool? value) {
                                _toggleExerciseCompletionStatus(exercise);
                              },
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: TextStyle(
                                    decoration: isComplete
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isComplete ? Colors.grey : null,
                                  ),
                                ),
                                Text(
                                  'Target: ${exercise.programTarget}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              icon: Icon(
                                isSelected
                                    ? Icons.visibility
                                    : Icons.visibility_outlined,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              tooltip: 'View Progress',
                              onPressed: () =>
                                  _toggleExerciseSelection(exercise.name),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIX: This entire method is refactored to use the new SharedInfoCard
  Widget _buildProgressPanel() {
    if (_selectedExerciseNames.isEmpty) {
      return Align(
        key: const ValueKey('progress_empty'),
        alignment: Alignment.topCenter,
        child: Card(
          margin: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: const Text(
              'Select an exercise from the "View Program" panel to see its progress.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final selectedExercises = _sessionWorkout!.exercises
        .where((ex) => _selectedExerciseNames.contains(ex.name))
        .toList();

    return Align(
      key: const ValueKey('progress'),
      alignment: Alignment.topCenter,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: selectedExercises.length,
            itemBuilder: (context, index) {
              final exercise = selectedExercises[index];
              return SharedInfoCard(
                // Use a simple title and subtitle for the card.
                title: exercise.name,
                subtitle: 'Target: ${exercise.programTarget}',
                // The expandable content is the detailed progress table.
                expandableContent: _buildExerciseProgressTable(exercise),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // FIX: Extracted the progress table logic into a helper method.
  Widget _buildExerciseProgressTable(Exercise exercise) {
    final lastSession = _lastSessionData[exercise.name];
    int programmedSets = 0;
    final match = RegExp(r'(\d+)\s*x').firstMatch(exercise.programTarget);
    if (match != null) {
      programmedSets = int.tryParse(match.group(1)!) ?? 0;
    }
    int totalRows = max(programmedSets, exercise.sets.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
          child: Row(
            children: const [
              SizedBox(width: 40, child: Text('Set')),
              SizedBox(width: 90, child: Text("Today's Log")),
              SizedBox(width: 90, child: Text('Last Time')),
              Expanded(child: Text('Notes')),
            ],
          ),
        ),
        const Divider(),
        ...List.generate(totalRows, (rowIndex) {
          final loggedSet = (rowIndex < exercise.sets.length)
              ? exercise.sets[rowIndex]
              : null;
          final lastSet = (lastSession != null &&
                  rowIndex < lastSession.sets.length)
              ? lastSession.sets[rowIndex]
              : null;
          final todaysLogWidget = loggedSet != null
              ? Text(
                  '${loggedSet.weight.toStringAsFixed(0)} x ${loggedSet.reps}')
              : const Text('---',
                  style: TextStyle(color: Colors.grey));
          final lastTimeLog = lastSet != null
              ? '${lastSet.weight.toStringAsFixed(0)} x ${lastSet.reps}'
              : 'N/A';
          final noteText = loggedSet?.notes ?? '---';
          return InkWell(
            onTap: () => _showEditNoteDialog(exercise, rowIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.grey.shade200, width: 1)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('${rowIndex + 1}')),
                  SizedBox(width: 90, child: todaysLogWidget),
                  SizedBox(width: 90, child: Text(lastTimeLog)),
                  Expanded(
                    child: Text(
                      noteText,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}