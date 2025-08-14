import 'package:flutter/material.dart';

class MacroIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;
  // NEW: Flag to control showing the target value
  final bool showTarget;

  const MacroIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = '',
    this.showTarget = false, // Defaults to false to not break the nutrition log screen
  });

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
                color: color,
              ),
              Center(
                child: Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
        // NEW: Conditionally show the target value
        if (showTarget && target > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              'Goal: ${target.toStringAsFixed(0)}${unit.isNotEmpty ? ' $unit' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}