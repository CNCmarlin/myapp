// lib/screens/onboarding/pages/nutrition_goals_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/nutrition_goal_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';
import 'package:flutter/services.dart';

import '../../../services/ai_service.dart'; // Import for input formatters

class NutritionGoalsPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const NutritionGoalsPage({super.key, required this.formKey});

  @override
  State<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends State<NutritionGoalsPage> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  late bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OnboardingProvider>();
    _updateControllers(provider.finalProfile);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<OnboardingProvider>();
    _updateControllers(provider.finalProfile);
  }
  

  void _updateControllers(UserProfile profile) {
    _caloriesController.text = profile.targetCalories?.toStringAsFixed(0) ?? '';
    _proteinController.text = profile.targetProtein?.toStringAsFixed(0) ?? '';
    _carbsController.text = profile.targetCarbs?.toStringAsFixed(0) ?? '';
    _fatController.text = profile.targetFat?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _getAiSuggestions(bool fromCalories) async {
    setState(() => _isAiLoading = true);
    final provider = context.read<OnboardingProvider>();
    final service = NutritionGoalService(aiService: context.read<AIService>());

    Map<String, dynamic>? suggestions;

    if (fromCalories) {
      final calories = double.tryParse(_caloriesController.text);
      if (calories == null || calories == 0) {
        setState(() => _isAiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please enter a valid calorie target first.')));
        return;
      }
      suggestions =
          await service.getMacrosFromCalories(calories, provider.finalProfile);
    } else {
      suggestions = await service.suggestGoals(provider.finalProfile);
    }

    if (mounted && suggestions != null) {
      if (!fromCalories) {
        _caloriesController.text =
            (suggestions['targetCalories'] ?? 0).toString();
      }

      if (kDebugMode) {
        print("DEBUG: Suggestion received - ${suggestions.toString()}");
      }
      
      _proteinController.text = (suggestions['targetProtein'] ?? 0).toString();
      _carbsController.text = (suggestions['targetCarbs'] ?? 0).toString();
      _fatController.text = (suggestions['targetFat'] ?? 0).toString();

      provider.updateNutritionGoals(
        calories: double.tryParse(_caloriesController.text) ?? 0.0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
      );
    }
    setState(() => _isAiLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    String? macroValidator(String? value) {
      if (value == null || value.isEmpty) return 'Cannot be empty';
      if (double.tryParse(value) == null) return 'Invalid number';
      return null;
    }

    String? allMacrosValidator() {
      if ((double.tryParse(_caloriesController.text) ?? 0) == 0 &&
          (double.tryParse(_proteinController.text) ?? 0) == 0 &&
          (double.tryParse(_carbsController.text) ?? 0) == 0 &&
          (double.tryParse(_fatController.text) ?? 0) == 0) {
        return 'Please enter at least one macro goal or use an AI suggestion.';
      }
      return null;
    }

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Set Your Nutrition Goals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
                "Let's set your daily targets. You can enter your own or ask our AI for a personalized suggestion based on your profile."),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isAiLoading ? null : () => _getAiSuggestions(false),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Suggest Full Plan'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "These suggestions are for informational purposes only. Consult with a qualified health professional for medical advice.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Target Calories'),
                onChanged: (value) => provider.updateNutritionGoals(
                    calories: double.tryParse(value)),
                validator: (value) {
                  final zeroCheck = allMacrosValidator();
                  if (zeroCheck != null) return zeroCheck;
                  return macroValidator(value);
                }),
            const SizedBox(height: 16),
            if (_isAiLoading)
              const Center(child: CircularProgressIndicator())
            else
              TextButton.icon(
                onPressed: () => _getAiSuggestions(true),
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate Macros from Calories'),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width / 3) - 22,
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                    onChanged: (value) => provider.updateNutritionGoals(
                        protein: double.tryParse(value)),
                    validator: macroValidator,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width / 3) - 22,
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    onChanged: (value) => provider.updateNutritionGoals(
                        carbs: double.tryParse(value)),
                    validator: macroValidator,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width / 3) - 22,
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                    onChanged: (value) => provider.updateNutritionGoals(
                        fat: double.tryParse(value)),
                    validator: macroValidator,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}