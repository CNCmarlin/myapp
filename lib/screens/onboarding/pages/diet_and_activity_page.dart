// lib/screens/onboarding/pages/diet_and_activity_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';


class DietAndActivityPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const DietAndActivityPage({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final profile = provider.finalProfile;
        final bool isLosingWeight = profile.primaryGoal == 'Lose Weight';

        return Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Diet & Activity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Do you prefer a low-carb diet?'),
                  value: profile.prefersLowCarb,
                  onChanged: provider.updatePrefersLowCarb,
                ),
                if (isLosingWeight) ...[
                  const SizedBox(height: 24),
                  Text(
                    'What is your weekly weight loss goal?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Current Goal: ${profile.weeklyWeightLossGoal.toStringAsFixed(1)} lbs',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Slider(
                    value: profile.weeklyWeightLossGoal,
                    min: 0.5,
                    max: 2.0,
                    divisions: 3,
                    label:
                        '${profile.weeklyWeightLossGoal.toStringAsFixed(1)} lbs',
                    onChanged: provider.updateWeeklyWeightLossGoal,
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                    'Outside of planned exercise, how active is your daily life?'),
                FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'Sedentary',
                          'Lightly Active',
                          'Moderately Active',
                          'Very Active'
                        ].map((level) {
                          return ListTile(
                            title: Text(level),
                            leading: Radio<String>(
                              value: level,
                              groupValue: provider.finalProfile.activityLevel,
                              onChanged: (value) {
                                provider.updateActivityLevel(value!);
                                state.didChange(value);
                              },
                            ),
                            onTap: () {
                              provider.updateActivityLevel(level);
                              state.didChange(level);
                            },
                          );
                        }),
                        if (state.hasError)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          )
                      ],
                    );
                  },
                  validator: (value) =>
                      provider.finalProfile.activityLevel == null
                          ? 'Please select an activity level.'
                          : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}