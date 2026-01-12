// lib/screens/onboarding/pages/goal_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';

class GoalPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const GoalPage({super.key, required this.formKey});
  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final goal = provider.finalProfile.primaryGoal;
        return Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('What is your primary goal?',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                            title: const Text('Lose Weight'),
                            leading: Radio<String>(
                                value: 'Lose Weight',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Lose Weight');
                              state.didChange('Lose Weight');
                            }),
                        ListTile(
                            title: const Text('Gain Muscle'),
                            leading: Radio<String>(
                                value: 'Gain Muscle',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Gain Muscle');
                              state.didChange('Gain Muscle');
                            }),
                        ListTile(
                            title: const Text('Maintain Weight'),
                            leading: Radio<String>(
                                value: 'Maintain Weight',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Maintain Weight');
                              state.didChange('Maintain Weight');
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
                      provider.finalProfile.primaryGoal == null
                          ? 'Please select a goal.'
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