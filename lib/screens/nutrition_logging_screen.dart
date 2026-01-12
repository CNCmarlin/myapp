// lib/screens/nutrition_logging_screen.dart

import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import '../models/user_profile.dart';
import '../providers/nutrition_log_provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/manual_meal_entry_screen.dart';
import '../widgets/macro_indicator.dart';
import 'package:provider/provider.dart';

class NutritionLoggingScreen extends StatefulWidget {
  const NutritionLoggingScreen({super.key});

  @override
  State<NutritionLoggingScreen> createState() => _NutritionLoggingScreenState();
}

class _NutritionLoggingScreenState extends State<NutritionLoggingScreen> {
  final _textController = TextEditingController();

  void _addMealFromText(BuildContext context) {
    if (_textController.text.trim().isEmpty) return;
    context.read<NutritionLogProvider>().addMealFromText(_textController.text);
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _navigateAndAddFood(BuildContext context, String mealType) async {
    final provider = context.read<NutritionLogProvider>();
    final result = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualMealEntryScreen(),
      ),
    );

    if (result != null) {
      provider.addFoodToMeal(mealType, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<NutritionLogProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (nutritionProvider.isLoading || userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final log = nutritionProvider.log!;
    final mealTypes = log.meals.keys.toList();

    return DefaultTabController(
      length: mealTypes.length,
      child: Column(
        children: [
          _buildTotalsCard(log, userProfile),
          TabBar(
            isScrollable: true,
            tabs: mealTypes.map((type) => Tab(text: type)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: mealTypes.map((type) {
                return _buildMealList(
                  context,
                  type,
                  log.meals[type]!,
                  nutritionProvider,
                );
              }).toList(),
            ),
          ),
          _buildAiInputField(context, nutritionProvider.isAnalyzing),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(NutritionLog log, UserProfile profile) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            MacroIndicator(
              label: 'Calories',
              value: log.totalCalories,
              target: profile.targetCalories ?? 0,
              color: Colors.blue, // ADDED
            ),
            MacroIndicator(
              label: 'Protein',
              value: log.totalMacros['protein'] ?? 0,
              target: profile.targetProtein ?? 0,
              unit: 'g',
              color: Colors.red, // ADDED
            ),
            MacroIndicator(
              label: 'Carbs',
              value: log.totalMacros['carbs'] ?? 0,
              target: profile.targetCarbs ?? 0,
              unit: 'g',
              color: Colors.orange, // ADDED
            ),
            MacroIndicator(
              label: 'Fat',
              value: log.totalMacros['fat'] ?? 0,
              target: profile.targetFat ?? 0,
              unit: 'g',
              color: Colors.purple, // ADDED
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealList(
    BuildContext context,
    String mealType,
    List<FoodItem> foodItems,
    NutritionLogProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: foodItems.length + 1, // +1 for the "Add Food" button
      itemBuilder: (context, index) {
        if (index == foodItems.length) {
          return Center(
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Food Manually'),
              onPressed: () => _navigateAndAddFood(context, mealType),
            ),
          );
        }
        final item = foodItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(
              '${item.calories.toStringAsFixed(0)} kcal - P:${item.protein.toStringAsFixed(0)}g C:${item.carbs.toStringAsFixed(0)}g F:${item.fat.toStringAsFixed(0)}g'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => provider.removeFoodFromMeal(mealType, item),
          ),
        );
      },
    );
  }

  Widget _buildAiInputField(BuildContext context, bool isAnalyzing) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _textController,
            enabled: !isAnalyzing,
            decoration: InputDecoration(
              hintText: isAnalyzing
                  ? 'Analyzing...'
                  : 'Log a meal with AI (e.g., "protein shake and a banana")',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: isAnalyzing
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _addMealFromText(context),
                    ),
            ),
            onSubmitted: (_) => _addMealFromText(context),
          ),
        ),
      ),
    );
  }
}