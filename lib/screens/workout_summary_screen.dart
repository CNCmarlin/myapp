import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/auth_service.dart';
import '../models/workout_data.dart';
import '../services/ai_service.dart';
import '../providers/user_profile_provider.dart';
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
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    // CORRECTED: Instantiate AIService here using the context
    _aiService = AIService(authService: context.read<AuthService>());
    _fetchInsights();
  }

  

  Future<void> _fetchInsights() async {
    // Get the user's profile from the provider
    final userProfile = context.read<UserProfileProvider>().userProfile;

    // If there's no profile, we can't get the correct units, so we stop.
    if (userProfile == null) {
      _aiInsights = "Could not generate summary because user profile was not found.";
      setState(() => _isLoadingInsights = false);
      return;
    }
    // Pass the userProfile object to the service
    final insights = await _aiService.getWorkoutInsights(
        widget.workout, widget.lastSessionData, userProfile);

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
        Text(
            'Start Time: ${DateFormat('h:mm a').format(widget.workout.startTime)}'),
        Text(
            'End Time: ${DateFormat('h:mm a').format(widget.workout.endTime)}'),
        Text('Duration: ${widget.workout.duration}'),
      ],
    );
  }

  // REFACTORED: This section now uses the custom table layout
  Widget _buildExerciseDetailsSection(BuildContext context) {
    // Fix: Added null safety for exercises and their nested sets
    final loggedExercises =
        widget.workout.exercises.where((e) => e.sets?.isNotEmpty ?? false).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises Logged:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
       ...loggedExercises.map((exercise) {
          // Fix: Handle nullable exercise name for map lookup
          final lastSession = widget.lastSessionData[exercise.name ?? ''];

          int programmedSets = 0;
          // Fix: Null safety for regex match on programTarget
          final match = RegExp(r'(\d+)\s*x').firstMatch(exercise.programTarget ?? '');
          if (match != null) {
            programmedSets = int.tryParse(match.group(1)!) ?? 0;
          }
          // Fix: Added null-aware access to sets length
          int totalRows = max(programmedSets, exercise.sets?.length ?? 0);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${exercise.name} (${exercise.programTarget})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DefaultTextStyle(
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.bold),
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
                    // Fix: Replaced ternary logic with explicit variable assignment to resolve parser ambiguity
                    ExerciseSet? loggedSet;
                    final currentSets = exercise.sets;
                    if (currentSets != null && rowIndex < currentSets.length) {
                      loggedSet = currentSets[rowIndex];
                    }

                    // Fix: Replaced historical ternary with explicit if-block for syntax stability
                    ExerciseSet? lastSet;
                    final previousSets = lastSession?.sets;
                    if (previousSets != null && rowIndex < previousSets.length) {
                      lastSet = previousSets[rowIndex];
                    }

                    final todaysLogWidget = loggedSet != null
                        ? Text(
                            '${(loggedSet.weight ?? 0).toStringAsFixed(0)} x ${loggedSet.reps ?? 0}') // Fix: Added fallbacks for nullable numeric fields
                        : const Text('---',
                            style: TextStyle(color: Colors.grey));
                    final lastTimeLog = lastSet != null
                        // Fix: Added null fallback for historical weight and reps fields
                        ? '${(lastSet.weight ?? 0).toStringAsFixed(0)} x ${lastSet.reps ?? 0}'
                        : 'N/A';
                    final noteText = loggedSet?.notes ?? '---';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 1)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('${rowIndex + 1}')),
                          SizedBox(width: 90, child: todaysLogWidget),
                          SizedBox(width: 90, child: Text(lastTimeLog)),
                          Expanded(
                            child: Text(
                              noteText,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
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
        }),
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
    final insights = parts.isNotEmpty
        ? parts[0].replaceFirst('Overall Session Insights:', '').trim()
        : '';
    final notes = parts.length > 1
        ? parts[1].replaceFirst('Performance Notes:', '').trim()
        : '';
    final recommendations = parts.length > 2
        ? parts[2].replaceFirst('Recommendations for Next Time:', '').trim()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.isNotEmpty) ...[
          Text('Overall Session Insights',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(insights),
          const SizedBox(height: 24),
        ],
        if (notes.isNotEmpty) ...[
          Text('Performance Notes',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(notes),
          const SizedBox(height: 24),
        ],
        if (recommendations.isNotEmpty) ...[
          Text('Recommendations for Next Time',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(recommendations),
        ],
        const SizedBox(height: 16),
        const Text(
          'AI-generated insights are for informational purposes only and are not a substitute for professional medical or fitness advice.',
          style: TextStyle(
              fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }
}
