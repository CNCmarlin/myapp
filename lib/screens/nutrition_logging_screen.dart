import 'package:flutter/material.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/providers/nutrition_log_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/widgets/macro_indicator.dart';
import 'package:myapp/screens/manual_meal_entry_screen.dart';
import 'package:provider/provider.dart';

class NutritionLoggingScreen extends StatelessWidget {
  const NutritionLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid;
    final selectedDate = context.watch<DateProvider>().selectedDate;
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (userId == null) {
      return const Center(child: Text("Please sign in."));
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

class _NutritionLoggingView extends StatelessWidget {
  const _NutritionLoggingView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionLogProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (provider.isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

    return DefaultTabController(
      length: mealTypes.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: _DailySummaryCard(log: provider.log, profile: userProfile),
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                toolbarHeight: 140, // Height for the summary card area
                bottom: TabBar(
                  tabs: mealTypes.map((name) => Tab(text: name)).toList(),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: mealTypes.map((mealType) {
              final foodItems = provider.log?.meals[mealType] ?? [];
              final insight = provider.getInsightForMeal(mealType);
              return _MealListView(
                mealType: mealType,
                foodItems: foodItems,
                aiInsight: insight,
              );
            }).toList(),
          ),
        ),
        bottomNavigationBar: const _AiEntryBar(),
      ),
    );
  }
}

class _MealListView extends StatelessWidget {
  final String mealType;
  final List<FoodItem> foodItems;
  final String? aiInsight;

  const _MealListView({required this.mealType, required this.foodItems, this.aiInsight});

  void _addFoodItem(BuildContext context) async {
    final result = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (ctx) => const ManualMealEntryScreen()),
    );
    if (result != null && context.mounted) {
      context.read<NutritionLogProvider>().addFoodToMeal(mealType, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (foodItems.isEmpty && aiInsight == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No food logged for $mealType'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _addFoodItem(context),
              child: const Text('Add Food'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: foodItems.length + 2, // +1 for insight, +1 for add button
      itemBuilder: (context, index) {
        if (index == 0) {
          if (aiInsight != null) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple.shade300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiInsight!,
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.deepPurple.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        if (index == foodItems.length + 1) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => _addFoodItem(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Another Food'),
            ),
          );
        }

        final item = foodItems[index - 1];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(
              '${item.calories.toStringAsFixed(0)} kcal | P:${item.protein.toStringAsFixed(0)} C:${item.carbs.toStringAsFixed(0)} F:${item.fat.toStringAsFixed(0)}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<NutritionLogProvider>().removeFoodFromMeal(mealType, item);
            },
          ),
        );
      },
    );
  }
}

class _AiEntryBar extends StatefulWidget {
  const _AiEntryBar();
  @override
  State<_AiEntryBar> createState() => _AiEntryBarState();
}

class _AiEntryBarState extends State<_AiEntryBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _onAiSubmit() async {
    final provider = context.read<NutritionLogProvider>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    FocusScope.of(context).unfocus();
    final success = await provider.addMealFromText(text);

    if (mounted) {
      if (success) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Meal added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sorry, the AI couldn't understand that.")),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionLogProvider>();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      child: Row(
        children: [
          Expanded(child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Quick add with AI...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _onAiSubmit(),
          )),
          const SizedBox(width: 8),
          provider.isAnalyzing
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _onAiSubmit,
                ),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroColumn(
              context,
              'Calories',
              currentLog.totalCalories,
              targetCalories,
              Colors.blue,
              unit: '',
            ),
            _buildMacroColumn(
              context,
              'Protein',
              currentLog.totalMacros['protein'] ?? 0,
              targetProtein,
              Colors.red,
            ),
            _buildMacroColumn(
              context,
              'Carbs',
              currentLog.totalMacros['carbs'] ?? 0,
              targetCarbs,
              Colors.orange,
            ),
            _buildMacroColumn(
              context,
              'Fat',
              currentLog.totalMacros['fat'] ?? 0,
              targetFat,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroColumn(BuildContext context, String label, double value, double target, Color color, {String unit = 'g'}) {
    return Column(
      children: [
        MacroIndicator(
          label: label,
          value: value,
          target: target,
          color: color,
          unit: unit,
        ),
        const SizedBox(height: 4),
        Text(
          'Goal: ${target.toStringAsFixed(0)}$unit',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}