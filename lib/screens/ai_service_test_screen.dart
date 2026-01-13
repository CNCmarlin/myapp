// lib/screens/ai_service_test_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// CORRECTED: Added all necessary imports
import 'package:myapp/models/ai_workout_update.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/auth_service.dart';

import '../services/secure_storage_service.dart';

class AIServiceTestScreen extends StatefulWidget {
  const AIServiceTestScreen({super.key});

  @override
  State<AIServiceTestScreen> createState() => _AIServiceTestScreenState();
}

class _AIServiceTestScreenState extends State<AIServiceTestScreen> {
  late final AIService _aiService;
  String _responseText = 'Awaiting test...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the service exactly as we would in the real screen
    _aiService = AIService(secureStorage: context.read<SecureStorageService>());
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Running test...';
    });

    // --- Create dummy data that matches the function's requirements ---
    final dummyWorkout = Workout(
      id: 'test-workout',
      name: 'Test Day',
      date: DateTime.now(),
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: '0 mins',
      caloriesBurned: 0,
      exercises: [
        Exercise(
            name: 'Bench Press',
            programTarget: '3x5',
            sets: [],
            status: 'incomplete'),
      ],
    );
    const userInput = '135x5';
    // --- End of dummy data ---

    // --- DEBUG LOGGING ---
    final authService = context.read<AuthService>();
    if (kDebugMode) {
      print('[TEST SCREEN] Current User ID: ${authService.currentUser?.uid}');
    }
    if (authService.currentUser == null) {
      setState(() {
        _responseText = 'TEST FAILED: User is null before the call.';
        _isLoading = false;
      });
      return;
    }
    // --- END DEBUG LOGGING ---

    final AIWorkoutUpdate? result = await _aiService.processWorkoutUserInput(
      userInput,
      dummyWorkout,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _responseText =
              'SUCCESS!\n\nAI Response: "${result.responseMessage}"';
        } else {
          _responseText = 'TEST FAILED. See debug console for error details.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Authentication Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'This screen tests the AIService in isolation to diagnose the "UNAUTHENTICATED" error.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _runTest,
                icon: const Icon(Icons.bug_report),
                label: const Text('Run Authentication Test'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _responseText.startsWith('SUCCESS')
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Text(
                    _responseText,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}