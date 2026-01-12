// lib/screens/onboarding/pages/create_program_page.dart

import 'package:flutter/material.dart';
import 'package:myapp/models/assistant_response.dart';
import 'package:myapp/models/workout_data.dart';
import 'package:myapp/screens/edit_workout_day_screen.dart';
import 'package:myapp/services/assistant_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';


class CreateProgramPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const CreateProgramPage({super.key, required this.formKey});

  @override
  State<CreateProgramPage> createState() => _CreateProgramPageState();
}

enum CreationMode { manual, ai }

class _CreateProgramPageState extends State<CreateProgramPage> {
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
      'Beginner': [
        'A 3-day full body workout',
        'A 4-day upper/lower body split'
      ],
      'Intermediate': [
        'A 4-day push/pull split',
        'A 5-day body part split (bro split)'
      ],
      'Advanced': [
        'A 6-day push/pull/legs program',
        'A 5-day undulating periodization plan'
      ]
    };

    final prompts = suggestions[proficiency] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Quick Start Ideas for "$proficiency"',
                style: Theme.of(ctx).textTheme.titleLarge),
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
    // Capture the navigator and scaffold messenger *before* the async gap.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final onboardingProvider = context.read<OnboardingProvider>();
      final firestoreService = context.read<FirestoreService>();
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId == null) throw Exception("User not found");

      // We now have a more robust save method in FirestoreService
      final newProgramId = await firestoreService.saveNewWorkoutProgram(userId, programToSave);
      
      onboardingProvider.updateActiveProgramId(newProgramId);
      
      // No need to validate here, we just care about the result.
      
      setState(() { _isProgramSaved = true; });

      // The context is no longer used directly here.
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Program saved successfully! You can now proceed.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      // The context is no longer used directly here.
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving program: $e')));
    } finally {
      // Check mounted before calling setState to avoid errors if the widget was disposed.
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture for async gap

    try {
      final userProfile = context.read<OnboardingProvider>().finalProfile;
      
      // CORRECTED: Call the new unified assistant service
      final response = await _assistantService.getAssistantResponse(
        prompt: _textController.text.trim(),
        history: [], // History is not needed for a one-shot generation
        userProfile: userProfile,
      );

      // Handle the polymorphic response
      if (mounted) {
        if (response.type == AssistantResponseType.program && response.programResponse != null) {
          final program = response.programResponse!;
          context.read<OnboardingProvider>().updateExerciseDaysPerWeek(program.days.length);
          await _navigateToEditor(program);
        } else {
          // Handle text response or error
          final errorMessage = response.textResponse ?? 'The AI failed to generate a program.';
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("An error occurred: $e")));
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
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          FormField<bool>(
            builder: (state) {
              if (state.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                      child: Text(state.errorText!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13))),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<CreationMode>(
            segments: [
              const ButtonSegment(
                  value: CreationMode.ai, label: Text('Ask AI')),
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
            Text('1. Choose your equipment',
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                OutlinedButton.icon(
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("Public Gym"),
                    onPressed: () => _showPromptSuggestions("Public Gym")),
                OutlinedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Home Gym"),
                    onPressed: () => _showPromptSuggestions("Home Gym")),
                OutlinedButton.icon(
                    icon: const Icon(Icons.self_improvement),
                    label: const Text("Bodyweight"),
                    onPressed: () => _showPromptSuggestions("Bodyweight Only")),
              ],
            ),
            const SizedBox(height: 16),
            Text('2. Describe your ideal program or get a suggestion',
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'e.g., "A 4-day upper/lower split"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please provide a description.'
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              onPressed: _isLoading ? null : _submitAIPrompt,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
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
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please provide a name.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (!hasProgramToReview) ...[
              Text('How many days per week?', style: textTheme.titleMedium),
              Slider(
                value: _numberOfDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: _numberOfDays.toString(),
                onChanged: (value) =>
                    setState(() => _numberOfDays = value.toInt()),
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
                backgroundColor: _isProgramSaved
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _isLoading ? null : _handleManualCreation,
              icon:
                  Icon(_isProgramSaved ? Icons.check_circle : Icons.edit_note),
              label: Text(_isProgramSaved
                  ? 'Program Saved!'
                  : (hasProgramToReview
                      ? 'Re-edit & Confirm'
                      : 'Design Program')),
            ),
          ],
        ],
      ),
    );
  }
}