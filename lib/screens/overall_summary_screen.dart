// lib/screens/overall_summary_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_data.dart';
import '../models/meal_data.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';

class OverallSummaryScreen extends StatefulWidget {
  final DateTime selectedDate;
  const OverallSummaryScreen({super.key, required this.selectedDate});

  @override
  _OverallSummaryScreenState createState() => _OverallSummaryScreenState();
}

class _OverallSummaryScreenState extends State<OverallSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  Workout? _workoutLog;
  NutritionLog? _nutritionLog;

  @override
  void initState() {
    super.initState();
    _fetchDailyData();
 }

  Future<void> _fetchDailyData() async {
  setState(() => _isLoading = true);

  final userId = context.read<AuthService>().currentUser?.uid;
  if (userId == null) {
    if (mounted) setState(() => _isLoading = false);
    return;
  }
  
  final workout = await _firestoreService.getWorkoutLogByDate(userId, widget.selectedDate);
  final nutrition = await _firestoreService.getNutritionLog(userId, widget.selectedDate);

  if (mounted) {
    setState(() {
      _workoutLog = workout;
      _nutritionLog = nutrition;
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Daily Summary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
 padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary for: ${DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate)}', style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Key Daily Metrics Overview
                  Card(
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
 Text('Key Daily Metrics',
 style: Theme.of(context).textTheme.titleLarge!),
                          const SizedBox(height: 8),
                          Text(
 'Workout Duration: ${_workoutLog?.duration ?? 'N/A'}'),
                          Text(
 'Calories Burned: ${_workoutLog?.caloriesBurned.toStringAsFixed(0) ?? 'N/A'} kcal'),
                          const SizedBox(height: 8),
                          Text(
 'Total Calories Consumed: ${_nutritionLog?.totalCalories.toStringAsFixed(0) ?? 'N/A'} kcal'),
                          Text(
 'Protein Intake: ${_nutritionLog?.totalMacros['protein']?.toStringAsFixed(0) ?? 'N/A'} g'),
                          Text(
 'Carbs Intake: ${_nutritionLog?.totalMacros['carbs']?.toStringAsFixed(0) ?? 'N/A'} g'),
                          Text(
 'Fat Intake: ${_nutritionLog?.totalMacros['fat']?.toStringAsFixed(0) ?? 'N/A'} g'),
                          Text(
 'Water Intake: ${_nutritionLog?.waterIntake.toStringAsFixed(0) ?? 'N/A'} oz'),
                          Text(
                              'Low-Carb Day: ${_nutritionLog?.isLowCarbDay == true ? 'Yes' : _nutritionLog?.isLowCarbDay == false ? 'No' : 'N/A'}'),
                          Text(
                              'Hunger Rating: ${_nutritionLog?.hungerRating?.toString() ?? 'N/A'}'),
 ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Integrated Performance & Nutrition Insights (Placeholder)
                  Text('Integrated Performance & Nutrition Insights', style: Theme.of(context).textTheme.titleLarge!,),
                  const SizedBox(height: 8),
                  const Text(
                    'Analyze correlations between workout performance and nutrition intake.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),

                  // Overall Daily Recommendations & Focus for Tomorrow (Placeholder)
                  Text('Overall Daily Recommendations & Focus for Tomorrow',
                      style: Theme.of(context).textTheme.titleLarge!),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide actionable recommendations based on today\'s performance and nutrition.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }
}
