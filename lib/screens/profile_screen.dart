import 'package:flutter/material.dart';
import 'package:myapp/models/user_profile.dart';
//import 'package:myapp/models/workout_data.dart';
import 'package:provider/provider.dart';
//import 'package.provider/provider.dart';
import 'package:myapp/providers/profile_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';

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
        ],
      ),
    );
  }
}

// --- Sub-View for Goals & Settings ---
class _GoalsSettingsView extends StatefulWidget {
  const _GoalsSettingsView({super.key});
  @override
  State<_GoalsSettingsView> createState() => _GoalsSettingsViewState();
}

class _GoalsSettingsViewState extends State<_GoalsSettingsView> {
  // Local state variables to hold UI selections
  String? _selectedActivityLevel;
  String? _selectedPrimaryGoal;
  String? _selectedProgramId;
  final _targetCaloriesController = TextEditingController();
  final _targetProteinController = TextEditingController();
  final _targetCarbsController = TextEditingController();
  final _targetFatController = TextEditingController();
  bool _isInit = false;
  final bool _isAiLoading = false; // State for AI suggestion button

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadAvailablePrograms();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    if (userProfile != null && !_isInit) {
      // Populate state from the provider when the widget first loads
      _selectedActivityLevel = userProfile.activityLevel;
      _selectedPrimaryGoal = userProfile.primaryGoal;
      _selectedProgramId = userProfile.activeProgramId;
      _targetCaloriesController.text =
          userProfile.targetCalories?.toStringAsFixed(0) ?? '';
      _targetProteinController.text =
          userProfile.targetProtein?.toStringAsFixed(0) ?? '';
      _targetCarbsController.text =
          userProfile.targetCarbs?.toStringAsFixed(0) ?? '';
      _targetFatController.text =
          userProfile.targetFat?.toStringAsFixed(0) ?? '';
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }
  
  void _handleSave() {
    context.read<ProfileProvider>().saveGoals(
      activityLevel: _selectedActivityLevel ?? 'Sedentary',
      primaryGoal: _selectedPrimaryGoal ?? 'Maintain Weight',
      activeProgramId: _selectedProgramId,
      targetCalories: _targetCaloriesController.text,
      targetProtein: _targetProteinController.text,
      targetCarbs: _targetCarbsController.text,
      targetFat: _targetFatController.text,
    ).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goals saved successfully!'))));
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers
    final profileProvider = context.watch<ProfileProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    if (userProfile == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(value: _selectedPrimaryGoal, decoration: const InputDecoration(labelText: 'Primary Goal'), items: ['Lose Weight', 'Maintain Weight', 'Gain Muscle'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? newValue) => setState(() => _selectedPrimaryGoal = newValue)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(value: _selectedActivityLevel, decoration: const InputDecoration(labelText: 'Activity Level'), items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? newValue) => setState(() => _selectedActivityLevel = newValue)),
                const SizedBox(height: 16),
                // This dropdown now shows a loading indicator
                profileProvider.isLoadingPrograms
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Active Workout Program'),
                      value: _selectedProgramId,
                      items: profileProvider.availablePrograms.map((program) => DropdownMenuItem<String>(value: program.id, child: Text(program.name))).toList(),
                      onChanged: (String? newValue) => setState(() => _selectedProgramId = newValue)
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
                Text('Nutrition Goals', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _targetCaloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Calories'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _targetProteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _targetCarbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _targetFatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _handleSave,
          child: const Text('Save Goals & Settings'),
        ),
      ],
    );
  }
}

// --- Sub-View for Body Stats ---
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
  final Map<String, TextEditingController> _measurementControllers = { for (var item in ['Waist', 'Hips', 'Chest', 'Arms', 'Thighs']) item: TextEditingController() };
  bool _isMetric = true;
  String? _selectedBiologicalSex;
  bool _isInit = false;

  final List<String> _biologicalSexes = ['Male', 'Female'];
  final List<String> _measurements = ['Waist', 'Hips', 'Chest', 'Arms', 'Thighs'];

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    if (userProfile != null && !_isInit) {
      _initializeLocalState(userProfile);
      _isInit = true;
    }
  }

  void _initializeLocalState(UserProfile profile) {
    _isMetric = profile.unitSystem == 'metric';
    _selectedBiologicalSex = profile.biologicalSex;
    _updateTextFields(profile);
  }

  void _updateTextFields(UserProfile profile) {
    final weightData = profile.weight ?? {'value': 0.0, 'unit': 'kg'};
    final storedWeightValue = (weightData['value'] as num?)?.toDouble() ?? 0.0;
    final storedWeightUnit = weightData['unit'] as String? ?? 'kg';
    final double weightKg = (storedWeightUnit == 'lbs') ? storedWeightValue * 0.453592 : storedWeightValue;

    final heightCm = profile.height?['value'] as double? ?? 0.0;

    if (_isMetric) {
      _weightController.text = weightKg > 0 ? weightKg.toStringAsFixed(1) : '';
      _heightCmController.text = heightCm > 0 ? heightCm.toStringAsFixed(1) : '';
    } else {
      _weightController.text = weightKg > 0 ? (weightKg * 2.20462).toStringAsFixed(1) : '';
      if (heightCm > 0) {
        final totalInches = heightCm * 0.393701;
        _heightFtController.text = (totalInches ~/ 12).toString();
        _heightInController.text = (totalInches % 12).toStringAsFixed(1);
      } else { _heightFtController.text = ''; _heightInController.text = ''; }
    }
    _bodyFatController.text = profile.bodyFatPercentage?.toString() ?? '';
    _measurementControllers.forEach((name, controller) {
      final valueCm = profile.measurements?[name] as double? ?? 0.0;
      controller.text = (valueCm > 0) ? _isMetric ? valueCm.toStringAsFixed(1) : (valueCm * 0.393701).toStringAsFixed(1) : '';
    });
  }

  void _handleSave() {
    context.read<ProfileProvider>().saveStats(
      isMetric: _isMetric,
      biologicalSex: _selectedBiologicalSex ?? _biologicalSexes.first,
      bodyFat: _bodyFatController.text,
      weight: _weightController.text,
      heightCm: _heightCmController.text,
      heightFt: _heightFtController.text,
      heightIn: _heightInController.text,
      measurements: _measurementControllers.map((key, value) => MapEntry(key, value.text)),
    ).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Body stats saved successfully!'))));
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    if (userProfile == null) return const Center(child: CircularProgressIndicator());

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
                Text('Biometrics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(value: _selectedBiologicalSex, decoration: const InputDecoration(labelText: 'Biological Sex'), items: _biologicalSexes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? newValue) => setState(() => _selectedBiologicalSex = newValue)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _weightController, decoration: InputDecoration(labelText: 'Weight (${_isMetric ? 'kg' : 'lbs'})'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _bodyFatController, decoration: const InputDecoration(labelText: 'Body Fat (%)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ]),
                const SizedBox(height: 16),
                if (_isMetric)
                  TextField(controller: _heightCmController, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))
                else
                  Row(children: [
                    Expanded(child: TextField(controller: _heightFtController, decoration: const InputDecoration(labelText: 'Height (ft)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _heightInController, decoration: const InputDecoration(labelText: 'Height (in)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
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
                Text('Body Measurements', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16.0, runSpacing: 16.0,
                  children: _measurements.map((measurement) => SizedBox(
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: TextField(
                          controller: _measurementControllers[measurement],
                          decoration: InputDecoration(labelText: '$measurement (${_isMetric ? 'cm' : 'in'})'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      )).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _handleSave,
          child: const Text('Save Body Stats'),
        ),
      ],
    );
  }
}