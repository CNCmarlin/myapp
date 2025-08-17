import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/providers/onboarding_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/services/assistant_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:myapp/services/nutrition_goal_service.dart';
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

  // Form keys for validation
  final _goalFormKey = GlobalKey<FormState>();
  final _biometricsFormKey = GlobalKey<FormState>();
  final _dietActivityFormKey = GlobalKey<FormState>();
  final _programFormKey = GlobalKey<FormState>();
  final _nutritionFormKey = GlobalKey<FormState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _WelcomePage(),
      _GoalPage(formKey: _goalFormKey),
      const _UnitSystemPage(),
      _BiometricsPage(formKey: _biometricsFormKey),
      _DietAndActivityPage(formKey: _dietActivityFormKey),
      const _FitnessProficiencyPage(),
      _CreateProgramPage(formKey: _programFormKey),
      _NutritionGoalsPage(formKey: _nutritionFormKey),
      const _SummaryPage(),
    ];
  }

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

  // In lib/screens/onboarding_screen.dart -> _OnboardingScreenState

  void _nextPage(BuildContext context) {
    bool canProceed = true;
    String errorMessage = '';

    switch (_currentPage) {
      case 1: // Goal Page
        canProceed = _goalFormKey.currentState?.validate() ?? false;
        break;
      case 3: // Biometrics Page
        canProceed = _biometricsFormKey.currentState?.validate() ?? false;
        break;
      case 4: // Diet & Activity Page
        canProceed = _dietActivityFormKey.currentState?.validate() ?? false;
        break;
      case 6: // FIX: Create Program Page
        canProceed = context.read<OnboardingProvider>().finalProfile.activeProgramId != null;
        if (!canProceed) {
          errorMessage = 'Please create and save a program to continue.';
        }
        break;
      case 7: // Nutrition Goals Page
        canProceed = _nutritionFormKey.currentState?.validate() ?? false;
        break;
    }

    if (canProceed) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else if (errorMessage.isNotEmpty) {
      // Provide feedback to the user if the check fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
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

  // This ensures the activeProgramId is explicitly included.
  final finalProfile = onboardingProvider.finalProfile.copyWith(
    onboardingCompleted: true,
    activeProgramId: onboardingProvider.finalProfile.activeProgramId,
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
                              _nextPage(innerContext);
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
        leading:
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _GoalPage({required this.formKey});
  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final goal = provider.finalProfile.primaryGoal;
        return Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('What is your primary goal?',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                            title: const Text('Lose Weight'),
                            leading: Radio<String>(
                                value: 'Lose Weight',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Lose Weight');
                              state.didChange('Lose Weight');
                            }),
                        ListTile(
                            title: const Text('Gain Muscle'),
                            leading: Radio<String>(
                                value: 'Gain Muscle',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Gain Muscle');
                              state.didChange('Gain Muscle');
                            }),
                        ListTile(
                            title: const Text('Maintain Weight'),
                            leading: Radio<String>(
                                value: 'Maintain Weight',
                                groupValue: goal,
                                onChanged: (value) {
                                  provider.updatePrimaryGoal(value!);
                                  state.didChange(value);
                                }),
                            onTap: () {
                              provider.updatePrimaryGoal('Maintain Weight');
                              state.didChange('Maintain Weight');
                            }),
                        if (state.hasError)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          )
                      ],
                    );
                  },
                  validator: (value) =>
                      provider.finalProfile.primaryGoal == null
                          ? 'Please select a goal.'
                          : null,
                ),
              ],
            ),
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

class _BiometricsPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _BiometricsPage({required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final isImperial = provider.finalProfile.unitSystem == 'imperial';

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Tell us about yourself',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: provider.finalProfile.biologicalSex,
            decoration: const InputDecoration(
                labelText: 'Biological Sex', border: OutlineInputBorder()),
            items: ['Male', 'Female']
                .map((label) =>
                    DropdownMenuItem(value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              if (value != null) provider.updateBiologicalSex(value);
            },
            validator: (value) => value == null ? 'Please select a sex' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: provider.finalProfile.age?.toString(),
            decoration: const InputDecoration(
                labelText: 'Age', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final int? age = int.tryParse(value);
              if (age != null) provider.updateAge(age);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 13) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: provider.finalProfile.weight?['value']?.toString(),
            decoration: InputDecoration(
                labelText: 'Current Weight (${isImperial ? 'lbs' : 'kg'})',
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final double? weight = double.tryParse(value);
              if (weight != null) {
                provider.updateWeight(weight, isImperial ? 'lbs' : 'kg');
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (isImperial)
            _ImperialHeightInput(
              onChanged: (feet, inches) {
                final double totalCm = (feet * 12 + inches) * 2.54;
                provider.updateHeight(totalCm, 'cm');
              },
            )
          else
            TextFormField(
              initialValue: provider.finalProfile.height?['value']?.toString(),
              decoration: const InputDecoration(
                  labelText: 'Height (cm)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final double? heightCm = double.tryParse(value);
                if (heightCm != null) provider.updateHeight(heightCm, 'cm');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                return null;
              },
            ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue:
                provider.finalProfile.goalWeight?['value']?.toString(),
            decoration: InputDecoration(
                labelText: 'Goal Weight (${isImperial ? 'lbs' : 'kg'})',
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final double? weight = double.tryParse(value);
              if (weight != null) {
                provider.updateGoalWeight(weight, isImperial ? 'lbs' : 'kg');
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your goal weight';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ImperialHeightInput extends StatefulWidget {
  final Function(double feet, double inches) onChanged;
  const _ImperialHeightInput({required this.onChanged});

  @override
  State<_ImperialHeightInput> createState() => _ImperialHeightInputState();
}

class _ImperialHeightInputState extends State<_ImperialHeightInput> {
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController(text: '0');
  final _inchesFocusNode = FocusNode(); // NEW

  @override
  void initState() {
    super.initState();
    // NEW: Add a listener to select text on focus
    _inchesFocusNode.addListener(() {
      if (_inchesFocusNode.hasFocus) {
        _inchesController.selectAll();
      }
    });

    final provider = context.read<OnboardingProvider>();
    final heightCm = provider.finalProfile.height?['value'] as double? ?? 0.0;
    if (heightCm > 0) {
      final totalInches = heightCm * 0.393701;
      _feetController.text = (totalInches ~/ 12).toString();
      _inchesController.text = (totalInches % 12).round().toString();
    }
  }

  @override
  void dispose() {
    _feetController.dispose();
    _inchesController.dispose();
    _inchesFocusNode.dispose(); // NEW
    super.dispose();
  }

  void _updateHeight() {
    final double feet = double.tryParse(_feetController.text) ?? 0;
    final double inches = double.tryParse(_inchesController.text) ?? 0;
    widget.onChanged(feet, inches);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _feetController,
            decoration: const InputDecoration(
                labelText: 'Height (ft)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _updateHeight(),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _inchesController,
            focusNode: _inchesFocusNode, // NEW
            decoration: const InputDecoration(
                labelText: '(in)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _updateHeight(),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

// Helper extension to select all text in a controller
extension SelectAllExtension on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

// In lib/screens/onboarding_screen.dart

class _DietAndActivityPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _DietAndActivityPage({required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final profile = provider.finalProfile;
        final bool isLosingWeight = profile.primaryGoal == 'Lose Weight';

        return Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Diet & Activity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Current Goal: ${profile.weeklyWeightLossGoal.toStringAsFixed(1)} lbs',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Slider(
                    value: profile.weeklyWeightLossGoal,
                    min: 0.5,
                    max: 2.0,
                    divisions: 3,
                    label:
                        '${profile.weeklyWeightLossGoal.toStringAsFixed(1)} lbs',
                    onChanged: provider.updateWeeklyWeightLossGoal,
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                    'Outside of planned exercise, how active is your daily life?'),
                FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              onChanged: (value) {
                                provider.updateActivityLevel(value!);
                                state.didChange(value);
                              },
                            ),
                            onTap: () {
                              provider.updateActivityLevel(level);
                              state.didChange(level);
                            },
                          );
                        }),
                        if (state.hasError)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          )
                      ],
                    );
                  },
                  validator: (value) =>
                      provider.finalProfile.activityLevel == null
                          ? 'Please select an activity level.'
                          : null,
                ),
              ],
            ),
          ),
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
              const Text('What is your fitness level?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'This helps the AI create a plan that\'s right for you.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Beginner'),
                subtitle: const Text('New to structured workouts'),
                leading: Radio<String>(
                  value: 'Beginner',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Beginner'),
              ),
              ListTile(
                title: const Text('Intermediate'),
                subtitle: const Text('Consistent with workouts for 6+ months'),
                leading: Radio<String>(
                  value: 'Intermediate',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
                ),
                onTap: () => provider.updateFitnessProficiency('Intermediate'),
              ),
              ListTile(
                title: const Text('Advanced'),
                subtitle: const Text('Multiple years of structured training'),
                leading: Radio<String>(
                  value: 'Advanced',
                  groupValue: proficiency,
                  onChanged: (value) =>
                      provider.updateFitnessProficiency(value!),
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
  final GlobalKey<FormState> formKey;
  const _CreateProgramPage({required this.formKey});

  @override
  State<_CreateProgramPage> createState() => _CreateProgramPageState();
}

enum CreationMode { manual, ai }

class _CreateProgramPageState extends State<_CreateProgramPage> {
  final _textController = TextEditingController();
  final _assistantService = AssistantService();

  CreationMode _mode = CreationMode.ai;
  int _numberOfDays = 3;
  bool _isLoading = false;
  WorkoutProgram? _programToReview;
  bool _isProgramSaved = false;
  String? _selectedEquipmentForAI;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showPromptSuggestions(String equipmentType) {
    setState(() {
      _selectedEquipmentForAI = equipmentType;
    });

    final provider = context.read<OnboardingProvider>();
    final proficiency = provider.finalProfile.fitnessProficiency ?? 'Beginner';
    
    Map<String, List<String>> suggestions = {
      'Beginner': [ 'A 3-day full body workout', 'A 4-day upper/lower body split' ],
      'Intermediate': [ 'A 4-day push/pull split', 'A 5-day body part split (bro split)' ],
      'Advanced': [ 'A 6-day push/pull/legs program', 'A 5-day undulating periodization plan' ]
    };

    final prompts = suggestions[proficiency] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Quick Start Ideas for "$proficiency"', style: Theme.of(ctx).textTheme.titleLarge),
          ),
          ...prompts.map((p) => ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(p),
            onTap: () {
              Navigator.of(ctx).pop();
              _textController.text = p;
            },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Type my own prompt...'),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgram(WorkoutProgram programToSave) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final pageContext = context;
    try {
      final onboardingProvider = pageContext.read<OnboardingProvider>();
      final firestoreService = FirestoreService();
      final userId = pageContext.read<AuthService>().currentUser?.uid;
      if (userId == null) throw Exception("User not found");

      final newProgramId = await firestoreService.createNewWorkoutProgram(
        userId, programToSave.name, programToSave.days.map((d) => d.dayName).toList()
      );
      
      programToSave.id = newProgramId;
      await firestoreService.updateWorkoutProgram(userId, programToSave);
      onboardingProvider.updateActiveProgramId(newProgramId);
      
      widget.formKey.currentState?.validate();
      
      setState(() { _isProgramSaved = true; });

      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(
          content: Text('Program saved successfully! You can now proceed.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(pageContext).showSnackBar(SnackBar(content: Text('Error saving program: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditor(WorkoutProgram programToEdit) async {
    final pageContext = context;
    await Navigator.push(
      pageContext,
      MaterialPageRoute(
        builder: (context) => EditWorkoutDayScreen(
          program: programToEdit,
          onSave: (editedProgram) async {
            await _saveProgram(editedProgram);
            if (mounted) {
              setState(() {
                _programToReview = editedProgram;
                _textController.text = editedProgram.name;
                _mode = CreationMode.manual;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleManualCreation() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;

    final programName = _textController.text.trim();
    context.read<OnboardingProvider>().updateExerciseDaysPerWeek(_numberOfDays);

    // FIX: Use the unified _programToReview variable
    final programToEdit = _programToReview?.copyWith(name: programName) ??
        WorkoutProgram(
            id: '',
            name: programName,
            days: List.generate(_numberOfDays,
                (i) => WorkoutDay(dayName: 'Day ${i + 1}', exercises: [])));

    // FIX: Call the universal navigateToEditor function which handles the onSave callback correctly.
    await _navigateToEditor(programToEdit);
  }

  Future<void> _submitAIPrompt() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    if (_selectedEquipmentForAI == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a gym type first.')));
       return;
    }

    setState(() => _isLoading = true);
    try {
      final userProfile = context.read<OnboardingProvider>().finalProfile;
      final program = await _assistantService.generateProgram(
        prompt: _textController.text.trim(),
        equipmentInfo: _selectedEquipmentForAI!,
        userProfile: userProfile,
      );

      if (mounted && program != null) {
        context.read<OnboardingProvider>().updateExerciseDaysPerWeek(program.days.length);
        await _navigateToEditor(program);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The AI failed to generate a program.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
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
    final bool hasProgramToReview = _programToReview != null;

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Create Your First Program',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          FormField<bool>(
            builder: (state) {
              if (state.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13))),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<CreationMode>(
            segments: [
              const ButtonSegment(value: CreationMode.ai, label: Text('Ask AI')),
              ButtonSegment(
                  value: CreationMode.manual,
                  label: Text(hasProgramToReview
                      ? 'Review Program'
                      : 'Create Manually')),
            ],
            selected: {_mode},
            onSelectionChanged: (Set<CreationMode> newSelection) {
              setState(() => _mode = newSelection.first);
            },
          ),
          const SizedBox(height: 16),
          
          if (_mode == CreationMode.ai) ...[
            Text('1. Choose your equipment', style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0, runSpacing: 8.0,
              children: [
                OutlinedButton.icon(icon: const Icon(Icons.fitness_center), label: const Text("Public Gym"), onPressed: () => _showPromptSuggestions("Public Gym")),
                OutlinedButton.icon(icon: const Icon(Icons.home), label: const Text("Home Gym"), onPressed: () => _showPromptSuggestions("Home Gym")),
                OutlinedButton.icon(icon: const Icon(Icons.self_improvement), label: const Text("Bodyweight"), onPressed: () => _showPromptSuggestions("Bodyweight Only")),
              ],
            ),
            const SizedBox(height: 16),
            Text('2. Describe your ideal program or get a suggestion', style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'e.g., "A 4-day upper/lower split"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => (value == null || value.isEmpty) ? 'Please provide a description.' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _isLoading ? null : _submitAIPrompt,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
              label: const Text('Generate Program with AI'),
            ),
          ],
          
          if (_mode == CreationMode.manual) ...[
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                border: OutlineInputBorder(),
              ),
               validator: (value) => (value == null || value.isEmpty) ? 'Please provide a name.' : null,
            ),
            const SizedBox(height: 16),
            if (!hasProgramToReview) ...[
              Text('How many days per week?', style: textTheme.titleMedium),
              Slider(
                value: _numberOfDays.toDouble(),
                min: 1, max: 7, divisions: 6,
                label: _numberOfDays.toString(),
                onChanged: (value) => setState(() => _numberOfDays = value.toInt()),
              ),
              Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Goal: ${_numberOfDays.toStringAsFixed(1)} Days',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: _isProgramSaved ? Colors.green : Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _isLoading ? null : _handleManualCreation,
              icon: Icon(_isProgramSaved ? Icons.check_circle : Icons.edit_note),
              label: Text(_isProgramSaved ? 'Program Saved!' : (hasProgramToReview ? 'Re-edit & Confirm' : 'Design Program')),
            ),
          ],
        ],
      ),
    );
  }
}


class _NutritionGoalsPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const _NutritionGoalsPage({required this.formKey});

  @override
  State<_NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends State<_NutritionGoalsPage> {
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
    final service = NutritionGoalService();

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
      _proteinController.text = (suggestions['targetProtein'] ?? 0).toString();
      _carbsController.text = (suggestions['targetCarbs'] ?? 0).toString();
      _fatController.text = (suggestions['targetFat'] ?? 0).toString();

      provider.updateNutritionGoals(
        calories: double.tryParse(_caloriesController.text) ?? 0.0,
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
              onChanged: (value) =>
                  provider.updateNutritionGoals(calories: double.tryParse(value)),
              validator: (value){
                final zeroCheck = allMacrosValidator();
                if(zeroCheck != null) return zeroCheck;
                return macroValidator(value);
              }
            ),
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
                    onChanged: (value) =>
                        provider.updateNutritionGoals(protein: double.tryParse(value)),
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
                    onChanged: (value) =>
                        provider.updateNutritionGoals(carbs: double.tryParse(value)),
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
                    onChanged: (value) =>
                        provider.updateNutritionGoals(fat: double.tryParse(value)),
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
            style:
                textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  icon: Icons.trending_up,
                  title: 'Goal Weight',
                  value: profile.goalWeight != null
                      ? '${(profile.goalWeight!['value'] as num).toStringAsFixed(1)} ${profile.goalWeight!['unit']}'
                      : 'Not Set',
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
                  icon: Icons.fitness_center,
                  title: 'Fitness Level',
                  value: profile.fitnessProficiency ?? 'Not Set',
                ),
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
                Text(
                    'Low-Carb Preference: ${profile.prefersLowCarb ? "Yes" : "No"}',
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
