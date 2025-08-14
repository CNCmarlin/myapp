import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/profile_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/screens/program_management_screen.dart';
import 'package:myapp/widgets/workout_day_view.dart';
import 'package:provider/provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Load available programs when the screen is initialized
    // Do not force refresh here, only when returning from ProgramManagementScreen
    context.read<ProfileProvider>().loadAvailablePrograms();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final activeProgramId = profileProvider.activeProgramId;

    if (profileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeProgramId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No Active Program',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select an active program from your Profile screen to begin logging workouts.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return FutureBuilder<WorkoutProgram?>(
      future: context.read<ProfileProvider>().getActiveProgramDetails(activeProgramId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Error loading workout program.'));
        }

        final activeProgram = snapshot.data!;

        return DefaultTabController(
          length: activeProgram.days.length,
          // FIX: The screen now returns its own Scaffold.
          child: Scaffold(
            appBar: AppBar(
              // The interactive AppBar logic now lives here, where it belongs.
              title: _buildAppBarTitle(context, activeProgram),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Edit Program'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProgramManagementScreen()),
                    ).then((_) {
                        // Force refresh the list of available programs when returning
                        context.read<ProfileProvider>().loadAvailablePrograms(forceRefresh: true);
                    });
                  },
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabs: activeProgram.days.map((day) => Tab(text: day.dayName)).toList(),
              ),
            ),
            body: TabBarView(
              children: activeProgram.days.map((day) {
                return WorkoutDayView(
                  day: day,
                  programId: activeProgram.id,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for the dropdown title in the AppBar
  Widget _buildAppBarTitle(BuildContext context, WorkoutProgram activeProgram) {
    return Consumer<ProfileProvider>(
      builder: (context, programsProvider, child) {
        return DropdownButton<String>(
          value: activeProgram.id,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
          items: programsProvider.availablePrograms.map((program) {
            return DropdownMenuItem(
              value: program.id,
              child: Text(
                program.name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newProgramId) {
            if (newProgramId != null) {
              context.read<UserProfileProvider>().updateActiveProgram(newProgramId);
            }
          },
        );
      },
    );
  }
}