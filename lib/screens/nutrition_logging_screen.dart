import 'package:flutter/material.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/providers/nutrition_log_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/auth_service.dart';
// FIX: Import the new shared widget
import 'package:myapp/widgets/shared_info_card.dart';
import 'package:provider/provider.dart';

class NutritionLoggingScreen extends StatelessWidget {
  const NutritionLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid;
    final selectedDate = context.watch<DateProvider>().selectedDate;
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in.")),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => NutritionLogProvider(
        userId: userId,
        date: selectedDate,
        userProfile: userProfile,
      ),
      child: const _NutritionLoggingView(),
    );
  }
}

class _NutritionLoggingView extends StatefulWidget {
  const _NutritionLoggingView();

  @override
  State<_NutritionLoggingView> createState() => _NutritionLoggingViewState();
}

class _NutritionLoggingViewState extends State<_NutritionLoggingView> {
  final TextEditingController _aiTextController = TextEditingController();

  @override
  void dispose() {
    _aiTextController.dispose();
    super.dispose();
  }

  Future<void> _onAiSubmit() async {
    final provider = context.read<NutritionLogProvider>();
    if (_aiTextController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    final success = await provider.addMealFromText(_aiTextController.text);

    if (mounted) {
      if (success) {
        _aiTextController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sorry, I couldn't understand that.")),
        );
      }
    }
  }

  void _showSecondaryDataDialog() {
    final provider = context.read<NutritionLogProvider>();
    final currentLog = provider.log ?? NutritionLog.empty();
    
    final waterController = TextEditingController(
        text: currentLog.waterIntake > 0
            ? currentLog.waterIntake.toStringAsFixed(0)
            : '');
    bool isLowCarb = currentLog.isLowCarbDay;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Log Additional Data'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: waterController,
                decoration:
                    const InputDecoration(labelText: 'Water Intake (oz)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Low-Carb Day?'),
                value: isLowCarb,
                onChanged: (value) => setDialogState(() => isLowCarb = value),
              ),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final waterValue = double.tryParse(waterController.text);
                  provider.updateSecondaryData(
                    water: waterValue,
                    isLowCarb: isLowCarb,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionLogProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _DailySummaryCard(
                        log: provider.log, profile: userProfile)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text('Logged Meals',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                if (provider.log?.meals.isEmpty ?? true)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No meals logged yet.")),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meal = provider.log!.meals[index];
                        // FIX: Replace the old _MealCard with the new SharedInfoCard
                        return SharedInfoCard(
                          title: meal.mealName,
                          subtitle: '${meal.calories.toStringAsFixed(0)} kcal | P:${meal.protein.toStringAsFixed(0)} C:${meal.carbs.toStringAsFixed(0)} F:${meal.fat.toStringAsFixed(0)}',
                          expandableContent: _buildMealDetails(context, meal),
                        );
                      },
                      childCount: provider.log!.meals.length,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(
            8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aiTextController,
                decoration: const InputDecoration(
                  labelText: 'Describe your meal...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _onAiSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            provider.isAnalyzing
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: _onAiSubmit,
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSecondaryDataDialog,
        tooltip: 'Log Water / Other',
        child: const Icon(Icons.add),
      ),
    );
  }

  // FIX: Extracted the expandable content into a helper method for clarity.
  Widget _buildMealDetails(BuildContext context, Meal meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...meal.foods.map((foodItem) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(foodItem.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '~${foodItem.calories.toStringAsFixed(0)} kcal | P:${foodItem.protein.toStringAsFixed(0)} C:${foodItem.carbs.toStringAsFixed(0)} F:${foodItem.fat.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }),
        if (meal.aiInsight != null && meal.aiInsight!.isNotEmpty) ...[
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: Colors.deepPurple.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meal.aiInsight!,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.deepPurple.shade400),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final NutritionLog? log;
  final UserProfile? profile;
  const _DailySummaryCard({required this.log, this.profile});

  @override
  Widget build(BuildContext context) {
    final currentLog = log ?? NutritionLog.empty();
    final targetCalories = profile?.targetCalories ?? 2500.0;
    final targetProtein = profile?.targetProtein ?? 180.0;
    final targetCarbs = profile?.targetCarbs ?? 300.0;
    final targetFat = profile?.targetFat ?? 70.0;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Totals', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroIndicator(
                    label: 'Calories',
                    value: currentLog.totalCalories,
                    target: targetCalories,
                    color: Colors.blue),
                _MacroIndicator(
                    label: 'Protein',
                    value: currentLog.totalMacros['protein'] ?? 0,
                    target: targetProtein,
                    color: Colors.red,
                    unit: 'g'),
                _MacroIndicator(
                    label: 'Carbs',
                    value: currentLog.totalMacros['carbs'] ?? 0,
                    target: targetCarbs,
                    color: Colors.orange,
                    unit: 'g'),
                _MacroIndicator(
                    label: 'Fat',
                    value: currentLog.totalMacros['fat'] ?? 0,
                    target: targetFat,
                    color: Colors.purple,
                    unit: 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// REMOVED: The old _MealCard widget is no longer needed.

class _MacroIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;

  const _MacroIndicator(
      {required this.label,
      required this.value,
      required this.target,
      required this.color,
      this.unit = ''});

  @override
  Widget build(BuildContext context) {
    final double progress = (target > 0) ? value / target : 0.0;
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  color: color),
              Center(
                  child: Text(value.toStringAsFixed(0),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('${label}${unit.isNotEmpty ? ' ($unit)' : ''}'),
      ],
    );
  }
}