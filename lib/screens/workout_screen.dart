import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/screens/program_management_screen.dart';
import 'package:myapp/widgets/workout_day_view.dart';
import 'package:provider/provider.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = context.watch<UserProfileProvider>();

    if (userProfileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeProgramId = userProfileProvider.userProfile?.activeProgramId;
    if (activeProgramId == null) {
      return const _NoActiveProgramView();
    }

    final activeProgram = userProfileProvider.availablePrograms
        .cast<WorkoutProgram?>()
        .firstWhere(
          (p) => p?.id == activeProgramId,
          orElse: () => null,
        );

    if (activeProgram == null) {
      return const Center(
          child: Text(
              'Active program not found. Please select one in your profile.'));
    }

    return DefaultTabController(
      length: activeProgram.days.length,
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppBarTitle(context, activeProgram, userProfileProvider),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: const Text('Edit Program'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProgramManagementScreen()),
                ).then((_) {
                  context.read<UserProfileProvider>().refreshData();
                });
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: activeProgram.days
                .map((day) => Tab(text: day.dayName))
                .toList(),
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
  }

  Widget _buildAppBarTitle(BuildContext context, WorkoutProgram activeProgram,
      UserProfileProvider provider) {
    // Use a color that is guaranteed to be visible on the AppBar's surface.
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return DropdownButton<String>(
      value: activeProgram.id,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      icon: Icon(Icons.arrow_drop_down, color: textColor), // Use contrast color
      dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
      items: provider.availablePrograms.map((program) {
        return DropdownMenuItem(
          value: program.id,
          child: Text(
            program.name,
            style: TextStyle(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
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
  }
}

class _NoActiveProgramView extends StatelessWidget {
  const _NoActiveProgramView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Active Program',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please select an active program from your Profile screen to begin logging workouts.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
