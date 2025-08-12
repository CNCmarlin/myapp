import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/assistant_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/nutrition_goal_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // FIX: Reordered the pages for a logical data collection flow.
  final List<Widget> _pages = [
    const _WelcomePage(),
    const _GoalPage(),
    const _UnitSystemPage(),
    const _BiometricsPage(),
    const _DietAndActivityPage(), // This now comes BEFORE nutrition goals
    const _CreateProgramPage(),   // This also comes BEFORE nutrition goals
    const _NutritionGoalsPage(),  // Now the AI has all the data it needs
    const _SummaryPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _completeOnboarding(BuildContext context) {
    final userProfileProvider = context.read<UserProfileProvider>();
    final authService = context.read<AuthService>();
    final String? userId = authService.currentUser?.uid;

    if (userId == null) {
      print("Error: No user is currently signed in. Cannot complete onboarding.");
      return;
    }

    final onboardingProvider = context.read<OnboardingProvider>();
    final finalProfile = onboardingProvider.finalProfile.copyWith(onboardingCompleted: true);
    userProfileProvider.updateUserProfile(userId, finalProfile);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Builder(
        builder: (BuildContext innerContext) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _pages,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: _previousPage,
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              _completeOnboarding(innerContext);
                            } else {
                              _nextPage();
                            }
                          },
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Complete Setup'
                                : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Page Widgets ---
// (The individual page widgets remain unchanged from your provided code)
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(
              'Let\'s get your profile set up to personalize your fitness journey.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage();
  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('What is your primary goal?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Lose Weight'),
                leading: Radio<String>(
                  value: 'Lose Weight',
                  groupValue: provider.finalProfile.primaryGoal,
                  onChanged: (value) {
                    if (value != null) provider.updatePrimaryGoal(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Gain Muscle'),
                leading: Radio<String>(
                  value: 'Gain Muscle',
                  groupValue: provider.finalProfile.primaryGoal,
                  onChanged: (value) {
                    if (value != null) provider.updatePrimaryGoal(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Maintain Weight'),
                leading: Radio<String>(
                  value: 'Maintain Weight',
                  groupValue: provider.finalProfile.primaryGoal,
                  onChanged: (value) {
                    if (value != null) provider.updatePrimaryGoal(value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitSystemPage extends StatelessWidget {
  const _UnitSystemPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choose your preferred units', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'imperial', label: Text('US (lbs, ft)')),
                  ButtonSegment<String>(value: 'metric', label: Text('Metric (kg, cm)')),
                ],
                selected: <String>{provider.finalProfile.unitSystem ?? 'imperial'},
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

class _BiometricsPage extends StatefulWidget {
  const _BiometricsPage();

  @override
  State<_BiometricsPage> createState() => _BiometricsPageState();
}

class _BiometricsPageState extends State<_BiometricsPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightPrimaryController = TextEditingController();
  final TextEditingController _heightSecondaryController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _heightPrimaryController.dispose();
    _heightSecondaryController.dispose();
    super.dispose();
  }

  void _updateImperialHeight(OnboardingProvider provider) {
    final double feet = double.tryParse(_heightPrimaryController.text) ?? 0;
    final double inches = double.tryParse(_heightSecondaryController.text) ?? 0;
    final double totalCm = (feet * 12 + inches) * 2.54;
    provider.updateHeight(totalCm, 'cm');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final bool isImperial = provider.finalProfile.unitSystem == 'imperial';
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tell us about yourself', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: provider.finalProfile.biologicalSex,
                decoration: const InputDecoration(labelText: 'Biological Sex', border: OutlineInputBorder()),
                items: ['Male', 'Female'].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                onChanged: (value) {
                  if (value != null) provider.updateBiologicalSex(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: isImperial ? 'Weight (lbs)' : 'Weight (kg)', border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final double? weight = double.tryParse(value);
                  if (weight != null) provider.updateWeight(weight, isImperial ? 'lbs' : 'kg');
                },
              ),
              const SizedBox(height: 16),
              if (isImperial)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightPrimaryController,
                        decoration: const InputDecoration(labelText: 'Height (ft)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateImperialHeight(provider),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _heightSecondaryController,
                        decoration: const InputDecoration(labelText: '(in)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateImperialHeight(provider),
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _heightPrimaryController,
                  decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final double? heightCm = double.tryParse(value);
                    if (heightCm != null) provider.updateHeight(heightCm, 'cm');
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DietAndActivityPage extends StatelessWidget {
  const _DietAndActivityPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final profile = provider.finalProfile;
        final bool isLosingWeight = profile.primaryGoal == 'Lose Weight';

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Diet & Activity',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'How many days per week do you plan to exercise?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: profile.exerciseDaysPerWeek.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              label: profile.exerciseDaysPerWeek.toString(),
              onChanged: (value) {
                provider.updateExerciseDaysPerWeek(value.toInt());
              },
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
              Slider(
                value: profile.weeklyWeightLossGoal,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                label: '${profile.weeklyWeightLossGoal.toStringAsFixed(1)} lbs',
                onChanged: provider.updateWeeklyWeightLossGoal,
              ),
            ],
            const SizedBox(height: 24),
            const Text('Outside of exercise, how active is your daily life?'),
            ...['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'].map((level) => ListTile(
              title: Text(level),
              leading: Radio<String>(
                value: level,
                groupValue: provider.finalProfile.activityLevel,
                onChanged: (value) {
                  if (value != null) provider.updateActivityLevel(value);
                },
              ),
            )),
          ],
        );
      },
    );
  }
}

class _NutritionGoalsPage extends StatefulWidget {
  const _NutritionGoalsPage();

  @override
  State<_NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends State<_NutritionGoalsPage> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  bool _isAiLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _getAiSuggestions() async {
    setState(() => _isAiLoading = true);
    final provider = context.read<OnboardingProvider>();
    final service = NutritionGoalService();

    final suggestions = await service.suggestGoals(provider.finalProfile);

    if (mounted && suggestions != null) {
      _caloriesController.text = (suggestions['targetCalories'] ?? 0).toString();
      _proteinController.text = (suggestions['targetProtein'] ?? 0).toString();
      _carbsController.text = (suggestions['targetCarbs'] ?? 0).toString();
      _fatController.text = (suggestions['targetFat'] ?? 0).toString();

      provider.updateNutritionGoals(
        calories: (suggestions['targetCalories'] as num?)?.toDouble() ?? 0.0,
        protein: (suggestions['targetProtein'] as num?)?.toDouble() ?? 0.0,
        carbs: (suggestions['targetCarbs'] as num?)?.toDouble() ?? 0.0,
        fat: (suggestions['targetFat'] as num?)?.toDouble() ?? 0.0,
      );
    }
    
    setState(() => _isAiLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    
    if (!_isInit) {
      _caloriesController.text = provider.finalProfile.targetCalories?.toStringAsFixed(0) ?? '';
      _proteinController.text = provider.finalProfile.targetProtein?.toStringAsFixed(0) ?? '';
      _carbsController.text = provider.finalProfile.targetCarbs?.toStringAsFixed(0) ?? '';
      _fatController.text = provider.finalProfile.targetFat?.toStringAsFixed(0) ?? '';
      _isInit = true;
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Set Your Nutrition Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text("Let's set your daily targets. You can enter your own or ask our AI for a personalized suggestion based on your profile."),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isAiLoading ? null : _getAiSuggestions,
          icon: _isAiLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: const Text('Ask AI for Suggestions'),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Calories'),
          onChanged: (value) => provider.updateNutritionGoals(calories: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _proteinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Protein (g)'),
          onChanged: (value) => provider.updateNutritionGoals(protein: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _carbsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Carbs (g)'),
          onChanged: (value) => provider.updateNutritionGoals(carbs: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fatController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Fat (g)'),
          onChanged: (value) => provider.updateNutritionGoals(fat: double.tryParse(value)),
        ),
      ],
    );
  }
}

class _CreateProgramPage extends StatefulWidget {
  const _CreateProgramPage();

  @override
  State<_CreateProgramPage> createState() => _CreateProgramPageState();
}

enum CreationMode { manual, ai }

class _CreateProgramPageState extends State<_CreateProgramPage> {
  final _textController = TextEditingController();
  final _assistantService = AssistantService();

  CreationMode _mode = CreationMode.manual;
  final List<String> _allDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final Set<String> _selectedDays = {'Mon', 'Wed', 'Fri'};
  bool _isLoading = false;

  String? _aiQuestion;
  String? _selectedEquipment;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createManualProgram() async {
    final programName = _textController.text.trim();
    if (programName.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and select at least one day.')),
      );
      return;
    }

    final workoutDays = _selectedDays.map((dayName) {
      return WorkoutDay(dayName: dayName, exercises: []);
    }).toList();

    final newProgram = WorkoutProgram(
      id: '',
      name: programName,
      days: workoutDays,
    );
    
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditWorkoutDayScreen(
            program: newProgram,
          ),
        ),
      );
    }
  }
  
  Future<void> _submitAIPrompt() async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the program you want.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedEquipment == null) {
        setState(() {
          _aiQuestion = "What kind of equipment do you have access to?";
          _isLoading = false;
        });
        return;
      }
      
      final program = await _assistantService.generateProgram(
        prompt: prompt,
        equipmentInfo: _selectedEquipment!,
      );

      if (mounted && program != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditWorkoutDayScreen(
              program: program,
            ),
          ),
        );
        setState(() {
          _textController.clear();
          _aiQuestion = null;
          _selectedEquipment = null;
        });
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The AI failed to generate a program. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Create Your First Program',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        SegmentedButton<CreationMode>(
          segments: const [
            ButtonSegment(value: CreationMode.manual, label: Text('Create Manually')),
            ButtonSegment(value: CreationMode.ai, label: Text('Ask AI')),
          ],
          selected: {_mode},
          onSelectionChanged: (Set<CreationMode> newSelection) {
            setState(() => _mode = newSelection.first);
          },
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: _mode == CreationMode.manual
                ? 'Program Name (e.g., "My Lifting Plan")'
                : 'Describe the program you want...',
            hintText: _mode == CreationMode.ai
                ? 'e.g., "A 4 day push pull full body strength program"'
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        if (_mode == CreationMode.manual) ...[
          Text('Select Workout Days', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: _allDays.map((day) {
              return FilterChip(
                label: Text(day),
                selected: _selectedDays.contains(day),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],

        if (_mode == CreationMode.ai && _aiQuestion != null) ...[
            Text(_aiQuestion!, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: ['Public Gym', 'Home Gym', 'Bodyweight Only'].map((equipment) {
                return ChoiceChip(
                  label: Text(equipment),
                  selected: _selectedEquipment == equipment,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedEquipment = selected ? equipment : null;
                    });
                  },
                );
              }).toList(),
            ),
        ],

        const SizedBox(height: 32),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _mode == CreationMode.manual ? _createManualProgram : _submitAIPrompt,
            icon: Icon(_mode == CreationMode.manual ? Icons.add : Icons.auto_awesome),
            label: Text(_mode == CreationMode.ai && _aiQuestion != null ? 'Generate Program' : 'Design Program'),
          ),
      ],
    );
  }
}

class _SummaryPage extends StatelessWidget {
  const _SummaryPage();
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<OnboardingProvider>().finalProfile;
    final bool isImperial = profile.unitSystem == 'imperial';
    final goal = profile.primaryGoal ?? 'Not Set';
    final sex = profile.biologicalSex ?? 'Not Set';
    final weightValue = profile.weight?['value'] as double?;
    final weightDisplay = weightValue != null ? '${weightValue.toStringAsFixed(1)} ${profile.weight?['unit']}' : 'Not Set';
    final heightCm = profile.height?['value'] as double?;
    String heightDisplay = 'Not Set';
    if (heightCm != null && heightCm > 0) {
      if (isImperial) {
        final totalInches = heightCm * 0.393701;
        final feet = totalInches ~/ 12;
        final inches = (totalInches % 12).toStringAsFixed(1);
        heightDisplay = '$feet ft $inches in';
      } else {
        heightDisplay = '${heightCm.toStringAsFixed(1)} cm';
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ready to go?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('Goal: $goal', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Sex: $sex', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Weight: $weightDisplay', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Height: $heightDisplay', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            const Text(
              'You can always change these details later in your profile.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  } 
}