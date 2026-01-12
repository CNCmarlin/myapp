// lib/screens/onboarding/pages/welcome_page.dart

import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Simply Fit!',
                style: textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text(
              'Simplifying your fitness and nutrition with personalized AI coaching, so you can focus on what matters: your results.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            const _FeatureHighlight(
              icon: Icons.auto_awesome,
              title: 'AI-Powered Coaching',
              subtitle: 'Get personalized workout and nutrition plans.',
            ),
            const _FeatureHighlight(
              icon: Icons.track_changes,
              title: 'Effortless Tracking',
              subtitle: 'Log meals and workouts with simple text commands.',
            ),
            const _FeatureHighlight(
              icon: Icons.insights,
              title: 'Actionable Insights',
              subtitle: 'Understand your progress with weekly summaries.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Let\'s get your profile set up to personalize your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureHighlight(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading:
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}