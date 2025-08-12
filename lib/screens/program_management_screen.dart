import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:provider/provider.dart';

class ProgramManagementScreen extends StatefulWidget {
  const ProgramManagementScreen({super.key});

  @override
  State<ProgramManagementScreen> createState() => _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends State<ProgramManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<WorkoutProgram> _workoutPrograms = [];
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
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final programs = await _firestoreService.getAllWorkoutPrograms(userId);
    if (mounted) {
      setState(() {
        _workoutPrograms = programs;
        _isLoading = false;
      });
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
              ? const Center(child: Text('No workout programs found. Create one from your Profile page!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _workoutPrograms.length,
                  itemBuilder: (context, index) {
                    final program = _workoutPrograms[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                program.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              // This button now navigates to the fully-featured editor.
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Program',
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditWorkoutDayScreen(
                                        // FIX: Pass the entire program object, not just the ID.
                                        program: program,
                                      ),
                                    ),
                                  );
                                  // Refresh the list after editing.
                                  _loadWorkoutPrograms();
                                },
                              ),
                            ),
                            const Divider(),
                            // This simply lists the days in the program.
                            for (var day in program.days)
                              ListTile(
                                dense: true,
                                title: Text(day.dayName),
                                subtitle: Text(
                                  day.exercises.isEmpty
                                      ? 'No exercises yet'
                                      : day.exercises.map((e) => e.name).join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}