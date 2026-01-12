// lib/screens/onboarding/pages/fitness_proficiency_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';

class FitnessProficiencyPage extends StatelessWidget {
  const FitnessProficiencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final proficiency = provider.finalProfile.fitnessProficiency;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('What is your fitness level?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'This helps the AI create a plan that\'s right for you.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Beginner'),
                subtitle: const Text('New to structured workouts'),
                leading: Radio<String>(
                  value: 'Beginner',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Beginner'),
              ),
              ListTile(
                title: const Text('Intermediate'),
                subtitle: const Text('Consistent with workouts for 6+ months'),
                leading: Radio<String>(
                  value: 'Intermediate',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Intermediate'),
              ),
              ListTile(
                title: const Text('Advanced'),
                subtitle: const Text('Multiple years of structured training'),
                leading: Radio<String>(
                  value: 'Advanced',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Advanced'),
              ),
            ],
          ),
        );
      },
    );
  }
}