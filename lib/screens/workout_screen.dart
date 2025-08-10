import 'package:flutter/material.dart';
import 'package:myapp/screens/program_management_screen.dart'; // Ensure this import uses your app's package name
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/user_profile_provider.dart'; // Ensure 'myapp' is your project's package name
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/widgets/workout_day_view.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

// In lib/screens/workout_screen.dart

// In lib/screens/workout_screen.dart

class _WorkoutScreenState extends State<WorkoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  WorkoutProgram? _activeProgram;

  // The local _isLoading flag has been removed.

  @override
  void initState() {
    super.initState();
    // We can remove the initial fetch call as the build method now handles it.
  }

  // Simplified fetch method - it no longer needs to manage isLoading.
  Future<void> _fetchProgramDetails(String programId) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final program = await _firestoreService.getWorkoutProgramById(userId, programId);
    if (mounted) {
      setState(() {
        _activeProgram = program;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final activeProgramId = profileProvider.activeProgramId;

    // State 1: The UserProfile itself is loading.
    if (profileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // State 2: Profile is loaded, but no active program is set.
    if (activeProgramId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Please select an active program in your Profile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // State 3: We have an active program ID, but the program details are not yet loaded
    // or they don't match the active ID.
    if (_activeProgram?.id != activeProgramId) {
      // Trigger the fetch to get the correct program details.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchProgramDetails(activeProgramId);
      });
      // Show a loading indicator while the fetch is in progress.
      return const Center(child: CircularProgressIndicator());
    }

    // State 4: Everything is loaded and matches. Display the UI.
    return DefaultTabController(
      length: _activeProgram!.days.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_activeProgram!.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Manage Programs',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramManagementScreen()));
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: _activeProgram!.days.map((day) => Tab(text: day.dayName)).toList(),
          ),
        ),
        body: TabBarView(
          children: _activeProgram!.days.map((day) {
            return WorkoutDayView(
              day: day,
              programId: _activeProgram!.id,
            );
          }).toList(),
        ),
      ),
    );
  }
}