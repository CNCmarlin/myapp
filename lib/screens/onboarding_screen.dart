import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/nutrition_goal_service.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // This is the complete list of pages for our onboarding flow.
  final List<Widget> _pages = [
    const _WelcomePage(),
    const _GoalPage(),
    const _UnitSystemPage(),
    const _BiometricsPage(),
    const _ActivityLevelPage(),
    const _NutritionGoalsPage(),
    const _CreateProgramPage(),
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

    // Get the temporary profile from the OnboardingProvider.
    final onboardingProvider = context.read<OnboardingProvider>();
    final UserProfile tempProfile = onboardingProvider.finalProfile;
    if (userId == null) {
      print("Error: No user is currently signed in. Cannot complete onboarding.");
      return;
    }

    final finalProfile = onboardingProvider.finalProfile.copyWith(onboardingCompleted: true);
    userProfileProvider.updateUserProfile(userId, finalProfile);

    // DEBUG STEP 1: Confirm the data we are about to send.
    print('[DEBUG 1] OnboardingScreen: Calling updateUserProfile. onboardingCompleted is: ${tempProfile.onboardingCompleted}');
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
  final TextEditingController _heightPrimaryController = TextEditingController(); // For cm or ft
  final TextEditingController _heightSecondaryController = TextEditingController(); // For in

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

class _ActivityLevelPage extends StatelessWidget {
  const _ActivityLevelPage();
  @override
  Widget build(BuildContext context) {
    final List<String> activityLevels = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'];
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('How active are you?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...activityLevels.map((level) => ListTile(
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
          ),
        );
      },
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
    final activity = profile.activityLevel ?? 'Not Set';
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
            Text('Activity: $activity', style: const TextStyle(fontSize: 18)),
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

class _CreateProgramPage extends StatefulWidget {
  const _CreateProgramPage();
  @override
  State<_CreateProgramPage> createState() => _CreateProgramPageState();
}
class _CreateProgramPageState extends State<_CreateProgramPage> {
  final _programNameController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isCreated = false;
  bool _isLoading = false;
  @override
  void dispose() {
    _programNameController.dispose();
    super.dispose();
  }
  Future<void> _createProgram() async {
    if (_programNameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final onboardingProvider = context.read<OnboardingProvider>();
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final newProgramId = await _firestoreService.createNewWorkoutProgram(userId, _programNameController.text.trim());
        // This method needs to be added to OnboardingProvider
        onboardingProvider.updateActiveProgramId(newProgramId);
        setState(() => _isCreated = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create program: $e")),
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
 return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
 const Text('Create Your First Program', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
 const SizedBox(height: 16),
 const Text('Give your new workout plan a name. You can add exercises later.', textAlign: TextAlign.center),
 const SizedBox(height: 24),
          TextFormField(
            controller: _programNameController,
 decoration: const InputDecoration(
              labelText: 'Program Name (e.g., "My Lifting Plan")',
              border: OutlineInputBorder(),
 ),
 enabled: !_isCreated, // Disable field after creation
          ),
 const SizedBox(height: 24),
 if (_isLoading)
 const CircularProgressIndicator()
 else
            ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 minimumSize: const Size.fromHeight(50),
 backgroundColor: _isCreated ? Colors.green : Theme.of(context).primaryColor,
 ),
              onPressed: _isCreated ? null : _createProgram, // Disable button after creation
 icon: Icon(_isCreated ? Icons.check : Icons.add),
 label: Text(_isCreated ? 'Program Created!' : 'Create Program'),
            ),
        ],
 ),
 );
  }
}

// Add this class to the bottom of lib/screens/onboarding_screen.dart

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
      // Update the text controllers with the AI's suggestions
      _caloriesController.text = (suggestions['targetCalories'] ?? 0).toString();
      _proteinController.text = (suggestions['targetProtein'] ?? 0).toString();
      _carbsController.text = (suggestions['targetCarbs'] ?? 0).toString();
      _fatController.text = (suggestions['targetFat'] ?? 0).toString();

      // Also update the provider so the data persists if the user navigates away and back
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
    // Watch the provider to keep the text fields in sync
    final provider = context.watch<OnboardingProvider>();
    
    // Initialize the text fields once from the provider's data
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
              ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2))
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