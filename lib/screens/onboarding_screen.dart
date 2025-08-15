import 'package:flutter/material.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/assistant_service.dart';
import 'package:myapp/services/nutrition_goal_service.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:myapp/widgets/macro_indicator.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [
    const _WelcomePage(),
    const _GoalPage(),
    const _UnitSystemPage(),
    const _BiometricsPage(),
    const _DietAndActivityPage(),
    const _FitnessProficiencyPage(), // NEW
    const _CreateProgramPage(),
    const _NutritionGoalsPage(),
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

  void _completeOnboarding(BuildContext context) async {
    final userProfileProvider = context.read<UserProfileProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    final finalProfile = onboardingProvider.finalProfile.copyWith(
      onboardingCompleted: true,
    );

    userProfileProvider.setInitialProfile(finalProfile);
    await userProfileProvider.saveProfileChanges();
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();
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
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
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
        final goal = provider.finalProfile.primaryGoal;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('What is your primary goal?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Lose Weight'),
                leading: Radio<String>(
                  value: 'Lose Weight',
                  groupValue: goal,
                  onChanged: (value) => provider.updatePrimaryGoal(value!),
                ),
                onTap: () => provider.updatePrimaryGoal('Lose Weight'),
              ),
              ListTile(
                title: const Text('Gain Muscle'),
                leading: Radio<String>(
                  value: 'Gain Muscle',
                  groupValue: goal,
                  onChanged: (value) => provider.updatePrimaryGoal(value!),
                ),
                onTap: () => provider.updatePrimaryGoal('Gain Muscle'),
              ),
              ListTile(
                title: const Text('Maintain Weight'),
                leading: Radio<String>(
                  value: 'Maintain Weight',
                  groupValue: goal,
                  onChanged: (value) => provider.updatePrimaryGoal(value!),
                ),
                onTap: () => provider.updatePrimaryGoal('Maintain Weight'),
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

class _BiometricsPage extends StatefulWidget {
  const _BiometricsPage();

  @override
  State<_BiometricsPage> createState() => _BiometricsPageState();
}

class _BiometricsPageState extends State<_BiometricsPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightPrimaryController =
      TextEditingController();
  final TextEditingController _heightSecondaryController =
      TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _heightPrimaryController.dispose();
    _heightSecondaryController.dispose();
    super.dispose();
  }

  void _updateImperialHeight(OnboardingProvider provider) {
    final double feet = double.tryParse(_heightPrimaryController.text) ?? 0;
    final double inches =
        double.tryParse(_heightSecondaryController.text) ?? 0;
    final double totalCm = (feet * 12 + inches) * 2.54;
    provider.updateHeight(totalCm, 'cm');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final bool isImperial =
            provider.finalProfile.unitSystem == 'imperial';
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tell us about yourself',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: provider.finalProfile.biologicalSex,
                decoration: const InputDecoration(
                    labelText: 'Biological Sex',
                    border: OutlineInputBorder()),
                items: ['Male', 'Female']
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) provider.updateBiologicalSex(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                    labelText: isImperial ? 'Weight (lbs)' : 'Weight (kg)',
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final double? weight = double.tryParse(value);
                  if (weight != null) {
                    provider.updateWeight(weight, isImperial ? 'lbs' : 'kg');
                  }
                },
              ),
              const SizedBox(height: 16),
              if (isImperial)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightPrimaryController,
                        decoration: const InputDecoration(
                            labelText: 'Height (ft)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateImperialHeight(provider),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _heightSecondaryController,
                        decoration: const InputDecoration(
                            labelText: '(in)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateImperialHeight(provider),
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _heightPrimaryController,
                  decoration: const InputDecoration(
                      labelText: 'Height (cm)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final double? heightCm = double.tryParse(value);
                    if (heightCm != null) {
                      provider.updateHeight(heightCm, 'cm');
                    }
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
            const Text(
                'Outside of exercise, how active is your daily life?'),
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
                  onChanged: (value) => provider.updateActivityLevel(value!),
                ),
                onTap: () => provider.updateActivityLevel(level),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FitnessProficiencyPage extends StatelessWidget {
  const _FitnessProficiencyPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final proficiency = provider.finalProfile.fitnessProficiency;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('What is your fitness level?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('This helps the AI create a plan that\'s right for you.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Beginner'),
                subtitle: const Text('New to structured workouts'),
                leading: Radio<String>(
                  value: 'Beginner',
                  groupValue: proficiency,
                  onChanged: (value) => provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Beginner'),
              ),
              ListTile(
                title: const Text('Intermediate'),
                subtitle: const Text('Consistent with workouts for 6+ months'),
                leading: Radio<String>(
                  value: 'Intermediate',
                  groupValue: proficiency,
                  onChanged: (value) => provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Intermediate'),
              ),
              ListTile(
                title: const Text('Advanced'),
                subtitle: const Text('Multiple years of structured training'),
                leading: Radio<String>(
                  value: 'Advanced',
                  groupValue: proficiency,
                  onChanged: (value) => provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Advanced'),
              ),
            ],
          ),
        );
      },
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
  int _numberOfDays = 3;
  bool _isLoading = false;
  WorkoutProgram? _aiGeneratedProgram;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showPromptSuggestions(String equipmentType) {
    final provider = context.read<OnboardingProvider>();
    final proficiency = provider.finalProfile.fitnessProficiency ?? 'Beginner';
    
    Map<String, List<String>> suggestions = {
      'Beginner': [
        'A 3-day full body workout',
        'A 4-day upper/lower body split',
        'A beginner strength training program',
      ],
      'Intermediate': [
        'A 4-day push/pull split',
        'A 5-day body part split (bro split)',
        'An intermediate powerlifting program',
      ],
      'Advanced': [
        'A 6-day push/pull/legs program',
        'A 5-day undulating periodization plan',
        'An advanced bodybuilding program focusing on hypertrophy',
      ]
    };

    final prompts = suggestions[proficiency] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Quick Start Ideas for a "$proficiency" Level', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...prompts.map((prompt) => ListTile(
              title: Text(prompt),
              onTap: () {
                Navigator.of(context).pop();
                _textController.text = prompt;
                _submitAIPrompt(equipmentType);
              },
            )),
          ],
        );
      },
    );
  }

  Future<void> _handleManualCreation() async {
    final programName = _textController.text.trim();
    if (programName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your program.')),
      );
      return;
    }

    final workoutDays = _aiGeneratedProgram?.days ??
        List.generate(_numberOfDays, (index) => 'Day ${index + 1}')
            .map((dayName) => WorkoutDay(dayName: dayName, exercises: []))
            .toList();

    final newProgram = _aiGeneratedProgram?.copyWith(
          name: programName,
          days: workoutDays,
        ) ??
        WorkoutProgram(
          id: '',
          name: programName,
          days: workoutDays,
        );

    if (mounted) {
      final result = await Navigator.push<WorkoutProgram>(
        context,
        MaterialPageRoute(
          builder: (context) => EditWorkoutDayScreen(
            program: newProgram,
          ),
        ),
      );

      if (result != null && mounted) {
        Provider.of<OnboardingProvider>(context, listen: false)
            .updateActiveProgramId(result.id);
      }
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
        final editedProgram = await Navigator.push<WorkoutProgram>(
          context,
          MaterialPageRoute(
            builder: (context) => EditWorkoutDayScreen(
              program: program,
            ),
          ),
        );

        setState(() {
          if (editedProgram != null) {
            _aiGeneratedProgram = editedProgram;
            Provider.of<OnboardingProvider>(context, listen: false)
                .updateActiveProgramId(editedProgram.id);
          } else {
            _aiGeneratedProgram = program;
          }
          _mode = CreationMode.manual;
          _textController.text = _aiGeneratedProgram!.name;
          _numberOfDays = _aiGeneratedProgram!.days.length;
          _aiQuestion = null;
          _selectedEquipment = null;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('The AI failed to generate a program. Please try again.')),
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
    final bool hasAiProgramToEdit = _aiGeneratedProgram != null;
    final proficiency =
        context.select((OnboardingProvider p) => p.finalProfile.fitnessProficiency);
    final String hintText = proficiency == 'Beginner'
        ? 'e.g., "A 4 day workout for a beginner"'
        : 'e.g., "A 5 day push/pull/legs split using free weights"';

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
          segments: [
            ButtonSegment(
                value: CreationMode.manual,
                label:
                    Text(hasAiProgramToEdit ? 'Manual / Edit AI' : 'Create Manually')),
            const ButtonSegment(value: CreationMode.ai, label: Text('Ask AI')),
          ],
          selected: {_mode},
          onSelectionChanged: (Set<CreationMode> newSelection) {
            setState(() => _mode = newSelection.first);
          },
        ),
        if (_mode == CreationMode.ai)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "Please be patient, AI generation can take up to 30 seconds.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: _mode == CreationMode.manual
                ? 'Program Name (e.g., "My Lifting Plan")'
                : 'Describe the program you want...',
            hintText: _mode == CreationMode.ai ? hintText : null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        if (_mode == CreationMode.manual) ...[
          Text('How many days per week?', style: textTheme.titleMedium),
          Slider(
            value: _numberOfDays.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: _numberOfDays.toString(),
            onChanged: hasAiProgramToEdit
                ? null
                : (value) {
                    setState(() {
                      _numberOfDays = value.toInt();
                    });
                  },
          ),
        ],
        if (_mode == CreationMode.ai && _aiQuestion != null) ...[
          Text(_aiQuestion!, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ['Public Gym', 'Home Gym', 'Bodyweight Only']
                .map((equipment) {
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
            onPressed: _mode == CreationMode.manual
                ? _handleManualCreation
                : _submitAIPrompt,
            icon: Icon(_mode == CreationMode.manual
                ? Icons.edit_note
                : Icons.auto_awesome),
            label: Text(_mode == CreationMode.ai
                ? (_aiQuestion != null
                    ? 'Generate Program'
                    : 'Ask AI to Design')
                : (hasAiProgramToEdit
                    ? 'Edit & Confirm Program'
                    : 'Design Program')),
          ),
      ],
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
      _caloriesController.text =
          (suggestions['targetCalories'] ?? 0).toString();
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
      _caloriesController.text =
          provider.finalProfile.targetCalories?.toStringAsFixed(0) ?? '';
      _proteinController.text =
          provider.finalProfile.targetProtein?.toStringAsFixed(0) ?? '';
      _carbsController.text =
          provider.finalProfile.targetCarbs?.toStringAsFixed(0) ?? '';
      _fatController.text =
          provider.finalProfile.targetFat?.toStringAsFixed(0) ?? '';
      _isInit = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Set Your Nutrition Goals',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
            "Let's set your daily targets. You can enter your own or ask our AI for a personalized suggestion based on your profile."),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isAiLoading ? null : _getAiSuggestions,
          icon: _isAiLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: const Text('Ask AI for Suggestions'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            "Please be patient, AI suggestions can take up to 30 seconds.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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
        TextField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Calories'),
          onChanged: (value) =>
              provider.updateNutritionGoals(calories: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _proteinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Protein (g)'),
          onChanged: (value) =>
              provider.updateNutritionGoals(protein: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _carbsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Carbs (g)'),
          onChanged: (value) =>
              provider.updateNutritionGoals(carbs: double.tryParse(value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fatController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Fat (g)'),
          onChanged: (value) =>
              provider.updateNutritionGoals(fat: double.tryParse(value)),
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
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Onboarding Complete!',
            style: textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
            'Here is a summary of your new profile. You can change this information at any time.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vitals & Goal', style: textTheme.titleLarge),
                const Divider(),
                _SummaryTile(
                  icon: Icons.flag_outlined,
                  title: 'Primary Goal',
                  value: profile.primaryGoal ?? 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.person_outline,
                  title: 'Biological Sex',
                  value: profile.biologicalSex ?? 'Not Set',
                ),
                _SummaryTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Weight',
                  value: profile.weight != null
                      ? '${(profile.weight!['value'] as num).toStringAsFixed(1)} ${profile.weight!['unit']}'
                      : 'Not Set',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Plan', style: textTheme.titleLarge),
                const Divider(),
                _SummaryTile(
                  icon: Icons.directions_run,
                  title: 'Weekly Exercise',
                  value: '${profile.exerciseDaysPerWeek} days/week',
                ),
                _SummaryTile(
                  icon: Icons.work_outline,
                  title: 'Daily Activity',
                  value: profile.activityLevel ?? 'Not Set',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition Plan', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Low-Carb Preference: ${profile.prefersLowCarb ? "Yes" : "No"}',
                    style: textTheme.bodyMedium),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MacroIndicator(
                        label: 'Calories',
                        value: profile.targetCalories ?? 0,
                        target: profile.targetCalories ?? 2000,
                        color: Colors.blue,
                        showTarget: true),
                    MacroIndicator(
                        label: 'Protein',
                        value: profile.targetProtein ?? 0,
                        target: profile.targetProtein ?? 150,
                        color: Colors.red,
                        unit: 'g',
                        showTarget: true),
                    MacroIndicator(
                        label: 'Carbs',
                        value: profile.targetCarbs ?? 0,
                        target: profile.targetCarbs ?? 200,
                        color: Colors.orange,
                        unit: 'g',
                        showTarget: true),
                    MacroIndicator(
                        label: 'Fat',
                        value: profile.targetFat ?? 0,
                        target: profile.targetFat ?? 60,
                        color: Colors.purple,
                        unit: 'g',
                        showTarget: true),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing:
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}