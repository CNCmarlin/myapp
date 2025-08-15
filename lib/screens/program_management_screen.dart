import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:provider/provider.dart';

class ProgramManagementScreen extends StatelessWidget {
  const ProgramManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume the provider to get the list of programs
    final userProfileProvider = context.watch<UserProfileProvider>();
    final workoutPrograms = userProfileProvider.availablePrograms;
    final isLoading = userProfileProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Programs'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workoutPrograms.isEmpty
              ? const Center(
                  child: Text('No workout programs found. Create one from your Profile page!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: workoutPrograms.length,
                  itemBuilder: (context, index) {
                    final program = workoutPrograms[index];
                    return _ProgramCard(program: program);
                  },
                ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  const _ProgramCard({required this.program});

  void _showRenameDialog(BuildContext context) {
    final textController = TextEditingController(text: program.name);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Program'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New program name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  context
                      .read<UserProfileProvider>()
                      .renameWorkoutProgram(program.id, newName);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Program?'),
          content: Text('Are you sure you want to delete "${program.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<UserProfileProvider>().deleteWorkoutProgram(program.id);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              subtitle: Text('${program.days.length} days'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Rename Program',
                    onPressed: () => _showRenameDialog(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    tooltip: 'Delete Program',
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Edit Days & Exercises'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditWorkoutDayScreen(program: program),
                        ),
                      ).then((_) {
                        // Refresh all data when returning
                        context.read<UserProfileProvider>().refreshData();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}