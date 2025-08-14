import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/profile_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/widgets/workout_day_view.dart';
//import 'package/myapp/widgets/workout_day_view.dart';
import 'package:provider/provider.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final activeProgramId = profileProvider.activeProgramId;

    if (profileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // FIX: This check now correctly handles the null case BEFORE the FutureBuilder.
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
              const SizedBox(height: 16),
              // Note: The user can navigate to the profile via the main bottom navigation bar.
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
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: activeProgram.days.map((day) => Tab(text: day.dayName)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: activeProgram.days.map((day) {
                    return WorkoutDayView(
                      day: day,
                      programId: activeProgram.id,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}