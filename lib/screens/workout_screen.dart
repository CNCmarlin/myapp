// lib/screens/workout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_data.dart';
import '../providers/user_profile_provider.dart';
import '../providers/workout_provider.dart';
import '../screens/program_management_screen.dart';
import '../widgets/workout_day_view.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = context.watch<UserProfileProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();

    if (userProfileProvider.isLoading || workoutProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeProgramId = userProfileProvider.userProfile?.activeProgramId;
    if (activeProgramId == null) {
      return _NoActiveProgramView();
    }

    final activeProgram = workoutProvider.programs.firstWhere(
      (p) => p.id == activeProgramId,
      orElse: () => WorkoutProgram(id: '', name: 'Not Found', days: []),
    );

    if (activeProgram.id.isEmpty) {
      return const Center(
          child: Text(
              'Active program not found. Please select one in your profile.'));
    }

    // UPDATED: The Scaffold is now the root widget to host the FloatingActionButton
    return Scaffold(
      body: Column(
        children: [
          _ActiveProgramCard(
            activeProgram: activeProgram,
            availablePrograms: workoutProvider.programs,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: activeProgram.days.length,
              itemBuilder: (context, index) {
                final day = activeProgram.days[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: ExpansionTile(
                    title: Text(day.dayName,
                        style: Theme.of(context).textTheme.titleLarge),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: WorkoutDayView(
                          day: day,
                          programId: activeProgram.id,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveProgramCard extends StatelessWidget {
  final WorkoutProgram activeProgram;
  final List<WorkoutProgram> availablePrograms;

  const _ActiveProgramCard({
    required this.activeProgram,
    required this.availablePrograms,
});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ACTIVE PROGRAM', style: TextStyle(color: Colors.grey)),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'manage') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramManagementScreen()));
                    }
                    if (value == 'create') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual program creation not implemented yet.')));
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'manage',
                      child: Text('Manage Programs'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'create',
                      child: Text('Create New Program'),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            DropdownButton<String>(
              value: activeProgram.id,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: availablePrograms.map((program) {
                return DropdownMenuItem(
                  value: program.id,
                  child: Text(
                    program.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newProgramId) {
                if (newProgramId != null) {
                  context.read<UserProfileProvider>().updateActiveProgram(newProgramId);
                }
              },
            ),
            // REMOVED the TextButton.icon for history from here
          ],
        ),
      ),
    );
  }
}

class _NoActiveProgramView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No Active Program', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Select a program from your Profile page to get started.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement manual program creation flow
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual program creation not implemented yet.')));
              },
              child: const Text('Create a New Program'),
            )
          ],
        ),
      ),
    );
  }
}