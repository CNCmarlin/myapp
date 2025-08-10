import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:provider/provider.dart';

class ProgramManagementScreen extends StatefulWidget {
  const ProgramManagementScreen({super.key});

  @override
  State<ProgramManagementScreen> createState() =>
      _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends State<ProgramManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<WorkoutProgram> _workoutPrograms = [];
  late List<bool> _isPanelExpanded;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPrograms();
  }

  Future<void> _loadWorkoutPrograms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final programs = await _firestoreService.getAllWorkoutPrograms(userId);
    if (mounted) {
      setState(() {
        _workoutPrograms = programs;
        // Initialize the expansion state for each panel to be collapsed.
        _isPanelExpanded = List.generate(programs.length, (_) => false);
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditDayNameDialog(
      String programId, int dayIndex, String currentName) async {
    final newNameController = TextEditingController(text: currentName);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Day'),
        content: TextField(
          controller: newNameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Day Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(newNameController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        // Show a loading indicator while saving
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saving...')));
        await _firestoreService.updateWorkoutDayName(
            userId, programId, dayIndex, newName);
        // Refresh the programs list to show the change
        await _loadWorkoutPrograms();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Programs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workoutPrograms.isEmpty
              ? const Center(child: Text('No workout programs found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpansionPanelList(
                    // This callback is triggered when a panel header is tapped.
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        _isPanelExpanded[index] = isExpanded;
                      });
                    },
                    children: _workoutPrograms
                        .asMap()
                        .entries
                        .map<ExpansionPanel>((entry) {
                      int programIndex = entry.key;
                      WorkoutProgram program = entry.value;

                      return ExpansionPanel(
                        isExpanded: _isPanelExpanded[programIndex],
                        // The header that is always visible.
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(program.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            // We can add program-level edit/delete buttons here later
                          );
                        },
                        // The content that is shown when the panel is expanded.
                        body: Column(
                          children:
                              program.days.asMap().entries.map((dayEntry) {
                            int dayIndex = dayEntry.key;
                            WorkoutDay day = dayEntry.value;

                            // --- REFINEMENT 1: Create a descriptive subtitle ---
                            String subtitleText;
                            if (day.exercises.isEmpty) {
                              subtitleText = 'No exercises yet';
                            } else {
                              // Map the exercise names and join them into a single string.
                              subtitleText =
                                  day.exercises.map((e) => e.name).join(', ');
                            }

                            return ListTile(
                              title: Text(day.dayName),
                              subtitle: Text(
                                subtitleText,
                                // --- REFINEMENT 2: Add overflow protection ---
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              // --- REFINEMENT 3: Replace IconButton with a PopupMenuButton ---
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'rename') {
                                    _showEditDayNameDialog(
                                        program.id, dayIndex, day.dayName);
                                  } else if (value == 'edit_exercises') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditWorkoutDayScreen(
                                          programId: program.id,
                                          dayIndex: dayIndex,
                                        ),
                                      ),
                                    );
                                    // Refresh list after editing exercises
                                    _loadWorkoutPrograms();
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'rename',
                                    child: Text('Rename Day'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'edit_exercises',
                                    child: Text('Edit Exercises'),
                                  ),
                                ],
                              ),
                              // We no longer need the main onTap, as the actions are in the menu.
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
