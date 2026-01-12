// lib/screens/onboarding/pages/biometrics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';


class BiometricsPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const BiometricsPage({super.key, required this.formKey});

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