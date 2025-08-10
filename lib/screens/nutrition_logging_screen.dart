import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:myapp/models/meal_data.dart';
import 'package:myapp/models/user_profile.dart';
//import 'package:myapp/providers/auth_service.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/meal_insight_service.dart';
import 'package:provider/provider.dart';

class NutritionLoggingScreen extends StatefulWidget {
  const NutritionLoggingScreen({super.key});
  @override
  NutritionLoggingScreenState createState() => NutritionLoggingScreenState();
}

class NutritionLoggingScreenState extends State<NutritionLoggingScreen> {
  DateTime? _previousDate;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  NutritionLog _currentLog = NutritionLog.empty();
  final TextEditingController _aiTextController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentDate = context.watch<DateProvider>().selectedDate;
    if (_previousDate == null || !isSameDay(currentDate, _previousDate!)) {
      _loadLogForDate(currentDate);
      _previousDate = currentDate;
    }
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _aiTextController.dispose();
    super.dispose();
  }

  Future<void> _loadLogForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final log = await _firestoreService.getNutritionLog(userId, date);
    if (mounted) {
      setState(() {
        _currentLog = log ?? NutritionLog.empty(date: date);
        _isLoading = false;
      });
    }
  }

  Future<void> _onAiSubmit() async {
    if (_aiTextController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isAnalyzing = true);
    final aiService = AIService();
    final meal = await aiService.getMealFromText(_aiTextController.text);
    if (mounted && meal != null) {
      _aiTextController.clear();
      _currentLog.meals.add(meal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added successfully!')),
      );
      await _saveLog();
      setState(() => _isAnalyzing = false);

      final userProfile = context.read<UserProfileProvider>().userProfile;
      if (userProfile != null) {
        final insightService = MealInsightService();
        final insightText = await insightService.generateInsight(
          userProfile: userProfile,
          meal: meal,
        );
        if (insightText != null && mounted) {
          final mealIndex = _currentLog.meals.indexOf(meal);
          if (mealIndex != -1) {
            _currentLog.meals[mealIndex].aiInsight = insightText;
            await _saveLog();
          }
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sorry, I couldn't understand that.")),
      );
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveLog() async {
  final userId = context.read<AuthService>().currentUser?.uid;
  if (userId == null) {
    print("Cannot save log, user not signed in.");
    return;
  }

  // Recalculate totals from the meals list before saving
  setState(() {
    _currentLog.recalculateTotals();
  });

  await _firestoreService.saveNutritionLog(userId, _currentLog);
}

  void _showSecondaryDataDialog() {
    final waterController = TextEditingController(
        text: _currentLog.waterIntake > 0
            ? _currentLog.waterIntake.toStringAsFixed(0)
            : '');
    bool isLowCarb = _currentLog.isLowCarbDay;

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
                  _currentLog.waterIntake =
                      double.tryParse(waterController.text) ??
                          _currentLog.waterIntake;
                  _currentLog.isLowCarbDay = isLowCarb;
                  _saveLog();
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
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _DailySummaryCard(
                        log: _currentLog, profile: userProfile)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text('Logged Meals',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                if (_currentLog.meals.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No meals logged yet.")),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meal = _currentLog.meals[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Card(
                            child: ExpansionTile(
                              title: Text(meal.mealName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${meal.calories.toStringAsFixed(0)} kcal | P:${meal.protein.toStringAsFixed(0)} C:${meal.carbs.toStringAsFixed(0)} F:${meal.fat.toStringAsFixed(0)}'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0)
                                      .copyWith(top: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // NEW: A Column to build the list of food items
                                      ...meal.foods.map((foodItem) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(foodItem.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                '~${foodItem.calories.toStringAsFixed(0)} kcal | P:${foodItem.protein.toStringAsFixed(0)} C:${foodItem.carbs.toStringAsFixed(0)} F:${foodItem.fat.toStringAsFixed(0)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),

                                      if (meal.aiInsight != null &&
                                          meal.aiInsight!.isNotEmpty) ...[
                                        const Divider(height: 24),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.auto_awesome,
                                                size: 18,
                                                color:
                                                    Colors.deepPurple.shade300),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                meal.aiInsight!,
                                                style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors
                                                        .deepPurple.shade400),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _currentLog.meals.length,
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
            _isAnalyzing
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
}

class _DailySummaryCard extends StatelessWidget {
  final NutritionLog log;
  final UserProfile? profile;
  const _DailySummaryCard({required this.log, this.profile});

  @override
  Widget build(BuildContext context) {
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
                    value: log.totalCalories,
                    target: targetCalories,
                    color: Colors.blue),
                _MacroIndicator(
                    label: 'Protein',
                    value: log.totalMacros['protein'] ?? 0,
                    target: targetProtein,
                    color: Colors.red,
                    unit: 'g'),
                _MacroIndicator(
                    label: 'Carbs',
                    value: log.totalMacros['carbs'] ?? 0,
                    target: targetCarbs,
                    color: Colors.orange,
                    unit: 'g'),
                _MacroIndicator(
                    label: 'Fat',
                    value: log.totalMacros['fat'] ?? 0,
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
