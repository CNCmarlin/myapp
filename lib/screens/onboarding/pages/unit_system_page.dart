// lib/screens/onboarding/pages/unit_system_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';

class UnitSystemPage extends StatelessWidget {
  const UnitSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choose your preferred units',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                      value: 'imperial', label: Text('US (lbs, ft)')),
                  ButtonSegment<String>(
                      value: 'metric', label: Text('Metric (kg, cm)')),
                ],
                selected: <String>{
                  provider.finalProfile.unitSystem ?? 'imperial'
                },
                onSelectionChanged: (Set<String> newSelection) {
                  provider.updateUnitSystem(newSelection.first);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}