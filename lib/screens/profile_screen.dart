import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

enum ActiveProfileView { goals, stats }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ActiveProfileView _activeView = ActiveProfileView.goals;

  @override
  Widget build(BuildContext context) {
    // This top-level widget remains the same, managing the view toggling.
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _activeView == ActiveProfileView.goals
                  ? const _GoalsSettingsView(key: ValueKey('goals'))
                  : const _BodyStatsView(key: ValueKey('stats')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SegmentedButton<ActiveProfileView>(
              segments: const [
                ButtonSegment<ActiveProfileView>(
                    value: ActiveProfileView.goals,
                    label: Text('Goals'),
                    icon: Icon(Icons.flag_outlined)),
                ButtonSegment<ActiveProfileView>(
                    value: ActiveProfileView.stats,
                    label: Text('Body Stats'),
                    icon: Icon(Icons.assessment_outlined)),
              ],
              selected: {_activeView},
              onSelectionChanged: (Set<ActiveProfileView> newSelection) {
                setState(() => _activeView = newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Goals View - Already refactored, remains the same.
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

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().userProfile;
    _targetCaloriesController = TextEditingController(
        text: profile?.targetCalories?.toStringAsFixed(0) ?? '');
    _targetProteinController = TextEditingController(
        text: profile?.targetProtein?.toStringAsFixed(0) ?? '');
    _targetCarbsController = TextEditingController(
        text: profile?.targetCarbs?.toStringAsFixed(0) ?? '');
    _targetFatController = TextEditingController(
        text: profile?.targetFat?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final provider = context.read<UserProfileProvider>();
    // Update provider with values from text fields first
    provider.updateGoals(
      targetCalories: double.tryParse(_targetCaloriesController.text),
      targetProtein: double.tryParse(_targetProteinController.text),
      targetCarbs: double.tryParse(_targetCarbsController.text),
      targetFat: double.tryParse(_targetFatController.text),
    );
    // Then call the single save method
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
    final userProfile = userProfileProvider.userProfile;

    if (userProfile == null ||
        userProfileProvider.status == UserProfileStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General Settings',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: userProfile.primaryGoal,
                    decoration:
                        const InputDecoration(labelText: 'Primary Goal'),
                    items: ['Lose Weight', 'Maintain Weight', 'Gain Muscle']
                        .map((String value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? newValue) =>
                        userProfileProvider.updateGoals(
                            primaryGoal: newValue ?? 'Maintain Weight')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: userProfile.activityLevel,
                    decoration:
                        const InputDecoration(labelText: 'Activity Level'),
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
                        .updateGoals(activityLevel: newValue ?? 'Sedentary')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Active Workout Program'),
                    value: (userProfile.activeProgramId != null &&
                            userProfileProvider.availablePrograms.any(
                                (p) => p.id == userProfile.activeProgramId))
                        ? userProfile.activeProgramId
                        : null,
                    isExpanded: true,
                    items: userProfileProvider.availablePrograms
                        .map((program) => DropdownMenuItem<String>(
                              value: program.id,
                              child: Text(program.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (String? newValue) => userProfileProvider
                        .updateGoals(activeProgramId: newValue)),
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
                  Expanded(
                      child: TextField(
                          controller: _targetCaloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Target Calories'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextField(
                          controller: _targetProteinController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Protein (g)'))),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _targetCarbsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Carbs (g)'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextField(
                          controller: _targetFatController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Fat (g)'))),
                ]),
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

// Body Stats View - Reintegrated and refactored to use the new provider.
class _BodyStatsView extends StatefulWidget {
  const _BodyStatsView({super.key});
  @override
  State<_BodyStatsView> createState() => _BodyStatsViewState();
}

class _BodyStatsViewState extends State<_BodyStatsView> {
  // Text controllers are essential for managing form input state.
  final _weightController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {
    for (var item in ['Waist', 'Hips', 'Chest', 'Arms', 'Thighs'])
      item: TextEditingController()
  };

  // Local UI state not stored in the provider.
  bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    // Initialize the local state from the provider when the widget is first built.
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile != null) {
      _initializeLocalState(userProfile);
    }
  }

  @override
  void didUpdateWidget(covariant _BodyStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the profile data changes from an external source, re-initialize the view.
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
    // This logic from the OLD code is preserved to handle unit conversions.
    final weightData = profile.weight ?? {'value': 0.0, 'unit': 'kg'};
    final storedWeightValue = (weightData['value'] as num?)?.toDouble() ?? 0.0;
    final storedWeightUnit = weightData['unit'] as String? ?? 'kg';
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

    // --- Data Conversion ---
    // Convert all input data into a consistent format (metric) before updating.
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

    // --- Provider Update ---
    // Call the provider's update method with the consistent data.
    provider.updateBodyStats(
      unitSystem: _isMetric ? 'metric' : 'imperial',
      biologicalSex: biologicalSex,
      bodyFatPercentage: double.tryParse(_bodyFatController.text),
      weight: {'value': weightValueKg, 'unit': 'kg'},
      height: {'value': heightValueCm, 'unit': 'cm'},
      measurements: measurements,
    );

    // --- Save to Firestore ---
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
    // Watch the provider to rebuild when data changes.
    final userProfileProvider =
        context.watch<UserProfileProvider>(); // DEFINED HERE
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
              _updateTextFields(
                  userProfile); // Re-run conversion when toggling units
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
