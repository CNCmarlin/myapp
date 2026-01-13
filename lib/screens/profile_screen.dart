// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../providers/workout_provider.dart';
import '../services/ai_service.dart';
import '../services/nutrition_goal_service.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';

enum ActiveProfileView { goals, stats }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ActiveProfileView _activeView = ActiveProfileView.goals;

  Future<bool> _onWillPop() async {
    final provider = context.read<UserProfileProvider>();
    if (!provider.hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content:
            const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.revertChanges();
              Navigator.of(context).pop(true);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

 @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents accidental pop
      onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Profile'),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _activeView == ActiveProfileView.goals
              ? const _GoalsSettingsView(key: ValueKey('goals'))
              : const _BodyStatsView(key: ValueKey('stats')),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<ActiveProfileView>(
              segments: const [
                ButtonSegment<ActiveProfileView>(
                  value: ActiveProfileView.goals,
                  label: Text('Goals'),
                  icon: Icon(Icons.flag_outlined),
                ),
                ButtonSegment<ActiveProfileView>(
                  value: ActiveProfileView.stats,
                  label: Text('Body Stats'),
                  icon: Icon(Icons.assessment_outlined),
                ),
              ],
              selected: {_activeView},
              onSelectionChanged: (Set<ActiveProfileView> newSelection) {
                setState(() => _activeView = newSelection.first);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsSettingsView extends StatefulWidget {
  const _GoalsSettingsView({super.key});
  @override
  State<_GoalsSettingsView> createState() => _GoalsSettingsViewState();
}

class _GoalsSettingsViewState extends State<_GoalsSettingsView> {
  late TextEditingController _targetCaloriesController;
  late TextEditingController _targetProteinController;
  late TextEditingController _targetCarbsController;
  late TextEditingController _targetFatController;
  bool _isAiLoading = false;

  void _showApiKeyDialog(BuildContext context) async {
    final storage = context.read<SecureStorageService>();
    final currentKey = await storage.getGeminiKey() ?? '';
    final currentProvider = await storage.getProvider();


    final controller = TextEditingController(text: currentKey);
    String selectedProvider = currentProvider;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Added to handle dropdown state in dialog
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('AI Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedProvider,
                decoration: const InputDecoration(labelText: 'AI Provider'),
                items: const [
                  DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI (Coming Soon)')),
                ],
                onChanged: (val) => setDialogState(() => selectedProvider = val!),
              ),
              const SizedBox(height: 16),
              const Text('Your API key is encrypted and stored locally on this device.'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await storage.setGeminiKey(controller.text.trim());
                await storage.setProvider(selectedProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out? Your local data will remain on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AuthService>().signOut();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Exit profile
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _targetCaloriesController = TextEditingController();
    _targetProteinController = TextEditingController();
    _targetCarbsController = TextEditingController();
    _targetFatController = TextEditingController();
    _initializeControllers();
    context.read<UserProfileProvider>().addListener(_initializeControllers);
  }

  @override
  void dispose() {
    context.read<UserProfileProvider>().removeListener(_initializeControllers);
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final profile = context.read<UserProfileProvider>().userProfile;
    if (profile != null && mounted) {
      _targetCaloriesController.text =
          profile.targetCalories?.toStringAsFixed(0) ?? '';
      _targetProteinController.text =
          profile.targetProtein?.toStringAsFixed(0) ?? '';
      _targetCarbsController.text =
          profile.targetCarbs?.toStringAsFixed(0) ?? '';
      _targetFatController.text = profile.targetFat?.toStringAsFixed(0) ?? '';
    }
  }

  Future<void> _getAiSuggestions() async {
    setState(() => _isAiLoading = true);
    final provider = context.read<UserProfileProvider>();
    final service = NutritionGoalService(aiService: context.read<AIService>());

    if (provider.userProfile == null) return;

    final suggestions = await service.suggestGoals(provider.userProfile!);

    if (mounted && suggestions != null) {
      provider.updateGoals(
        targetCalories: (suggestions['targetCalories'] as num?)?.toDouble() ?? 0.0,
        targetProtein: (suggestions['targetProtein'] as num?)?.toDouble() ?? 0.0,
        targetCarbs: (suggestions['targetCarbs'] as num?)?.toDouble() ?? 0.0,
        targetFat: (suggestions['targetFat'] as num?)?.toDouble() ?? 0.0,
      );
    }
    if (mounted) {
      setState(() => _isAiLoading = false);
    }
  }

  void _handleSave() async {
    final provider = context.read<UserProfileProvider>();
    provider.updateGoals(
      targetCalories: double.tryParse(_targetCaloriesController.text),
      targetProtein: double.tryParse(_targetProteinController.text),
      targetCarbs: double.tryParse(_targetCarbsController.text),
      targetFat: double.tryParse(_targetFatController.text),
    );
    final success = await provider.saveProfileChanges();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(success ? 'Goals saved successfully!' : 'Error saving goals.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = context.watch<UserProfileProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final userProfile = userProfileProvider.userProfile;

    if (userProfile == null ||
        userProfileProvider.status == UserProfileStatus.loading ||
        workoutProvider.status == DataStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0), // Increased padding
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userProfile.primaryGoal,
                  decoration: const InputDecoration(labelText: 'Primary Goal'),
                  items: ['Lose Weight', 'Maintain Weight', 'Gain Muscle']
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? newValue) => userProfileProvider
                      .updateGoals(primaryGoal: newValue ?? 'Maintain Weight'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userProfile.activityLevel,
                  decoration: const InputDecoration(labelText: 'Activity Level'),
                  items: [
                    'Sedentary',
                    'Lightly Active',
                    'Moderately Active',
                    'Very Active',
                    'Extra Active'
                  ]
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? newValue) => userProfileProvider
                      .updateGoals(activityLevel: newValue ?? 'Sedentary'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Active Workout Program'),
                  value: (userProfile.activeProgramId != null &&
                          workoutProvider.programs
                              .any((p) => p.id == userProfile.activeProgramId))
                      ? userProfile.activeProgramId
                      : null,
                  isExpanded: true,
                  items: workoutProvider.programs
                      .map((program) => DropdownMenuItem<String>(
                            value: program.id,
                            child: Text(program.name,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (String? newValue) =>
                      userProfileProvider.updateActiveProgram(newValue),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition Goals',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _targetCaloriesController, /*... a ...*/)),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _targetProteinController, /*... b ...*/)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _targetCarbsController, /*... c ...*/)),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _targetFatController, /*... d ...*/)),
                ]),
                const SizedBox(height: 16),
                // NEW: AI Suggestion Button
                Center(
                  child: _isAiLoading 
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: _getAiSuggestions,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Recalculate with AI'),
                      ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('System Settings', style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key_outlined, color: Colors.blue),
                title: const Text('Gemini API Key'),
                subtitle: const Text('Manage your own local AI token'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showApiKeyDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _showLogoutConfirmation(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: userProfileProvider.isSaving ? null : _handleSave,
          child: userProfileProvider.isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save Goals & Settings'),
        ),
      ],
    );
  }
}

// NOTE: _BodyStatsView requires NO changes as it only deals with UserProfile state.
class _BodyStatsView extends StatefulWidget {
  const _BodyStatsView({super.key});
  @override
  State<_BodyStatsView> createState() => _BodyStatsViewState();
}

class _BodyStatsViewState extends State<_BodyStatsView> {
  final _weightController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {
    for (var item in ['Waist', 'Hips', 'Chest', 'Arms', 'Thighs'])
      item: TextEditingController()
  };
  bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile != null) {
      _initializeLocalState(userProfile);
    }
  }

  @override
  void didUpdateWidget(covariant _BodyStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile != null) {
      _initializeLocalState(userProfile);
    }
  }

  void _initializeLocalState(UserProfile profile) {
    _isMetric = profile.unitSystem == 'metric';
    _updateTextFields(profile);
  }

  void _updateTextFields(UserProfile profile) {
    // SURGICAL: Access properties directly from the class instead of using Map indexing
    final storedWeightValue = profile.weight?.value ?? 0.0;
    final storedWeightUnit = profile.weight?.unit ?? 'kg';
    final double weightKg = (storedWeightUnit == 'lbs')
        ? storedWeightValue * 0.453592
        : storedWeightValue;

    final heightCm = profile.height?['value'] as double? ?? 0.0;

    if (_isMetric) {
      _weightController.text = weightKg > 0 ? weightKg.toStringAsFixed(1) : '';
      _heightCmController.text =
          heightCm > 0 ? heightCm.toStringAsFixed(1) : '';
    } else {
      _weightController.text =
          weightKg > 0 ? (weightKg * 2.20462).toStringAsFixed(1) : '';
      if (heightCm > 0) {
        final totalInches = heightCm * 0.393701;
        _heightFtController.text = (totalInches ~/ 12).toString();
        _heightInController.text = (totalInches % 12).toStringAsFixed(1);
      } else {
        _heightFtController.text = '';
        _heightInController.text = '';
      }
    }
    _bodyFatController.text = profile.bodyFatPercentage?.toString() ?? '';
    _measurementControllers.forEach((name, controller) {
      final valueCm = profile.measurements?[name] as double? ?? 0.0;
      controller.text = (valueCm > 0)
          ? _isMetric
              ? valueCm.toStringAsFixed(1)
              : (valueCm * 0.393701).toStringAsFixed(1)
          : '';
    });
  }

  void _handleSave() async {
    final provider = context.read<UserProfileProvider>();
    final biologicalSex =
        provider.userProfile?.biologicalSex; // Get current sex

    double weightValueKg = 0;
    if (_weightController.text.isNotEmpty) {
      final double parsedWeight = double.tryParse(_weightController.text) ?? 0;
      weightValueKg = _isMetric ? parsedWeight : parsedWeight * 0.453592;
    }

    double heightValueCm = 0;
    if (_isMetric) {
      heightValueCm = double.tryParse(_heightCmController.text) ?? 0;
    } else {
      final double feet = double.tryParse(_heightFtController.text) ?? 0;
      final double inches = double.tryParse(_heightInController.text) ?? 0;
      heightValueCm = (feet * 12 + inches) * 2.54;
    }

    final Map<String, dynamic> measurements = {};
    _measurementControllers.forEach((name, controller) {
      if (controller.text.isNotEmpty) {
        final double parsedValue = double.tryParse(controller.text) ?? 0;
        measurements[name] = _isMetric ? parsedValue : parsedValue * 2.54;
      }
    });

    provider.updateBodyStats(
      unitSystem: _isMetric ? 'metric' : 'imperial',
      biologicalSex: biologicalSex,
      bodyFatPercentage: double.tryParse(_bodyFatController.text),
      weight: {'value': weightValueKg, 'unit': 'kg'},
      height: {'value': heightValueCm, 'unit': 'cm'},
      measurements: measurements,
    );

    final success = await provider.saveProfileChanges();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Body stats saved!' : 'Error saving stats.'),
      ));
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _heightCmController.dispose();
    _bodyFatController.dispose();
    for (var controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = context.watch<UserProfileProvider>();
    final userProfile = userProfileProvider.userProfile;

    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('US (lbs, ft)')),
            ButtonSegment<bool>(value: true, label: Text('Metric (kg, cm)')),
          ],
          selected: {_isMetric},
          onSelectionChanged: (newSelection) {
            setState(() {
              _isMetric = newSelection.first;
              _updateTextFields(userProfile);
            });
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biometrics',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: userProfile.biologicalSex,
                    decoration:
                        const InputDecoration(labelText: 'Biological Sex'),
                    items: ['Male', 'Female']
                        .map((String value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? newValue) {
                      context
                          .read<UserProfileProvider>()
                          .updateBodyStats(biologicalSex: newValue);
                    }),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: userProfile.fitnessProficiency,
                    decoration:
                        const InputDecoration(labelText: 'Fitness Level'),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map((String value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? newValue) {
                      context
                          .read<UserProfileProvider>()
                          .updateBodyStats(fitnessProficiency: newValue);
                    }),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                              labelText:
                                  'Weight (${_isMetric ? 'kg' : 'lbs'})'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextField(
                          controller: _bodyFatController,
                          decoration:
                              const InputDecoration(labelText: 'Body Fat (%)'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                ]),
                const SizedBox(height: 16),
                if (_isMetric)
                  TextField(
                      controller: _heightCmController,
                      decoration:
                          const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true))
                else
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _heightFtController,
                            decoration:
                                const InputDecoration(labelText: 'Height (ft)'),
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: _heightInController,
                            decoration:
                                const InputDecoration(labelText: 'Height (in)'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                  ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Body Measurements',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: ['Waist', 'Hips', 'Chest', 'Arms', 'Thighs']
                      .map((measurement) => SizedBox(
                            width: MediaQuery.of(context).size.width / 2.5,
                            child: TextField(
                              controller: _measurementControllers[measurement],
                              decoration: InputDecoration(
                                  labelText:
                                      '$measurement (${_isMetric ? 'cm' : 'in'})'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: userProfileProvider.isSaving ? null : _handleSave,
          child: userProfileProvider.isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save Goals & Settings'),
        ),
      ],
    );
  }
}
