import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/services/ai_service.dart';
//import '..provider/provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
//import 'package:myapp/models/user_profile.dart';
import 'package:provider/provider.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final Workout workout;
  final Map<String, Exercise?> lastSessionData;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.lastSessionData,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  bool _isLoadingInsights = true;
  String? _aiInsights;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
  // Get the user's profile from the provider
  final userProfile = context.read<UserProfileProvider>().userProfile;

  // If there's no profile, we can't get the correct units, so we stop.
  if (userProfile == null) {
    setState(() => _isLoadingInsights = false);
    return;
  }
  
  final aiService = AIService();
  // Pass the userProfile object to the service
  final insights = await aiService.getWorkoutInsights(widget.workout, widget.lastSessionData, userProfile);
  
  if (mounted) {
    setState(() {
      _aiInsights = insights;
      _isLoadingInsights = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false, // Prevents a back button
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('DONE'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogisticsSection(context),
            const SizedBox(height: 24),
            _buildExerciseDetailsSection(context),
            const SizedBox(height: 24),
            _buildAiInsightsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(widget.workout.date)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Start Time: ${DateFormat('h:mm a').format(widget.workout.startTime)}'),
        Text('End Time: ${DateFormat('h:mm a').format(widget.workout.endTime)}'),
        Text('Duration: ${widget.workout.duration}'),
      ],
    );
  }

  // REFACTORED: This section now uses the custom table layout
  Widget _buildExerciseDetailsSection(BuildContext context) {
    // Filter for exercises that were actually performed
    final loggedExercises = widget.workout.exercises.where((e) => e.sets.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises Logged:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...loggedExercises.map((exercise) {
          final lastSession = widget.lastSessionData[exercise.name];

          int programmedSets = 0;
          final match = RegExp(r'(\d+)\s*x').firstMatch(exercise.programTarget);
          if (match != null) {
            programmedSets = int.tryParse(match.group(1)!) ?? 0;
          }
          int totalRows = max(programmedSets, exercise.sets.length);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${exercise.name} (${exercise.programTarget})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
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
                    final loggedSet = (rowIndex < exercise.sets.length) ? exercise.sets[rowIndex] : null;
                    final lastSet = (lastSession != null && rowIndex < lastSession.sets.length) ? lastSession.sets[rowIndex] : null;
                    
                    final todaysLogWidget = loggedSet != null
                        ? Text('${loggedSet.weight.toStringAsFixed(0)} x ${loggedSet.reps}')
                        : const Text('---', style: TextStyle(color: Colors.grey));
                    final lastTimeLog = lastSet != null ? '${lastSet.weight.toStringAsFixed(0)} x ${lastSet.reps}' : 'N/A';
                    final noteText = loggedSet?.notes ?? '---';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('${rowIndex + 1}')),
                          SizedBox(width: 90, child: todaysLogWidget),
                          SizedBox(width: 90, child: Text(lastTimeLog)),
                          Expanded(
                            child: Text(
                              noteText,
                              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAiInsightsSection(BuildContext context) {
    if (_isLoadingInsights) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_aiInsights == null || _aiInsights!.isEmpty) {
      return const Center(child: Text('Could not generate AI insights.'));
    }
    // This assumes the AI response uses "---" as a separator.
    // Consider a more robust parsing method like JSON if the AI can provide it.
    final parts = _aiInsights!.split('---');
    final insights = parts.isNotEmpty ? parts[0].replaceFirst('Overall Session Insights:', '').trim() : '';
    final notes = parts.length > 1 ? parts[1].replaceFirst('Performance Notes:', '').trim() : '';
    final recommendations = parts.length > 2 ? parts[2].replaceFirst('Recommendations for Next Time:', '').trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.isNotEmpty) ...[
          Text('Overall Session Insights', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(insights),
          const SizedBox(height: 24),
        ],
        if (notes.isNotEmpty) ...[
          Text('Performance Notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(notes),
          const SizedBox(height: 24),
        ],
        if (recommendations.isNotEmpty) ...[
          Text('Recommendations for Next Time', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(recommendations),
        ],
        const SizedBox(height: 16),
        const Text(
          'AI-generated insights are for informational purposes only and are not a substitute for professional medical or fitness advice.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }
}