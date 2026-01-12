// lib/screens/onboarding/pages/summary_page.dart

import 'package:flutter/material.dart';
import 'package:myapp/widgets/macro_indicator.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<OnboardingProvider>().finalProfile;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Onboarding Complete!',
            style:
                textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
            'Here is a summary of your new profile. You can change this information at any time.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vitals & Goal', style: textTheme.titleLarge),
                const Divider(),
                _SummaryTile(
                  icon: Icons.flag_outlined,
                  title: 'Primary Goal',
                  value: profile.primaryGoal ?? 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.trending_up,
                  title: 'Goal Weight',
                  value: profile.goalWeight != null
                      ? '${(profile.goalWeight!['value'] as num).toStringAsFixed(1)} ${profile.goalWeight!['unit']}'
                      : 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.person_outline,
                  title: 'Biological Sex',
                  value: profile.biologicalSex ?? 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Weight',
                  value: profile.weight != null
                      ? '${(profile.weight!['value'] as num).toStringAsFixed(1)} ${profile.weight!['unit']}'
                      : 'Not Set',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Plan', style: textTheme.titleLarge),
                const Divider(),
                _SummaryTile(
                  icon: Icons.fitness_center,
                  title: 'Fitness Level',
                  value: profile.fitnessProficiency ?? 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.directions_run,
                  title: 'Weekly Exercise',
                  value: '${profile.exerciseDaysPerWeek} days/week',
                ),
                _SummaryTile(
                  icon: Icons.work_outline,
                  title: 'Daily Activity',
                  value: profile.activityLevel ?? 'Not Set',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition Plan', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    'Low-Carb Preference: ${profile.prefersLowCarb ? "Yes" : "No"}',
                    style: textTheme.bodyMedium),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MacroIndicator(
                        label: 'Calories',
                        value: profile.targetCalories ?? 0,
                        target: profile.targetCalories ?? 2000,
                        color: Colors.blue,
                        showTarget: true),
                    MacroIndicator(
                        label: 'Protein',
                        value: profile.targetProtein ?? 0,
                        target: profile.targetProtein ?? 150,
                        color: Colors.red,
                        unit: 'g',
                        showTarget: true),
                    MacroIndicator(
                        label: 'Carbs',
                        value: profile.targetCarbs ?? 0,
                        target: profile.targetCarbs ?? 200,
                        color: Colors.orange,
                        unit: 'g',
                        showTarget: true),
                    MacroIndicator(
                        label: 'Fat',
                        value: profile.targetFat ?? 0,
                        target: profile.targetFat ?? 60,
                        color: Colors.purple,
                        unit: 'g',
                        showTarget: true),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing:
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
